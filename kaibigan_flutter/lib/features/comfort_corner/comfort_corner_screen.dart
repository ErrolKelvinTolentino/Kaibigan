import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'comfort_provider.dart';

class ComfortCornerScreen extends StatefulWidget {
  const ComfortCornerScreen({super.key});

  @override
  State<ComfortCornerScreen> createState() => _ComfortCornerScreenState();
}

class _ComfortCornerScreenState extends State<ComfortCornerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comfortProvider = Provider.of<ComfortProvider>(context);
    final currentStep =
        comfortProvider.groundingStepsData[comfortProvider.groundingStep];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comfort Corner 🫶',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guided 4-7-8 Breathing Exercise Section
              Text(
                '4-7-8 Guided Breathing',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final cycleSeconds = _breathingController.value * 19.0;

                    double scale;
                    String stateText;

                    if (cycleSeconds < 4.0) {
                      // Inhale phase (0s - 4s): Expand 0.7 -> 1.25 smoothly
                      final progress = cycleSeconds / 4.0;
                      final curveProgress =
                          Curves.easeInOut.transform(progress);
                      scale = 0.7 + (1.25 - 0.7) * curveProgress;
                      final remaining = (4.0 - cycleSeconds).ceil();
                      stateText =
                          'Inhale... (${remaining > 0 ? remaining : 1}s)';
                    } else if (cycleSeconds < 11.0) {
                      // Hold phase (4s - 11s): Stay expanded at 1.25
                      scale = 1.25;
                      final remaining = (11.0 - cycleSeconds).ceil();
                      stateText = 'Hold... (${remaining > 0 ? remaining : 1}s)';
                    } else {
                      // Exhale phase (11s - 19s): Deflate 1.25 -> 0.7 smoothly over 8s
                      final progress = (cycleSeconds - 11.0) / 8.0;
                      final curveProgress =
                          Curves.easeInOut.transform(progress);
                      scale = 1.25 - (1.25 - 0.7) * curveProgress;
                      final remaining = (19.0 - cycleSeconds).ceil();
                      stateText =
                          'Exhale slowly... (${remaining > 0 ? remaining : 1}s)';
                    }

                    return Column(
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sageGreen.withValues(alpha: 0.2),
                              border: Border.all(
                                  color: AppColors.sageGreen, width: 3),
                            ),
                            child: const Center(
                              child:
                                  Text('🌬️', style: TextStyle(fontSize: 44)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          stateText,
                          style: AppTypography.titleSmall(context,
                              isDark: isDark, color: AppColors.sageGreen),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Follow the rhythm of the expanding circle to calm your nervous system.',
                          textAlign: TextAlign.center,
                          style:
                              AppTypography.bodyMedium(context, isDark: isDark),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 5-4-3-2-1 Sensory Grounding Tool
              Text(
                '5-4-3-2-1 Sensory Grounding',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.warmPeach.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.warmPeach, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep['title']!,
                      style: AppTypography.titleSmall(context,
                          isDark: isDark, color: AppColors.annPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentStep['desc']!,
                      style: AppTypography.bodyMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.annPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () => comfortProvider.nextGroundingStep(),
                        child: const Text('Next Step',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Uplifting Quotes Carousel
              Text(
                'Uplifting Words',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: PageView.builder(
                  itemCount: comfortProvider.quotes.length,
                  itemBuilder: (context, index) {
                    final item = comfortProvider.quotes[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lavenderMist.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '"${item.quote}"',
                            textAlign: TextAlign.center,
                            style: AppTypography.companionInlineResponse(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.beePrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— ${item.author}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
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
      ),
    );
  }
}
