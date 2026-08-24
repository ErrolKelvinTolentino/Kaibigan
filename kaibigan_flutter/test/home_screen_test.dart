import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home is a complete navigation surface without a bottom bar',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'taglish',
    });
    await tester.binding.setSurfaceSize(const Size(620, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kamusta, Errol', findRichText: true), findsOneWidget);
    expect(find.text('Highlight of the day'), findsOneWidget);
    expect(find.text('Wellness Activities'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
