import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../settings/user_provider.dart';
import 'garden_layout.dart';
import 'gratitude_model.dart';
import 'gratitude_planting_page.dart';
import 'gratitude_provider.dart';
import 'polished_flower_asset.dart';
import 'responsive_garden_scene.dart';

class GardenScreen extends StatefulWidget {
  final VoidCallback? onEntrySaved;
  final VoidCallback? onRoutineSkip;
  final bool openPlantingOnStart;

  const GardenScreen({
    super.key,
    this.onEntrySaved,
    this.onRoutineSkip,
    this.openPlantingOnStart = false,
  });

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _selectedGardenIndex = 0;
  bool _isListView = false;
  bool _didOpenInitialPlanting = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _showPreviousGarden() {
    if (_selectedGardenIndex == 0) return;
    setState(() => _selectedGardenIndex--);
  }

  void _showNextGarden(int unlockedCount) {
    if (_selectedGardenIndex >= unlockedCount - 1) return;
    setState(() => _selectedGardenIndex++);
  }

  void _handleHorizontalSwipe(
    DragEndDetails details,
    int unlockedCount,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -180) {
      _showNextGarden(unlockedCount);
    } else if (velocity > 180) {
      _showPreviousGarden();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GratitudeProvider>();
    final user = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlockedCount = provider.unlockedGardenCount;
    if (_selectedGardenIndex >= unlockedCount) {
      _selectedGardenIndex = unlockedCount - 1;
    }
    final gardenEntries = provider.entriesForGarden(_selectedGardenIndex);
    final isFull = provider.isGardenFull(_selectedGardenIndex);
    final period = GardenLayout.periodFor(
      _now,
      appearance: user.gardenAppearance,
    );
    final sceneForeground = period == GardenScenePeriod.day
        ? const Color(0xFF2D3B2A)
        : Colors.white;
    if (widget.openPlantingOnStart &&
        !_didOpenInitialPlanting &&
        !provider.isLoading) {
      _didOpenInitialPlanting = true;
      final plantingGarden = GardenLayout.automaticPlantingGarden(
        provider.entries,
      );
      _selectedGardenIndex = plantingGarden;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPlantingPage(context, plantingGarden);
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      extendBodyBehindAppBar: !_isListView,
      appBar: AppBar(
        backgroundColor: _isListView
            ? (isDark ? AppColors.darkBackground : AppColors.warmCream)
            : Colors.transparent,
        elevation: 0,
        foregroundColor: _isListView
            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
            : sceneForeground,
        title: Text(
          'Gratitude Garden',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _isListView
                ? (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)
                : sceneForeground,
            fontWeight: FontWeight.w800,
            shadows: _isListView
                ? null
                : [
                    Shadow(
                      color: period == GardenScenePeriod.day
                          ? Colors.white70
                          : Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('garden-view-toggle'),
            tooltip: _isListView ? 'View garden' : 'View gratitude list',
            onPressed: () => setState(() => _isListView = !_isListView),
            icon: Icon(
              _isListView
                  ? Icons.yard_outlined
                  : Icons.format_list_bulleted_rounded,
            ),
          ),
        ],
      ),
      body: _isListView
          ? _buildListView(context, provider, user.language, isDark)
          : Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) =>
                      _handleHorizontalSwipe(details, unlockedCount),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    child: ResponsiveGardenScene(
                      key: ValueKey(
                        'garden-scene-$_selectedGardenIndex-${period.name}',
                      ),
                      entries: gardenEntries,
                      now: _now,
                      appearance: user.gardenAppearance,
                      onFlowerTap: (entry) => _showFlowerDetailSheet(
                        context,
                        entry,
                        user.language,
                      ),
                      onEmptyTap: () => _openPlantingPage(
                        context,
                        _selectedGardenIndex,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Column(
                      children: [
                        if (provider.errorMessage != null)
                          SyncStatusBanner(
                            message: provider.errorMessage!,
                            onRetry: provider.fetchGratitudeEntries,
                            margin: const EdgeInsets.only(bottom: 10),
                            backgroundColor: period == GardenScenePeriod.day
                                ? Colors.white.withValues(alpha: 0.94)
                                : const Color(0xFF142F38)
                                    .withValues(alpha: 0.96),
                            foregroundColor: period == GardenScenePeriod.day
                                ? AppColors.textPrimaryLight
                                : Colors.white,
                          ),
                        const Spacer(),
                        _GardenBottomControls(
                          gardenIndex: _selectedGardenIndex,
                          flowerCount: gardenEntries.length,
                          unlockedCount: unlockedCount,
                          isFull: isFull,
                          isLoading: provider.isLoading,
                          isDay: period == GardenScenePeriod.day,
                          onPrevious: _showPreviousGarden,
                          onNext: () => _showNextGarden(unlockedCount),
                          onPlant: () => _openPlantingPage(
                            context,
                            _selectedGardenIndex,
                          ),
                          onOpenNext: () => _showNextGarden(unlockedCount),
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    GratitudeProvider provider,
    String language,
    bool isDark,
  ) {
    final entries = List<GratitudeEntry>.of(provider.entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return SafeArea(
      child: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (provider.errorMessage != null)
            SyncStatusBanner(
              message: provider.errorMessage!,
              onRetry: provider.fetchGratitudeEntries,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your gratitude memories',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${provider.flowerCount} flowers across ${provider.unlockedGardenCount} ${provider.unlockedGardenCount == 1 ? 'garden' : 'gardens'}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: provider.isGardenFull(
                          GardenLayout.automaticPlantingGarden(
                              provider.entries))
                      ? null
                      : () => _openPlantingPage(
                            context,
                            GardenLayout.automaticPlantingGarden(
                              provider.entries,
                            ),
                          ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Plant'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.honeyAmber,
                    foregroundColor: AppColors.onHoney,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_florist_outlined,
                            size: 48,
                            color: AppColors.sageGreen,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your first gratitude can grow here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _GardenMemoryTile(
                        entry: entry,
                        isDark: isDark,
                        language: language,
                        onTap: () => _showFlowerDetailSheet(
                          context,
                          entry,
                          language,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlantingPage(
    BuildContext rootContext,
    int gardenIndex,
  ) async {
    final provider = rootContext.read<GratitudeProvider>();
    if (provider.isGardenFull(gardenIndex)) return;
    final countBefore = provider.unlockedGardenCount;

    final result = await Navigator.of(rootContext).push<Object?>(
      MaterialPageRoute<Object?>(
        fullscreenDialog: true,
        builder: (_) => GratitudePlantingPage(
          gardenIndex: gardenIndex,
          allowRoutineSkip: widget.onRoutineSkip != null,
        ),
      ),
    );
    if (result == GratitudePlantingOutcome.skipped) {
      widget.onRoutineSkip?.call();
      return;
    }
    final planted = result is GratitudeEntry ? result : null;
    if (!mounted || planted == null) return;

    final countAfter = provider.unlockedGardenCount;
    if (countAfter > countBefore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Garden $countAfter unlocked — a fresh space is ready.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () => setState(
              () => _selectedGardenIndex = countAfter - 1,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${GratitudeEntry.getFlowerName(planted.flowerType)} planted in Garden ${gardenIndex + 1}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    widget.onEntrySaved?.call();
  }

  void _showFlowerDetailSheet(
    BuildContext rootContext,
    GratitudeEntry entry,
    String language,
  ) {
    showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final provider = sheetContext.watch<GratitudeProvider>();
        final current = provider.entries.firstWhere(
          (candidate) => candidate.id == entry.id,
          orElse: () => entry,
        );
        final isDark = Theme.of(rootContext).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                PolishedFlowerAsset(
                  flowerType: current.flowerType,
                  width: 82 * GratitudeEntry.getFlowerScale(current.flowerType),
                  height:
                      142 * GratitudeEntry.getFlowerScale(current.flowerType),
                  glowOpacity: 0.18,
                  glowBlur: 7,
                  cacheWidth: 246,
                  cacheHeight: 450,
                ).animate().fadeIn(duration: 250.ms).scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1, 1),
                      alignment: Alignment.bottomCenter,
                    ),
                const SizedBox(height: 6),
                Text(
                  GratitudeEntry.getFlowerName(current.flowerType),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GratitudeEntry.getFlowerMeaning(current.flowerType)} • Garden ${current.gardenIndex + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.softOlive : AppColors.sageGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormatter.formatFullDate(
                    current.createdAt,
                    language: language,
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.17)
                        : const Color(0xFFF5F4EF),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    '“${current.content}”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 15,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final saved = await provider.waterFlower(current.id);
                          if (!rootContext.mounted) return;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'You watered this gratitude flower.'
                                    : provider.errorMessage ??
                                        'The flower could not be watered.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.water_drop_outlined, size: 18),
                        label: Text('Watered ${current.waterCount}×'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.honeyAmber,
                          foregroundColor: AppColors.onHoney,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Edit gratitude',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showEditDialog(rootContext, current, provider);
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 5),
                    IconButton.filledTonal(
                      tooltip: 'Remove flower',
                      onPressed: () async {
                        final confirmed = await CozyConfirmSheet.show(
                          rootContext,
                          title: LanguageHelper.pick(
                            language,
                            english: 'Remove this gratitude flower?',
                            filipino: 'Alisin ang bulaklak ng pasasalamat?',
                          ),
                          message: LanguageHelper.pick(
                            language,
                            english:
                                'Its plot will become available for another memory.',
                            filipino: 'Magiging bakante muli ang puwesto nito.',
                          ),
                          confirmLabel: 'Remove',
                          cancelLabel: 'Keep flower',
                          icon: Icons.local_florist_outlined,
                        );
                        if (!confirmed) return;
                        final deleted =
                            await provider.deleteGratitudeEntry(current.id);
                        if (!sheetContext.mounted) return;
                        if (deleted) Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    GratitudeEntry entry,
    GratitudeProvider provider,
  ) {
    final controller = TextEditingController(text: entry.content);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit gratitude'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Update this gratitude memory…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final saved = await provider.updateGratitudeEntry(
                entry.id,
                controller.text,
              );
              if (saved && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _GardenBottomControls extends StatelessWidget {
  final int gardenIndex;
  final int flowerCount;
  final int unlockedCount;
  final bool isFull;
  final bool isLoading;
  final bool isDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlant;
  final VoidCallback onOpenNext;

  const _GardenBottomControls({
    required this.gardenIndex,
    required this.flowerCount,
    required this.unlockedCount,
    required this.isFull,
    required this.isLoading,
    required this.isDay,
    required this.onPrevious,
    required this.onNext,
    required this.onPlant,
    required this.onOpenNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasNext = gardenIndex < unlockedCount - 1;
    final foreground = isDay ? AppColors.textPrimaryLight : Colors.white;
    return Container(
      key: const ValueKey('garden-controls'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDay
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFF142F38).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDay ? Colors.white : Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            key: const ValueKey('garden-navigator'),
            children: [
              IconButton(
                key: const ValueKey('previous-garden'),
                tooltip: 'Previous garden',
                onPressed: gardenIndex == 0 ? null : onPrevious,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                color: foreground,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Garden ${gardenIndex + 1} of $unlockedCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$flowerCount / ${GardenLayout.capacity} flowers',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.66),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('next-garden'),
                tooltip: 'Next garden',
                onPressed: gardenIndex >= unlockedCount - 1 ? null : onNext,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                color: foreground,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: flowerCount / GardenLayout.capacity,
                    minHeight: 7,
                    backgroundColor:
                        isDay ? const Color(0xFFE0E8D2) : Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.honeyAmber,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isFull
                    ? 'Garden full'
                    : '${GardenLayout.capacity - flowerCount} plots open',
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton(
              key: ValueKey(isFull ? 'open-next-garden' : 'plant-flower'),
              onPressed: isLoading
                  ? null
                  : isFull && hasNext
                      ? onOpenNext
                      : isFull
                          ? null
                          : onPlant,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.honeyAmber,
                foregroundColor: AppColors.onHoney,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFull ? Icons.arrow_forward_rounded : Icons.add_rounded,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isFull
                          ? hasNext
                              ? 'Open Garden ${gardenIndex + 2}'
                              : 'Garden complete'
                          : 'Plant a gratitude flower',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenMemoryTile extends StatelessWidget {
  final GratitudeEntry entry;
  final bool isDark;
  final String language;
  final VoidCallback onTap;

  const _GardenMemoryTile({
    required this.entry,
    required this.isDark,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 70,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: GratitudeEntry.getFlowerColor(entry.flowerType)
                      .withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: PolishedFlowerAsset(
                  flowerType: entry.flowerType,
                  glowOpacity: 0.12,
                  glowBlur: 4,
                  cacheWidth: 128,
                  cacheHeight: 235,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GratitudeEntry.getFlowerName(entry.flowerType),
                      style: const TextStyle(
                        color: AppColors.sageGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Garden ${entry.gardenIndex + 1} • ${DateFormatter.formatFullDate(entry.createdAt, language: language)}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
