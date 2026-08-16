import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/ai_service.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import '../comfort_corner/akbay_safety_sheet.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
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
  final JournalEntry? initialEntry;
  final JournalEntry? entry;

  const JournalEditorScreen({super.key, this.initialEntry, this.entry});

  JournalEntry? get targetEntry => entry ?? initialEntry;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _activeFocusNode = FocusNode();

  final List<JournalTurn> _turns = [];
  bool _isGeneratingAi = false;
  String _selectedMood = 'calm';
  int _promptIndex = 0;

  final List<String> _guidingPrompts = [
    "What is occupying the most space in your head right now?",
    "What made you feel proud, grateful, or at peace recently?",
    "If you could say anything without fear of judgment, what would it be?",
    "What is one emotion you are trying not to feel today?",
    "What would the kindest version of yourself say to you right now?",
    "What is one small victory you achieved this week?",
  ];

  @override
  void initState() {
    super.initState();
    final target = widget.targetEntry;
    if (target != null) {
      _titleController.text = target.title;
      _selectedMood = target.mood;
      _turns.add(JournalTurn(
        userText: target.content,
        aiResponse: target.aiResponse,
      ));
    } else {
      _turns.add(JournalTurn(userText: ''));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    _activeFocusNode.dispose();
    for (var turn in _turns) {
      turn.dispose();
    }
    super.dispose();
  }

  void _shufflePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _guidingPrompts.length;
    });
  }

  int _calculateWordCount() {
    int total = 0;
    for (var turn in _turns) {
      final text = turn.userController.text.trim();
      if (text.isNotEmpty) {
        total += text.split(RegExp(r'\s+')).length;
      }
    }
    return total;
  }

  String _getAllUserContent() {
    return _turns
        .map((t) => t.userController.text.trim())
        .where((txt) => txt.isNotEmpty)
        .join('\n\n');
  }

  String? _getAllAiResponses() {
    final responses = _turns
        .map((t) => t.aiResponse)
        .where((res) => res != null && res.isNotEmpty)
        .join('\n\n---\n\n');
    return responses.isEmpty ? null : responses;
  }

  Future<void> _triggerAiReflection() async {
    final lastTurn = _turns.last;
    final textToReflectOn = lastTurn.userController.text.trim();

    if (textToReflectOn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something in your note before reflecting! ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAi = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final companionId = userProvider.selectedCompanion;
    final language = userProvider.language;

    try {
      final aiReply = await AIService.generateCompanionResponse(
        userText: textToReflectOn,
        companionId: companionId,
        language: language,
        mood: _selectedMood,
      );

      if (mounted) {
        setState(() {
          lastTurn.aiResponse = aiReply;
          _isGeneratingAi = false;

          // Prepare next turn prompt area
          _turns.add(JournalTurn(userText: ''));
        });

        // Auto-scroll to bottom
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
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAi = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate reflection: $e')),
        );
      }
    }
  }

  Widget _buildAiReplyBox(BuildContext context, MascotInfo mascot, String reply, bool isDark) {
    final isCrisisReply = reply.contains('1553') || reply.contains('Hotline') || reply.contains('Crisis');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? mascot.primaryColor.withValues(alpha: 0.14)
            : mascot.lightBgColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: mascot.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: mascot.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: mascot.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(mascot.avatarIcon, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mascot.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: mascot.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mascot.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI Companion Reflection',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: mascot.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: isDark ? Colors.white54 : Colors.black45,
                tooltip: 'Copy reflection',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reply));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reflection from ${mascot.name} copied!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: reply,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              em: GoogleFonts.lora(
                fontStyle: FontStyle.italic,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.honeyGold : AppColors.honeyAmber,
                height: 1.5,
              ),
              strong: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              blockquote: TextStyle(
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: mascot.primaryColor, width: 3),
                ),
              ),
              listBullet: TextStyle(
                color: mascot.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isCrisisReply) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '24/7 Free Crisis Hotlines (Philippines)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: '1553');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                        label: const Text('Call NCMH 1553', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: '09175584673');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone_in_talk, size: 14, color: Colors.redAccent),
                        label: const Text('Hopeline 0917-558-4673', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => AkbaySafetySheet.show(context),
                        icon: const Icon(Icons.info_outline, size: 14, color: AppColors.sageGreen),
                        label: const Text('All Safety Lines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sageGreen,
                          side: const BorderSide(color: AppColors.sageGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);
    final wordCount = _calculateWordCount();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => _saveAndPop(),
        ),
        actions: [
          if (widget.targetEntry != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.redAccent),
              tooltip: 'Delete Entry',
              onPressed: () async {
                final provider = Provider.of<JournalProvider>(context, listen: false);
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await CozyConfirmSheet.show(
                  context,
                  title: 'Palayain ang Tala?',
                  message: 'Sigurado ka bang nais mong alisin ang reflection na ito mula sa iyong journal?',
                  confirmLabel: 'Let Go',
                  cancelLabel: 'Keep Note',
                  icon: Icons.edit_note_rounded,
                );
                if (confirmed && mounted) {
                  provider.deleteJournalEntry(widget.targetEntry!.id);
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Journal note gently removed.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 22),
            color: mascot.primaryColor,
            tooltip: 'Export as PDF',
            onPressed: () async {
              final content = _getAllUserContent();
              if (content.isEmpty) return;

              await PdfService.exportJournalPdf(
                title: _titleController.text.isEmpty ? 'Journal Entry' : _titleController.text,
                content: content,
                aiResponse: _getAllAiResponses(),
                createdAt: widget.initialEntry?.createdAt ?? DateTime.now(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 24, color: AppColors.sageGreen),
            tooltip: 'Save Reflection',
            onPressed: () => _saveAndPop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guiding Prompt Banner with Reshuffle Icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.honeyGold.withValues(alpha: isDark ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.honeyGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _guidingPrompts[_promptIndex],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shuffle_rounded, color: AppColors.honeyAmber, size: 20),
                            tooltip: 'Reshuffle prompt',
                            onPressed: _shufflePrompt,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Header Date Subtitle & Mood Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.formatFullDate(widget.initialEntry?.createdAt ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Mood Tag Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildMoodChip('calm', 'Kalmado', Icons.spa_outlined, isDark),
                          const SizedBox(width: 6),
                          _buildMoodChip('grateful', 'Mapagpasalamat', Icons.favorite_outline_rounded, isDark),
                          const SizedBox(width: 6),
                          _buildMoodChip('reflective', 'Nagmumuni', Icons.self_improvement_rounded, isDark),
                          const SizedBox(width: 6),
                          _buildMoodChip('hopeful', 'May Pag-asa', Icons.wb_sunny_outlined, isDark),
                          const SizedBox(width: 6),
                          _buildMoodChip('tired', 'Pagod', Icons.bedtime_outlined, isDark),
                          const SizedBox(width: 6),
                          _buildMoodChip('heavy', 'Mabigat', Icons.cloud_outlined, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimal Title Input Field
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title of your reflection...',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Conversation / Entry Turns List
                    ..._turns.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final turn = entry.value;
                      final isLastTurn = idx == _turns.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: turn.userController,
                            focusNode: isLastTurn ? _activeFocusNode : null,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: idx == 0 ? 'Start writing freely here...' : 'Continue writing...',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (turn.aiResponse != null)
                            _buildAiReplyBox(context, mascot, turn.aiResponse!, isDark),
                        ],
                      );
                    }),

                    if (_isGeneratingAi)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
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
                              '${mascot.name} is reading and reflecting with you...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mascot.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 200.ms),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

            // Bottom Floating Notes Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$wordCount ${wordCount == 1 ? 'word' : 'words'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingAi ? null : _triggerAiReflection,
                    icon: Icon(Icons.auto_awesome_rounded, size: 16, color: mascot.primaryColor),
                    label: Text(
                      'Reflect with ${mascot.name} ✨',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: mascot.primaryColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mascot.primaryColor.withValues(alpha: 0.12),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: mascot.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndPop() {
    final title = _titleController.text.trim();
    final content = _getAllUserContent();

    if (title.isNotEmpty || content.isNotEmpty) {
      final provider = Provider.of<JournalProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final target = widget.targetEntry;
      if (target != null) {
        final updated = target.copyWith(
          title: title.isEmpty ? 'Untitled Entry' : title,
          content: content,
          aiResponse: _getAllAiResponses(),
          mood: _selectedMood,
        );
        provider.updateJournalEntry(updated);
      } else {
        provider.addJournalEntry(
          title: title.isEmpty ? 'Untitled Entry' : title,
          content: content,
          aiResponse: _getAllAiResponses(),
          companionId: userProvider.selectedCompanion,
          mood: _selectedMood,
        );
      }
    }
    Navigator.pop(context);
  }

  Widget _buildMoodChip(String moodKey, String label, IconData icon, bool isDark) {
    final isSelected = _selectedMood == moodKey;
    final activeColor = isDark ? AppColors.honeyGold : AppColors.honeyAmber;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = moodKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.honeyGold.withValues(alpha: isDark ? 0.3 : 0.2)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.honeyGold
                : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.07)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
