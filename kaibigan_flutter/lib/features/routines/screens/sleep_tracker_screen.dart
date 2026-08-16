import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  SleepFeeling _selectedFeeling = SleepFeeling.wellRested;
  double _hoursSlept = 7.5;
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  final List<String> _factorOptions = [
    'Screen Time Before Bed',
    'Late Caffeine',
    'Quiet Room',
    'Cool Temperature',
    'Heavy Meals',
    'Vivid Dreams',
    'Woke Up Mid-Night',
  ];
  final List<String> _selectedFactors = ['Quiet Room', 'Cool Temperature'];

  void _saveSleepLog() {
    final routinesProvider = Provider.of<RoutinesProvider>(context, listen: false);
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'morning',
        routineType: RoutineType.morning,
        completedAt: DateTime.now(),
        sleepFeeling: _selectedFeeling,
        focusOrHighlight: 'Slept ${_hoursSlept.toStringAsFixed(1)} hours. Bed: ${_bedTime.format(context)}, Wake: ${_wakeTime.format(context)}.',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sleep log saved successfully!'),
        backgroundColor: AppColors.sageGreen,
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
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sleep Feeling & Quality',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.nights_stay_outlined, color: AppColors.sageGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Morning Sleep Check', style: AppTypography.bodySmall(context, isDark: isDark)),
                          Text('How restored are you?', style: AppTypography.titleMedium(context, isDark: isDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.05),
              const SizedBox(height: 24),

              // Sleep feeling cards
              Text('Sleep Feeling:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 12),
              ...SleepFeeling.values.map((feeling) {
                final isSelected = _selectedFeeling == feeling;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFeeling = feeling;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sageGreen.withValues(alpha: isDark ? 0.25 : 0.12)
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sageGreen
                            : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            feeling.assetPath,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              feeling.icon,
                              color: isSelected ? AppColors.sageGreen : (isDark ? Colors.white60 : Colors.black54),
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feeling.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              Text(feeling.description, style: AppTypography.bodySmall(context, isDark: isDark)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: AppColors.sageGreen, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Hours Slept Slider
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hours Slept', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        Text('${_hoursSlept.toStringAsFixed(1)} hours', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sageGreen)),
                      ],
                    ),
                    Slider(
                      value: _hoursSlept,
                      min: 3.0,
                      max: 12.0,
                      divisions: 18,
                      activeColor: AppColors.sageGreen,
                      onChanged: (val) {
                        setState(() {
                          _hoursSlept = val;
                        });
                      },
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: _bedTime);
                            if (time != null) setState(() => _bedTime = time);
                          },
                          child: Column(
                            children: [
                              Text('Bedtime', style: AppTypography.bodySmall(context, isDark: isDark)),
                              const SizedBox(height: 4),
                              Text(_bedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: isDark ? AppColors.darkCardBorder : Colors.black12),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: _wakeTime);
                            if (time != null) setState(() => _wakeTime = time);
                          },
                          child: Column(
                            children: [
                              Text('Wake Time', style: AppTypography.bodySmall(context, isDark: isDark)),
                              const SizedBox(height: 4),
                              Text(_wakeTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sleep Factors
              Text('Sleep Environment & Factors:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _factorOptions.map((factor) {
                  final isSelected = _selectedFactors.contains(factor);
                  return FilterChip(
                    label: Text(factor),
                    selected: isSelected,
                    selectedColor: AppColors.sageGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.sageGreen,
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? AppColors.sageGreen : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08))),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFactors.add(factor);
                        } else {
                          _selectedFactors.remove(factor);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSleepLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Text('Save Sleep Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
