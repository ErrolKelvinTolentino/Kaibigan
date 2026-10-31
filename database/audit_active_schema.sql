-- Metadata and aggregate counts only: no journal text, emails or memories.
SELECT 'profiles' AS table_name, count(*) AS rows FROM public.profiles
UNION ALL SELECT 'journal_entries', count(*) FROM public.journal_entries
UNION ALL SELECT 'gratitude_entries', count(*) FROM public.gratitude_entries
UNION ALL SELECT 'mood_logs', count(*) FROM public.mood_logs
UNION ALL SELECT 'future_letters', count(*) FROM public.future_letters
UNION ALL SELECT 'routine_logs', count(*) FROM public.routine_logs
UNION ALL SELECT 'user_memories', count(*) FROM public.user_memories
UNION ALL SELECT 'learning_progress', count(*) FROM public.learning_progress
UNION ALL SELECT 'user_activity_stats', count(*) FROM public.user_activity_stats;
