-- Kaibigan schema for a NEW Supabase database.
-- Existing projects: run migrations/20260903010000_align_active_features.sql
-- from the repository's supabase directory instead. Do not run this file over
-- an existing installation. Deploy the matching Flutter build after migration.
BEGIN;

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL DEFAULT 'Friend',
    preferred_mascot_id TEXT NOT NULL DEFAULT 'kai',
    preferred_language TEXT NOT NULL DEFAULT 'taglish',
    theme_mode TEXT NOT NULL DEFAULT 'light',
    garden_appearance TEXT NOT NULL DEFAULT 'syncWithTime',
    journal_paper_style TEXT NOT NULL DEFAULT 'ruled',
    journal_accent TEXT NOT NULL DEFAULT 'honey',
    journal_text_size TEXT NOT NULL DEFAULT 'normal',
    ui_sound_level TEXT NOT NULL DEFAULT 'soft',
    ai_memory_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_wellbeing_context_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    has_completed_setup BOOLEAN NOT NULL DEFAULT FALSE,
    has_seen_tutorial BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    ai_response TEXT,
    conversation_turns JSONB NOT NULL DEFAULT '[]'::JSONB
        CHECK (jsonb_typeof(conversation_turns) = 'array'),
    summary JSONB
        CHECK (summary IS NULL OR jsonb_typeof(summary) = 'object'),
    reflection_mode TEXT NOT NULL DEFAULT 'auto',
    companion_id TEXT NOT NULL DEFAULT 'kai',
    mood TEXT NOT NULL DEFAULT '',
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.gratitude_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    flower_type TEXT NOT NULL DEFAULT 'anemone',
    garden_index INT NOT NULL DEFAULT 0 CHECK (garden_index >= 0),
    plot_index INT NOT NULL DEFAULT 0 CHECK (plot_index >= 0 AND plot_index < 10),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    mood_score INT NOT NULL CHECK (mood_score BETWEEN 1 AND 5),
    mood_label TEXT NOT NULL,
    stress_level INT DEFAULT 3 CHECK (stress_level BETWEEN 1 AND 5),
    energy_level INT DEFAULT 3 CHECK (energy_level BETWEEN 1 AND 5),
    sleep_quality INT DEFAULT 3 CHECK (sleep_quality BETWEEN 1 AND 5),
    anxiety_level INT DEFAULT 3 CHECK (anxiety_level BETWEEN 1 AND 5),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.future_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    deliver_at TIMESTAMPTZ NOT NULL,
    is_opened BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Includes routine completions and standalone focus/highlight/sleep/breathing
-- activity logs. routine_id is intentionally NOT a foreign key to a config:
-- built-in and custom routine configurations are stored locally by the app.
CREATE TABLE public.routine_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    routine_id TEXT NOT NULL,
    routine_type TEXT NOT NULL,
    sleep_feeling TEXT,
    focus_or_highlight TEXT,
    mood_score INT CHECK (mood_score BETWEEN 1 AND 5),
    mood_note TEXT,
    gratitude_content TEXT,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.user_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    memory_category TEXT DEFAULT 'theme',
    memory_summary TEXT NOT NULL,
    relevance_score INT DEFAULT 5 CHECK (relevance_score BETWEEN 1 AND 10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lesson content is bundled in LearningCatalog; only personal progress syncs.
CREATE TABLE public.learning_progress (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lesson_id TEXT NOT NULL CHECK (btrim(lesson_id) <> ''),
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    viewed_ideas INT[] NOT NULL DEFAULT '{}' CHECK (0 <= ALL(viewed_ideas)),
    helpful_ideas INT[] NOT NULL DEFAULT '{}' CHECK (0 <= ALL(helpful_ideas)),
    last_idea_index INT NOT NULL DEFAULT 0 CHECK (last_idea_index >= 0),
    last_opened_at TIMESTAMPTZ,
    quiz_score INTEGER,
    quiz_total INTEGER,
    practice_count INTEGER NOT NULL DEFAULT 0,
    last_practice_scenario TEXT,
    last_practiced_at TIMESTAMPTZ,
    practice_reply_count INTEGER NOT NULL DEFAULT 0,
    practice_supportive_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT learning_progress_quiz_valid CHECK (
      (quiz_score IS NULL AND quiz_total IS NULL) OR
      (quiz_score IS NOT NULL AND quiz_total IS NOT NULL AND quiz_total > 0 AND quiz_score BETWEEN 0 AND quiz_total)
    ),
    CONSTRAINT learning_progress_practice_valid CHECK (
      practice_count >= 0 AND practice_reply_count >= 0 AND
      practice_supportive_count BETWEEN 0 AND practice_reply_count AND
      (last_practice_scenario IS NULL OR btrim(last_practice_scenario) <> '')
    ),
    PRIMARY KEY (user_id, lesson_id)
);

CREATE TABLE public.user_activity_stats (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    login_dates TEXT[] NOT NULL DEFAULT '{}',
    activity_counts JSONB NOT NULL DEFAULT '{}'::JSONB,
    pinned_favorites TEXT[] NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Streaks remain derived from these dated records using the device's local
-- calendar, matching JourneyScreen/RoutinesProvider. No stale streak counter.
CREATE INDEX journal_entries_user_created_idx ON public.journal_entries(user_id, created_at DESC);
CREATE INDEX gratitude_entries_user_created_idx ON public.gratitude_entries(user_id, created_at DESC);
CREATE UNIQUE INDEX gratitude_entries_user_garden_plot_key ON public.gratitude_entries(user_id, garden_index, plot_index);
CREATE INDEX mood_logs_user_created_idx ON public.mood_logs(user_id, created_at DESC);
CREATE INDEX future_letters_user_deliver_idx ON public.future_letters(user_id, deliver_at);
CREATE INDEX routine_logs_user_completed_idx ON public.routine_logs(user_id, completed_at DESC);
CREATE INDEX user_memories_user_relevance_idx ON public.user_memories(user_id, relevance_score DESC);
CREATE INDEX learning_progress_user_opened_idx ON public.learning_progress(user_id, last_opened_at DESC);

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
    FOREACH app_table IN ARRAY ARRAY['profiles', 'journal_entries', 'user_memories', 'learning_progress', 'user_activity_stats']
    LOOP
        EXECUTE format('CREATE TRIGGER kaibigan_updated_at BEFORE UPDATE ON public.%I
            FOR EACH ROW EXECUTE FUNCTION public.kaibigan_set_updated_at()', app_table);
    END LOOP;
END;
$$;

DO $$
DECLARE app_table TEXT;
        owner_column TEXT;
BEGIN
    FOREACH app_table IN ARRAY ARRAY[
        'profiles', 'journal_entries', 'gratitude_entries', 'mood_logs',
        'future_letters', 'routine_logs', 'user_memories', 'learning_progress', 'user_activity_stats'
    ]
    LOOP
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
