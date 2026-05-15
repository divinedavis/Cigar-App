-- ============================================================
-- 002 — Daily feed seeding
--
-- Adds view_count / is_seed columns to posts and a pg_cron job
-- that repopulates the feed once a day with 100 video + 100
-- photo demo posts:
--   * comment_count  100 – 200 per post
--   * view_count     10,000 – 300,000 per post
--
-- Each run first deletes the previous day's demo posts
-- (is_seed = true) so the table stays bounded at ~200 rows.
-- Real user posts (is_seed = false) are never touched.
--
-- Schedule: every day at 08:00 UTC.
-- ============================================================

-- 1. New columns -------------------------------------------------
alter table public.posts
  add column if not exists view_count integer not null default 0,
  add column if not exists is_seed boolean not null default false;

-- 2. Seeding function -------------------------------------------
create or replace function public.seed_daily_feed()
returns void
language plpgsql
security definer
set search_path = public
as $func$
declare
  videos text[] := array[
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4'
  ];
  captions text[] := array[
    'Sunday afternoon with a 1964 Anniversary.',
    'First OpusX of the year. Worth the wait.',
    'Padron 1926 pairs perfectly with this bourbon.',
    'New humidor, who dis.',
    'Friday night at the lounge.',
    'Ash game strong.',
    'Two-hour smoke and zero regrets.',
    'Don Carlos No. 3, Maduro wrapper, perfect draw.',
    'Bourbon and a Behike. Keeping this one quiet.',
    'Cigar trip to the Dominican was unreal.'
  ];
  i int;
begin
  -- clear the previous run's demo posts; leave real posts alone
  delete from public.posts where is_seed = true;

  -- 100 video posts
  for i in 1..100 loop
    insert into public.posts
      (author_id, media_url, media_kind, caption, created_at,
       cigar_reaction_count, comment_count, save_count, view_count, is_seed)
    values
      (gen_random_uuid(),
       videos[1 + floor(random() * array_length(videos, 1))::int],
       'video',
       captions[1 + floor(random() * array_length(captions, 1))::int],
       now() - (random() * interval '12 hours'),
       floor(random() * 2389 + 12)::int,        -- reactions
       floor(random() * 101 + 100)::int,        -- 100 – 200 comments
       floor(random() * 400)::int,              -- saves
       floor(random() * 290001 + 10000)::int,   -- 10k – 300k views
       true);
  end loop;

  -- 100 photo posts
  for i in 1..100 loop
    insert into public.posts
      (author_id, media_url, media_kind, caption, created_at,
       cigar_reaction_count, comment_count, save_count, view_count, is_seed)
    values
      (gen_random_uuid(),
       'https://picsum.photos/seed/maduro-' || gen_random_uuid() || '/800/1400',
       'photo',
       captions[1 + floor(random() * array_length(captions, 1))::int],
       now() - (random() * interval '12 hours'),
       floor(random() * 2389 + 12)::int,
       floor(random() * 101 + 100)::int,
       floor(random() * 400)::int,
       floor(random() * 290001 + 10000)::int,
       true);
  end loop;
end;
$func$;

-- 3. Daily schedule via pg_cron ---------------------------------
create extension if not exists pg_cron;

do $cron$
begin
  if exists (select 1 from cron.job where jobname = 'maduro-daily-feed-seed') then
    perform cron.unschedule('maduro-daily-feed-seed');
  end if;
end
$cron$;

select cron.schedule(
  'maduro-daily-feed-seed',
  '0 8 * * *',
  $job$select public.seed_daily_feed();$job$
);

-- 4. Populate immediately so the feed isn't empty before 08:00 --
select public.seed_daily_feed();

-- 5. Data API grants (see migration 001) ------------------------
grant select on public.posts to anon;
grant select, insert, update, delete on public.posts to authenticated;
grant all on public.posts to service_role;
