import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import 'letters_provider.dart';

class FutureLettersScreen extends StatefulWidget {
  const FutureLettersScreen({super.key});

  @override
  State<FutureLettersScreen> createState() => _FutureLettersScreenState();
}

class _FutureLettersScreenState extends State<FutureLettersScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int _selectedDurationDays = 30; // 7, 30, 365

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lettersProvider = Provider.of<LettersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Letters to Future Self 💌',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Write a message to your future self. It will remain locked until your chosen date arrives.',
                style: AppTypography.bodyMedium(context, isDark: isDark),
              ),
            ),
            Expanded(
              child: lettersProvider.letters.isEmpty
                  ? const Center(child: Text('No future letters written yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: lettersProvider.letters.length,
                      itemBuilder: (context, index) {
                        final letter = lettersProvider.letters[index];
                        final isUnlocked = letter.isReadyToUnlock;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUnlocked
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    color: isUnlocked
                                        ? AppColors.sageGreen
                                        : AppColors.moodLow,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      letter.title,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? AppColors.sageGreen
                                              .withValues(alpha: 0.15)
                                          : AppColors.moodLow
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isUnlocked
                                          ? 'Unlocked'
                                          : 'Unlocks ${DateFormatter.formatShortDate(letter.deliverAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isUnlocked
                                            ? AppColors.sageGreen
                                            : AppColors.moodLow,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isUnlocked
                                    ? letter.content
                                    : '🔒 This letter is sealed until the unlock date arrives.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: isUnlocked
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  color: isUnlocked
                                      ? (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.annPrimary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Write Letter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _showWriteLetterSheet(context),
      ),
    );
  }

  void _showWriteLetterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write to Your Future Self 💌',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Title (e.g. Note to me in 1 month)',
                      filled: true,
                      fillColor: AppColors.warmCream,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Write your hopes, reminders, or encouragement...',
                      filled: true,
                      fillColor: AppColors.warmCream,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Unlock After:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDurationChip(7, '1 Week', setSheetState),
                      const SizedBox(width: 8),
                      _buildDurationChip(30, '1 Month', setSheetState),
                      const SizedBox(width: 8),
                      _buildDurationChip(365, '1 Year', setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.annPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () {
                        if (_contentController.text.trim().isEmpty) return;
                        final provider = Provider.of<LettersProvider>(context,
                            listen: false);
                        provider.createLetter(
                          title: _titleController.text.isEmpty
                              ? 'Letter to Future Self'
                              : _titleController.text,
                          content: _contentController.text.trim(),
                          deliverAt: DateTime.now()
                              .add(Duration(days: _selectedDurationDays)),
                        );
                        _titleController.clear();
                        _contentController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Seal & Send to Future',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationChip(int days, String label, StateSetter setSheetState) {
    final isSelected = _selectedDurationDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.annPrimary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (val) {
        if (val) {
          setSheetState(() {
            _selectedDurationDays = days;
          });
        }
      },
    );
  }
}
