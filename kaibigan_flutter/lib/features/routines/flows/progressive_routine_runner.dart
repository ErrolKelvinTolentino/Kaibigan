import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routine_model.dart';
import '../routines_provider.dart';
import 'dynamic_routine_flow.dart';

/// Resolves the saved routine configuration before starting its activities.
///
/// Autoplay supplies only a phase, while launches from the routines hub can
/// supply the exact config (important for custom routines). Both paths end up
/// in [DynamicRoutineFlow], which honors every enabled activity and its order.
class ProgressiveRoutineRunner extends StatelessWidget {
  final RoutineType routineType;
  final RoutineConfig? config;
  final bool resumeSession;

  const ProgressiveRoutineRunner({
    super.key,
    required this.routineType,
    this.config,
    this.resumeSession = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedConfig = config ??
        context.read<RoutinesProvider>().getRoutineById(routineType.name);

    if (resolvedConfig == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine unavailable')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This routine could not be loaded. Please return and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DynamicRoutineFlow(
      config: resolvedConfig,
      resumeSession: resumeSession,
    );
  }
}
