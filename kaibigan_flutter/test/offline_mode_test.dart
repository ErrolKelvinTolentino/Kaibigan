import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/local_record_store.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OfflineMode.setEnabledForTesting(true);
  });
  tearDown(() => OfflineMode.setEnabledForTesting(false));

  group('LocalRecordStore', () {
    final store = LocalRecordStore<MoodPoint>(
      collection: 'test_points',
      encode: (p) => {'id': p.id, 'value': p.value},
      decode: (m) => MoodPoint(m['id'] as String, m['value'] as int),
      idOf: (p) => p.id,
    );

    test('records survive a reload', () async {
      await store.replaceAll('guest', [MoodPoint('a', 1), MoodPoint('b', 2)]);
      final loaded = await store.load('guest');

      expect(loaded.map((p) => p.id), ['a', 'b']);
      expect(loaded.map((p) => p.value), [1, 2]);
    });

    test('scopes cannot read each other', () async {
      await store.replaceAll('guest', [MoodPoint('a', 1)]);
      await store.replaceAll('user-123', [MoodPoint('b', 2)]);

      expect((await store.load('guest')).single.id, 'a');
      expect((await store.load('user-123')).single.id, 'b');
    });

    test('upsert replaces by id instead of duplicating', () async {
      await store.upsert('guest', MoodPoint('a', 1));
      await store.upsert('guest', MoodPoint('a', 9));
      final loaded = await store.load('guest');

      expect(loaded, hasLength(1));
      expect(loaded.single.value, 9);
    });

    test('remove takes out one record and leaves the rest', () async {
      await store.replaceAll('guest', [MoodPoint('a', 1), MoodPoint('b', 2)]);
      await store.remove('guest', 'a');

      expect((await store.load('guest')).map((p) => p.id), ['b']);
    });

    test('an unreadable record does not take the history with it', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        store.keyFor('guest'),
        '[{"id":"good","value":1},{"id":"bad"},{"id":"also-good","value":3}]',
      );

      final loaded = await store.load('guest');
      expect(loaded.map((p) => p.id), ['good', 'also-good']);
    });

    test('corrupt storage reads as empty rather than throwing', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(store.keyFor('guest'), 'not json at all');

      expect(await store.load('guest'), isEmpty);
    });
  });

  group('offline mode flag', () {
    test('defaults to off so an account stays the normal path', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await OfflineMode.loadPreference(), isFalse);
    });

    test('the choice survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      await OfflineMode.setEnabled(true);

      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(OfflineMode.preferenceKey), isTrue);
      expect(await OfflineMode.loadPreference(), isTrue);
    });

    test('with no backend at all, records still go somewhere', () {
      OfflineMode.setEnabledForTesting(false);
      // Supabase is never initialised in tests, so this is the "app has no
      // usable backend" case: writing locally beats discarding the entry.
      expect(OfflineMode.storesLocally, isTrue);
    });
  });

  group('providers write to the device', () {
    test('a mood check-in is readable by a fresh provider', () async {
      final writer = MoodProvider(syncOnCreate: false);
      final saved = await writer.logMood(score: 4, label: 'Good');
      expect(saved, isNotNull);

      final reader = MoodProvider(syncOnCreate: false);
      await reader.fetchMoodLogs();

      expect(reader.logs, hasLength(1));
      expect(reader.logs.single.moodScore, 4);
      expect(reader.errorMessage, isNull);
    });

    test('a journal entry keeps its conversation and summary', () async {
      final writer = JournalProvider();
      final saved = await writer.addJournalEntry(
        title: 'A quiet evening',
        content: 'Nothing was asked of me tonight.',
        companionId: 'kai',
        mood: '',
        conversationTurns: const [
          JournalConversationTurn(
            userText: 'Nothing was asked of me tonight.',
            aiResponse: 'That sounds like room to breathe.',
            companionId: 'kai',
          ),
        ],
      );
      expect(saved, isNotNull);

      final reader = JournalProvider();
      await reader.fetchJournalEntries();

      expect(reader.allEntries, hasLength(1));
      final entry = reader.allEntries.single;
      expect(entry.title, 'A quiet evening');
      expect(entry.conversationTurns, hasLength(1));
      expect(entry.conversationTurns.single.aiResponse,
          'That sounds like room to breathe.');
    });

    test('editing and deleting a journal entry both persist', () async {
      final provider = JournalProvider();
      final saved = await provider.addJournalEntry(
        title: 'Draft',
        content: 'First pass.',
        companionId: 'kai',
        mood: '',
      );

      final edited = await provider
          .updateJournalEntry(saved!.copyWith(title: 'Revised'));
      expect(edited, isTrue);

      var reader = JournalProvider();
      await reader.fetchJournalEntries();
      expect(reader.allEntries.single.title, 'Revised');

      expect(await provider.deleteJournalEntry(saved.id), isTrue);
      reader = JournalProvider();
      await reader.fetchJournalEntries();
      expect(reader.allEntries, isEmpty);
    });

    test('a gratitude flower is kept', () async {
      final writer = GratitudeProvider();
      final saved = await writer.addGratitudeEntry('My sister called back');
      expect(saved, isNotNull);

      final reader = GratitudeProvider();
      await reader.fetchGratitudeEntries();
      expect(reader.entries.single.content, 'My sister called back');
    });

    test('a routine log is kept and reaches the sleep analytics', () async {
      final writer = RoutinesProvider(syncOnCreate: false);
      final stored = await writer.addLog(RoutineLog(
        id: '',
        routineId: 'sleep_1',
        routineType: RoutineType.morning,
        sleepFeeling: SleepFeeling.groggy,
        focusOrHighlight: 'Slept 6 hrs: Needed more',
        completedAt: DateTime.now(),
      ));
      expect(stored, isTrue);

      final reader = RoutinesProvider(syncOnCreate: false);
      await reader.fetchRoutineLogs();
      expect(reader.logs, hasLength(1));
      expect(reader.logs.single.sleepFeeling, SleepFeeling.groggy);
    });

    test('a future letter is kept', () async {
      final writer = LettersProvider();
      final saved = await writer.createLetter(
        title: 'To me in a year',
        content: 'I hope this week reads smaller by then.',
        deliverAt: DateTime.now().add(const Duration(days: 365)),
      );
      expect(saved, isNotNull);

      final reader = LettersProvider();
      await reader.fetchLetters();
      expect(reader.letters.single.title, 'To me in a year');
    });

    test('nothing reports a sync error while offline', () async {
      final mood = MoodProvider(syncOnCreate: false);
      await mood.fetchMoodLogs();
      expect(mood.errorMessage, isNull);

      final journal = JournalProvider();
      await journal.fetchJournalEntries();
      expect(journal.errorMessage, isNull);
    });
  });

  group('entering and leaving offline mode', () {
    test('continuing offline opens the app and is remembered', () async {
      SharedPreferences.setMockInitialValues({});
      OfflineMode.setEnabledForTesting(false);
      final user = UserProvider();
      await user.ready;
      expect(user.canUseApp, isFalse);

      await user.continueOffline();

      expect(user.isOffline, isTrue);
      expect(user.canUseApp, isTrue);
      expect(user.isAuthenticated, isFalse,
          reason: 'offline is not the same as having an account');
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(OfflineMode.preferenceKey), isTrue);
    });

    test('leaving offline mode does not touch what was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final user = UserProvider();
      await user.ready;
      await user.continueOffline();

      final writer = MoodProvider(syncOnCreate: false);
      await writer.logMood(score: 2, label: 'Low');

      await user.leaveOfflineMode();
      expect(user.isOffline, isFalse);
      expect(user.canUseApp, isFalse);

      // The records are still on the device, waiting.
      OfflineMode.setEnabledForTesting(true);
      final reader = MoodProvider(syncOnCreate: false);
      await reader.fetchMoodLogs();
      expect(reader.logs, hasLength(1));
    });

    test('a remembered offline choice reopens the app on launch', () async {
      SharedPreferences.setMockInitialValues(
        {OfflineMode.preferenceKey: true},
      );
      OfflineMode.setEnabledForTesting(false);

      final user = UserProvider();
      await user.ready;

      expect(user.isOffline, isTrue);
      expect(user.canUseApp, isTrue);
    });
  });
}

/// A minimal record for exercising the store without dragging a feature
/// model's validation into these tests.
class MoodPoint {
  const MoodPoint(this.id, this.value);
  final String id;
  final int value;
}
