import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/journal_appearance.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('journal appearance loads and persists locally', () async {
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'user_pref_offline:guest_journal_paper_style': 'dotted',
      'user_pref_offline:guest_journal_accent': 'sage',
    });

    final provider = UserProvider();
    addTearDown(provider.dispose);
    await provider.ready;

    expect(provider.journalPaperStyle, JournalPaperStyle.dotted);
    expect(provider.journalAccent, JournalAccent.sage);

    await provider.setJournalPaperStyle(JournalPaperStyle.botanical);
    await provider.setJournalAccent(JournalAccent.rose);

    final reopened = UserProvider();
    addTearDown(reopened.dispose);
    await reopened.ready;
    expect(reopened.journalPaperStyle, JournalPaperStyle.botanical);
    expect(reopened.journalAccent, JournalAccent.rose);
  });

  test('journal appearance safely falls back for unknown stored values', () {
    expect(
      JournalPaperStyleX.fromStorage('future-paper'),
      JournalPaperStyle.ruled,
    );
    expect(JournalAccentX.fromStorage('future-accent'), JournalAccent.honey);
  });
}
