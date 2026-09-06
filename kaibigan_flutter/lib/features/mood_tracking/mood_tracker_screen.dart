import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../settings/user_provider.dart';
import '../companion/companion_model.dart';
import '../insights/wellness_insights_button.dart';
import 'mood_provider.dart';
import 'mood_model.dart';
import 'mood_detail_sheet.dart';

class MoodTrackerScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const MoodTrackerScreen({super.key, this.onCompleted});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

/// Compact calendar marker: older check-ins sit behind while the most recent
/// color is layered last and therefore remains easiest to read.
class _MoodDotStack extends StatelessWidget {
  const _MoodDotStack({required this.logs});

  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context) {
    final ordered = List<MoodLog>.of(logs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final visible =
        ordered.length <= 5 ? ordered : ordered.sublist(ordered.length - 5);
    const dotSize = 14.0;
    const overlapStep = 5.5;
    final width = dotSize + (visible.length - 1) * overlapStep;

    return Semantics(
      label:
          '${logs.length} mood ${logs.length == 1 ? 'entry' : 'entries'}; newest is ${ordered.last.moodLabel}',
      child: SizedBox(
        width: width,
        height: 18,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < visible.length; index++)
              Positioned(
                left: index * overlapStep,
                top: (visible.length - index - 1) * 0.8,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: MoodLog.getMoodColor(visible[index].moodScore),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBackground
                          : Colors.white,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int _currentStep =
      0; // 0: Beemoji, 1: Emotion Tags, 2: Free Reflection Note, 3: Completed Recap
  int _selectedScore = 4;
  String _selectedLabel = 'Good';
  final Set<String> _selectedEmotions = {};
  final TextEditingController _noteController = TextEditingController();
  bool _showHistory = false;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDate;

  final List<String> _commonEmotions = [
    'Grateful',
    'Peaceful',
    'Hopeful',
    'Energetic',
    'Content',
    'Inspired',
    'Loved',
    'Calm',
    'Proud',
    'Motivated',
    'Joyful',
    'Relieved',
    'Confident',
    'Curious',
    'Connected',
    'Tired',
    'Anxious',
    'Overwhelmed',
    'Stressed',
    'Frustrated',
    'Lonely',
    'Confused',
    'Restless',
    'Sad',
    'Irritated',
    'Disappointed',
    'Insecure',
    'Drained',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMoodLog() async {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final combinedNote = StringBuffer();
    if (_selectedEmotions.isNotEmpty) {
      combinedNote.writeln("Emotions: ${_selectedEmotions.join(', ')}");
    }
    if (_noteController.text.trim().isNotEmpty) {
      combinedNote.writeln(_noteController.text.trim());
    }

    await moodProvider.logMood(
      score: _selectedScore,
      label: _selectedLabel,
      note: combinedNote.toString().trim().isEmpty
          ? null
          : combinedNote.toString().trim(),
    );

    if (!mounted) return;
    if (moodProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(moodProvider.errorMessage!)),
      );
      return;
    }

    setState(() {
      _currentStep = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _showHistory || (_currentStep > 0 && _currentStep < 3)
                ? Icons.arrow_back_ios_new_rounded
                : Icons.close_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () {
            if (_showHistory) {
              setState(() => _showHistory = false);
            } else if (_currentStep > 0 && _currentStep < 3) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _showHistory ? 'Mood history' : 'Check in',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
        actions: [
          const WellnessInsightsButton(feature: 'mood'),
          if (!_showHistory && _currentStep < 3)
            IconButton(
              tooltip: 'View mood history',
              onPressed: () => setState(() => _showHistory = true),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _showHistory
          ? SafeArea(child: _buildCalendarView(context, isDark))
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: MobileLayout.pageInsets(
                    context,
                    top: 14,
                    bottom: 20,
                  ),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 34),
                    child: _buildCheckInFlow(context, isDark, mascot),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCheckInFlow(
      BuildContext context, bool isDark, MascotInfo mascot) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Beemoji(context, isDark);
      case 1:
        return _buildStep2Emotions(context, isDark);
      case 2:
        return _buildStep3Reflection(context, isDark);
      default:
        return _buildStep4Success(context, isDark, mascot);
    }
  }

  Widget _buildStep1Beemoji(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(1, 3, isDark),
        const SizedBox(height: 20),
        Text(
          "Which bee describes you the most right now?",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Tap the bee emoji that matches your mood energy.",
          style: TextStyle(
              fontSize: 13.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const labels = ['Struggling', 'Low', 'Okay', 'Good', 'Great'];
            const spacing = 10.0;
            final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
            final imageSize = (cardWidth - 24).clamp(70.0, 108.0);

            Widget card(int index) => SizedBox(
                  width: cardWidth,
                  child: _buildBeemojiItem(
                    index + 1,
                    labels[index],
                    isDark,
                    imageSize: imageSize,
                  ),
                );

            return Column(
              key: const ValueKey('mood-expression-list'),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [card(0), card(1), card(2)],
                ),
                const SizedBox(height: spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [card(3), const SizedBox(width: spacing), card(4)],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: AppColors.onHoney,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Continue",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildBeemojiItem(int score, String label, bool isDark,
      {double imageSize = 96}) {
    final isSelected = _selectedScore == score;
    final moodColor = MoodLog.getMoodColor(score);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label mood',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedScore = score;
            _selectedLabel = label;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 158,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? moodColor.withValues(alpha: isDark ? 0.25 : 0.16)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? moodColor
                  : (isDark
                      ? AppColors.darkCardBorder
                      : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? moodColor.withValues(alpha: isDark ? 0.3 : 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    MoodLog.getMoodAssetPath(score),
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      MoodLog.getMoodEmoji(score),
                      style: TextStyle(fontSize: imageSize * 0.65),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? moodColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Emotions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(2, 3, isDark),
        const SizedBox(height: 24),
        Text(
          "What emotions are you feeling right now?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Choose up to three, or continue without choosing.",
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _commonEmotions.map((emotion) {
            final isSelected = _selectedEmotions.contains(emotion);

            return FilterChip(
              label: Text(emotion),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedEmotions.length < 3) {
                      _selectedEmotions.add(emotion);
                    }
                  } else {
                    _selectedEmotions.remove(emotion);
                  }
                });
              },
              selectedColor:
                  AppColors.honeyGold.withValues(alpha: isDark ? 0.4 : 0.25),
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              labelStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.honeyAmber
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
                          : Colors.black.withValues(alpha: 0.08)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: AppColors.onHoney,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Continue",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Reflection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(3, 3, isDark),
        const SizedBox(height: 24),
        Text(
          "What got you feeling this way?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Optional. A sentence can help you remember the context later.",
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 5,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText:
                  "e.g. Work felt demanding today, but having lunch with friends helped me feel more relaxed...",
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveMoodLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: AppColors.onHoney,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Save check-in",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Success(
      BuildContext context, bool isDark, MascotInfo mascot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            color: MoodLog.getMoodColor(_selectedScore)
                .withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: MoodLog.getMoodColor(_selectedScore)
                    .withValues(alpha: isDark ? 0.18 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              MoodLog.getMoodAssetPath(_selectedScore),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  MoodLog.getMoodEmoji(_selectedScore),
                  style: const TextStyle(fontSize: 84),
                ),
              ),
            ),
          ),
        ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          "Check-in saved",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : MoodLog.getMoodColor(_selectedScore)
                      .withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Logged as $_selectedLabel",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: MoodLog.getMoodColor(_selectedScore),
                ),
              ),
              if (_selectedEmotions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _selectedEmotions.join(' • '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mascot.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(mascot.avatarIcon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${mascot.name} will use this check-in to offer a gentler next step today.",
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 160.ms),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onCompleted != null) {
                widget.onCompleted!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: AppColors.onHoney,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Done",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(BuildContext context, bool isDark) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final logs = moodProvider.logs;

    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

    // Filter logs for selected date
    final selectedDateLogs = _selectedCalendarDate == null
        ? <MoodLog>[]
        : logs
            .where(
                (l) => DateUtils.isSameDay(l.createdAt, _selectedCalendarDate))
            .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          if (moodProvider.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (moodProvider.errorMessage != null)
            SyncStatusBanner(
              message: moodProvider.errorMessage!,
              onRetry: moodProvider.fetchMoodLogs,
            ),
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.grey)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: daysInMonth + firstDayOffset,
              itemBuilder: (context, index) {
                if (index < firstDayOffset) {
                  return const SizedBox();
                }

                final dayNumber = index - firstDayOffset + 1;
                final currentDate = DateTime(
                    _focusedMonth.year, _focusedMonth.month, dayNumber);
                final isSelectedDate = _selectedCalendarDate != null &&
                    DateUtils.isSameDay(currentDate, _selectedCalendarDate);

                // Find log for this day if any
                final dayLogs = logs
                    .where((l) => DateUtils.isSameDay(l.createdAt, currentDate))
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final hasLog = dayLogs.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCalendarDate = currentDate);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelectedDate
                          ? AppColors.honeyGold.withValues(alpha: 0.25)
                          : (hasLog
                              ? (isDark ? AppColors.darkCard : Colors.white)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelectedDate
                            ? AppColors.honeyGold
                            : (hasLog
                                ? (isDark
                                    ? AppColors.darkCardBorder
                                    : Colors.black.withValues(alpha: 0.05))
                                : Colors.transparent),
                        width: isSelectedDate ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                hasLog ? FontWeight.w800 : FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (hasLog)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: _MoodDotStack(logs: dayLogs),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Day details container
          if (_selectedCalendarDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d')
                            .format(_selectedCalendarDate!),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text('${selectedDateLogs.length} logs',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedDateLogs.isEmpty)
                    const Text('No mood check-ins for this day.',
                        style: TextStyle(fontSize: 13, color: Colors.grey))
                  else
                    ...selectedDateLogs.map((l) => GestureDetector(
                          onTap: () => _showMoodDetailSheet(
                              context, l, isDark, moodProvider),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black26
                                  : const Color(0xFFF9F7F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Semantics(
                                  label: '${l.moodLabel} mood color',
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: MoodLog.getMoodColor(l.moodScore),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.28 : 0.9,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l.moodLabel,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  MoodLog.getMoodColor(l.moodScore),
                                            ),
                                          ),
                                          Text(
                                            DateFormat('h:mm a')
                                                .format(l.createdAt.toLocal()),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (l.note != null && l.note!.isNotEmpty)
                                        Text(
                                          l.note!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showMoodDetailSheet(
      BuildContext context, MoodLog log, bool isDark, MoodProvider provider) {
    MoodDetailSheet.show(
      context,
      log: log,
      isDark: isDark,
    );
  }

  Widget _buildProgressBar(int current, int total, bool isDark) {
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.honeyGold
                  : (isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
