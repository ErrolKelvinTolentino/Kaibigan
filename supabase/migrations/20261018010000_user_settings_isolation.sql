-- Migration: Add user settings columns to profiles table for account isolation
BEGIN;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS theme_mode TEXT NOT NULL DEFAULT 'light',
    ADD COLUMN IF NOT EXISTS garden_appearance TEXT NOT NULL DEFAULT 'syncWithTime',
    ADD COLUMN IF NOT EXISTS journal_paper_style TEXT NOT NULL DEFAULT 'ruled',
    ADD COLUMN IF NOT EXISTS journal_accent TEXT NOT NULL DEFAULT 'honey',
    ADD COLUMN IF NOT EXISTS journal_text_size TEXT NOT NULL DEFAULT 'normal',
    ADD COLUMN IF NOT EXISTS ui_sound_level TEXT NOT NULL DEFAULT 'soft',
    ADD COLUMN IF NOT EXISTS ai_memory_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS ai_wellbeing_context_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS has_completed_setup BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_seen_tutorial BOOLEAN NOT NULL DEFAULT FALSE;

-- Ensure existing profiles that have configured companions are marked as having completed setup
UPDATE public.profiles
SET has_completed_setup = TRUE
WHERE preferred_mascot_id IS NOT NULL 
  AND preferred_language IS NOT NULL
  AND has_completed_setup = FALSE;

COMMIT;
