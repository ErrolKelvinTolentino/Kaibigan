-- =================================================================
-- KAIBIGAN FULL SUPABASE DATABASE SCHEMA
-- Execute this SQL script in your Supabase SQL Editor.
-- =================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Profiles Table (User Settings & Companion Preferences)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL DEFAULT 'Friend',
    preferred_mascot_id TEXT NOT NULL DEFAULT 'kai',
    preferred_language TEXT NOT NULL DEFAULT 'taglish',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Journal Entries Table
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    ai_response TEXT,
    reflection_mode TEXT NOT NULL DEFAULT 'companion',
    companion_id TEXT NOT NULL DEFAULT 'kai',
    mood TEXT NOT NULL DEFAULT 'calm',
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    reflection_seed_stage INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe migration for projects created before companion modes were added.
ALTER TABLE public.journal_entries
    ADD COLUMN IF NOT EXISTS reflection_mode TEXT NOT NULL DEFAULT 'companion';

-- 4. Gratitude Entries Table
CREATE TABLE IF NOT EXISTS public.gratitude_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    flower_type TEXT NOT NULL DEFAULT 'sunflower',
    water_count INT DEFAULT 1,
    garden_index INT NOT NULL DEFAULT 0 CHECK (garden_index >= 0),
    plot_index INT NOT NULL DEFAULT 0 CHECK (plot_index >= 0 AND plot_index < 15),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, garden_index, plot_index)
);

-- 5. Mood Logs Table
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    mood_score INT NOT NULL, -- 1 (Struggling) to 5 (Awesome)
    mood_label TEXT NOT NULL,
    stress_level INT DEFAULT 3,
    energy_level INT DEFAULT 3,
    sleep_quality INT DEFAULT 3,
    anxiety_level INT DEFAULT 3,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Future Letters Table
CREATE TABLE IF NOT EXISTS public.future_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    deliver_at TIMESTAMPTZ NOT NULL,
    is_opened BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Daily Goals Table
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL,
    title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Routine Configurations Table
CREATE TABLE IF NOT EXISTS public.routine_configs (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    routine_type TEXT NOT NULL,
    reminder_time TEXT NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Routine Logs Table
CREATE TABLE IF NOT EXISTS public.routine_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    routine_id TEXT NOT NULL,
    routine_type TEXT NOT NULL,
    sleep_feeling TEXT,
    focus_or_highlight TEXT,
    mood_score INT,
    mood_note TEXT,
    gratitude_content TEXT,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. User Memories Table (Long-Term AI Memory Context)
CREATE TABLE IF NOT EXISTS public.user_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    memory_category TEXT DEFAULT 'theme', -- 'theme', 'coping_strategy', 'milestone', 'trigger'
    memory_summary TEXT NOT NULL,
    relevance_score INT DEFAULT 5, -- 1 (Minor) to 10 (High Priority)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- ROW LEVEL SECURITY (PRIVATE, PER-USER DATA)
-- =================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gratitude_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.future_letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_memories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage their own profile" ON public.profiles;
CREATE POLICY "Users manage their own profile"
    ON public.profiles FOR ALL TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users manage their own journal entries" ON public.journal_entries;
CREATE POLICY "Users manage their own journal entries"
    ON public.journal_entries FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own gratitude entries" ON public.gratitude_entries;
CREATE POLICY "Users manage their own gratitude entries"
    ON public.gratitude_entries FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own mood logs" ON public.mood_logs;
CREATE POLICY "Users manage their own mood logs"
    ON public.mood_logs FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own future letters" ON public.future_letters;
CREATE POLICY "Users manage their own future letters"
    ON public.future_letters FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own daily goals" ON public.daily_goals;
CREATE POLICY "Users manage their own daily goals"
    ON public.daily_goals FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own routine configs" ON public.routine_configs;
CREATE POLICY "Users manage their own routine configs"
    ON public.routine_configs FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own routine logs" ON public.routine_logs;
CREATE POLICY "Users manage their own routine logs"
    ON public.routine_logs FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage their own AI memories" ON public.user_memories;
CREATE POLICY "Users manage their own AI memories"
    ON public.user_memories FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
