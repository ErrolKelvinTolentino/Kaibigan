import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../journaling/journal_provider.dart';
import '../../settings/user_provider.dart';

class NightHighlightScreen extends StatefulWidget {
  const NightHighlightScreen({super.key});

  @override
  State<NightHighlightScreen> createState() => _NightHighlightScreenState();
}

class _NightHighlightScreenState extends State<NightHighlightScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _saveHighlight() {
    if (_titleController.text.trim().isEmpty &&
        _storyController.text.trim().isEmpty) {
      return;
    }

    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    journalProvider.addJournalEntry(
      title: _titleController.text.trim().isEmpty
          ? 'Evening Highlight'
          : _titleController.text.trim(),
      content: _storyController.text.trim(),
      companionId: userProvider.selectedCompanion,
      mood: 'peaceful',
      tags: ['Night', 'Highlight'],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evening highlight saved to your Journal!'),
        backgroundColor: AppColors.beePrimary,
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
          'Today\'s Highlight',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.beePrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of 2',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.beePrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Page 1: Favorite Moment
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.beePrimary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_stories_outlined,
                                  color: AppColors.beePrimary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text('Page 1: Favorite Moment',
                                style: AppTypography.titleLarge(context,
                                    isDark: isDark)),
                          ],
                        ).animate().fadeIn(),
                        const SizedBox(height: 20),
                        Text(
                          'What was the best part of your day?',
                          style: AppTypography.titleMedium(context,
                              isDark: isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Write a short headline or summary of a moment that brought a smile.',
                          style:
                              AppTypography.bodyMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. Laughing with friends over lunch...',
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.beePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Next: Tell Us More',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page 2: Story Detail
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.beePrimary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_note_outlined,
                                  color: AppColors.beePrimary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text('Page 2: Reflect & Describe',
                                style: AppTypography.titleLarge(context,
                                    isDark: isDark)),
                          ],
                        ).animate().fadeIn(),
                        const SizedBox(height: 20),
                        Text(
                          'Tell us more about it!',
                          style: AppTypography.titleMedium(context,
                              isDark: isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Why did this moment feel special? What were you feeling?',
                          style:
                              AppTypography.bodyMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _storyController,
                            maxLines: 6,
                            style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe the details of your highlight...',
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveHighlight,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.beePrimary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('Save Highlight',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
