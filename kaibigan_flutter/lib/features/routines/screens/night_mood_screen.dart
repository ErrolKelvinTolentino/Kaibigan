import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../mood_tracking/mood_provider.dart';

class NightMoodScreen extends StatefulWidget {
  const NightMoodScreen({super.key});

  @override
  State<NightMoodScreen> createState() => _NightMoodScreenState();
}

class _NightMoodScreenState extends State<NightMoodScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int _selectedScore = 4;
  String _selectedLabel = 'Good';
  double _stressLevel = 2.0;
  double _energyLevel = 3.0;
  final TextEditingController _noteController = TextEditingController();
  final List<String> _selectedFactors = [];

  final List<Map<String, dynamic>> _moodOptions = [
    {'score': 1, 'label': 'Struggling', 'icon': Icons.sentiment_very_dissatisfied_outlined, 'color': AppColors.moodAwful},
    {'score': 2, 'label': 'Low', 'icon': Icons.sentiment_dissatisfied_outlined, 'color': AppColors.moodLow},
    {'score': 3, 'label': 'Okay', 'icon': Icons.sentiment_neutral_outlined, 'color': AppColors.moodOkay},
    {'score': 4, 'label': 'Good', 'icon': Icons.sentiment_satisfied_outlined, 'color': AppColors.moodGood},
    {'score': 5, 'label': 'Awesome', 'icon': Icons.sentiment_very_satisfied_outlined, 'color': AppColors.moodAwesome},
  ];

  final List<String> _factorOptions = [
    'Work & School',
    'Family & Friends',
    'Self Care',
    'Sleep & Rest',
    'Health & Fitness',
    'Weather',
    'Hobbies',
    'Peaceful Moment',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveMoodLog() {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    moodProvider.logMood(
      score: _selectedScore,
      label: _selectedLabel,
      stress: _stressLevel.round(),
      energy: _energyLevel.round(),
      note: '${_selectedFactors.join(", ")}. ${_noteController.text.trim()}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evening mood logged successfully!'),
        backgroundColor: AppColors.beePrimary,
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
          'Night Mood Check-In',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.beePrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of 2',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.beePrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Page 1: How do you feel?
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Page 1: Mood Score', style: AppTypography.bodySmall(context, isDark: isDark)),
                        Text('How do you feel tonight?', style: AppTypography.titleLarge(context, isDark: isDark)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _moodOptions.map((opt) {
                            final isSelected = _selectedScore == opt['score'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedScore = opt['score'];
                                  _selectedLabel = opt['label'];
                                });
                              },
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: isSelected ? (opt['color'] as Color).withValues(alpha: 0.2) : (isDark ? AppColors.darkCard : Colors.white),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? (opt['color'] as Color) : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08)),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Icon(opt['icon'] as IconData, color: isSelected ? (opt['color'] as Color) : (isDark ? Colors.white60 : Colors.black54), size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    opt['label'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? (opt['color'] as Color) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        // Stress & Energy Sliders
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
                                  Text('Stress Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  Text('${_stressLevel.round()} / 5', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.beePrimary)),
                                ],
                              ),
                              Slider(
                                value: _stressLevel,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                activeColor: AppColors.beePrimary,
                                onChanged: (val) => setState(() => _stressLevel = val),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Energy Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  Text('${_energyLevel.round()} / 5', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.beePrimary)),
                                ],
                              ),
                              Slider(
                                value: _energyLevel,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                activeColor: AppColors.beePrimary,
                                onChanged: (val) => setState(() => _energyLevel = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.beePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Next: Influencing Factors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page 2: Influencing factors & Notes
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Page 2: Factors & Notes', style: AppTypography.bodySmall(context, isDark: isDark)),
                        Text('What contributed to this feeling?', style: AppTypography.titleLarge(context, isDark: isDark)),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _factorOptions.map((factor) {
                            final isSelected = _selectedFactors.contains(factor);
                            return FilterChip(
                              label: Text(factor),
                              selected: isSelected,
                              selectedColor: AppColors.beePrimary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.beePrimary,
                              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: isSelected ? AppColors.beePrimary : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08))),
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _noteController,
                            maxLines: 4,
                            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            decoration: const InputDecoration(
                              hintText: 'Add an optional evening note...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveMoodLog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.beePrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('Save Mood Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
