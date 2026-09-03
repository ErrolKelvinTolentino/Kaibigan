-- Align the live app contract. Back up first; retire old app builds before
-- deployment. This transaction aborts instead of deleting personal records.
-- Run once in Supabase SQL Editor, or through the normal migration workflow.
BEGIN;

-- These tables have no readers/writers in the current app. Only drop EMPTY
-- tables; if a prior version stored data, export/review it before proceeding.
DO $$
DECLARE retired_table TEXT;
        has_records BOOLEAN;
BEGIN
    FOREACH retired_table IN ARRAY ARRAY['daily_goals', 'routine_configs']
    LOOP
        IF to_regclass('public.' || retired_table) IS NOT NULL THEN
            EXECUTE format('LOCK TABLE public.%I IN ACCESS EXCLUSIVE MODE', retired_table);
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I)', retired_table)
                INTO has_records;
            IF has_records THEN
                RAISE EXCEPTION 'Refusing to drop public.%: saved rows require review/export first.', retired_table;
            END IF;
            EXECUTE format('DROP TABLE public.%I', retired_table);
        END IF;
    END LOOP;
END;
$$;

-- Make ownership mandatory. Missing/orphaned owners require review, never a
-- DELETE or reassignment to the currently signed-in user.
DO $$
DECLARE app_table TEXT;
        has_orphans BOOLEAN;
BEGIN
    FOREACH app_table IN ARRAY ARRAY[
        'journal_entries', 'gratitude_entries', 'mood_logs',
        'future_letters', 'routine_logs', 'user_memories'
    ]
    LOOP
        EXECUTE format('LOCK TABLE public.%I IN ACCESS EXCLUSIVE MODE', app_table);
        EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I child
            LEFT JOIN public.profiles p ON p.id = child.user_id
            WHERE child.user_id IS NULL OR p.id IS NULL)', app_table)
            INTO has_orphans;
        IF has_orphans THEN
            RAISE EXCEPTION 'Ownership repair required in public.% before migration.', app_table;
        END IF;
        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN user_id SET NOT NULL', app_table);
        EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I', app_table, app_table || '_user_id_fkey');
        EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I
            FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE',
            app_table, app_table || '_user_id_fkey');
    END LOOP;
END;
$$;

ALTER TABLE public.profiles ALTER COLUMN id SET DEFAULT auth.uid();
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
-- Validation fails safely if a profile is not backed by a Supabase auth user.
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Obsolete mechanics only: no notes, flowers, or replies are deleted.
ALTER TABLE public.gratitude_entries
    DROP COLUMN IF EXISTS water_count,
    DROP COLUMN IF EXISTS growth_stage;
ALTER TABLE public.journal_entries DROP COLUMN IF EXISTS reflection_seed_stage;
ALTER TABLE public.gratitude_entries ALTER COLUMN flower_type SET DEFAULT 'anemone';
ALTER TABLE public.journal_entries ALTER COLUMN reflection_mode SET DEFAULT 'auto';
ALTER TABLE public.journal_entries ALTER COLUMN mood SET DEFAULT '';

-- Current GardenLayout has 10 slots. If an older build really used slots
-- 10..14, validation aborts so their placement can be reviewed, not overwritten.
ALTER TABLE public.gratitude_entries
    DROP CONSTRAINT IF EXISTS gratitude_entries_plot_index_check;
ALTER TABLE public.gratitude_entries
    ADD CONSTRAINT gratitude_entries_plot_index_check CHECK (plot_index >= 0 AND plot_index < 10);
-- Older bootstrap scripts created this duplicate of the named unique index.
ALTER TABLE public.gratitude_entries
    DROP CONSTRAINT IF EXISTS gratitude_entries_user_id_garden_index_plot_index_key;

ALTER TABLE public.journal_entries
    ADD COLUMN IF NOT EXISTS conversation_turns JSONB NOT NULL DEFAULT '[]'::JSONB;
ALTER TABLE public.journal_entries
    DROP CONSTRAINT IF EXISTS journal_entries_conversation_turns_check;
ALTER TABLE public.journal_entries
    ADD CONSTRAINT journal_entries_conversation_turns_check
        CHECK (jsonb_typeof(conversation_turns) = 'array');

-- Copy legacy encoded turns into their own field. Keep original ai_response
-- intact so there is no destructive rewrite of an existing conversation.
DO $$
DECLARE legacy RECORD;
        turns JSONB;
BEGIN
    FOR legacy IN
        SELECT id, ai_response FROM public.journal_entries
        WHERE starts_with(ai_response, '__KAIBIGAN_TURNS_V1__')
          AND conversation_turns = '[]'::JSONB
    LOOP
        BEGIN
            turns := substring(legacy.ai_response FROM length('__KAIBIGAN_TURNS_V1__') + 1)::JSONB;
            IF jsonb_typeof(turns) <> 'array' THEN
                RAISE EXCEPTION 'Expected an array';
            END IF;
            IF EXISTS (
                SELECT 1 FROM jsonb_array_elements(turns) AS turn(value)
                WHERE jsonb_typeof(value) <> 'object'
                   OR (value ? 'user' AND jsonb_typeof(value->'user') NOT IN ('string', 'null'))
                   OR (value ? 'assistant' AND jsonb_typeof(value->'assistant') NOT IN ('string', 'null'))
                   OR (value ? 'companion' AND jsonb_typeof(value->'companion') NOT IN ('string', 'null'))
            ) THEN
                RAISE EXCEPTION 'Invalid conversation turn';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Journal % has an invalid legacy conversation. Original preserved; review before retrying.', legacy.id;
        END;
        UPDATE public.journal_entries SET conversation_turns = turns WHERE id = legacy.id;
    END LOOP;
