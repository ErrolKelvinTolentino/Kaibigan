import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/offline_account_import.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';
import 'package:kaibigan_flutter/core/utils/uuid_helper.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cloud implements OfflineImportCloud {
  final data = <String, List<Map<String, dynamic>>>{};
  String? failTable;
  bool failAfterCommit = false;
  int saves = 0;

  @override
  Future<List<Map<String, dynamic>>> fetch(String table, String owner) async =>
      [
        for (final row in data[table] ?? <Map<String, dynamic>>[])
          if (row['user_id'] == owner) {...row}
      ];

  @override
  Future<void> save(String table, List<Map<String, dynamic>> rows) async {
    saves++;
    if (failTable == table && !failAfterCommit) {
      throw StateError('Disconnected');
    }
    final stored = data.putIfAbsent(table, () => []);
    for (final row in rows) {
      final index = stored.indexWhere((old) => table == 'learning_progress'
          ? old['user_id'] == row['user_id'] &&
              old['lesson_id'] == row['lesson_id']
          : old['id'] == row['id']);
      if (index == -1) {
        stored.add({...row});
      } else if (table == 'learning_progress') {
        stored[index] = {...stored[index], ...row};
      }
    }
    if (failTable == table) throw StateError('Lost upload acknowledgement');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Cloud cloud;
  String? owner;
  late OfflineAccountImport transfer;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cloud = _Cloud();
    owner = null;
    transfer = OfflineAccountImport(cloud: cloud, currentUserId: () => owner);
    OfflineMode.setEnabledForTesting(true);
  });

  Future<String> seed(String table,
      {Map<String, dynamic> fields = const {}}) async {
    final id = UuidHelper.generateV4();
    await prefs.setString(
        'kaibigan_local_${table}_guest',
        jsonEncode([
          {'id': id, ...fields}
        ]));
    return id;
  }

  test('normal sign-in does not silently import guest records', () async {
    await seed('journal_entries', fields: {'content': 'Private local writing'});
    owner = 'A';
    expect(await transfer.sync(), isTrue);
    expect(cloud.saves, 0);
  });

  test('explicit linking imports all record types and retains their stable IDs',
      () async {
    final ids = <String, String>{};
    for (final table in OfflineAccountImport.collections) {
      ids[table] = await seed(table,
          fields: table == 'gratitude_entries'
              ? {
                  'garden_index': 0,
                  'plot_index': 0,
                  'content': 'A friend listened'
                }
              : {'content': 'Local record'});
    }
    await transfer.prepare('guest');
    expect(await transfer.sync(), isFalse);
    owner = 'A';
    expect(await transfer.sync(), isTrue);
    for (final table in ids.keys) {
      expect(cloud.data[table]!.single['id'], ids[table]);
      expect(cloud.data[table]!.single['user_id'], 'A');
      expect(cloud.data[table]!.single.containsKey('_source_id'), isFalse);
      expect(prefs.getString('kaibigan_local_${table}_guest'), isNotNull);
    }
    expect(prefs.getString(OfflineAccountImport.jobKey), isNull);
  });

  test('failed backup resumes after restart and cannot switch account owners',
      () async {
    await seed('journal_entries', fields: {'content': 'Keep this journal'});
    await seed('mood_logs', fields: {'mood_score': 4});
    await transfer.prepare('guest');
    owner = 'A';
    cloud.failTable = 'mood_logs';
    expect(await transfer.sync(), isFalse);
    expect(cloud.data['journal_entries'], hasLength(1));
    final restarted =
        OfflineAccountImport(cloud: cloud, currentUserId: () => owner);
    owner = 'B';
    expect(await restarted.sync(), isFalse);
    expect(await restarted.pendingFor('B'), isFalse);
    expect(
        cloud.data.values
            .expand((rows) => rows)
            .any((row) => row['user_id'] == 'B'),
        isFalse);
    owner = 'A';
    cloud.failTable = null;
    expect(await restarted.sync(), isTrue);
    expect(cloud.data['journal_entries'], hasLength(1));
    expect(cloud.data['mood_logs']!.single['user_id'], 'A');
  });

  test(
      'lost acknowledgement retries without duplicate or overwriting a cloud edit',
      () async {
    await seed('journal_entries',
        fields: {'content': 'Original local writing'});
    await transfer.prepare('guest');
    owner = 'A';
    cloud.failTable = 'journal_entries';
    cloud.failAfterCommit = true;
    expect(await transfer.sync(), isFalse);
    cloud.data['journal_entries']!.single['content'] = 'Edited after upload';
    cloud.failTable = null;
    expect(await transfer.sync(), isTrue);
    expect(cloud.data['journal_entries'], hasLength(1));
    expect(cloud.data['journal_entries']!.single['content'],
        'Edited after upload');
    // Retained backup IDs cannot be claimed by another account later.
    await transfer.prepare('guest');
    owner = 'B';
    expect(await transfer.sync(), isTrue);
    expect(cloud.data['journal_entries'], hasLength(1));
  });

  test('importing flowers preserves cloud flowers and allocates a free plot',
      () async {
    await seed('gratitude_entries', fields: {
      'garden_index': 0,
      'plot_index': 0,
      'content': 'Local flower'
    });
    cloud.data['gratitude_entries'] = [
      {
        'id': 'existing-flower',
        'user_id': 'A',
        'garden_index': 0,
        'plot_index': 0,
        'content': 'Cloud flower'
      }
    ];
    await transfer.prepare('guest');
    owner = 'A';
    expect(await transfer.sync(), isTrue);
    final flowers = cloud.data['gratitude_entries']!;
    expect(flowers, hasLength(2));
    expect(flowers.first['content'], 'Cloud flower');
    expect(flowers.last['plot_index'], 1);
  });

  test('lesson marks merge without rewinding existing account progress',
      () async {
    await prefs
        .setStringList('mental_health_learning_completed_ids', ['lesson']);
    await prefs
        .setStringList('mental_health_learning_helpful_ideas', ['lesson:0']);
    cloud.data['learning_progress'] = [
      {
        'user_id': 'A',
        'lesson_id': 'lesson',
        'completed': false,
        'helpful_ideas': [1],
        'last_idea_index': 3
      }
    ];
    await transfer.prepare('guest');
    owner = 'A';
    expect(await transfer.sync(), isTrue);
    final row = cloud.data['learning_progress']!.single;
    expect(row['completed'], isTrue);
    expect(row['helpful_ideas'], unorderedEquals([0, 1]));
    expect(row['last_idea_index'], 3);
  });

  test('unreadable local history is preserved rather than silently skipped',
      () async {
    await prefs.setString('kaibigan_local_journal_entries_guest', '{broken');
    await expectLater(transfer.prepare('guest'), throwsFormatException);
    expect(prefs.getString('kaibigan_local_journal_entries_guest'), '{broken');
    expect(prefs.getString(OfflineAccountImport.jobKey), isNull);
  });

  test('returning to offline mode cancels an unbound linking request only',
      () async {
    final user = UserProvider(offlineImport: transfer);
    await user.ready;
    await user.continueOffline();
    await seed('journal_entries', fields: {'content': 'Local journal'});
    await user.leaveOfflineMode(importLocalData: true);
    expect(user.canUseApp, isFalse);
    expect(user.hasSeenKaiValueDemo, isTrue);
    expect(user.hasPendingLocalImport, isTrue);
    await user.continueOffline();
    expect(user.isOffline, isTrue);
    expect(prefs.getString(OfflineAccountImport.jobKey), isNull);
    expect(prefs.getString('kaibigan_local_journal_entries_guest'),
        contains('Local journal'));
  });
}
