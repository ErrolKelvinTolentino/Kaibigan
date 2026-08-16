import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'routines/routines_hub_screen.dart';
import 'gratitude_garden/garden_screen.dart';
import 'journaling/journal_list_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    const RoutinesHubScreen(),
    const GardenScreen(),
    const JournalListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', isDark),
              _buildNavItem(1, Icons.schedule_outlined, Icons.schedule_rounded, 'Routines', isDark),
              _buildNavItem(2, Icons.local_florist_outlined, Icons.local_florist_rounded, 'Garden', isDark),
              _buildNavItem(3, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Journal', isDark),
              _buildNavItem(4, Icons.tune_outlined, Icons.tune_rounded, 'Settings', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    final primaryColor = AppColors.sageGreen;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              size: 22,
              color: isSelected
                  ? primaryColor
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
