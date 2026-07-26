import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/ai_service.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import 'journal_provider.dart';
import 'journal_model.dart';

class JournalTurn {
  final TextEditingController userController;
  String? aiResponse;

  JournalTurn({
    required String userText,
    this.aiResponse,
  }) : userController = TextEditingController(text: userText);

  void dispose() {
    userController.dispose();
  }
}

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? entry;
  const JournalEditorScreen({super.key, this.entry});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _activeContentController;
  late FocusNode _activeFocusNode;
  late ScrollController _scrollController;

  final List<JournalTurn> _turns = [];
  bool _isGenerating = false;
  int _seedStage = 1; // 1: Seed, 2: Sprout, 3: Bloom

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _activeContentController = TextEditingController();
    _activeFocusNode = FocusNode();
    _scrollController = ScrollController();

    _seedStage = widget.entry?.reflectionSeedStage ?? 1;

    // Load initial entry content if editing an existing entry
    if (widget.entry != null) {
      final initialContent = widget.entry!.content;
      final initialAi = widget.entry!.aiResponse;

      if (initialContent.isNotEmpty) {
        _turns.add(JournalTurn(
          userText: initialContent,
          aiResponse: initialAi,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _activeContentController.dispose();
    _activeFocusNode.dispose();
    _scrollController.dispose();
    for (final turn in _turns) {
      turn.dispose();
    }
    super.dispose();
  }

  String _getAllUserContent() {
    final List<String> parts = [];
    for (final turn in _turns) {
      if (turn.userController.text.trim().isNotEmpty) {
        parts.add(turn.userController.text.trim());
      }
    }
    if (_activeContentController.text.trim().isNotEmpty) {
      parts.add(_activeContentController.text.trim());
    }
    return parts.join('\n\n');
  }

  String? _getAllAiResponses() {
    final List<String> responses = [];
    for (final turn in _turns) {
      if (turn.aiResponse != null && turn.aiResponse!.isNotEmpty) {
        responses.add(turn.aiResponse!);
      }
    }
    return responses.isEmpty ? null : responses.join('\n\n');
  }

  Widget _buildAiReplyBox(BuildContext context, MascotInfo mascot, String reply, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mascot.lightBgColor.withValues(alpha: isDark ? 0.15 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: mascot.primaryColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mascot.avatarIcon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '• ${mascot.name.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mascot.primaryColor,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply,
            style: AppTypography.companionInlineResponse(
              color: isDark ? AppColors.textPrimaryDark : mascot.primaryColor.withValues(alpha: 0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    final hasContent = _turns.isNotEmpty || _activeContentController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'Bagong Journal' : 'Journal Entry',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          if (widget.entry != null || hasContent)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export to PDF',
              onPressed: () {
                PDFService.exportJournalToPDF(
                  title: _titleController.text.isEmpty ? 'Journal Entry' : _titleController.text,
                  content: _getAllUserContent(),
                  aiResponse: _getAllAiResponses(),
                  companionName: mascot.name,
                  createdAt: widget.entry?.createdAt ?? DateTime.now(),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Date Header & Reflection Seed Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: isDark ? AppColors.darkCard : AppColors.warmCream,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatFullDate(
                      widget.entry?.createdAt ?? DateTime.now(),
                      language: userProvider.preferredLanguage,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _seedStage == 3 ? '🌺 Blooming Reflection' : (_seedStage == 2 ? '🌱 Sprouting Seed' : '🌱 Reflection Seed'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Note Content Editor Flow
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Medyo mabigat na araw...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Render completed turns (User text followed by Kai Message box)
                    for (int i = 0; i < _turns.length; i++) ...[
                      TextField(
                        controller: _turns[i].userController,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                      if (_turns[i].aiResponse != null && _turns[i].aiResponse!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildAiReplyBox(context, mascot, _turns[i].aiResponse!, isDark),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // Active Input Field positioned BELOW Kai's message!
                    TextField(
                      controller: _activeContentController,
                      focusNode: _activeFocusNode,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: _turns.isEmpty
                            ? 'Isulat mo lang rito ang nararamdaman mo ngayon...'
                            : 'Ipagpatuloy ang pagsusulat dito...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),

                    if (_isGenerating) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(mascot.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Nagiisip si ${mascot.name}...',
                            style: AppTypography.companionInlineResponse(color: mascot.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Bar ("I-send kay Kai")
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mascot.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  icon: _isGenerating
                      ? const SizedBox.shrink()
                      : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  label: Text(
                    _isGenerating ? 'Nag-iisip si ${mascot.name}...' : 'I-send kay ${mascot.name}',
                    style: AppTypography.labelButton(context),
                  ),
                  onPressed: _isGenerating
                      ? null
                      : () async {
                          final activeText = _activeContentController.text.trim();
                          if (activeText.isEmpty && _turns.isEmpty) return;

                          setState(() {
                            _isGenerating = true;
                          });

                          final fullUserText = _getAllUserContent();

                          final aiReply = await AIService.generateCompanionResponse(
                            userText: _titleController.text.isEmpty
                                ? fullUserText
                                : '${_titleController.text}\n$fullUserText',
                            companionId: mascot.id,
                            language: userProvider.preferredLanguage,
                          );

                          if (mounted) {
                            setState(() {
                              if (activeText.isNotEmpty) {
                                _turns.add(JournalTurn(
                                  userText: activeText,
                                  aiResponse: aiReply,
                                ));
                                _activeContentController.clear();
                              } else if (_turns.isNotEmpty) {
                                _turns.last.aiResponse = aiReply;
                              }

                              _seedStage = 3; // Flower bloomed!
                              _isGenerating = false;
                            });

                            // Save aggregated journal entry
                            await journalProvider.addJournalEntry(
                              title: _titleController.text,
                              content: _getAllUserContent(),
                              companionId: mascot.id,
                              language: userProvider.preferredLanguage,
                              requestAiReflection: false,
                            );

                            // Auto-focus input field below Kai message & scroll to bottom
                            Future.delayed(const Duration(milliseconds: 150), () {
                              if (mounted) {
                                _activeFocusNode.requestFocus();
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              }
                            });
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
