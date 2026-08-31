import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../../core/widgets/cozy_motion.dart';
import 'comfort_provider.dart';

class ComfortCornerScreen extends StatefulWidget {
  const ComfortCornerScreen({super.key});

  @override
  State<ComfortCornerScreen> createState() => _ComfortCornerScreenState();
}

class _ComfortCornerScreenState extends State<ComfortCornerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final PageController _quoteController;
  int _quoteIndex = 0;
  bool _motionPreferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..repeat();
    _quoteController = PageController(viewportFraction: 0.92);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPreferenceApplied) return;
    _motionPreferenceApplied = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _breathingController
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comfort = context.watch<ComfortProvider>();
    final currentStep = comfort.groundingStepsData[comfort.groundingStep];

    return Scaffold(
      appBar: AppBar(title: const Text('Comfort Corner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CozyFeatureBanner(
                eyebrow: 'A softer moment',
                title: 'Come back to yourself',
                subtitle:
                    'Breathe, notice what is around you, and take only the next gentle step.',
                placeholderLabel: 'comfort-corner',
                placeholderIcon: Icons.self_improvement_rounded,
                accent: AppColors.honeyAmber,
              ),
              const SizedBox(height: 26),
              const _SectionLabel(
                eyebrow: 'BREATHE WITH ME',
                title: '4–7–8 guided breathing',
                subtitle:
                    'Let the warm circle set the pace. Nothing else needs your attention yet.',
              ),
              const SizedBox(height: 12),
              CozyEntrance(
                delay: const Duration(milliseconds: 80),
                child: _BreathingCard(
                  controller: _breathingController,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 30),
              const _SectionLabel(
                eyebrow: 'FIND THE PRESENT',
                title: '5–4–3–2–1 grounding',
                subtitle:
                    'Move through one sense at a time. Small observations are enough.',
              ),
              const SizedBox(height: 12),
              CozyEntrance(
                delay: const Duration(milliseconds: 140),
                child: _GroundingCard(
                  isDark: isDark,
                  stepIndex: comfort.groundingStep,
                  stepCount: comfort.groundingStepsData.length,
                  title: currentStep['title']!,
                  description: currentStep['desc']!,
                  onNext: comfort.nextGroundingStep,
                  onReset: comfort.groundingStep == 0
                      ? null
                      : comfort.resetGrounding,
                ),
              ),
              const SizedBox(height: 30),
              const _SectionLabel(
                eyebrow: 'KEEP THIS CLOSE',
                title: 'A few gentle words',
                subtitle:
                    'Swipe whenever you want a different reminder for this moment.',
              ),
              const SizedBox(height: 12),
              CozyEntrance(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    SizedBox(
                      height: 176,
                      child: PageView.builder(
                        controller: _quoteController,
                        itemCount: comfort.quotes.length,
                        onPageChanged: (index) =>
                            setState(() => _quoteIndex = index),
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(
                            right: index == comfort.quotes.length - 1 ? 0 : 10,
                          ),
                          child: _QuoteCard(
                            quote: comfort.quotes[index].quote,
                            author: comfort.quotes[index].author,
                            isDark: isDark,
                            index: index,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        comfort.quotes.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          width: index == _quoteIndex ? 22 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == _quoteIndex
                                ? AppColors.honeyAmber
                                : AppColors.honeyBorder,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.honeyAmber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _BreathingCard extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _BreathingCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkHoneySurface, AppColors.darkCard]
              : [AppColors.honeyLight, Colors.white],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.darkHoneyBorder : AppColors.honeyBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.06 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final seconds = controller.value * 19;
          late final double scale;
          late final String phase;
          late final String count;
          if (seconds < 4) {
            scale = 0.76 + 0.24 * Curves.easeInOut.transform(seconds / 4);
            phase = 'Breathe in';
            count = '${(4 - seconds).ceil().clamp(1, 4)}';
          } else if (seconds < 11) {
            scale = 1;
            phase = 'Hold gently';
            count = '${(11 - seconds).ceil().clamp(1, 7)}';
          } else {
            scale = 1 - 0.24 * Curves.easeInOut.transform((seconds - 11) / 8);
            phase = 'Breathe out';
            count = '${(19 - seconds).ceil().clamp(1, 8)}';
          }
          return Column(
            children: [
              SizedBox(
                width: 176,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pollenGlow.withValues(alpha: 0.42),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 138,
                        height: 138,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              AppColors.pollenGlow,
                              AppColors.warmHoney,
                              AppColors.honeyAmber,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.honeyAmber
                                  .withValues(alpha: isDark ? 0.22 : 0.3),
                              blurRadius: 32,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.air_rounded,
                                color: Colors.white, size: 30),
                            const SizedBox(height: 3),
                            Text(
                              count,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  phase,
                  key: ValueKey(phase),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.honeyAmber,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Follow the circle—there is nowhere else to be right now.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroundingCard extends StatelessWidget {
  final bool isDark;
  final int stepIndex;
  final int stepCount;
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onReset;

  const _GroundingCard({
    required this.isDark,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.description,
    required this.onNext,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex + 1) / stepCount;
    final isLast = stepIndex == stepCount - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.honeyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.honeyLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '${stepIndex + 1} of $stepCount',
                  style: const TextStyle(
                    color: AppColors.honeyAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Start over'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  AppColors.honeyBorder.withValues(alpha: isDark ? 0.12 : 0.5),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(stepIndex),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 7),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(isLast ? 'Complete grounding' : 'Next sense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  final bool isDark;
  final int index;

  const _QuoteCard({
    required this.quote,
    required this.author,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final accents = [
      AppColors.honeyAmber,
      AppColors.sageGreen,
      AppColors.softRose,
      AppColors.lavenderMist,
    ];
    final accent = accents[index % accents.length];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [accent.withValues(alpha: 0.14), AppColors.darkCard]
              : [accent.withValues(alpha: 0.16), Colors.white],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -3,
            child: Icon(
              Icons.format_quote_rounded,
              color: accent.withValues(alpha: 0.18),
              size: 58,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                quote,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '— $author',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
