-- Gratitude flowers are complete visual memories rather than staged growth.
ALTER TABLE public.gratitude_entries
    DROP COLUMN IF EXISTS growth_stage;
