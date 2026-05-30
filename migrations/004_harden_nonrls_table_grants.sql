-- ============================================================
-- Harden the over-broad write grant from 001_explicit_grants.sql
--
-- ROOT CAUSE (HIGH — broken access control)
--   001_explicit_grants.sql walks every table in `public` and runs
--     grant select, insert, update, delete on <table> to authenticated
--   UNCONDITIONALLY — i.e. regardless of whether the table has RLS
--   enabled. Tables defined in schema.sql WITHOUT
--   `alter table ... enable row level security` (notably the reference
--   tables `cigars` and `cigar_stores`) therefore end up writable by any
--   signed-in user, with no policy to constrain the write. 003 fixed the
--   two known catalog tables specifically; this migration fixes the
--   GENERAL rule so the same hole can never reappear for another non-RLS
--   table.
--
-- FIX
--   For every BASE TABLE in `public` that does NOT have RLS enabled,
--   REVOKE insert/update/delete from `anon` and `authenticated`. A table
--   with RLS disabled has no row-level constraints, so client roles must
--   not hold write on it; only the privileged `service_role` (used by the
--   scraper/seeder) keeps write. RLS-enabled tables are untouched — their
--   policies are the access control and 001's grants are correct for them.
--   SELECT grants are left as-is (catalog tables are meant to be readable).
--
-- Idempotent and forward-safe: re-running after new tables are added
-- re-applies the correct rule. A no-op today on a project where the only
-- live table is `posts` (RLS-enabled); it enforces automatically once
-- schema.sql creates the catalog tables.
-- ============================================================

do $$
declare
  rec record;
begin
  for rec in
    select c.relname as tablename
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'            -- ordinary tables only (not views/matviews)
      and c.relrowsecurity = false   -- RLS NOT enabled
  loop
    execute format(
      'revoke insert, update, delete on public.%I from anon, authenticated',
      rec.tablename
    );
  end loop;
end $$;
