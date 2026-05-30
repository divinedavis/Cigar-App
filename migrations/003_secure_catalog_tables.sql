-- ============================================================
-- 003 — Secure the shared catalog tables (cigars, cigar_stores)
--
-- VULNERABILITY
-- The base schema (schema.sql) only enables row-level security on
-- profiles / posts / cigar_reactions / comments / post_saves /
-- ad_creatives / subscriptions. The two shared-catalog tables —
-- `cigars` and `cigar_stores` — were left with RLS DISABLED.
--
-- Migration 001_explicit_grants.sql then grants
--   SELECT, INSERT, UPDATE, DELETE
-- to the `authenticated` role for *every* public table. With RLS
-- off, those grants are unguarded, so ANY signed-up user can
-- INSERT/UPDATE/DELETE rows in the shared cigar catalog and rewrite
-- store names and lat/long coordinates that the whole app depends on.
--
-- FIX
--   1. Enable RLS on both tables (defense-in-depth).
--   2. Allow public READ (anon + authenticated) — the catalog and
--      store directory are meant to be browsable by everyone.
--   3. REVOKE write (INSERT/UPDATE/DELETE) from anon + authenticated
--      so clients can no longer mutate the catalog. The scraper /
--      seeder writes with the service_role key, which bypasses both
--      RLS and these grants, so legitimate population still works.
--
-- Idempotent: safe to re-run.
--
-- Existence-guarded: the two catalog tables are created by
-- schema.sql, which may not yet have been applied to a given
-- environment. Each block is wrapped in a `to_regclass(...) is not
-- null` check so this migration is a harmless no-op until the
-- tables exist, and enforces the lock-down the moment they do.
-- ============================================================

do $$
begin
  if to_regclass('public.cigars') is not null then
    -- 1. Enable RLS (defense-in-depth; a missing write grant already
    --    blocks writes, but RLS makes the intent explicit and guards
    --    against a future blanket grant migration re-opening the hole).
    execute 'alter table public.cigars enable row level security';

    -- 2. Public read policy (anon + authenticated), idempotent.
    execute 'drop policy if exists "cigars readable" on public.cigars';
    execute 'create policy "cigars readable" on public.cigars '
         || 'for select to anon, authenticated using (true)';

    -- 3. Revoke client write access. The over-broad grant from
    --    001_explicit_grants.sql handed INSERT/UPDATE/DELETE to
    --    `authenticated`; pull it back. anon never had write but
    --    revoke defensively in case a future grant re-adds it.
    execute 'revoke insert, update, delete on public.cigars from authenticated';
    execute 'revoke insert, update, delete on public.cigars from anon';

    -- Ensure read access remains granted (Data API needs the
    -- table-level grant in addition to the RLS policy).
    execute 'grant select on public.cigars to anon, authenticated';

    -- service_role keeps full access (scraper / seeder writes).
    execute 'grant all on public.cigars to service_role';
  end if;

  if to_regclass('public.cigar_stores') is not null then
    execute 'alter table public.cigar_stores enable row level security';

    execute 'drop policy if exists "cigar_stores readable" on public.cigar_stores';
    execute 'create policy "cigar_stores readable" on public.cigar_stores '
         || 'for select to anon, authenticated using (true)';

    execute 'revoke insert, update, delete on public.cigar_stores from authenticated';
    execute 'revoke insert, update, delete on public.cigar_stores from anon';

    execute 'grant select on public.cigar_stores to anon, authenticated';

    execute 'grant all on public.cigar_stores to service_role';
  end if;
end $$;
