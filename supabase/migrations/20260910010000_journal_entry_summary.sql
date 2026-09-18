-- Keeps the AI look-back cards with the journal entry that produced them, so
-- reopening a record shows the same summary, moments and advice instead of the
-- conversation alone. Existing rows keep NULL and simply render no cards.
BEGIN;

ALTER TABLE public.journal_entries
    ADD COLUMN IF NOT EXISTS summary JSONB;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'journal_entries_summary_is_object'
    ) THEN
        ALTER TABLE public.journal_entries
            ADD CONSTRAINT journal_entries_summary_is_object
            CHECK (summary IS NULL OR jsonb_typeof(summary) = 'object');
    END IF;
END;
$$;

COMMIT;