END;
$$;

-- Range validation fails safely if old data needs repair. Never clamp or
-- fabricate a user's recorded mood/sleep/anxiety scores.
DO $$
DECLARE score_column TEXT;
BEGIN
    FOREACH score_column IN ARRAY ARRAY[
        'mood_score', 'stress_level', 'energy_level', 'sleep_quality', 'anxiety_level'
    ]
    LOOP
        EXECUTE format('ALTER TABLE public.mood_logs DROP CONSTRAINT IF EXISTS %I',
            'mood_logs_' || score_column || '_check');
        EXECUTE format('ALTER TABLE public.mood_logs ADD CONSTRAINT %I CHECK (%I BETWEEN 1 AND 5)',
            'mood_logs_' || score_column || '_check', score_column);
    END LOOP;
END;
$$;
ALTER TABLE public.routine_logs DROP CONSTRAINT IF EXISTS routine_logs_mood_score_check;
ALTER TABLE public.routine_logs ADD CONSTRAINT routine_logs_mood_score_check
    CHECK (mood_score BETWEEN 1 AND 5);
ALTER TABLE public.user_memories DROP CONSTRAINT IF EXISTS user_memories_relevance_score_check;
ALTER TABLE public.user_memories ADD CONSTRAINT user_memories_relevance_score_check
    CHECK (relevance_score BETWEEN 1 AND 10);

CREATE TABLE IF NOT EXISTS public.learning_progress (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lesson_id TEXT NOT NULL CHECK (btrim(lesson_id) <> ''),
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    viewed_ideas INT[] NOT NULL DEFAULT '{}' CHECK (0 <= ALL(viewed_ideas)),
    helpful_ideas INT[] NOT NULL DEFAULT '{}' CHECK (0 <= ALL(helpful_ideas)),
    last_idea_index INT NOT NULL DEFAULT 0 CHECK (last_idea_index >= 0),
    last_opened_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, lesson_id)
);


-- Streaks remain derived from these dated records using the device's local
-- calendar, matching JourneyScreen/RoutinesProvider. No stale streak counter.
CREATE INDEX IF NOT EXISTS journal_entries_user_created_idx ON public.journal_entries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS gratitude_entries_user_created_idx ON public.gratitude_entries(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS gratitude_entries_user_garden_plot_key ON public.gratitude_entries(user_id, garden_index, plot_index);
CREATE INDEX IF NOT EXISTS mood_logs_user_created_idx ON public.mood_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS future_letters_user_deliver_idx ON public.future_letters(user_id, deliver_at);
CREATE INDEX IF NOT EXISTS routine_logs_user_completed_idx ON public.routine_logs(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS user_memories_user_relevance_idx ON public.user_memories(user_id, relevance_score DESC);
CREATE INDEX IF NOT EXISTS learning_progress_user_opened_idx ON public.learning_progress(user_id, last_opened_at DESC);

CREATE OR REPLACE FUNCTION public.kaibigan_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE app_table TEXT;
BEGIN
    FOREACH app_table IN ARRAY ARRAY['profiles', 'journal_entries', 'user_memories', 'learning_progress']
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS kaibigan_updated_at ON public.%I', app_table);
        EXECUTE format('CREATE TRIGGER kaibigan_updated_at BEFORE UPDATE ON public.%I
            FOR EACH ROW EXECUTE FUNCTION public.kaibigan_set_updated_at()', app_table);
    END LOOP;
END;
$$;

DO $$
DECLARE app_table TEXT;
        owner_column TEXT;
        old_policy RECORD;
BEGIN
    FOREACH app_table IN ARRAY ARRAY[
        'profiles', 'journal_entries', 'gratitude_entries', 'mood_logs',
        'future_letters', 'routine_logs', 'user_memories', 'learning_progress'
    ]
    LOOP
        FOR old_policy IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = app_table
        LOOP
            EXECUTE format('DROP POLICY %I ON public.%I', old_policy.policyname, app_table);
        END LOOP;
        owner_column := CASE WHEN app_table = 'profiles' THEN 'id' ELSE 'user_id' END;
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', app_table);
        EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon', app_table);
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', app_table);
        EXECUTE format('GRANT ALL ON public.%I TO service_role', app_table);
        EXECUTE format('CREATE POLICY "Owner access" ON public.%I FOR ALL TO authenticated
            USING ((SELECT auth.uid()) = %I) WITH CHECK ((SELECT auth.uid()) = %I)',
            app_table, owner_column, owner_column);
    END LOOP;
END;
$$;


COMMIT;
