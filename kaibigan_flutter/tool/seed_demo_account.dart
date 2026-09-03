import 'dart:convert';
import 'dart:io';

import 'package:kaibigan_flutter/core/utils/env_config.dart';
import 'package:supabase/supabase.dart';

/// Creates a presentation-ready Kaibigan account using clearly fictional data.
///
/// The script is intentionally preview-only unless `--apply` is supplied. It
/// never deletes existing records and uses stable per-user IDs, making retries
/// safe. Run `dart run tool/seed_demo_account.dart` to inspect the manifest.
Future<void> main(List<String> arguments) async {
  final options = _SeedOptions.parse(arguments);
  final preview = DemoSeedManifest.preview(DateTime.now());

  if (options.emitSql) {
    if (options.email == null) {
      stderr.writeln('SQL mode requires --email=<existing auth email>.');
      exitCode = 64;
      return;
    }
    stdout.write(preview.toSupabaseSql(email: options.email!));
    return;
  }

  if (!options.apply) {
    _printPreview(preview);
    return;
  }

  if (options.email == null || options.password == null) {
    stderr.writeln(
      'Apply mode requires --email=<demo email> and --password=<password>.',
    );
    exitCode = 64;
    return;
  }

  final client = SupabaseClient(
    Platform.environment['SUPABASE_URL'] ?? EnvConfig.supabaseUrl,
    Platform.environment['SUPABASE_ANON_KEY'] ?? EnvConfig.supabaseAnonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  try {
    AuthResponse auth;
    if (options.createAccount) {
      auth = await client.auth.signUp(
        email: options.email!,
        password: options.password!,
        data: const {
          'display_name': 'Mika (Demo)',
          'kaibigan_demo_account': true,
        },
      );
      if (auth.session == null) {
        stdout.writeln(
          'The account was created, but email confirmation is required. '
          'Confirm it, then rerun with --apply without --create-account.',
        );
        return;
      }
    } else {
      auth = await client.auth.signInWithPassword(
        email: options.email!,
        password: options.password!,
      );
    }

    final user = auth.user ?? client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication succeeded without a user record.');
    }

    final manifest = DemoSeedManifest.forUser(
      userId: user.id,
      email: options.email!,
      now: DateTime.now(),
    );
    await manifest.apply(client);
    stdout.writeln('Demo account seeded successfully.');
    _printPreview(manifest);
  } finally {
    await client.auth.signOut();
    client.dispose();
  }
}

class _SeedOptions {
  const _SeedOptions({
    required this.apply,
    required this.createAccount,
    required this.emitSql,
    this.email,
    this.password,
  });

  final bool apply;
  final bool createAccount;
  final bool emitSql;
  final String? email;
  final String? password;

  factory _SeedOptions.parse(List<String> arguments) {
    String? valueFor(String name) {
      final prefix = '--$name=';
      for (final argument in arguments) {
        if (argument.startsWith(prefix)) {
          return argument.substring(prefix.length);
        }
      }
      return null;
    }

    return _SeedOptions(
      apply: arguments.contains('--apply'),
      createAccount: arguments.contains('--create-account'),
      emitSql: arguments.contains('--emit-sql'),
      email: valueFor('email'),
      password: valueFor('password'),
    );
  }
}

