import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/garden_appearance.dart';
import 'flower_suggestion.dart';
import 'garden_layout.dart';
import 'gratitude_model.dart';
import 'polished_flower_asset.dart';

class ResponsiveGardenScene extends StatelessWidget {
  final List<GratitudeEntry> entries;
  final DateTime now;
  final GardenAppearance appearance;
  final ValueChanged<GratitudeEntry> onFlowerTap;
  final VoidCallback onEmptyTap;

  const ResponsiveGardenScene({
    super.key,
    required this.entries,
    required this.now,
    this.appearance = GardenAppearance.syncWithTime,
    required this.onFlowerTap,
    required this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    final period = GardenLayout.periodFor(now, appearance: appearance);
    final background =
        GardenLayout.backgroundAssetFor(now, appearance: appearance);
    final ordered = List<GratitudeEntry>.of(entries)
      ..sort((a, b) {
        final aPlot =
            GardenLayout.plots[a.plotIndex.clamp(0, GardenLayout.capacity - 1)];
        final bPlot =
            GardenLayout.plots[b.plotIndex.clamp(0, GardenLayout.capacity - 1)];
        return aPlot.groundY.compareTo(bPlot.groundY);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetAspect = constraints.maxWidth / constraints.maxHeight;
        final fit = targetAspect > 0.72 ? BoxFit.contain : BoxFit.cover;
        return Container(
          key: const ValueKey('responsive-garden-scene'),
          color: period == GardenScenePeriod.day
              ? const Color(0xFFC8D29A)
              : const Color(0xFF173C4B),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: fit,
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: GardenLayout.sourceWidth,
                    height: GardenLayout.sourceHeight,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            background,
                            key: ValueKey(background),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                          ),
                        ),
                        for (var index = 0; index < ordered.length; index++)
                          _PositionedFlower(
                            entry: ordered[index],
                            animationIndex: index,
                            onTap: () => onFlowerTap(ordered[index]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (entries.isEmpty)
                Align(
                  alignment: const Alignment(0, 0.18),
                  child: Semantics(
                    button: true,
                    label: 'Plant the first gratitude flower in this garden',
                    child: InkWell(
                      key: const ValueKey('empty-garden-plant-action'),
                      onTap: onEmptyTap,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: period == GardenScenePeriod.day
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF17313A).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: period == GardenScenePeriod.day
                                ? Colors.white
                                : Colors.white24,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_florist_outlined,
                              color: AppColors.sageGreen,
                              size: 28,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'This garden is ready for a memory.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: period == GardenScenePeriod.day
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textPrimaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tap to plant the first flower',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: period == GardenScenePeriod.day
                                    ? AppColors.textSecondaryLight
                                    : AppColors.textSecondaryDark,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionedFlower extends StatelessWidget {
  final GratitudeEntry entry;
  final int animationIndex;
  final VoidCallback onTap;

  const _PositionedFlower({
    required this.entry,
    required this.animationIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plot =
        GardenLayout.plots[entry.plotIndex.clamp(0, GardenLayout.capacity - 1)];
    final typeScale = GratitudeEntry.getFlowerScale(entry.flowerType);
    final matched = FlowerMatcher.isSuggestedFor(
      entry.content,
      entry.flowerType,
    );
    // The supplied flower art includes generous transparent canvas around the
    // stem, so the source width is padded to keep the visible bloom legible.
    // Every plot shares one scale — the back row is not a smaller memory.
    const plantedFlowerScale = 1.3;
    final width =
        282 * plantedFlowerScale * GardenLayout.flowerScale * typeScale;
    final height = width * GardenLayout.sourceHeight / GardenLayout.sourceWidth;
    final hitWidth = width < 150 ? 150.0 : width;

    return Positioned(
      left: plot.x - hitWidth / 2,
      top: plot.groundY - height,
      width: hitWidth,
      height: height + 45,
      child: Semantics(
        button: true,
        label:
            '${GratitudeEntry.getFlowerName(entry.flowerType)} gratitude flower',
        child: GestureDetector(
          key: ValueKey('garden-flower-${entry.id}'),
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                key: ValueKey('garden-flower-shadow-${entry.id}'),
                left: (hitWidth - width * 0.3) / 2,
                top: height - 4,
                width: width * 0.3,
                height: (width * 0.07).clamp(7, 15),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 13,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _SwayingStem(
                  restAngle: plot.rotation,
                  swayIndex: animationIndex,
                  child: PolishedFlowerAsset(
                    flowerType: entry.flowerType,
                    width: width,
                    height: height,
                    glowOpacity: matched ? 0.42 : 0.3,
                    glowBlur: matched ? 20 : 14,
                    cacheWidth: 564,
                    cacheHeight: 1034,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 55 * animationIndex),
                      duration: 360.ms,
                    )
                    .scaleXY(
                      begin: 0.82,
                      end: 1,
                      delay: Duration(milliseconds: 55 * animationIndex),
                      duration: 420.ms,
                      curve: Curves.easeOutBack,
                      alignment: Alignment.bottomCenter,
                    ),
              ),
              if (matched)
                Positioned(
                  key: ValueKey('garden-flower-matched-${entry.id}'),
                  left: hitWidth / 2 + width * 0.22,
                  top: height * 0.1,
                  child: const _MatchedSparkle(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slow breeze on the stem so the garden feels tended rather than static.
/// Each bloom gets its own phase and period, and the motion stops entirely
/// when the platform asks for reduced motion.
class _SwayingStem extends StatefulWidget {
  const _SwayingStem({
    required this.child,
    required this.restAngle,
    required this.swayIndex,
  });

  final Widget child;
  final double restAngle;
  final int swayIndex;

  @override
  State<_SwayingStem> createState() => _SwayingStemState();
}

class _SwayingStemState extends State<_SwayingStem>
    with SingleTickerProviderStateMixin {
  static const double _swayRadians = 0.0075;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 4200 + (widget.swayIndex % 5) * 460,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-read the setting on every dependency change, so turning reduce-motion
    // on while the garden is open actually stops the garden.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.stop();
      // Mid-travel is the resting position, so a still garden shows every
      // flower upright rather than tilted permanently to one side.
      _controller.value = 0.5;
      return;
    }
    if (_controller.isAnimating) return;
    // Seeding the phase before repeating keeps neighbouring flowers off each
    // other's beat. Assigning `value` afterwards would stop the controller.
    _controller.value = (widget.swayIndex % 7) / 7;
    _controller.repeat(reverse: true, min: 0, max: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            (Curves.easeInOutSine.transform(_controller.value) - 0.5) *
                2 *
                _swayRadians;
        return Transform.rotate(
          angle: widget.restAngle + offset,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Marks a bloom that was planted on the flower Kaibigan matched to the note.
class _MatchedSparkle extends StatelessWidget {
  const _MatchedSparkle();

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.honeyAmber.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 15,
        color: AppColors.honeyAmber,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return badge;
    return badge
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 0.88,
          end: 1.08,
          duration: 1700.ms,
          curve: Curves.easeInOut,
        );
  }
}
