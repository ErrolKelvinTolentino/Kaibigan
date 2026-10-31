import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/kaibigan_loading_screen.dart';
import '../main_navigation_screen.dart';
import '../routines/flows/progressive_routine_runner.dart';
import '../routines/routines_provider.dart';
import '../settings/user_provider.dart';

/// Evaluates automatic routing once, after preferences and history are known.
/// Returning from an activity or resuming the OS app does not re-run startup.
class StartupHomeScreen extends StatefulWidget {
  const StartupHomeScreen({super.key});

  @override
  State<StartupHomeScreen> createState() => _StartupHomeScreenState();
}

class _StartupHomeScreenState extends State<StartupHomeScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final user = context.read<UserProvider>();
    final identity = user.startupIdentity;
    final routines = context.read<RoutinesProvider>();
    try {
      await routines.startupReady.timeout(const Duration(seconds: 8));
      if (!mounted ||
          !user.canUseApp ||
          user.isPasswordRecovery ||
          identity != user.startupIdentity) {
        return;
      }
      final launch = user.completedSetupThisSession
          ? null
          : await routines
              .claimStartupRoutine()
              .timeout(const Duration(seconds: 3));
      if (!mounted ||
          !user.canUseApp ||
          user.isPasswordRecovery ||
          identity != user.startupIdentity) {
        return;
      }
      setState(() => _ready = true);
      if (launch != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              ModalRoute.of(context)?.isCurrent != true ||
              identity != user.startupIdentity ||
              user.isPasswordRecovery) {
            return;
          }
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ProgressiveRoutineRunner(
                routineType: launch.config.type,
                config: launch.config,
                resumeSession: launch.resume),
          ));
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) => _ready
      ? const MainNavigationScreen()
      : const KaibiganLoadingScreen(message: 'Opening your space…');
}