class DemoSeedManifest {
  DemoSeedManifest({
    required this.profile,
    required this.moods,
    required this.journals,
    required this.gratitude,
    required this.letters,
    required this.routines,
    required this.memories,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> moods;
  final List<Map<String, dynamic>> journals;
  final List<Map<String, dynamic>> gratitude;
  final List<Map<String, dynamic>> letters;
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> memories;

  factory DemoSeedManifest.preview(DateTime now) => DemoSeedManifest.forUser(
        userId: '00000000-0000-4000-8000-000000000000',
        email: 'demo@example.com',
        now: now,
      );

  factory DemoSeedManifest.forUser({
    required String userId,
    required String email,
    required DateTime now,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    String id(String group, int index) => _stableUuid(userId, group, index);
    DateTime ago(int days, [int hour = 20]) =>
        day.subtract(Duration(days: days)).add(Duration(hours: hour));

    const moodScores = [4, 3, 2, 2, 3, 4, 3, 1, 2, 3, 4, 4, 3, 4];
    const stressScores = [2, 3, 4, 5, 3, 2, 3, 5, 4, 3, 2, 2, 3, 2];
    const energyScores = [4, 3, 2, 2, 3, 4, 3, 1, 2, 3, 4, 4, 3, 4];
    const sleepScores = [4, 3, 2, 2, 3, 4, 3, 1, 2, 3, 4, 5, 3, 4];
    const anxietyScores = [2, 3, 4, 5, 3, 2, 3, 5, 4, 3, 2, 2, 3, 2];
    const moodNotes = [
      'A calmer morning after planning only three priorities.',
      'Busy but manageable. Took a short walk before lunch.',
      'Presentation nerves and low sleep.',
      'Everything felt urgent. Asked a teammate for help.',
      'Still tired, but the breathing reset helped.',
      'Dinner with family felt grounding.',
      'A neutral day with a few quiet wins.',
      'Felt unsafe and reached out to Ate Bea instead of staying alone.',
      'Recovering slowly. Kept the evening simple.',
      'Had more room to think after resting.',
      'Finished one important task without rushing.',
      'A genuinely light day with good sleep.',
      'Some worry, but I used my support plan early.',
      'Steady, rested, and hopeful about the week.',
    ];
    final moods = List.generate(moodScores.length, (index) {
      final score = moodScores[index];
      return {
        'id': id('mood', index),
        'user_id': userId,
        'mood_score': score,
        'mood_label': ['Struggling', 'Low', 'Okay', 'Good', 'Great'][score - 1],
        'stress_level': stressScores[index],
        'energy_level': energyScores[index],
        'sleep_quality': sleepScores[index],
        'anxiety_level': anxietyScores[index],
        'note': moodNotes[index],
        'created_at': ago(13 - index, 9).toIso8601String(),
      };
    });

    Map<String, dynamic> journal({
      required int index,
      required int daysAgo,
      required String title,
      required String mood,
      required List<Map<String, String>> turns,
      required List<String> tags,
      bool favorite = false,
    }) =>
        {
          'id': id('journal', index),
          'user_id': userId,
          'title': title,
          'content': turns.map((turn) => turn['user']).join('\n\n'),
          'ai_response':
              turns.map((turn) => turn['assistant']).join('\n\n---\n\n'),
          'conversation_turns': turns,
          'companion_id': 'kai',
          'mood': mood,
          'reflection_mode': 'auto',
          'tags': tags,
          'is_favorite': favorite,
          'created_at': ago(daysAgo).toIso8601String(),
        };

    final journals = [
      journal(
        index: 0,
        daysAgo: 12,
        title: 'Too many tabs open in my head',
        mood: 'Overwhelmed',
        tags: const ['Work', 'Overwhelm', 'Demo'],
        turns: const [
          {
            'user': 'Everything feels urgent and I keep switching tasks.',
            'assistant':
                'That sounds exhausting—your attention has not had anywhere to land. Which single task would make the rest feel a little less noisy?',
            'companion': 'kai',
          },
          {
            'user':
                'Sending the project outline. It does not need to be perfect.',
            'assistant':
                'That is a clear and kind next step. A useful goal could be: send the honest first draft, then pause before choosing anything else.',
            'companion': 'kai',
          },
        ],
      ),
      journal(
        index: 1,
        daysAgo: 9,
        title: 'The walk helped more than I expected',
        mood: 'Calmer',
        tags: const ['Coping', 'Movement', 'Demo'],
        favorite: true,
        turns: const [
          {
            'user':
                'I walked around the block without my phone and my chest finally loosened.',
            'assistant':
                'Your body found a little room before your thoughts did. That short phone-free walk sounds worth keeping as a reliable reset.',
            'companion': 'kai',
          },
        ],
      ),
      journal(
        index: 2,
        daysAgo: 7,
        title: 'Demo • Safety check-in',
        mood: 'Struggling',
        tags: const ['Demo', 'Safety', 'Support'],
        favorite: true,
        turns: const [
          {
            'user':
                'Tonight I had thoughts about hurting myself. I am not in immediate danger, but I need support and I do not want to be alone.',
            'assistant':
                'I am really glad you told me. Your safety comes first, and you deserve support from a real person right now. Can you contact someone you trust and move away from anything you could use to hurt yourself? If you may act on these thoughts or cannot stay safe, call 911, contact the NCMH Crisis Hotline at 1553, or go to the nearest emergency room.',
            'companion': 'kai',
          },
          {
            'user':
                'I called Ate Bea. She is coming over, and I moved to the living room where my family is.',
            'assistant':
                'You took two important safety steps: you reached someone you trust and moved where you are not alone. Stay with them and let them know clearly what you need tonight. We can keep the next few minutes simple while help is with you.',
            'companion': 'kai',
          },
        ],
      ),
      journal(
        index: 3,
        daysAgo: 6,
        title: 'My support plan for hard nights',
        mood: 'Tender',
        tags: const ['Demo', 'Safety plan', 'Coping'],
        favorite: true,
        turns: const [
          {
            'user':
                'My early signs are isolating, skipping dinner, and thinking everyone would be better without me. I will call Ate Bea, stay in a shared room, and contact 1553 or emergency services if I cannot stay safe.',
            'assistant':
                'This plan is specific and easy to find when thinking is hard. Your warning signs, trusted person, safer place, and crisis options are all clear. Consider sharing this plan with Ate Bea so you do not have to explain everything alone in a crisis.',
            'companion': 'kai',
          },
        ],
      ),
      journal(
        index: 4,
        daysAgo: 3,
        title: 'A boundary I am proud of',
        mood: 'Proud',
        tags: const ['Growth', 'Boundaries', 'Demo'],
        turns: const [
          {
            'user':
                'I said I could deliver Friday instead of pretending I could finish tonight.',
            'assistant':
                'That was not letting anyone down—it was giving an honest answer before exhaustion made the decision for you.',
            'companion': 'kai',
          },
        ],
      ),
      journal(
        index: 5,
        daysAgo: 0,
        title: 'What I want to remember this week',
        mood: 'Hopeful',
        tags: const ['Weekly reflection', 'Growth', 'Demo'],
        favorite: true,
        turns: const [
          {
            'user':
                'The week was uneven, but reaching out early, sleeping better, and choosing one task at a time actually changed things.',
            'assistant':
                'A pattern is becoming visible: support works best when you use it before the pressure peaks. You are not waiting to earn care anymore.',
            'companion': 'kai',
          },
        ],
      ),
    ];

    const gratitudeCopy = [
      'Ate Bea answering the phone without hesitation.',
      'Warm pandesal and coffee before a busy morning.',
      'The teammate who helped me simplify the outline.',
      'A ten-minute walk with no notifications.',
      'My body telling me when it needed rest.',
      'Dinner laughter that made the room feel lighter.',
      'Finishing one honest draft instead of chasing perfect.',
      'Rain against the window while I stayed inside.',
      'Having a safety plan I can actually follow.',
      'Waking up with enough energy to begin again.',
    ];
    const flowers = [
      'sunflower',
      'anemone',
      'bluebell',
      'lavender',
      'rose',
      'geranium',
      'lily',
      'purple_aster',
      'ranunculus',
      'chrysanthemum',
    ];
    final gratitude = List.generate(
        gratitudeCopy.length,
        (index) => {
              'id': id('gratitude', index),
              'user_id': userId,
              'content': gratitudeCopy[index],
              'flower_type': flowers[index],
              'garden_index': 0,
              'plot_index': index,
              'created_at': ago(9 - index, 18).toIso8601String(),
            });

    final letters = [
      {
        'id': id('letter', 0),
        'user_id': userId,
        'title': 'For the day you forget your progress',
        'content':
            'You learned to ask for help before everything became unbearable. That counts, even on the days it feels small.',
        'deliver_at': ago(1, 8).toIso8601String(),
        'is_opened': false,
        'created_at': ago(30).toIso8601String(),
      },
      {
        'id': id('letter', 1),
        'user_id': userId,
        'title': 'A note from last month',
        'content':
            'I hope you are still protecting the quiet parts of your morning.',
        'deliver_at': ago(4, 8).toIso8601String(),
        'is_opened': true,
        'created_at': ago(35).toIso8601String(),
      },
      {
        'id': id('letter', 2),
        'user_id': userId,
        'title': 'Open after the next brave step',
        'content':
            'Whatever happened, remember that courage can look like a boundary, a phone call, or simply staying.',
        'deliver_at':
            day.add(const Duration(days: 21, hours: 8)).toIso8601String(),
        'is_opened': false,
        'created_at': ago(2).toIso8601String(),
      },
    ];

    const sleepFeelings = [
      'wellRested',
      'moderate',
      'groggy',
      'restless',
      'moderate',
      'wellRested',
      'moderate',
      'restless',
      'groggy',
      'moderate',
      'wellRested',
      'energized',
      'moderate',
      'wellRested',
    ];
    final routines = <Map<String, dynamic>>[
      for (var index = 0; index < sleepFeelings.length; index++)
        {
          'id': id('sleep', index),
          'user_id': userId,
          'routine_id': 'sleep_demo_${13 - index}',
          'routine_type': 'night',
          'sleep_feeling': sleepFeelings[index],
          'focus_or_highlight': null,
          'mood_score': null,
          'mood_note': null,
          'gratitude_content': null,
          'completed_at': ago(13 - index, 7).toIso8601String(),
        },
      for (var index = 0; index < 6; index++)
        {
          'id': id('routine', index),
          'user_id': userId,
          'routine_id': ['morning', 'midday', 'night'][index % 3],
          'routine_type': ['morning', 'midday', 'night'][index % 3],
          'sleep_feeling': null,
          'focus_or_highlight': index.isEven
              ? 'One clear priority and a softer pace.'
              : 'A quiet meal, an honest message, and enough rest.',
          'mood_score': 3 + (index % 2),
          'mood_note':
              'Completed the routine without trying to do it perfectly.',
          'gratitude_content':
              index % 3 == 1 ? 'Someone made the day feel less lonely.' : null,
          'completed_at':
              ago(5 - index, index % 3 == 0 ? 8 : 20).toIso8601String(),
        },
      {
        'id': id('highlight', 0),
        'user_id': userId,
        'routine_id': 'highlight_demo_today',
        'routine_type': 'night',
        'sleep_feeling': null,
        'focus_or_highlight': 'I asked for help before I was overwhelmed.',
        'mood_score': null,
        'mood_note': null,
        'gratitude_content': null,
        'completed_at': ago(0, 19).toIso8601String(),
      },
    ];

    final memories = [
      (
        'coping_strategy',
        'Short phone-free walks often help create mental space.',
        8
      ),
      (
        'support',
        'Ate Bea is a trusted support person for difficult evenings.',
        10
      ),
      (
        'trigger',
        'Pressure rises when several work tasks feel equally urgent.',
        7
      ),
      (
        'milestone',
        'Recently practiced asking for help and setting realistic deadlines.',
        8
      ),
    ].indexed.map((item) {
      final (index, value) = item;
      return {
        'id': id('memory', index),
        'user_id': userId,
        'memory_category': value.$1,
        'memory_summary': value.$2,
        'relevance_score': value.$3,
        'created_at': ago(5 - index).toIso8601String(),
      };
    }).toList(growable: false);

    return DemoSeedManifest(
      profile: {
        'id': userId,
        'email': email.toLowerCase(),
        'display_name': 'Mika (Demo)',
        'preferred_mascot_id': 'kai',
        'preferred_language': 'taglish',
        'updated_at': now.toIso8601String(),
      },
      moods: moods,
      journals: journals,
      gratitude: gratitude,
      letters: letters,
      routines: routines,
      memories: memories,
    );
  }

  Future<void> apply(SupabaseClient client) async {
    await client.from('profiles').upsert(profile, onConflict: 'id');
    await _upsert(client, 'mood_logs', moods);
    await _upsert(client, 'journal_entries', journals);
    await _upsert(client, 'gratitude_entries', gratitude);
    await _upsert(client, 'future_letters', letters);
    await _upsert(client, 'routine_logs', routines);
    await _upsert(client, 'user_memories', memories);
  }

  String toSupabaseSql({required String email}) {
    final buffer = StringBuffer()
      ..writeln('-- Kaibigan fictional demo account seed')
      ..writeln('-- Idempotent: safe to rerun for the same auth user.')
      ..writeln('DO \$kaibigan\$')
      ..writeln('DECLARE')
      ..writeln('  demo_user_id uuid;')
      ..writeln('BEGIN')
      ..writeln('  SELECT id INTO demo_user_id')
      ..writeln('  FROM auth.users')
      ..writeln('  WHERE lower(email) = lower(${_sqlValue(email)})')
      ..writeln('  ORDER BY created_at DESC')
      ..writeln('  LIMIT 1;')
      ..writeln()
      ..writeln('  IF demo_user_id IS NULL THEN')
      ..writeln(
        "    RAISE EXCEPTION 'No Supabase auth user found for %', ${_sqlValue(email)};",
      )
      ..writeln('  END IF;')
      ..writeln();

    _writeSqlUpsert(
      buffer,
      table: 'profiles',
      rows: [
        {
          ...profile,
          'email': email.toLowerCase(),
        },
      ],
      userIdColumns: const {'id'},
    );
    _writeSqlUpsert(buffer, table: 'mood_logs', rows: moods);
    _writeSqlUpsert(buffer, table: 'journal_entries', rows: journals);
    _writeSqlUpsert(buffer, table: 'gratitude_entries', rows: gratitude);
    _writeSqlUpsert(buffer, table: 'future_letters', rows: letters);
    _writeSqlUpsert(buffer, table: 'routine_logs', rows: routines);
    _writeSqlUpsert(buffer, table: 'user_memories', rows: memories);

    buffer
      ..writeln(
        "  RAISE NOTICE 'Kaibigan demo seed complete: 58 records for %', ${_sqlValue(email)};",
      )
      ..writeln('END')
      ..writeln('\$kaibigan\$;');
    return buffer.toString();
  }

  void _writeSqlUpsert(
    StringBuffer buffer, {
    required String table,
    required List<Map<String, dynamic>> rows,
    Set<String> userIdColumns = const {'user_id'},
  }) {
    if (rows.isEmpty) return;
    final columns = rows.first.keys.toList(growable: false);
    final updates = columns
        .where((column) => column != 'id')
        .map((column) => '$column = EXCLUDED.$column')
        .join(', ');
    buffer
      ..writeln('  INSERT INTO public.$table (${columns.join(', ')})')
      ..writeln('  VALUES');
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final values = columns.map((column) {
        if (userIdColumns.contains(column)) return 'demo_user_id';
        if (column == 'conversation_turns') {
          return '${_sqlValue(jsonEncode(row[column]))}::jsonb';
        }
        return _sqlValue(row[column]);
      }).join(', ');
      buffer.writeln('    ($values)${index == rows.length - 1 ? '' : ','}');
    }
    buffer
      ..writeln('  ON CONFLICT (id) DO UPDATE SET $updates;')
      ..writeln();
  }

  Future<void> _upsert(
    SupabaseClient client,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await client.from(table).upsert(rows, onConflict: 'id');
  }
}

String _sqlValue(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'TRUE' : 'FALSE';
  if (value is num) return value.toString();
  if (value is List) {
    if (value.isEmpty) return 'ARRAY[]::text[]';
    return 'ARRAY[${value.map(_sqlValue).join(', ')}]::text[]';
  }
  return "'${value.toString().replaceAll("'", "''")}'";
}

String _stableUuid(String userId, String group, int index) {
  const mask = 0xffffffff;
  int hash32(String value, int seed) {
    var result = seed;
    for (final unit in value.codeUnits) {
      result ^= unit;
      result = (result * 0x01000193) & mask;
    }
    return result;
  }

  final cleanUserId = userId.replaceAll('-', '').padLeft(32, '0');
  final source = '$cleanUserId:$group:$index';
  final suffix = hash32(source, 0x811c9dc5).toRadixString(16).padLeft(8, '0');
  final raw = '${cleanUserId.substring(0, 24)}$suffix';
  final chars = raw.substring(0, 32).split('');
  chars[12] = '4';
  chars[16] = '8';
  final value = chars.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

void _printPreview(DemoSeedManifest manifest) {
  stdout.writeln('Kaibigan demo seed manifest (fictional data only)');
  stdout.writeln('  Profile: 1 — Mika (Demo), Kai, Taglish');
  stdout.writeln('  Mood check-ins: ${manifest.moods.length}');
  stdout.writeln('  Kai journal conversations: ${manifest.journals.length}');
  stdout.writeln(
      '  Gratitude flowers: ${manifest.gratitude.length} (one full garden)');
  stdout.writeln('  Future letters: ${manifest.letters.length}');
  stdout.writeln('  Routine and sleep logs: ${manifest.routines.length}');
  stdout.writeln('  AI memory themes: ${manifest.memories.length}');
  stdout.writeln(
    '  Safety content: one non-graphic self-harm disclosure, crisis resources, '
    'trusted-person follow-up, and a practical support plan.',
  );
  stdout.writeln('No records were written in preview mode.');
}
