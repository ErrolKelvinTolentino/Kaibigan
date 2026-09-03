// Run: node database/tests/validate_schema.mjs <path-to-pglite-dist-index.js>
// Uses an isolated in-memory PostgreSQL engine, never the live Supabase project.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const { PGlite } = await import(pathToFileURL(path.resolve(process.argv[2])).href);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const read = name => readFile(path.join(root, name), 'utf8');
const migration = await read('supabase/migrations/20260903010000_align_active_features.sql');
const statsMigration = await read('supabase/migrations/20260903020000_user_activity_stats.sql');
const fresh = await read('database/supabase_setup.sql');
const oldFiles = [
  '20260821010000_kaibigan_schema_and_rls.sql',
  '20260825090000_gratitude_garden_plots.sql',
  '20260825110000_remove_gratitude_growth_stage.sql',
  '20260827010000_expand_gratitude_garden_capacity.sql',
];
const a = '00000000-0000-4000-8000-000000000001';
const b = '00000000-0000-4000-8000-000000000002';
const noteId = '00000000-0000-4000-8000-000000000003';
const rawReply = '__KAIBIGAN_TURNS_V1__' + JSON.stringify([
  { user: 'My original note', assistant: 'A saved reply', companion: 'kai' },
]);

async function database(legacy = false) {
  const db = new PGlite();
  await db.exec(`
    CREATE ROLE anon;
    CREATE ROLE authenticated;
    CREATE ROLE service_role BYPASSRLS;
    CREATE SCHEMA auth;
    CREATE TABLE auth.users (id UUID PRIMARY KEY);
    CREATE FUNCTION auth.uid() RETURNS UUID LANGUAGE SQL STABLE AS
      $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::UUID $$;
    GRANT USAGE ON SCHEMA public, auth TO authenticated, anon, service_role;
    INSERT INTO auth.users VALUES ('${a}'), ('${b}');
  `);
  if (legacy) {
    for (const file of oldFiles) {
      // Historical optional extension is unused; gen_random_uuid is built in.
      const sql = (await read('supabase/migrations/' + file))
        .replace('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";', '');
      await db.exec(sql);
    }
  } else {
    await db.exec(fresh);
  }
  await db.query(`INSERT INTO public.profiles (id, email) VALUES ($1, 'a@example.test'), ($2, 'b@example.test')`, [a, b]);
  return db;
}

async function seed(db) {
  await db.query(`INSERT INTO public.journal_entries (id, user_id, title, content, ai_response)
    VALUES ($1, $2, 'Existing journal', 'My original note', $3)`, [noteId, a, rawReply]);
  await db.query(`INSERT INTO public.gratitude_entries (user_id, content, water_count)
    VALUES ($1, 'A real gratitude memory', 9)`, [a]);
  await db.query(`INSERT INTO public.mood_logs (user_id, mood_score, mood_label)
    VALUES ($1, 3, 'Okay')`, [a]);
}

async function signature(db) {
  return (await db.query(`SELECT table_name, column_name, data_type, is_nullable, column_default
    FROM information_schema.columns WHERE table_schema = 'public'
    ORDER BY table_name, ordinal_position`)).rows
    .sort((x, y) => (x.table_name + x.column_name).localeCompare(y.table_name + y.column_name));
}

const db = await database(true);
await seed(db);
await db.exec(migration);
await db.exec(migration); // Safe rerun, including policy/trigger replacement.
await db.exec(statsMigration);
await db.exec(statsMigration); // Safe rerun
const tables = (await db.query(`SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename`)).rows.map(r => r.tablename);
assert.deepEqual(tables, ['future_letters', 'gratitude_entries', 'journal_entries', 'learning_progress', 'mood_logs', 'profiles', 'routine_logs', 'user_activity_stats', 'user_memories']);
const journal = (await db.query('SELECT * FROM public.journal_entries WHERE id = $1', [noteId])).rows[0];
assert.equal(journal.content, 'My original note');
assert.equal(journal.ai_response, rawReply);
assert.equal(journal.conversation_turns[0].assistant, 'A saved reply');
assert.equal('reflection_seed_stage' in journal, false);
const flower = (await db.query('SELECT * FROM public.gratitude_entries')).rows[0];
assert.equal(flower.content, 'A real gratitude memory');
assert.equal('water_count' in flower, false);
assert.equal(flower.plot_index, 0);
assert.equal((await db.query(`SELECT count(*)::INT n FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity`)).rows[0].n, 9);

const empty = await database();
assert.deepEqual(await signature(db), await signature(empty), 'fresh and upgraded column contracts must match');
await empty.close();
console.log('PASS: fresh schema, migration, rerun, and preserved journal/gratitude data');

