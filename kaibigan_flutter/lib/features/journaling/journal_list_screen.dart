import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../companion/companion_model.dart';
import 'journal_provider.dart';
import 'journal_editor_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Favorites', 'Daily', 'Gratitude', 'Reflection'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journalProvider = Provider.of<JournalProvider>(context);

    var entries = journalProvider.entries;

    if (_selectedCategory == 'Favorites') {
      entries = journalProvider.favoriteEntries;
    } else if (_selectedCategory != 'All') {
      final cleanCat = _selectedCategory.toLowerCase();
      entries = entries.where((e) => e.tags.any((t) => t.toLowerCase().contains(cleanCat)) || e.title.toLowerCase().contains(cleanCat)).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Journal Reflections 📖',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                onChanged: (val) => journalProvider.setSearchQuery(val),
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Search reflections, thoughts, or tags...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.honeyGold, width: 1.5),
                  ),
                ),
              ),
            ),

            // Category Filter Chips Row
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.honeyGold,
                      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.honeyGold
                              : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Entries List
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.honeyGold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 36,
                                color: AppColors.honeyAmber,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _selectedCategory == 'Favorites'
                                  ? 'No favorite entries yet.'
                                  : 'No journal reflections found.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Write a gentle reflection with your companion to start your journey.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final mascot = MascotInfo.getById(entry.companionId);

                        return Dismissible(
                          key: Key(entry.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await CozyConfirmSheet.show(
                              context,
                              title: 'Palayain ang Tala?',
                              message: 'Sigurado ka bang nais mong alisin ang journal note na "${entry.title}"? Valid at mahalaga ang bawat alaala mo.',
                              confirmLabel: 'Let Go',
                              cancelLabel: 'Keep Note',
                              icon: Icons.edit_note_rounded,
                            );
                          },
                          onDismissed: (_) {
                            journalProvider.deleteJournalEntry(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Journal reflection gently let go.'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Let Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                SizedBox(width: 8),
                                Icon(Icons.delete_outline, color: Colors.white),
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JournalEditorScreen(entry: entry),
                                  ),
                                );
                              },
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title.isEmpty ? 'Untitled Reflection' : entry.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 20,
                                      color: entry.isFavorite ? AppColors.moodAwful : Colors.grey,
                                    ),
                                    onPressed: () => journalProvider.toggleFavorite(entry.id),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: mascot.primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${mascot.avatarIcon} ${mascot.name}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: mascot.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormatter.formatShortDate(entry.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.honeyAmber,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text(
          'Write Reflection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
          );
        },
      ),
    );
  }
}
