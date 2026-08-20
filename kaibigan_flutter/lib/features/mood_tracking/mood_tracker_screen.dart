import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../settings/user_provider.dart';
import '../companion/companion_model.dart';
import 'mood_provider.dart';
import 'mood_model.dart';

class MoodTrackerScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const MoodTrackerScreen({super.key, this.onCompleted});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep =
      0; // 0: Beemoji, 1: Emotion Tags, 2: Free Reflection Note, 3: Completed Recap
  int _selectedScore = 4;
  String _selectedLabel = 'Good';
  final Set<String> _selectedEmotions = {};
  final TextEditingController _noteController = TextEditingController();

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
    'Tired',
    'Anxious',
    'Overwhelmed',
    'Stressed',
    'Frustrated',
    'Lonely',
    'Confused',
    'Restless',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            _currentStep > 0 && _currentStep < 3
                ? Icons.arrow_back_ios_new_rounded
                : Icons.close_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 3) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Mood Tracker',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.honeyGold,
          labelColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Daily Check-In'),
            Tab(text: 'Mood Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildCheckInFlow(context, isDark, mascot),
            ),
          ),
          SafeArea(
            child: _buildCalendarView(context, isDark),
          ),
        ],
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

        // ROW 1: 3 Beemojis (Struggling, Low, Okay)
        Row(
          children: [
            Expanded(
                child:
                    _buildBeemojiItem(1, 'Struggling', isDark, imageSize: 62)),
            const SizedBox(width: 10),
            Expanded(child: _buildBeemojiItem(2, 'Low', isDark, imageSize: 62)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildBeemojiItem(3, 'Okay', isDark, imageSize: 62)),
          ],
        ),

        const SizedBox(height: 12),

        // ROW 2: 2 Beemojis (Good, Awesome)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                  child: _buildBeemojiItem(4, 'Good', isDark, imageSize: 68)),
              const SizedBox(width: 14),
              Expanded(
                  child:
                      _buildBeemojiItem(5, 'Awesome', isDark, imageSize: 68)),
            ],
          ),
        ),

        const Spacer(),

        // Selected Mood Pill (Positioned right above the Next button as requested)
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: MoodLog.getMoodColor(_selectedScore)
                  .withValues(alpha: isDark ? 0.25 : 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    MoodLog.getMoodColor(_selectedScore).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: MoodLog.getMoodColor(_selectedScore)
                      .withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    MoodLog.getMoodAssetPath(_selectedScore),
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 24,
                      color: MoodLog.getMoodColor(_selectedScore),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: MoodLog.getMoodColor(_selectedScore),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Next: Identify Emotions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildBeemojiItem(int score, String label, bool isDark,
      {double imageSize = 64}) {
    final isSelected = _selectedScore == score;
    final moodColor = MoodLog.getMoodColor(score);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScore = score;
          _selectedLabel = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
            const SizedBox(height: 8),
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
          "Select up to 3 emotions that stand out most (${_selectedEmotions.length}/3 selected).",
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
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
                  selectedColor: AppColors.honeyGold
                      .withValues(alpha: isDark ? 0.4 : 0.25),
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
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Next: Add Reflection Note",
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
          "Feel free to write openly. Everything stays safe on your device.",
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
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveMoodLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Save Mood Check-In",
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
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            MoodLog.getMoodAssetPath(_selectedScore),
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(
                MoodLog.getMoodEmoji(_selectedScore),
                style: const TextStyle(fontSize: 72)),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          "Mood Checked In!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                "Logged as $_selectedLabel",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MoodLog.getMoodColor(_selectedScore)),
              ),
              if (_selectedEmotions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _selectedEmotions.join(' • '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mascot.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(mascot.avatarIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${mascot.name}: Your feelings are valid and acknowledged. I'll tailor today's gentle activities for your mood.",
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onCompleted != null) {
                widget.onCompleted!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
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
        ? []
        : logs
            .where(
                (l) => DateUtils.isSameDay(l.createdAt, _selectedCalendarDate))
            .toList();

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
                    .toList();
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
                            padding: const EdgeInsets.only(top: 2),
                            child: Image.asset(
                              MoodLog.getMoodAssetPath(dayLogs.first.moodScore),
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                MoodLog.getMoodEmoji(dayLogs.first.moodScore),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    MoodLog.getMoodAssetPath(l.moodScore),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Text(
                                            MoodLog.getMoodEmoji(l.moodScore),
                                            style:
                                                const TextStyle(fontSize: 22)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  MoodLog.getMoodAssetPath(log.moodScore),
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                      MoodLog.getMoodEmoji(log.moodScore),
                      style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mood: ${log.moodLabel}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MoodLog.getMoodColor(log.moodScore),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(log.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (log.note != null && log.note!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF6F4ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"${log.note}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF2C2C2C)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditMoodNoteDialog(context, log, provider, isDark);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Note',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.honeyAmber,
                        side: const BorderSide(color: AppColors.honeyAmber),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await CozyConfirmSheet.show(
                          context,
                          title: 'Palayain ang Mood Log?',
                          message:
                              'Sigurado ka bang nais mong alisin ang tala ng damdamin na ito?',
                          confirmLabel: 'Let Go',
                          cancelLabel: 'Keep Log',
                          icon: Icons.sentiment_neutral_rounded,
                        );
                        if (confirmed && context.mounted) {
                          provider.deleteMoodLog(log.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mood check-in gently removed.'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.white),
                      label: const Text('Let Go',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMoodNoteDialog(
      BuildContext context, MoodLog log, MoodProvider provider, bool isDark) {
    final noteController = TextEditingController(text: log.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Reflection Note',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: 'Add or edit your note...',
            filled: true,
            fillColor: isDark ? Colors.black26 : const Color(0xFFF6F4ED),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              final updated = log.copyWith(note: noteController.text.trim());
              provider.updateMoodLog(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mood note updated! ✨'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Note',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
