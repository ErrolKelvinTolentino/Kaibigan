import 'package:flutter_test/flutter_test.dart';

import '../tool/seed_demo_account.dart';

void main() {
  test('demo seed covers every synced product surface', () {
    final manifest = DemoSeedManifest.preview(DateTime(2026, 9, 1, 12));

    expect(manifest.profile['display_name'], 'Mika (Demo)');
    expect(manifest.moods, hasLength(14));
    expect(manifest.journals, hasLength(6));
    expect(manifest.gratitude, hasLength(10));
    expect(manifest.letters, hasLength(3));
    expect(manifest.routines, hasLength(21));
    expect(manifest.memories, hasLength(4));
    expect(
      manifest.gratitude.map((entry) => entry['plot_index']).toSet(),
      Set<int>.from(List.generate(10, (index) => index)),
    );

    final ids = [
      ...manifest.moods,
      ...manifest.journals,
      ...manifest.gratitude,
      ...manifest.letters,
      ...manifest.routines,
      ...manifest.memories,
    ].map((entry) => entry['id'] as String).toList(growable: false);
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-8[0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(ids, hasLength(58));
    expect(ids.toSet(), hasLength(58));
    expect(ids.every(uuid.hasMatch), isTrue);
  });

  test('safety demo is non-graphic and includes escalation plus follow-up', () {
    final manifest = DemoSeedManifest.preview(DateTime(2026, 9, 1, 12));
    final safety = manifest.journals.singleWhere(
      (entry) => entry['title'] == 'Demo • Safety check-in',
    );
    final safetyPlan = manifest.journals.singleWhere(
      (entry) => entry['title'] == 'My support plan for hard nights',
    );
    final response = safety['ai_response'] as String;

    expect(response, contains('NCMH Crisis Hotline at 1553'));
    expect(response, contains('call 911'));
    expect(
        safety['conversation_turns'].toString(), contains('I called Ate Bea'));
    expect(safetyPlan['ai_response'], contains('warning signs'));
  });

  test('SQL export targets the existing auth user and includes all tables', () {
    final manifest = DemoSeedManifest.preview(DateTime(2026, 9, 1, 12));
    final sql = manifest.toSupabaseSql(email: 'demo@example.com');

    expect(sql, contains('FROM auth.users'));
    expect(sql, contains("lower(email) = lower('demo@example.com')"));
    expect(sql, contains('INSERT INTO public.profiles'));
    expect(sql, contains('INSERT INTO public.mood_logs'));
    expect(sql, contains('INSERT INTO public.journal_entries'));
    expect(sql, contains('INSERT INTO public.gratitude_entries'));
    expect(sql, contains('INSERT INTO public.future_letters'));
    expect(sql, contains('INSERT INTO public.routine_logs'));
    expect(sql, contains('INSERT INTO public.user_memories'));
    expect(sql, contains('NCMH Crisis Hotline at 1553'));
    expect(sql, contains('ON CONFLICT (id) DO UPDATE'));
    expect(sql, contains('conversation_turns'));
    expect(sql, contains('::jsonb'));
    expect(sql, isNot(contains('reflection_seed_stage')));
    expect(sql, isNot(contains('water_count')));
  });
}
