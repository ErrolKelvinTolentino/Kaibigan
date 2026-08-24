import 'package:flutter/material.dart';
import 'home/home_screen.dart';

/// Home is the app's single navigation surface. Feature screens are opened
/// from its activity cards and return through the normal back action.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
