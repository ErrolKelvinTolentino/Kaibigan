import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import 'journal_provider.dart';
import 'journal_editor_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Favorites',
    'Daily',
    'Gratitude',
    'Reflection'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journalProvider = Provider.of<JournalProvider>(context);
    final language = context.watch<UserProvider>().language;
    String copy(String english, String filipino) => LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
        );

    var entries = journalProvider.entries;

    if (_selectedCategory == 'Favorites') {
      entries = journalProvider.favoriteEntries;
    } else if (_selectedCategory != 'All') {
      final cleanCat = _selectedCategory.toLowerCase();
      entries = entries
          .where((e) =>
              e.tags.any((t) => t.toLowerCase().contains(cleanCat)) ||
              e.title.toLowerCase().contains(cleanCat))
          .toList();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          copy('Journal reflections', 'Mga pagninilay'),
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: CozyFeatureBanner(
                eyebrow: copy(
                  'A place for the honest draft',
                  'Lugar para sa tapat na saloobin',
                ),
                title: copy('Your reflections', 'Iyong mga pagninilay'),
                subtitle: copy(
                  'Keep what mattered. Return when you are ready.',
                  'Itabi ang mahalaga. Balikan kapag handa ka na.',
                ),
                assetPath: 'assets/feature icons/Journal.png',
                placeholderLabel: 'journal-landscape',
                placeholderIcon: Icons.auto_stories_outlined,
                imageAlignment: Alignment(0, -0.28),
                height: 132,
              ),
            ),
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                onChanged: (val) => journalProvider.setSearchQuery(val),
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: copy(
                    'Search reflections, thoughts, or tags…',
                    'Maghanap sa mga pagninilay o tag…',
                  ),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                        color: AppColors.honeyGold, width: 1.5),
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
                      label: Text(
                        language == 'filipino'
                            ? switch (cat) {
                                'All' => 'Lahat',
                                'Favorites' => 'Paborito',
                                'Daily' => 'Araw-araw',
                                'Gratitude' => 'Pasasalamat',
                                _ => 'Pagninilay',
                              }
                            : cat,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.honeyGold,
                      backgroundColor:
                          isDark ? AppColors.darkCard : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.honeyGold
                              : (isDark
                                  ? AppColors.darkCardBorder
                                  : Colors.black.withValues(alpha: 0.06)),
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

            if (journalProvider.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            if (journalProvider.errorMessage != null)
              SyncStatusBanner(
                message: journalProvider.errorMessage!,
                onRetry: journalProvider.fetchJournalEntries,
              ),

            // Entries List
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: KaibiganStateView(
                        icon: _selectedCategory == 'Favorites'
                            ? Icons.favorite_border_rounded
                            : Icons.auto_stories_outlined,
                        title: _selectedCategory == 'Favorites'
                            ? copy(
                                'No favorites yet',
                                'Wala pang paborito',
                              )
                            : copy(
                                'This page is still quiet',
                                'Tahimik pa ang pahinang ito',
                              ),
                        message: copy(
                          'When something feels worth keeping, your reflection will wait for you here.',
                          'Kapag may nais kang itabi, hihintayin ka rito ng iyong pagninilay.',
                        ),
                        tone: KaibiganStateTone.warm,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
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
                              title: copy(
                                'Delete this entry?',
                                'Burahin ang talang ito?',
                              ),
                              message: copy(
                                '“${entry.title}” will be permanently removed.',
                                'Permanenteng buburahin ang “${entry.title}”.',
                              ),
                              confirmLabel: copy('Delete', 'Burahin'),
                              cancelLabel: copy('Keep entry', 'Panatilihin'),
                              icon: Icons.edit_note_rounded,
                            );
                          },
                          onDismissed: (_) async {
                            final deleted = await journalProvider
                                .deleteJournalEntry(entry.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  deleted
                                      ? copy(
                                          'Journal entry deleted.',
                                          'Nabura na ang tala.',
                                        )
                                      : journalProvider.errorMessage ??
                                          copy(
                                            'The entry could not be removed.',
                                            'Hindi mabura ang tala.',
                                          ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(copy('Delete', 'Burahin'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                const Icon(Icons.delete_outline,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.15 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JournalEditorScreen(entry: entry),
                                  ),
                                );
                              },
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.displayTitle(language),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      entry.isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 20,
                                      color: entry.isFavorite
                                          ? AppColors.moodAwful
                                          : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      final saved = await journalProvider
                                          .toggleFavorite(entry.id);
                                      if (!context.mounted || saved) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            journalProvider.errorMessage ??
                                                'The favorite change was not saved.',
                                          ),
                                        ),
                                      );
                                    },
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
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: mascot.primaryColor
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                        DateFormatter.formatJournalDate(
                                          entry.createdAt,
                                          language: language,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        label: Text(
          copy('Write reflection', 'Magsulat ng pagninilay'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
