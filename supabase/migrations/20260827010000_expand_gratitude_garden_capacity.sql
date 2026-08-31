-- Expand each gratitude garden from 10 to 15 planting plots.
ALTER TABLE public.gratitude_entries
    DROP CONSTRAINT IF EXISTS gratitude_entries_plot_index_check;

ALTER TABLE public.gratitude_entries
    ADD CONSTRAINT gratitude_entries_plot_index_check
        CHECK (plot_index >= 0 AND plot_index < 15);
