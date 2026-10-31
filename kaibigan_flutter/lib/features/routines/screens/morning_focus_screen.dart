import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../journaling/journal_provider.dart';
import '../../settings/user_provider.dart';

class MorningFocusScreen extends StatefulWidget {
  const MorningFocusScreen({super.key});

  @override
  State<MorningFocusScreen> createState() => _MorningFocusScreenState();
}

class _MorningFocusScreenState extends State<MorningFocusScreen> {
  final TextEditingController _focusController = TextEditingController();
  String _selectedPrompt =
      'What is your single most important intention for today?';

  final List<String> _promptSuggestions = [
    'What is your single most important intention for today?',
    'What would make today feel gentle and fulfilling?',
    'What mindset or energy do you want to cultivate today?',
    'What is one small win you want to achieve before sunset?',
  ];

  final List<String> _tagSuggestions = [
    'Productivity',
    'Calmness',
    'Healing',
    'Self Care',
    'Relationships',
    'Creativity'
  ];
  final List<String> _selectedTags = ['Calmness'];

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _saveFocus() {
    if (_focusController.text.trim().isEmpty) return;

    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    journalProvider.addJournalEntry(
      title: 'Morning Focus & Intention',
      content: _focusController.text.trim(),
      companionId: userProvider.selectedCompanion,
      mood: 'calm',
      tags: List.from(_selectedTags),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Morning focus saved to your Journal!'),
        backgroundColor: AppColors.sageGreen,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Today\'s Morning Focus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline,
                          color: AppColors.sageGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Intention',
                              style: AppTypography.bodySmall(context,
                                  isDark: isDark)),
                          Text('Set your gentle focus',
                              style: AppTypography.titleMedium(context,
                                  isDark: isDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.05),
              const SizedBox(height: 24),

              Text('Guided Focus Prompts:',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _promptSuggestions.map((prompt) {
                  final isSelected = _selectedPrompt == prompt;
                  return ChoiceChip(
                    label: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.sageGreen,
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.sageGreen
                              : (isDark
                                  ? AppColors.darkCardBorder
                                  : Colors.black.withValues(alpha: 0.08))),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPrompt = prompt;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Journal Text Input Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPrompt,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: AppColors.sageGreen),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _focusController,
                      maxLines: 6,
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      decoration: const InputDecoration(
                        hintText:
                            'Type your focus, priorities, or gentle intention for today...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Focus Tags:',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tagSuggestions.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.sageGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.sageGreen,
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.sageGreen
                              : (isDark
                                  ? AppColors.darkCardBorder
                                  : Colors.black.withValues(alpha: 0.08))),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveFocus,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Morning Focus',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
