import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../settings/user_provider.dart';
import '../../companion/companion_model.dart';
import '../../journaling/journal_provider.dart';

class DailyReflectionScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DailyReflectionScreen({super.key, this.onCompleted});

  @override
  State<DailyReflectionScreen> createState() => _DailyReflectionScreenState();
}

class _DailyReflectionScreenState extends State<DailyReflectionScreen> {
  static const _customTemplateKey = 'daily_reflection_custom_template';

  final TextEditingController _wellController = TextEditingController();
  final TextEditingController _challengeController = TextEditingController();
  final TextEditingController _learnedController = TextEditingController();

  late final List<_ReflectionTemplate> _templates = [
    const _ReflectionTemplate(
      id: 'evening_reset',
      title: 'Evening Reset',
      subtitle: 'Unpack the day and settle your mind.',
      emoji: '🌙',
      accent: Color(0xFFD79B35),
      prompts: [
        'What went well today?',
        'What challenged you, and how did you respond?',
        'What did you learn or appreciate?',
      ],
      hints: [
        'Big or small wins, kind moments, quiet progress…',
        'Name the hard part without judging yourself…',
        'A lesson, a person, or something worth remembering…',
      ],
    ),
    const _ReflectionTemplate(
      id: 'gentle_gratitude',
      title: 'Gentle Gratitude',
      subtitle: 'Notice the warmth already present.',
      emoji: '🌼',
      accent: Color(0xFF78A27A),
      prompts: [
        'What made you smile today?',
        'Who or what supported you?',
        'What small thing do you want to savor?',
      ],
      hints: [
        'A conversation, a meal, a tiny surprise…',
        'Someone, somewhere, or something inside you…',
        'Hold onto one detail before the day ends…',
      ],
    ),
    const _ReflectionTemplate(
      id: 'open_page',
      title: 'Open Page',
      subtitle: 'A softer space for whatever is here.',
      emoji: '📝',
      accent: Color(0xFF9B8BC4),
      prompts: [
        'What is on your mind right now?',
        'What feeling needs a little space?',
        'What would feel supportive tomorrow?',
      ],
      hints: [
        'Start anywhere. There is no right way to write…',
        'You can name it gently, in your own words…',
        'One small intention is enough…',
      ],
    ),
  ];

  String _selectedTemplateId = 'evening_reset';

  bool _isSubmitted = false;
  bool _isSaving = false;
  String _generatedAiInsight = '';

  _ReflectionTemplate get _selectedTemplate => _templates.firstWhere(
        (template) => template.id == _selectedTemplateId,
        orElse: () => _templates.first,
      );

  @override
  void initState() {
    super.initState();
    _loadCustomTemplate();
  }

