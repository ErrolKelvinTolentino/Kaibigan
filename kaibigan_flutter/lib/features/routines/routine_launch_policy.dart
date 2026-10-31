import 'routine_model.dart';

class RoutineLaunch {
  const RoutineLaunch(this.config, {this.resume = false});
  final RoutineConfig config;
  final bool resume;
}

/// Shared rules for startup, the routine hub, and the Home resume card.
abstract final class RoutineLaunchPolicy {
  static RoutineType phaseAt(DateTime now) => now.hour >= 5 && now.hour < 12
      ? RoutineType.morning
      : now.hour >= 12 && now.hour < 17
          ? RoutineType.midday
          : RoutineType.night;

  static DateTime periodStart(DateTime now, RoutineType type) {
    final date = DateTime(now.year, now.month, now.day);
    return switch (type) {
      RoutineType.morning => date.add(const Duration(hours: 5)),
      RoutineType.midday => date.add(const Duration(hours: 12)),
      RoutineType.night =>
        DateTime(now.year, now.month, now.hour < 5 ? now.day - 1 : now.day, 17),
      RoutineType.custom => date,
    };
  }

  static DateTime periodEnd(DateTime now, RoutineType type) {
    final start = periodStart(now, type);
    return switch (type) {
      RoutineType.morning => DateTime(start.year, start.month, start.day, 12),
      RoutineType.midday => DateTime(start.year, start.month, start.day, 17),
      RoutineType.night => DateTime(start.year, start.month, start.day + 1, 5),
      RoutineType.custom => DateTime(start.year, start.month, start.day + 1),
    };
  }

  static bool usable(RoutineConfig config) =>
      config.isEnabled && config.activeStepsCount > 0;

  static bool sessionIsCurrent(
      RoutineSessionState session, RoutineConfig config, DateTime now) {
    if (!usable(config) || session.updatedAt.isAfter(now)) return false;
    if (config.type == RoutineType.night && session.updatedAt.hour < 5) {
      return now.isBefore(DateTime(session.updatedAt.year,
          session.updatedAt.month, session.updatedAt.day, 5));
    }
    final sameDay = session.updatedAt.year == now.year &&
        session.updatedAt.month == now.month &&
        session.updatedAt.day == now.day;
    // A night routine started before midnight remains resumable until 5 AM.
    return sameDay ||
        (config.type == RoutineType.night &&
            now.hour < 5 &&
            !session.updatedAt.isBefore(periodStart(now, RoutineType.night)));
  }

  static bool isDue(RoutineConfig config, DateTime now) {
    final phase = phaseAt(now);
    if (config.type != RoutineType.custom && config.type != phase) return false;
    if (config.type == RoutineType.custom &&
        phaseAt(DateTime(
                now.year, now.month, now.day, config.reminderTime.hour)) !=
            phase) {
      return false;
    }
    final start = periodStart(now, phase);
    var due = DateTime(start.year, start.month, start.day,
        config.reminderTime.hour, config.reminderTime.minute);
    if (due.isBefore(start)) {
      due = DateTime(due.year, due.month, due.day + 1, due.hour, due.minute);
    }
    return !due.isBefore(start) &&
        due.isBefore(periodEnd(now, phase)) &&
        !now.isBefore(due);
  }

  static String offerKey(DateTime now) {
    final phase = phaseAt(now);
    final start = periodStart(now, phase);
    return '${start.year}-${start.month}-${start.day}:${phase.name}';
  }

  static RoutineLaunch? choose({
    required DateTime now,
    required Iterable<RoutineConfig> routines,
    required RoutineSessionState? session,
    required bool Function(RoutineConfig) completed,
    bool scheduledOnly = true,
  }) {
    final available = routines.where(usable).toList();
    if (session != null) {
      for (final config in available) {
        if (config.id == session.routineId &&
            sessionIsCurrent(session, config, now)) {
          // A manually repeated routine may have an older completion today.
          // Only a completion after this session began makes it stale.
          return RoutineLaunch(config, resume: true);
        }
      }
    }
    final phase = phaseAt(now);
    for (final config in available) {
      if (config.type == phase &&
          !completed(config) &&
          (!scheduledOnly || isDue(config, now))) {
        return RoutineLaunch(config);
      }
    }
    for (final config in available) {
      if (config.type == RoutineType.custom &&
          !completed(config) &&
          (!scheduledOnly || isDue(config, now))) {
        return RoutineLaunch(config);
      }
    }
    return null;
  }
}
