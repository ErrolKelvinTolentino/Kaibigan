import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Environment Config (.env)
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

class KaibiganApp extends StatelessWidget {
  const KaibiganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => ComfortProvider()),
        ChangeNotifierProvider(create: (_) => LettersProvider()),
        ChangeNotifierProvider(create: (_) => DailyGoalsProvider()),
        ChangeNotifierProvider(create: (_) => RoutinesProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return MaterialApp(
            title: 'Kaibigan - Mental Wellness Companion',
            debugShowCheckedModeBanner: false,
            scrollBehavior: AppScrollBehavior(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                userProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: userProvider.isAuthenticated
                ? const HomeScreen()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
