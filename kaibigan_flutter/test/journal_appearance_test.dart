import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/journal_appearance.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('journal appearance loads and persists locally', () async {
    SharedPreferences.setMockInitialValues({
      'journal_paper_style': 'dotted',
      'journal_accent': 'sage',
    });

    final provider = UserProvider();
    addTearDown(provider.dispose);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(provider.journalPaperStyle, JournalPaperStyle.dotted);
    expect(provider.journalAccent, JournalAccent.sage);

    await provider.setJournalPaperStyle(JournalPaperStyle.botanical);
    await provider.setJournalAccent(JournalAccent.rose);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('journal_paper_style'), 'botanical');
    expect(preferences.getString('journal_accent'), 'rose');
  });

  test('journal appearance safely falls back for unknown stored values', () {
    expect(
      JournalPaperStyleX.fromStorage('future-paper'),
      JournalPaperStyle.ruled,
    );
    expect(JournalAccentX.fromStorage('future-accent'), JournalAccent.honey);
  });
}
