import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';

import 'features/settings/user_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize public build-time configuration (dart-defines)
  await EnvConfig.init();

  // 2. Initialize Supabase
  await SupabaseService.init();

  // 3. Initialize Notifications
  await NotificationService.init();

  runApp(const KaibiganApp());
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
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
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
            themeMode:
                userProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
