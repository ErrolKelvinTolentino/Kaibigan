import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/utils/language_helper.dart';
import 'home/home_screen.dart';
import 'mental_health_learning/learning_hub_screen.dart';
import 'settings/user_provider.dart';
import 'unified_entries/unified_entries_screen.dart';

/// Each destination retains its position. Activities open above the shell,
/// giving writing and conversational practice the full screen.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selected = 0;
  bool _visible = true;
  final Set<int> _visited = {0};
  DateTime? _lastBackPressTime;

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    _lastBackPressTime = null;
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
    setState(() {
      _selected = index;
      _visited.add(index);
      _visible = true;
    });
  }

  bool _onScroll(UserScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.direction == ScrollDirection.idle) return false;
    final visible = notification.direction == ScrollDirection.forward;
    if (visible != _visible) setState(() => _visible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    String copy(String en, String fil) =>
        LanguageHelper.pick(language, english: en, filipino: fil);
    final pages = <Widget>[
      const HomeScreen(),
      const ActivitiesMenuScreen(embedded: true),
      const UnifiedEntriesScreen(embedded: true),
      const LearningHubScreen(embedded: true),
    ];
    final showBar = _visible && MediaQuery.viewInsetsOf(context).bottom == 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selected != 0) {
          _select(0);
          return;
        }
        final now = DateTime.now();
        final wasRecent = _lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) <= const Duration(seconds: 2);
        if (!wasRecent) {
          _lastBackPressTime = now;
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                copy(
                  'Press back again to exit',
                  'Pindutin muli ang back upang lumabas',
                ),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        _lastBackPressTime = null;
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        }
        final sent = await AppLifecycleService.sendToBackground();
        if (!sent) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: IndexedStack(
            index: _selected,
            children: List.generate(
                pages.length,
                (index) => _visited.contains(index)
                    ? pages[index]
                    : const SizedBox.shrink()),
          ),
        ),
        bottomNavigationBar: ClipRect(
          child: AnimatedAlign(
            key: const ValueKey('scroll-aware-navbar'),
            alignment: Alignment.topCenter,
            heightFactor: showBar ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !showBar,
              child: ExcludeSemantics(
                excluding: !showBar,
                child: NavigationBar(
                  selectedIndex: _selected,
                  onDestinationSelected: _select,
                  height: 64,
                  destinations: [
                    NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded),
                        label: copy('Home', 'Bahay')),
                    NavigationDestination(
                        icon: const Icon(Icons.spa_outlined),
                        selectedIcon: const Icon(Icons.spa_rounded),
                        label: copy('Activities', 'Mga Gawain')),
                    NavigationDestination(
                        icon: const Icon(Icons.history_outlined),
                        selectedIcon: const Icon(Icons.history_rounded),
                        label: copy('Records', 'Mga tala')),
                    NavigationDestination(
                        icon: const Icon(Icons.school_outlined),
                        selectedIcon: const Icon(Icons.school_rounded),
                        label: copy('Lessons', 'Aralin')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
