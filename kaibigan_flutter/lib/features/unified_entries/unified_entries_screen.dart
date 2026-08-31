import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../journaling/journal_provider.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../gratitude_garden/gratitude_model.dart';
import '../mood_tracking/mood_provider.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routines_provider.dart';
import '../routines/routine_model.dart';
import '../settings/user_provider.dart';
import 'unified_entry_detail_screen.dart';
import 'unified_feed_item.dart';

class UnifiedEntriesScreen extends StatefulWidget {
  const UnifiedEntriesScreen({super.key});

  @override
  State<UnifiedEntriesScreen> createState() => _UnifiedEntriesScreenState();
}

class _UnifiedEntriesScreenState extends State<UnifiedEntriesScreen> {
  EntryCategory _selectedCategory = EntryCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UnifiedFeedItem> _buildUnifiedList(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    final gratitudeProvider = Provider.of<GratitudeProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final routinesProvider = Provider.of<RoutinesProvider>(context);
    final language = context.read<UserProvider>().language;

    final List<UnifiedFeedItem> items = [];

    // 1. Journal entries
    for (final j in journalProvider.entries) {
      final isDailyReflection =
          j.tags.contains('Daily Reflection') || j.tags.contains('Reflection');
      items.add(UnifiedFeedItem(
        id: 'journal_${j.id}',
        title: j.displayTitle(language),
        content: j.content,
        subtitle: j.mood.isNotEmpty ? 'Mood: ${j.mood}' : null,
        aiInsight: j.aiResponse,
        category: isDailyReflection
            ? EntryCategory.reflection
            : EntryCategory.journal,
        categoryTag: isDailyReflection ? 'Daily Reflection' : 'AI Journal',
        categoryColor:
            isDailyReflection ? AppColors.lavenderMist : AppColors.sageGreen,
        iconAssetOrEmoji: isDailyReflection
            ? FeatureIconHelper.dailyReflection
            : FeatureIconHelper.journal,
        timestamp: j.createdAt,
        rawData: j,
      ));
    }

    // 2. Gratitude Garden entries
    for (final g in gratitudeProvider.entries) {
      items.add(UnifiedFeedItem(
        id: 'gratitude_${g.id}',
        title: 'Gratitude: ${GratitudeEntry.getFlowerName(g.flowerType)}',
        content: g.content,
        subtitle: GratitudeEntry.getFlowerMeaning(g.flowerType),
        category: EntryCategory.gratitude,
        categoryTag: 'Gratitude Garden',
        categoryColor: AppColors.honeyGold,
        iconAssetOrEmoji: FeatureIconHelper.gratitudeGarden,
        timestamp: g.createdAt,
        rawData: g,
      ));
    }

    // 3. Mood Tracker logs
    for (final m in moodProvider.logs) {
      items.add(UnifiedFeedItem(
        id: 'mood_${m.id}',
        title: 'Mood: ${m.moodLabel}',
        content: m.note?.isNotEmpty == true
            ? m.note!
            : 'Logged mood score of ${m.moodScore}/5 with Kai & Ann.',
        subtitle: 'Energy: ${m.energyLevel}/5 • Stress: ${m.stressLevel}/5',
        category: EntryCategory.mood,
        categoryTag: 'Mood Tracker',
        categoryColor: MoodLog.getMoodColor(m.moodScore),
        iconAssetOrEmoji: MoodLog.getMoodAssetPath(m.moodScore),
        timestamp: m.createdAt,
        rawData: m,
      ));
    }

    // 4. Routine Logs (Focus, Highlight, Sleep)
    for (final r in routinesProvider.logs) {
      if (r.focusOrHighlight != null && r.focusOrHighlight!.isNotEmpty) {
        final isHighlight = r.routineType == RoutineType.night;
        items.add(UnifiedFeedItem(
          id: 'routine_fh_${r.id}',
          title: isHighlight ? "Today's Highlight" : "Today's Focus",
          content: r.focusOrHighlight!,
          category: isHighlight ? EntryCategory.highlight : EntryCategory.focus,
          categoryTag: isHighlight ? "Today's Highlight" : "Today's Focus",
          categoryColor:
              isHighlight ? AppColors.softYellow : AppColors.sageGreen,
          iconAssetOrEmoji: isHighlight
              ? FeatureIconHelper.todaysHighlight
              : FeatureIconHelper.todaysFocus,
          timestamp: r.completedAt,
          rawData: r,
        ));
      }

      if (r.sleepFeeling != null) {
        items.add(UnifiedFeedItem(
          id: 'routine_sleep_${r.id}',
          title: 'Sleep Status: ${r.sleepFeeling!.label}',
          content: r.sleepFeeling!.description,
          category: EntryCategory.sleep,
          categoryTag: 'Sleep Log',
          categoryColor: AppColors.skyBlue,
          iconAssetOrEmoji: r.sleepFeeling!.assetPath,
          timestamp: r.completedAt,
          rawData: r,
        ));
      }
    }

    // Filter by category
    var filtered = items;
    if (_selectedCategory != EntryCategory.all) {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.content.toLowerCase().contains(q) ||
              (e.aiInsight?.toLowerCase().contains(q) ?? false) ||
              e.categoryTag.toLowerCase().contains(q))
          .toList();
    }

    // Sort by timestamp descending
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildUnifiedList(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Entries',
          style: AppTypography.heading2(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Search notes, reflections, thoughts...',
                    hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: AppColors.honeyAmber),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All', EntryCategory.all, isDark),
                  _buildFilterChip('Journal', EntryCategory.journal, isDark),
                  _buildFilterChip(
                      'Gratitude', EntryCategory.gratitude, isDark),
                  _buildFilterChip('Mood', EntryCategory.mood, isDark),
                  _buildFilterChip('Sleep', EntryCategory.sleep, isDark),
                  _buildFilterChip(
                      'Highlight', EntryCategory.highlight, isDark),
                  _buildFilterChip('Focus', EntryCategory.focus, isDark),
                  _buildFilterChip(
                      'Reflection', EntryCategory.reflection, isDark),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Feed Content
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: KaibiganStateView(
                        icon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.eco_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'Nothing matched that search'
                            : 'Your story begins quietly',
                        message: _searchQuery.isNotEmpty
                            ? 'Try a simpler word or choose a different entry type.'
                            : 'Saved reflections, moods, and meaningful moments will gather here over time.',
                        tone: KaibiganStateTone.botanical,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildEntryCard(context, item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, EntryCategory category, bool isDark) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedCategory = category);
        },
        selectedColor: AppColors.honeyGold,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12.5,
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
      ),
    );
  }

  Widget _buildEntryCard(
      BuildContext context, UnifiedFeedItem item, bool isDark) {
    final dateFormatted =
        DateFormat('EEE, MMM d, yyyy • h:mm a').format(item.timestamp);
    final isPng = item.iconAssetOrEmoji.startsWith('assets/');

    return InkWell(
      onTap: () => _openEntryDetail(context, item),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Icon + Tag + Date)
            Row(
              children: [
                if (isPng)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      item.iconAssetOrEmoji,
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Text(item.iconAssetOrEmoji,
                      style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.categoryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.categoryTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.categoryColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMM d').format(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              item.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 6),

            // Content preview
            Text(
              item.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),

            // AI Reflection pill if available
            if (item.aiInsight != null && item.aiInsight!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.honeyGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.honeyAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.aiInsight!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Footer date info
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEntryDetail(
    BuildContext context,
    UnifiedFeedItem item,
  ) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UnifiedEntryDetailScreen(item: item),
      ),
    );
    if (deleted == true && mounted) setState(() {});
  }
}
