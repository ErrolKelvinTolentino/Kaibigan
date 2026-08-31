import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/cozy_app_frame.dart';
import 'core/widgets/kaibigan_loading_screen.dart';

import 'features/settings/user_provider.dart';
import 'features/affirmations/affirmations_provider.dart';
import 'features/journaling/journal_provider.dart';
import 'features/gratitude_garden/gratitude_provider.dart';
import 'features/mood_tracking/mood_provider.dart';
import 'features/comfort_corner/comfort_provider.dart';
import 'features/future_letters/letters_provider.dart';
import 'features/wellness_journey/daily_goals_provider.dart';
import 'features/routines/routines_provider.dart';
import 'features/auth_onboarding/auth_screen.dart';
import 'features/auth_onboarding/reset_password_screen.dart';
import 'features/home/home_screen.dart';

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
    await EnvConfig.init();
    await Future.wait([
      SupabaseService.init(),
      NotificationService.init(),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.hasLoadedPreferences) {
          return const KaibiganLoadingScreen(message: 'Opening your space…');
        }
        if (userProvider.isPasswordRecovery) {
          return const ResetPasswordScreen();
        }
        if (userProvider.isAuthenticated) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class KaibiganApp extends StatelessWidget {
  const KaibiganApp({super.key});

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
        ChangeNotifierProxyProvider<UserProvider, DailyGoalsProvider>(
          create: (_) => DailyGoalsProvider(),
          update: (_, __, provider) {
            final value = provider ?? DailyGoalsProvider();
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
            title: 'Kaibigan - Mental Wellness Companion',
            debugShowCheckedModeBanner: false,
            scrollBehavior: AppScrollBehavior(),
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
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
                child: CozyAppFrame(
                  child: child ?? const SizedBox.shrink(),
                ),
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
