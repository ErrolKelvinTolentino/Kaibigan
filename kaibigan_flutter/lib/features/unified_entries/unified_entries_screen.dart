import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../journaling/journal_provider.dart';
import '../journaling/journal_model.dart';
import '../journaling/journal_editor_screen.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../gratitude_garden/gratitude_model.dart';
import '../mood_tracking/mood_provider.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routines_provider.dart';
import '../routines/routine_model.dart';
import '../companion/companion_model.dart';

enum EntryCategory {
  all,
  journal,
  gratitude,
  mood,
  sleep,
  highlight,
  focus,
  reflection,
}

class UnifiedFeedItem {
  final String id;
  final String title;
  final String content;
  final String? subtitle;
  final String? aiInsight;
  final EntryCategory category;
  final String categoryTag;
  final Color categoryColor;
  final String iconAssetOrEmoji;
  final DateTime timestamp;
  final dynamic rawData;

  UnifiedFeedItem({
    required this.id,
    required this.title,
    required this.content,
    this.subtitle,
    this.aiInsight,
    required this.category,
    required this.categoryTag,
    required this.categoryColor,
    required this.iconAssetOrEmoji,
    required this.timestamp,
    this.rawData,
  });
}

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

    final List<UnifiedFeedItem> items = [];

    // 1. Journal entries
    for (final j in journalProvider.entries) {
      final isDailyReflection = j.tags.contains('Daily Reflection') || j.tags.contains('Reflection');
      items.add(UnifiedFeedItem(
        id: 'journal_${j.id}',
        title: j.title.isEmpty ? 'Journal Entry' : j.title,
        content: j.content,
        subtitle: j.mood.isNotEmpty ? 'Mood: ${j.mood}' : null,
        aiInsight: j.aiResponse,
        category: isDailyReflection ? EntryCategory.reflection : EntryCategory.journal,
        categoryTag: isDailyReflection ? 'Daily Reflection' : 'AI Journal',
        categoryColor: isDailyReflection ? AppColors.lavenderMist : AppColors.sageGreen,
        iconAssetOrEmoji: isDailyReflection ? FeatureIconHelper.dailyReflection : FeatureIconHelper.journal,
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
        content: m.note?.isNotEmpty == true ? m.note! : 'Logged mood score of ${m.moodScore}/5 with Kai & Ann.',
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
          categoryColor: isHighlight ? AppColors.softYellow : AppColors.sageGreen,
          iconAssetOrEmoji: isHighlight ? FeatureIconHelper.todaysHighlight : FeatureIconHelper.todaysFocus,
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
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q) ||
          (e.aiInsight?.toLowerCase().contains(q) ?? false) ||
          e.categoryTag.toLowerCase().contains(q)).toList();
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
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
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Search notes, reflections, thoughts...',
                    hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.honeyAmber),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                  _buildFilterChip('Gratitude', EntryCategory.gratitude, isDark),
                  _buildFilterChip('Mood', EntryCategory.mood, isDark),
                  _buildFilterChip('Sleep', EntryCategory.sleep, isDark),
                  _buildFilterChip('Highlight', EntryCategory.highlight, isDark),
                  _buildFilterChip('Focus', EntryCategory.focus, isDark),
                  _buildFilterChip('Reflection', EntryCategory.reflection, isDark),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Feed Content
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco_outlined, size: 64, color: AppColors.sageGreen.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No entries found',
                            style: AppTypography.heading3(context, isDark: isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start writing or recording your daily activities!',
                            style: AppTypography.bodySmall(context, isDark: isDark),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.honeyGold : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, UnifiedFeedItem item, bool isDark) {
    final dateFormatted = DateFormat('EEE, MMM d, yyyy • h:mm a').format(item.timestamp);
    final isPng = item.iconAssetOrEmoji.startsWith('assets/');

    return GestureDetector(
      onTap: () => _showDetailModal(context, item, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
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
                  Text(item.iconAssetOrEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.categoryTag,
                    style: TextStyle(
                      color: item.categoryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                    const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.honeyAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.aiInsight!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

  void _showDetailModal(BuildContext context, UnifiedFeedItem item, bool isDark) {
    final isPng = item.iconAssetOrEmoji.startsWith('assets/');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            Row(
              children: [
                if (isPng)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      item.iconAssetOrEmoji,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Text(item.iconAssetOrEmoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.categoryColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.categoryTag,
                          style: TextStyle(color: item.categoryColor, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(item.timestamp),
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const Divider(height: 24),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: item.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        em: GoogleFonts.lora(fontStyle: FontStyle.italic),
                        strong: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    if (item.aiInsight != null && item.aiInsight!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Builder(builder: (context) {
                        final entryMascot = item.rawData is JournalEntry
                            ? MascotInfo.getById((item.rawData as JournalEntry).companionId)
                            : null;
                        final mascotName = entryMascot?.name ?? 'Companion';
                        final mascotColor = entryMascot?.primaryColor ?? AppColors.honeyAmber;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: mascotColor.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: mascotColor.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    entryMascot != null ? entryMascot.materialIcon : Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: mascotColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$mascotName\'s Reflection',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: mascotColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(
                                data: item.aiInsight!,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  em: GoogleFonts.lora(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13.5,
                                    color: isDark ? AppColors.honeyGold : AppColors.honeyAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons (Edit / Delete / Close)
            Row(
              children: [
                if (item.rawData is JournalEntry) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JournalEditorScreen(entry: item.rawData as JournalEntry),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.honeyAmber,
                        side: const BorderSide(color: AppColors.honeyAmber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await CozyConfirmSheet.show(
                        context,
                        title: 'Palayain ang Tala?',
                        message: 'Sigurado ka bang nais mong alisin ang "${item.title}"? Valid at mahalaga ang bawat tala mo.',
                        confirmLabel: 'Let Go',
                        cancelLabel: 'Keep Entry',
                        icon: Icons.delete_outline_rounded,
                      );
                      if (confirmed && context.mounted) {
                        Navigator.of(ctx).pop();
                        _deleteFeedItem(context, item);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: const Text('Let Go', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFeedItem(BuildContext context, UnifiedFeedItem item) {
    if (item.category == EntryCategory.journal || item.category == EntryCategory.reflection) {
      if (item.rawData is JournalEntry) {
        final jp = Provider.of<JournalProvider>(context, listen: false);
        jp.deleteJournalEntry((item.rawData as JournalEntry).id);
      }
    } else if (item.category == EntryCategory.gratitude) {
      if (item.rawData is GratitudeEntry) {
        final gp = Provider.of<GratitudeProvider>(context, listen: false);
        gp.deleteGratitudeEntry((item.rawData as GratitudeEntry).id);
      }
    } else if (item.category == EntryCategory.mood) {
      if (item.rawData is MoodLog) {
        final mp = Provider.of<MoodProvider>(context, listen: false);
        mp.deleteMoodLog((item.rawData as MoodLog).id);
      }
    } else if (item.rawData is RoutineLog) {
      final rp = Provider.of<RoutinesProvider>(context, listen: false);
      rp.deleteLog((item.rawData as RoutineLog).id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry gently removed.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