await db.exec(`SET ROLE authenticated; SELECT set_config('request.jwt.claim.sub', '${a}', false);`);
await db.query(`INSERT INTO public.learning_progress(user_id, lesson_id, completed, viewed_ideas)
  VALUES ($1, 'sleep-and-mind', TRUE, ARRAY[0,1])`, [a]);
await db.query(`INSERT INTO public.user_activity_stats(user_id, login_dates, activity_counts)
  VALUES ($1, ARRAY['2026-09-03'], '{"mood": 5}'::jsonb)`, [a]);
await assert.rejects(db.query(`INSERT INTO public.user_activity_stats(user_id) VALUES ($1)`, [b]), /row-level security/);
await assert.rejects(db.query(`INSERT INTO public.learning_progress(user_id, lesson_id) VALUES ($1, 'wrong-owner')`, [b]), /row-level security/);
await assert.rejects(db.query(`INSERT INTO public.mood_logs(user_id, mood_score, mood_label) VALUES ($1, 6, 'Invalid')`, [a]), /check constraint/);
await db.exec(`SELECT set_config('request.jwt.claim.sub', '${b}', false);`);
assert.equal((await db.query('SELECT * FROM public.journal_entries')).rows.length, 0);
assert.equal((await db.query('SELECT * FROM public.learning_progress')).rows.length, 0);
assert.equal((await db.query('SELECT * FROM public.user_activity_stats')).rows.length, 0);
await db.exec('RESET ROLE; SET ROLE anon;');
await assert.rejects(db.query('SELECT * FROM public.learning_progress'), /permission denied/);
await assert.rejects(db.query('SELECT * FROM public.user_activity_stats'), /permission denied/);
await db.exec('RESET ROLE;');
await db.query(`UPDATE public.profiles SET display_name = 'Changed', updated_at = '2000-01-01' WHERE id = $1`, [a]);
assert.notEqual(String((await db.query('SELECT updated_at FROM public.profiles WHERE id = $1', [a])).rows[0].updated_at).slice(0, 4), '2000');
await db.query('DELETE FROM auth.users WHERE id = $1', [a]);
for (const table of ['profiles', 'journal_entries', 'gratitude_entries', 'mood_logs', 'learning_progress', 'user_activity_stats']) {
  const ownerColumn = table === 'profiles' ? 'id' : 'user_id';
  assert.equal((await db.query(`SELECT * FROM public.${table} WHERE ${ownerColumn} = $1`, [a])).rows.length, 0);
}
await db.close();
console.log('PASS: owner RLS, anonymous denial, score checks, timestamps, account deletion cascade');

async function guard(name, mutate, expectedError, verify) {
  const guarded = await database(true);
  await seed(guarded);
  await mutate(guarded);
  await assert.rejects(guarded.exec(migration), expectedError);
  await guarded.exec('ROLLBACK;');
  await verify(guarded);
  const preserved = (await guarded.query('SELECT water_count FROM public.gratitude_entries LIMIT 1')).rows[0];
  assert.equal(preserved.water_count, 9, 'failed migration must roll back column removal');
  await guarded.close();
  console.log('PASS: ' + name);
}

await guard('nonempty daily goals block deletion', db => db.query(`INSERT INTO public.daily_goals(user_id, goal_type, title) VALUES ($1, 'custom', 'Keep me')`, [a]), /saved rows require review/, async db => {
  assert.equal((await db.query('SELECT title FROM public.daily_goals')).rows[0].title, 'Keep me');
});
await guard('nonempty routine configurations block deletion', db => db.query(`INSERT INTO public.routine_configs(id, user_id, title, subtitle, routine_type, reminder_time) VALUES ('custom', $1, 'Keep routine', '', 'custom', '09:00')`, [a]), /saved rows require review/, async db => {
  assert.equal((await db.query('SELECT title FROM public.routine_configs')).rows[0].title, 'Keep routine');
});
await guard('unowned journal blocks reassignment/deletion', db => db.query(`UPDATE public.journal_entries SET user_id = NULL WHERE id = $1`, [noteId]), /Ownership repair required/, async db => {
  assert.equal((await db.query('SELECT content FROM public.journal_entries')).rows[0].content, 'My original note');
});
await guard('malformed legacy response remains intact', db => db.query(`UPDATE public.journal_entries SET ai_response = '__KAIBIGAN_TURNS_V1__bad' WHERE id = $1`, [noteId]), /invalid legacy conversation/, async db => {
  assert.equal((await db.query('SELECT ai_response FROM public.journal_entries')).rows[0].ai_response, '__KAIBIGAN_TURNS_V1__bad');
});
await guard('out-of-range garden slot is not silently moved', db => db.query(`UPDATE public.gratitude_entries SET plot_index = 14`), /check constraint/, async db => {
  assert.equal((await db.query('SELECT plot_index FROM public.gratitude_entries')).rows[0].plot_index, 14);
});
console.log('All isolated PostgreSQL validation checks passed. Live Supabase was not accessed.');
