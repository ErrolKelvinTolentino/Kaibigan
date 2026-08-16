import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../settings/user_provider.dart';
import '../../companion/companion_model.dart';
import '../../mood_tracking/mood_model.dart';
import '../../journaling/journal_provider.dart';

class DailyReflectionScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DailyReflectionScreen({super.key, this.onCompleted});

  @override
  State<DailyReflectionScreen> createState() => _DailyReflectionScreenState();
}

class _DailyReflectionScreenState extends State<DailyReflectionScreen> {
  final TextEditingController _wellController = TextEditingController();
  final TextEditingController _challengeController = TextEditingController();
  final TextEditingController _learnedController = TextEditingController();

  bool _isSubmitted = false;
  String _generatedAiInsight = '';

  @override
  void dispose() {
    _wellController.dispose();
    _challengeController.dispose();
    _learnedController.dispose();
    super.dispose();
  }

  void _finishReflection(UserProvider userProvider, MascotInfo mascot) async {
    final well = _wellController.text.trim();
    final challenge = _challengeController.text.trim();
    final learned = _learnedController.text.trim();

    if (well.isEmpty && challenge.isEmpty && learned.isEmpty) return;

    final lang = userProvider.language;
    if (lang == 'filipino') {
      _generatedAiInsight = "Salamat sa paglalaan ng oras upang pagnilayan ang iyong araw. Ipinakita mo ang katatagan sa kabila ng mga pagsubok, at ang iyong pasasalamat ay nagdudulot ng kapayapaan sa iyong puso. Ipagpatuloy ang pag-aalaga sa iyong sarili.";
    } else if (lang == 'taglish') {
      _generatedAiInsight = "Ang ganda ng self-awareness mo today! Kahit may mga challenges na hinarap, you held space for gratitude and growth. Proud ako sa growth mo, magpahinga ka nang mabuti ngayong gabi! 🐝✨";
    } else {
      _generatedAiInsight = "Thank you for taking the time to gently reflect on your day. Embracing both the challenges and the moments of gratitude is a true sign of resilience and self-compassion. Rest well tonight knowing you did great.";
    }

    final combinedContent = "🌟 What went well:\n$well\n\n🌧️ Challenges & coping:\n$challenge\n\n🌱 Lessons & gratitude:\n$learned";

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    await journalProvider.addJournalEntry(
      title: "Daily Reflection - ${DateFormat('MMM d, yyyy').format(DateTime.now())}",
      content: combinedContent,
      companionId: mascot.id,
      mood: 'peaceful',
      tags: ['Daily Reflection', 'Evening Reflection'],
      aiResponse: _generatedAiInsight,
    );

    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Daily Reflection",
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: AppColors.honeyAmber),
            tooltip: 'View Past Reflections',
            onPressed: () => _showPastReflectionsModal(context, isDark),
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _isSubmitted
              ? _buildAiInsightView(context, isDark, mascot)
              : _buildTemplateInputView(context, isDark, userProvider, mascot),
        ),
      ),
    );
  }

  Widget _buildTemplateInputView(BuildContext context, bool isDark, UserProvider userProvider, MascotInfo mascot) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              FeatureIconHelper.dailyReflection,
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text('🪞', style: TextStyle(fontSize: 44)),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 10),

        Text(
          "Evening Reflection Template",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          "Unpack your thoughts with ${mascot.name} before resting.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),

        const SizedBox(height: 14),

        // Prompt 1
        _buildPromptSection(
          isDark: isDark,
          title: "1. What went well today?",
          hint: "Big or small wins, happy moments...",
          controller: _wellController,
        ),

        const SizedBox(height: 10),

        // Prompt 2
        _buildPromptSection(
          isDark: isDark,
          title: "2. What challenged you & how did you respond?",
          hint: "Moments of stress, frustration, or patience...",
          controller: _challengeController,
        ),

        const SizedBox(height: 10),

        // Prompt 3
        _buildPromptSection(
          isDark: isDark,
          title: "3. What did you learn or appreciate?",
          hint: "Key insight, a lesson about yourself...",
          controller: _learnedController,
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _finishReflection(userProvider, mascot),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              "Complete Reflection",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPromptSection({
    required bool isDark,
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightView(BuildContext context, bool isDark, MascotInfo mascot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: mascot.primaryColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(
            mascot.materialIcon,
            size: 48,
            color: mascot.primaryColor,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 20),

        Text(
          "${mascot.name}'s Reflection Insight",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: MarkdownBody(
            data: _generatedAiInsight,
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
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onCompleted != null) {
                widget.onCompleted!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Save & Finish 🌙", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showPastReflectionsModal(BuildContext context, bool isDark) {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final reflections = journalProvider.entries
        .where((e) => e.tags.contains('Daily Reflection') || e.tags.contains('Reflection'))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Past Daily Reflections",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: reflections.isEmpty
                  ? Center(
                      child: Text(
                        "No past reflections yet.\nComplete today's reflection to start your collection!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: reflections.length,
                      itemBuilder: (context, index) {
                        final item = reflections[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.warmCream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(item.createdAt),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const Text('🪞', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              if (item.aiResponse != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "🐝 ${item.aiResponse!}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.honeyAmber),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
