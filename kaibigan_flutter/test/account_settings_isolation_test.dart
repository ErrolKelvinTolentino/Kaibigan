import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_memory_service.dart';
import 'package:kaibigan_flutter/core/services/ai_response_feedback_service.dart';
import 'package:kaibigan_flutter/core/services/ui_sound_service.dart';
import 'package:kaibigan_flutter/core/theme/garden_appearance.dart';
import 'package:kaibigan_flutter/core/theme/journal_appearance.dart';
import 'package:kaibigan_flutter/features/home/activity_usage_store.dart';
import 'package:kaibigan_flutter/features/insights/wellbeing_context.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('guest migration does not inherit a legacy cloud account’s settings',
      () async {
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'auth_mode': 'authenticated',
      'user_email': 'other-qa@example.com',
      'display_name': 'Other account',
      'selected_companion': 'ann',
      'preferred_language': 'filipino',
    });
    final guest = UserProvider();
    await guest.ready;
    expect(guest.displayName, 'Friend');
    expect(guest.selectedCompanion, 'kai');
    expect(guest.hasCompletedSetup, isFalse);
    guest.dispose();
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'User A customizes settings, logs out, and state resets to fresh defaults',
      () async {
    final provider = UserProvider();
    await provider.ready;

    // Simulate User A customizing settings
    await provider.updateDisplayName('Alice');
    await provider.setCompanion('ann');
    await provider.setLanguage('filipino');
    await provider.setThemeMode(ThemeMode.dark);
    await provider.setGardenAppearance(GardenAppearance.night);
    await provider.setJournalPaperStyle(JournalPaperStyle.dotted);
    await provider.setJournalAccent(JournalAccent.lavender);
    await provider.setJournalTextSize(JournalTextSize.large);
    await provider.setUiSoundLevel(UiSoundLevel.off);
    await provider.setAiMemoryEnabled(false);
    await provider.setAiWellbeingContextEnabled(false);

    expect(provider.displayName, 'Alice');
    expect(provider.selectedCompanion, 'ann');
    expect(provider.preferredLanguage, 'filipino');
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.isDarkMode, isTrue);
    expect(provider.gardenAppearance, GardenAppearance.night);
    expect(provider.journalPaperStyle, JournalPaperStyle.dotted);
    expect(provider.journalAccent, JournalAccent.lavender);
    expect(provider.journalTextSize, JournalTextSize.large);
    expect(provider.uiSoundLevel, UiSoundLevel.off);
    expect(provider.aiMemoryEnabled, isFalse);
    expect(provider.aiWellbeingContextEnabled, isFalse);

    // User A logs out
    await provider.logout();

    // Provider state must be completely reset to default
    expect(provider.authMode, AuthMode.pending);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.userEmail, isNull);
    expect(provider.displayName, 'Friend');
    expect(provider.selectedCompanion, 'kai');
    expect(provider.preferredLanguage, 'taglish');
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.isDarkMode, isFalse);
    expect(provider.gardenAppearance, GardenAppearance.syncWithTime);
    expect(provider.journalPaperStyle, JournalPaperStyle.ruled);
    expect(provider.journalAccent, JournalAccent.honey);
    expect(provider.journalTextSize, JournalTextSize.normal);
    expect(provider.uiSoundLevel, UiSoundLevel.soft);
    expect(provider.aiMemoryEnabled, isTrue);
    expect(provider.aiWellbeingContextEnabled, isTrue);
    expect(provider.hasCompletedSetup, isFalse);
    expect(provider.hasSeenAppTutorial, isFalse);

    // Global un-scoped keys must be cleared so they never leak into the next login
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('display_name'), isFalse);
    expect(prefs.containsKey('selected_companion'), isFalse);
    expect(prefs.containsKey('preferred_language'), isFalse);
    expect(prefs.containsKey('theme_mode'), isFalse);
    expect(prefs.containsKey('is_dark_mode'), isFalse);
    expect(prefs.containsKey('garden_appearance'), isFalse);
    expect(prefs.containsKey('journal_paper_style'), isFalse);
    expect(prefs.containsKey('journal_accent'), isFalse);
    expect(prefs.containsKey('journal_text_size'), isFalse);
    expect(prefs.containsKey('ui_sound_level'), isFalse);
    expect(prefs.containsKey('ai_memory_enabled'), isFalse);
    expect(prefs.containsKey('ai_wellbeing_context_enabled'), isFalse);

    // Subsystems must also be reset
    expect(AIMemoryService.isEnabled, isTrue);
    expect(WellbeingContextService.isEnabled, isTrue);
    expect(AIResponseFeedbackService.cachedProfile, AIPreferenceProfile.empty);
  });

  test(
      'New provider instance after logout does not inherit previous user settings',
      () async {
    final userA = UserProvider();
    await userA.ready;
    await userA.setCompanion('bee');
    await userA.setLanguage('english');
    await userA.setThemeMode(ThemeMode.dark);
    await userA.logout();

    // A fresh UserProvider instance on the same device starts with fresh defaults
    final userB = UserProvider();
    await userB.ready;

    expect(userB.displayName, 'Friend');
    expect(userB.selectedCompanion, 'kai');
    expect(userB.preferredLanguage, 'taglish');
    expect(userB.themeMode, ThemeMode.light);
    expect(userB.isDarkMode, isFalse);
    expect(userB.uiSoundLevel, UiSoundLevel.soft);
  });

  test(
      'Activity stats and login dates are purged on logout so streak does not carry over',
      () async {
    await ActivityUsageStore.recordTodayLogin();
    await ActivityUsageStore.incrementActivityUsage('breathing');
    await ActivityUsageStore.savePinnedFavorites(['breathing']);

    final loginDatesBefore = await ActivityUsageStore.loadLoginDates();
    final countsBefore = await ActivityUsageStore.loadActivityCounts();
    final pinnedBefore = await ActivityUsageStore.loadPinnedFavorites();

    expect(loginDatesBefore.isNotEmpty, isTrue);
    expect(countsBefore['breathing'], 1);
    expect(pinnedBefore, ['breathing']);

    final provider = UserProvider();
    await provider.ready;
    await provider.logout();

    final loginDatesAfter = await ActivityUsageStore.loadLoginDates();
    final countsAfter = await ActivityUsageStore.loadActivityCounts();
    final pinnedAfter = await ActivityUsageStore.loadPinnedFavorites();

    expect(loginDatesAfter.isEmpty, isTrue);
    expect(countsAfter.isEmpty, isTrue);
    expect(pinnedAfter.isEmpty, isTrue);
  });
}
