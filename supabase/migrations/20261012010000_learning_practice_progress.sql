-- Keep learning state on its existing account/lesson row. No transcript table:
-- fictional practice conversations remain transient on the device.
BEGIN;

ALTER TABLE public.learning_progress
  ADD COLUMN IF NOT EXISTS quiz_score INTEGER,
  ADD COLUMN IF NOT EXISTS quiz_total INTEGER,
  ADD COLUMN IF NOT EXISTS practice_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_practice_scenario TEXT,
  ADD COLUMN IF NOT EXISTS last_practiced_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS practice_reply_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS practice_supportive_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.learning_progress DROP CONSTRAINT IF EXISTS learning_progress_quiz_valid;
ALTER TABLE public.learning_progress ADD CONSTRAINT learning_progress_quiz_valid CHECK (
  (quiz_score IS NULL AND quiz_total IS NULL) OR
  (quiz_score IS NOT NULL AND quiz_total IS NOT NULL AND quiz_total > 0 AND quiz_score BETWEEN 0 AND quiz_total)
);
ALTER TABLE public.learning_progress DROP CONSTRAINT IF EXISTS learning_progress_practice_valid;
ALTER TABLE public.learning_progress ADD CONSTRAINT learning_progress_practice_valid CHECK (
  practice_count >= 0 AND practice_reply_count >= 0 AND
  practice_supportive_count BETWEEN 0 AND practice_reply_count AND
  (last_practice_scenario IS NULL OR btrim(last_practice_scenario) <> '')
);

-- Existing owner-only RLS, FK cascade and updated_at trigger also protect
-- these columns. Avoid introducing a second copy of lessons or AI replies.
COMMENT ON COLUMN public.learning_progress.last_practice_scenario IS
  'Bundled fictional scenario identifier; no participant messages are persisted.';
COMMENT ON COLUMN public.journal_entries.summary IS
  'Saved AI look-back for this version of the entry, reused when reading records.';

COMMIT;
