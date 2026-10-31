import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'features/insights/wellbeing_context.dart';
import 'core/services/ui_sound_service.dart';
import 'core/widgets/kaibigan_sound_scope.dart';
import 'core/widgets/cozy_app_frame.dart';
import 'core/widgets/kaibigan_loading_screen.dart';

import 'features/settings/user_provider.dart';
import 'features/affirmations/affirmations_provider.dart';
import 'features/journaling/journal_provider.dart';
import 'features/gratitude_garden/gratitude_provider.dart';
import 'features/mood_tracking/mood_provider.dart';
import 'features/comfort_corner/comfort_provider.dart';
import 'features/future_letters/letters_provider.dart';
import 'features/routines/routines_provider.dart';
import 'features/auth_onboarding/auth_screen.dart';
import 'features/auth_onboarding/kai_value_demo_screen.dart';
import 'features/auth_onboarding/reset_password_screen.dart';
import 'features/auth_onboarding/mascot_selection_screen.dart';
import 'features/auth_onboarding/startup_destination.dart';
import 'features/auth_onboarding/startup_home_screen.dart';
import 'core/services/offline_mode.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaibiganBootstrap());
}

class KaibiganBootstrap extends StatefulWidget {
  const KaibiganBootstrap({super.key});

  @override
  State<KaibiganBootstrap> createState() => _KaibiganBootstrapState();
}

class _KaibiganBootstrapState extends State<KaibiganBootstrap> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final minimumSplash =
        Future<void>.delayed(const Duration(milliseconds: 900));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    // Nothing in start-up is allowed to strand the splash screen. Each step
    // is optional at this stage: a failed preference read or notification
    // permission should not stop the app from opening, and a failure here
    // was previously an infinite "Preparing your space…".
    Future<void> optional(Future<void> work, String label) => work.catchError(
          (Object error) => debugPrint('Start-up step "$label" failed: $error'),
        );

    try {
      await EnvConfig.init().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Environment load failed: $error');
    }
    await Future.wait([
      optional(SupabaseService.init().timeout(const Duration(seconds: 8)),
          'supabase'),
      optional(
          OfflineMode.loadPreference()
              .then((_) {})
              .timeout(const Duration(seconds: 3)),
          'offline preference'),
      optional(NotificationService.init().timeout(const Duration(seconds: 3)),
          'notifications'),
      // Read before any journal screen can open: the default is on, so a
      // user who turned it off must not have one request slip through.
      optional(
          WellbeingContextService.loadPreference()
              .then((_) {})
              .timeout(const Duration(seconds: 3)),
          'wellbeing context preference'),
      minimumSplash,
    ]);
    if (mounted) setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return const KaibiganApp();
    return MaterialApp(
      title: 'Kaibigan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const KaibiganLoadingScreen(message: 'Preparing your space…'),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (getPlatform(context)) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      _ => const ClampingScrollPhysics(),
    };
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showDemo = false;
  int _authTabIndex = 0;

  void _finishDemo(bool register) {
    context.read<UserProvider>().completeKaiValueDemo();
    setState(() {
      _showDemo = false;
      _authTabIndex = register ? 1 : 0;
    });
  }

  void _reopenDemo() => setState(() => _showDemo = true);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return switch (StartupDestinationPolicy.choose(
          loaded: userProvider.hasLoadedPreferences,
          recovery: userProvider.isPasswordRecovery,
          canUseApp: userProvider.canUseApp,
          setupComplete: userProvider.hasCompletedSetup,
          demoSeen: userProvider.hasSeenKaiValueDemo,
          reopenDemo: _showDemo,
        )) {
          StartupDestination.loading =>
            const KaibiganLoadingScreen(message: 'Opening your space…'),
          StartupDestination.recovery => const ResetPasswordScreen(),
          StartupDestination.demo =>
            KaiValueDemoScreen(onContinue: _finishDemo),
          StartupDestination.authentication =>
            AuthScreen(initialTabIndex: _authTabIndex, onShowDemo: _reopenDemo),
          StartupDestination.setup => const MascotSelectionScreen(),
          StartupDestination.home =>
            StartupHomeScreen(key: ValueKey(userProvider.startupIdentity)),
        };
      },
    );
  }
}

class KaibiganApp extends StatefulWidget {
  const KaibiganApp({super.key, this.soundController});

  /// Injected by tests so no audio device is touched.
  final UiSoundController? soundController;

  @override
  State<KaibiganApp> createState() => _KaibiganAppState();
}

class _KaibiganAppState extends State<KaibiganApp> {
  late final UiSoundController _sound =
      widget.soundController ?? UiSoundPlayer();

  @override
  void initState() {
    super.initState();
    // Reads the saved level; the default is already usable if this fails.
    _sound.load();
  }

  @override
  void dispose() {
    if (widget.soundController == null) _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
        ChangeNotifierProxyProvider<UserProvider, JournalProvider>(
          create: (_) => JournalProvider(),
          update: (_, __, provider) {
            final value = provider ?? JournalProvider();
            value.syncForCurrentUser();
            return value;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, GratitudeProvider>(
          create: (_) => GratitudeProvider(),
          update: (_, __, provider) {
            final value = provider ?? GratitudeProvider();
            value.syncForCurrentUser();
            return value;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, MoodProvider>(
          create: (_) => MoodProvider(),
          update: (_, __, provider) {
            final value = provider ?? MoodProvider();
            value.syncForCurrentUser();
            return value;
          },
        ),
        ChangeNotifierProvider(create: (_) => ComfortProvider()),
        ChangeNotifierProxyProvider<UserProvider, LettersProvider>(
          create: (_) => LettersProvider(),
          update: (_, __, provider) {
            final value = provider ?? LettersProvider();
            value.syncForCurrentUser();
            return value;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, RoutinesProvider>(
          create: (_) => RoutinesProvider(),
          update: (_, __, provider) {
            final value = provider ?? RoutinesProvider();
            value.syncForCurrentUser();
            return value;
          },
        ),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return MaterialApp(
            key: ValueKey(
                '${userProvider.startupIdentity}:${userProvider.isPasswordRecovery}'),
            title: 'Kaibigan - Mental Wellness Companion',
            debugShowCheckedModeBanner: false,
            scrollBehavior: AppScrollBehavior(),
            navigatorObservers: [KaibiganSoundNavigatorObserver(_sound)],
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              // One scope above every route: this is what makes "every tap"
              // true for screens that have not been written yet.
              child = KaibiganSoundScope(controller: _sound, child: child!);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  systemStatusBarContrastEnforced: false,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: CozyAppFrame(child: child),
              );
            },
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: userProvider.preferredLanguage == 'filipino'
                ? const Locale('fil')
                : const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('fil')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: userProvider.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
