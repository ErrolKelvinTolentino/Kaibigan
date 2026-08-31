-- Give every gratitude flower a stable garden and planting plot.
ALTER TABLE public.gratitude_entries
    ADD COLUMN IF NOT EXISTS garden_index INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS plot_index INT NOT NULL DEFAULT 0;

-- Existing flowers are assigned chronologically, ten per garden. This runs
-- once as a managed migration, so future deletions leave an intentional open
-- plot instead of moving a user's remaining flowers around.
WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY created_at ASC, id ASC
        ) - 1 AS position
    FROM public.gratitude_entries
)
UPDATE public.gratitude_entries AS entry
SET
    garden_index = (ranked.position / 10)::INT,
    plot_index = (ranked.position % 10)::INT
FROM ranked
WHERE entry.id = ranked.id;

ALTER TABLE public.gratitude_entries
    DROP CONSTRAINT IF EXISTS gratitude_entries_garden_index_check,
    DROP CONSTRAINT IF EXISTS gratitude_entries_plot_index_check;

ALTER TABLE public.gratitude_entries
    ADD CONSTRAINT gratitude_entries_garden_index_check
        CHECK (garden_index >= 0),
    ADD CONSTRAINT gratitude_entries_plot_index_check
        CHECK (plot_index >= 0 AND plot_index < 10);

CREATE UNIQUE INDEX IF NOT EXISTS gratitude_entries_user_garden_plot_key
    ON public.gratitude_entries (user_id, garden_index, plot_index);