  Future<void> _loadCustomTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_customTemplateKey);
    if (saved == null) return;

    try {
      final custom = _ReflectionTemplate.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _templates.removeWhere((template) => template.id == 'custom');
        _templates.add(custom);
      });
    } on FormatException {
      await prefs.remove(_customTemplateKey);
    } on TypeError {
      await prefs.remove(_customTemplateKey);
    }
  }

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

    if (well.isEmpty && challenge.isEmpty && learned.isEmpty || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);

    final lang = userProvider.language;
    if (lang == 'filipino') {
      _generatedAiInsight =
          "Salamat sa paglalaan ng oras upang pagnilayan ang iyong araw. Ipinakita mo ang katatagan sa kabila ng mga pagsubok, at ang iyong pasasalamat ay nagdudulot ng kapayapaan sa iyong puso. Ipagpatuloy ang pag-aalaga sa iyong sarili.";
    } else if (lang == 'taglish') {
      _generatedAiInsight =
          "Ang ganda ng self-awareness mo today! Kahit may mga challenges na hinarap, you held space for gratitude and growth. Proud ako sa growth mo, magpahinga ka nang mabuti ngayong gabi! 🐝✨";
    } else {
      _generatedAiInsight =
          "Thank you for taking the time to gently reflect on your day. Embracing both the challenges and the moments of gratitude is a true sign of resilience and self-compassion. Rest well tonight knowing you did great.";
    }

    final template = _selectedTemplate;
    final answers = [well, challenge, learned];
    final combinedContent = List.generate(
      template.prompts.length,
      (index) => '${index + 1}. ${template.prompts[index]}\n${answers[index]}',
    ).join('\n\n');

    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    await journalProvider.addJournalEntry(
      title:
          "${template.title} - ${DateFormat('MMM d, yyyy').format(DateTime.now())}",
      content: combinedContent,
      companionId: mascot.id,
      mood: 'peaceful',
      tags: ['Daily Reflection', template.title],
      aiResponse: _generatedAiInsight,
    );

    if (!mounted) return;
    if (journalProvider.errorMessage != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(journalProvider.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _isSaving = false;
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
          icon: Icon(Icons.close_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
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

  Widget _buildTemplateInputView(BuildContext context, bool isDark,
      UserProvider userProvider, MascotInfo mascot) {
    final template = _selectedTemplate;
    final paperColor =
        isDark ? const Color(0xFF252B27) : const Color(0xFFFFFEFA);

    return ListView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.honeyGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: template.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child:
                    Text(template.emoji, style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Writing with ${mascot.name}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.sageGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showTemplatePicker(context, isDark),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Templates'),
                style: TextButton.styleFrom(
                  foregroundColor: template.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.08),
        const SizedBox(height: 14),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
              decoration: BoxDecoration(
                color: paperColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE8DFD0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    template.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _showTemplateEditor(context, isDark),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Customize these prompts'),
                    style: TextButton.styleFrom(
                      foregroundColor: template.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    color:
                        template.accent.withValues(alpha: isDark ? 0.25 : 0.18),
                  ),
                  const SizedBox(height: 2),
                  _buildPromptSection(
                    isDark: isDark,
                    number: 1,
                    accent: template.accent,
                    title: template.prompts[0],
                    hint: template.hints[0],
                    controller: _wellController,
                  ),
                  _buildPromptSection(
                    isDark: isDark,
                    number: 2,
                    accent: template.accent,
                    title: template.prompts[1],
                    hint: template.hints[1],
                    controller: _challengeController,
                  ),
                  _buildPromptSection(
                    isDark: isDark,
                    number: 3,
                    accent: template.accent,
                    title: template.prompts[2],
                    hint: template.hints[2],
                    controller: _learnedController,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -7,
              left: 38,
              right: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 9,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF59625C)
                          : const Color(0xFFD7C9B4),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 80.ms, duration: 320.ms).slideY(begin: 0.04),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _finishReflection(userProvider, mascot),
            style: ElevatedButton.styleFrom(
              backgroundColor: template.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Save Reflection",
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
    required int number,
    required Color accent,
    required String title,
    required String hint,
    required TextEditingController controller,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomPaint(
            painter: _RuledPaperPainter(
              lineColor: isDark
                  ? Colors.white.withValues(alpha: 0.055)
                  : const Color(0xFFDDD6CA).withValues(alpha: 0.56),
            ),
            child: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.lora(
                fontSize: 14,
                height: 1.7,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lora(
                  fontSize: 13,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.52)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.46),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                border: InputBorder.none,
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 17,
              color: accent.withValues(alpha: isDark ? 0.20 : 0.13),
            ),
        ],
      ),
    );
  }

  Future<void> _showTemplatePicker(BuildContext context, bool isDark) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFFFFDF8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose your writing space',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Pick the prompts that fit the kind of day you had.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 18),
              ..._templates.map((template) {
                final isSelected = template.id == _selectedTemplateId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => Navigator.pop(sheetContext, template.id),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? template.accent
                                .withValues(alpha: isDark ? 0.18 : 0.10)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.035)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? template.accent.withValues(alpha: 0.55)
                              : isDark
                                  ? AppColors.darkCardBorder
                                  : const Color(0xFFEAE4DA),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: template.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              template.emoji,
                              style: const TextStyle(fontSize: 25),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  template.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: isSelected
                                ? template.accent
                                : isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.07),
      ),
    );

    if (selectedId != null && mounted) {
      setState(() => _selectedTemplateId = selectedId);
    }
  }

  Future<void> _showTemplateEditor(BuildContext context, bool isDark) async {
    final source = _selectedTemplate;
    final titleController = TextEditingController(text: source.title);
    final promptControllers = source.prompts
        .map((prompt) => TextEditingController(text: prompt))
        .toList();

    final customTemplate = await showModalBottomSheet<_ReflectionTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          top: 48,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFFFFDF8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Make this page yours',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Rename your template and adjust the questions. It will be saved for next time.',
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 18),
                _editorField(
                  isDark: isDark,
                  controller: titleController,
                  label: 'Template name',
                  icon: Icons.bookmark_outline_rounded,
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  promptControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _editorField(
                      isDark: isDark,
                      controller: promptControllers[index],
                      label: 'Prompt ${index + 1}',
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final prompts = promptControllers
                          .map((controller) => controller.text.trim())
                          .toList();
                      if (title.isEmpty ||
                          prompts.any((prompt) => prompt.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Add a name and complete all three prompts.'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                        sheetContext,
                        _ReflectionTemplate(
                          id: 'custom',
                          title: title,
                          subtitle: 'Your personal reflection ritual.',
                          emoji: '✍️',
                          accent: AppColors.sageGreen,
                          prompts: prompts,
                          hints: source.hints,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Save custom template',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final controller in promptControllers) {
      controller.dispose();
    }
    titleController.dispose();

    if (customTemplate == null || !mounted) return;
    setState(() {
      _templates.removeWhere((template) => template.id == 'custom');
      _templates.add(customTemplate);
      _selectedTemplateId = 'custom';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customTemplateKey,
      jsonEncode(customTemplate.toJson()),
    );
  }

  Widget _editorField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.sageGreen),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : const Color(0xFFE8E1D6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.sageGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAiInsightView(
      BuildContext context, bool isDark, MascotInfo mascot) {
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
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : Colors.black.withValues(alpha: 0.08),
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
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Save & Finish 🌙",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showPastReflectionsModal(BuildContext context, bool isDark) {
    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final reflections = journalProvider.entries
        .where((e) =>
            e.tags.contains('Daily Reflection') ||
            e.tags.contains('Reflection'))
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
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: reflections.isEmpty
                  ? Center(
                      child: Text(
                        "No past reflections yet.\nComplete today's reflection to start your collection!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
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
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.warmCream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy')
                                        .format(item.createdAt),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  const Text('🪞',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                              if (item.aiResponse != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "🐝 ${item.aiResponse!}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.honeyAmber),
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

class _ReflectionTemplate {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final List<String> prompts;
  final List<String> hints;

  const _ReflectionTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accent,
    required this.prompts,
    required this.hints,
  });

  factory _ReflectionTemplate.fromJson(Map<String, dynamic> json) {
    final prompts = (json['prompts'] as List<dynamic>).cast<String>();
    final hints = (json['hints'] as List<dynamic>).cast<String>();
    if (prompts.length != 3 || hints.length != 3) {
      throw const FormatException('A reflection template needs three prompts.');
    }
    return _ReflectionTemplate(
      id: 'custom',
      title: json['title'] as String,
      subtitle:
          json['subtitle'] as String? ?? 'Your personal reflection ritual.',
      emoji: json['emoji'] as String? ?? '✍️',
      accent: Color(json['accent'] as int? ?? AppColors.sageGreen.toARGB32()),
      prompts: prompts,
      hints: hints,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'emoji': emoji,
        'accent': accent.toARGB32(),
        'prompts': prompts,
        'hints': hints,
      };
}

class _RuledPaperPainter extends CustomPainter {
  final Color lineColor;

  const _RuledPaperPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const lineHeight = 23.8;
    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
