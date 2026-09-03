BEGIN;

CREATE TABLE IF NOT EXISTS public.user_activity_stats (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    login_dates TEXT[] NOT NULL DEFAULT '{}',
    activity_counts JSONB NOT NULL DEFAULT '{}'::JSONB,
    pinned_favorites TEXT[] NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
DECLARE app_table TEXT := 'user_activity_stats';
        old_policy RECORD;
BEGIN
    FOR old_policy IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = app_table
    LOOP
        EXECUTE format('DROP POLICY %I ON public.%I', old_policy.policyname, app_table);
    END LOOP;
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', app_table);
    EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon', app_table);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', app_table);
    EXECUTE format('GRANT ALL ON public.%I TO service_role', app_table);
    EXECUTE format('CREATE POLICY "Owner access" ON public.%I FOR ALL TO authenticated
        USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id)',
        app_table);
    EXECUTE format('DROP TRIGGER IF EXISTS kaibigan_updated_at ON public.%I', app_table);
    EXECUTE format('CREATE TRIGGER kaibigan_updated_at BEFORE UPDATE ON public.%I
        FOR EACH ROW EXECUTE FUNCTION public.kaibigan_set_updated_at()', app_table);
END;
$$;

COMMIT;
