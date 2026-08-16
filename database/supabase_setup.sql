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
    companion_id TEXT NOT NULL DEFAULT 'kai',
    mood TEXT NOT NULL DEFAULT 'calm',
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    reflection_seed_stage INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Gratitude Entries Table
CREATE TABLE IF NOT EXISTS public.gratitude_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    flower_type TEXT NOT NULL DEFAULT 'sunflower',
    growth_stage INT DEFAULT 3,
    water_count INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
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
-- DISABLE ROW LEVEL SECURITY (RLS) FOR DEVELOPMENT ENVIRONMENT
-- =================================================================
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.gratitude_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.future_letters DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_configs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_memories DISABLE ROW LEVEL SECURITY;
