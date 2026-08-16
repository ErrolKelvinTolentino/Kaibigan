import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class MindfulnessMeditationScreen extends StatefulWidget {
  const MindfulnessMeditationScreen({super.key});

  @override
  State<MindfulnessMeditationScreen> createState() => _MindfulnessMeditationScreenState();
}

class _MindfulnessMeditationScreenState extends State<MindfulnessMeditationScreen> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  Timer? _timer;
  int _selectedDurationMins = 1;
  int _secondsLeft = 60;
  bool _isActive = false;
  String _phaseInstruction = 'Inhale deeply...';

  final List<int> _durationOptions = [1, 3, 5, 10];

  final List<Map<String, dynamic>> _soundscapes = [
    {'name': 'Gentle Rain', 'icon': Icons.water_drop_outlined},
    {'name': 'Ocean Waves', 'icon': Icons.waves_outlined},
    {'name': 'Forest Breeze', 'icon': Icons.park_outlined},
    {'name': 'Soft Chimes', 'icon': Icons.notifications_active_outlined},
  ];
  String _selectedSoundscape = 'Gentle Rain';

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _phaseInstruction = 'Hold breath gently...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isActive) {
            setState(() => _phaseInstruction = 'Exhale slowly...');
            _breathingController.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _phaseInstruction = 'Hold empty...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isActive) {
            setState(() => _phaseInstruction = 'Inhale deeply...');
            _breathingController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMeditation() {
    if (_isActive) {
      _pauseMeditation();
    } else {
      _startMeditation();
    }
  }

  void _startMeditation() {
    setState(() {
      _isActive = true;
    });
    _breathingController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _breathingController.stop();
        setState(() {
          _secondsLeft = 0;
          _isActive = false;
          _phaseInstruction = 'Meditation Session Complete';
        });
        _recordSessionLog();
      }
    });
  }

  void _pauseMeditation() {
    _timer?.cancel();
    _breathingController.stop();
    setState(() {
      _isActive = false;
    });
  }

  void _resetTimer(int mins) {
    _timer?.cancel();
    _breathingController.stop();
    setState(() {
      _selectedDurationMins = mins;
      _secondsLeft = mins * 60;
      _isActive = false;
      _phaseInstruction = 'Inhale deeply...';
    });
  }

  void _recordSessionLog() {
    final routinesProvider = Provider.of<RoutinesProvider>(context, listen: false);
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'midday',
        routineType: RoutineType.midday,
        completedAt: DateTime.now(),
        focusOrHighlight: 'Completed $_selectedDurationMins min Mindfulness Meditation with $_selectedSoundscape soundscape.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minsDisplay = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secsDisplay = (_secondsLeft % 60).toString().padLeft(2, '0');

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
          'Mindfulness Meditation',
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
            children: [
              // Duration selector pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _durationOptions.map((mins) {
                  final isSelected = _selectedDurationMins == mins;
                  return GestureDetector(
                    onTap: () => _resetTimer(mins),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.softRose : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.softRose : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08))),
                      ),
                      child: Text(
                        '$mins Min',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Animated Breathing Ring & Timer
              Center(
                child: AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final scale = 1.0 + (_breathingController.value * 0.35);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.softRose.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.softRose.withValues(alpha: 0.6), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.softRose.withValues(alpha: 0.25),
                              blurRadius: 24 * scale,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$minsDisplay:$secsDisplay',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.softRose,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedSoundscape,
                                style: AppTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),

              Text(
                _phaseInstruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Focus gently on your breath flowing in and out',
                style: AppTypography.bodyMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 32),

              // Play / Pause Button
              ElevatedButton.icon(
                onPressed: _toggleMeditation,
                icon: Icon(_isActive ? Icons.pause : Icons.play_arrow),
                label: Text(_isActive ? 'Pause Meditation' : 'Start Meditation', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softRose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 36),

              // Ambient Soundscapes
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ambient Soundscapes:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ),
              const SizedBox(height: 12),
              Row(
                children: _soundscapes.map((snd) {
                  final isSelected = _selectedSoundscape == snd['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSoundscape = snd['name']!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.softRose.withValues(alpha: 0.2) : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.softRose : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08))),
                        ),
                        child: Column(
                          children: [
                            Icon(snd['icon'] as IconData, color: isSelected ? AppColors.softRose : (isDark ? Colors.white54 : Colors.black45), size: 20),
                            const SizedBox(height: 4),
                            Text(snd['name']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
