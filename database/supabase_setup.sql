-- Kaibigan Supabase Database Setup Script
-- Disables RLS for development environment as requested.

-- 1. Create User Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name TEXT DEFAULT 'Kaibigan User',
    selected_companion TEXT DEFAULT 'kai', -- 'kai', 'ann', 'bee'
    preferred_language TEXT DEFAULT 'taglish', -- 'taglish', 'filipino', 'english'
    dark_mode BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Journal Entries Table
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    ai_response TEXT,
    companion_id TEXT DEFAULT 'kai',
    mood TEXT DEFAULT 'calm',
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    reflection_seed_stage INT DEFAULT 1, -- 1: Seed, 2: Sprout, 3: Bloom
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Gratitude Entries Table
CREATE TABLE IF NOT EXISTS public.gratitude_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    flower_type TEXT DEFAULT 'sunflower', -- 'sunflower', 'sampaguita', 'tulip', 'orchid', 'rose'
    growth_stage INT DEFAULT 3, -- 1: Seedling, 2: Bud, 3: Full Bloom
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Mood Logs Table
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    mood_score INT NOT NULL, -- 1 (Very Low) to 5 (Very High)
    mood_label TEXT NOT NULL, -- 'Awesome', 'Good', 'Okay', 'Low', 'Struggling'
    stress_level INT DEFAULT 3, -- 1 to 5
    energy_level INT DEFAULT 3, -- 1 to 5
    sleep_quality INT DEFAULT 3, -- 1 to 5
    anxiety_level INT DEFAULT 3, -- 1 to 5
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Future Letters Table
CREATE TABLE IF NOT EXISTS public.future_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    deliver_at TIMESTAMPTZ NOT NULL,
    is_opened BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create Daily Goals Table
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL, -- 'hydration', 'walk', 'gratitude', 'breathing'
    title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable Row Level Security (RLS) for Development
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.gratitude_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.future_letters DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals DISABLE ROW LEVEL SECURITY;

-- Insert Default Development Profile
INSERT INTO public.profiles (id, display_name, selected_companion, preferred_language)
VALUES ('00000000-0000-0000-0000-000000000001', 'Errol', 'kai', 'taglish')
ON CONFLICT (id) DO NOTHING;

-- Seed Sample Gratitude Entries
INSERT INTO public.gratitude_entries (user_id, content, flower_type, growth_stage)
VALUES 
('00000000-0000-0000-0000-000000000001', 'Grateful for warm morning coffee and a clear sky.', 'sunflower', 3),
('00000000-0000-0000-0000-000000000001', 'Tumawag si Mama, ang saya ng boses niya.', 'sampaguita', 3),
('00000000-0000-0000-0000-000000000001', 'Completed a hard task at work today.', 'tulip', 3)
ON CONFLICT DO NOTHING;

-- Seed Sample Mood Logs
INSERT INTO public.mood_logs (user_id, mood_score, mood_label, stress_level, energy_level, sleep_quality, anxiety_level, note)
VALUES
('00000000-0000-0000-0000-000000000001', 4, 'Good', 2, 4, 4, 2, 'Felt productive and peaceful.'),
('00000000-0000-0000-0000-000000000001', 3, 'Okay', 3, 3, 3, 3, 'A bit tiring day, but did some breathing exercises.'),
('00000000-0000-0000-0000-000000000001', 5, 'Awesome', 1, 5, 5, 1, 'Spent quality time in the Gratitude Garden.')
ON CONFLICT DO NOTHING;
