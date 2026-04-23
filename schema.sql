-- Stogie — Supabase schema (v1 scaffold)
--
-- Run this against the Stogie Supabase project to create the base
-- tables. RLS policies are intentionally permissive here and should
-- be tightened per-table before production.

create extension if not exists "uuid-ossp";

-- Profiles ---------------------------------------------------------
create table if not exists profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique not null,
    display_name text not null,
    bio text default '',
    avatar_url text,
    date_of_birth date not null,
    account_type text not null default 'personal' check (account_type in ('personal','business')),
    is_verified boolean not null default false,
    created_at timestamptz default now()
);

-- Age gate: enforce 21+ at the database layer too, not just the client.
alter table profiles
    add constraint profiles_must_be_21 check (
        date_of_birth <= (current_date - interval '21 years')
    );

-- Cigars -----------------------------------------------------------
create table if not exists cigars (
    id uuid primary key default uuid_generate_v4(),
    brand text not null,
    line text not null,
    vitola text,
    created_at timestamptz default now()
);

create index if not exists cigars_brand_line_idx on cigars (brand, line);

-- Cigar stores (places, validated by Apple Maps) --------------------
create table if not exists cigar_stores (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    address text not null,
    latitude double precision not null,
    longitude double precision not null,
    created_at timestamptz default now()
);

-- Posts ------------------------------------------------------------
create table if not exists posts (
    id uuid primary key default uuid_generate_v4(),
    author_id uuid not null references profiles(id) on delete cascade,
    media_url text not null,
    media_kind text not null check (media_kind in ('photo','video')),
    caption text default '',
    cigar_id uuid references cigars(id) on delete set null,
    store_id uuid references cigar_stores(id) on delete set null,
    created_at timestamptz default now()
);

create index if not exists posts_author_idx on posts (author_id);
create index if not exists posts_created_idx on posts (created_at desc);

-- Cigar reactions (instead of "likes") -----------------------------
create table if not exists cigar_reactions (
    post_id uuid not null references posts(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    created_at timestamptz default now(),
    primary key (post_id, user_id)
);

-- Comments ---------------------------------------------------------
create table if not exists comments (
    id uuid primary key default uuid_generate_v4(),
    post_id uuid not null references posts(id) on delete cascade,
    author_id uuid not null references profiles(id) on delete cascade,
    body text not null,
    created_at timestamptz default now()
);

-- Saves ------------------------------------------------------------
create table if not exists post_saves (
    post_id uuid not null references posts(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    created_at timestamptz default now(),
    primary key (post_id, user_id)
);

-- Ad creatives (uploaded via separate business portal) -------------
create table if not exists ad_creatives (
    id uuid primary key default uuid_generate_v4(),
    business_id uuid not null references profiles(id) on delete cascade,
    media_url text not null,
    media_kind text not null check (media_kind in ('photo','video')),
    headline text not null,
    cta_label text not null,
    cta_url text,
    active boolean not null default true,
    created_at timestamptz default now()
);

-- Subscriptions (paid tier — no ads) -------------------------------
create table if not exists subscriptions (
    user_id uuid primary key references profiles(id) on delete cascade,
    started_at timestamptz default now(),
    expires_at timestamptz,
    status text not null default 'active'
);

-- RLS --------------------------------------------------------------
alter table profiles enable row level security;
alter table posts enable row level security;
alter table cigar_reactions enable row level security;
alter table comments enable row level security;
alter table post_saves enable row level security;
alter table ad_creatives enable row level security;
alter table subscriptions enable row level security;

-- Profiles: readable by all signed-in users, writable by self.
create policy "profiles readable" on profiles for select using (auth.role() = 'authenticated');
create policy "profiles self-insert" on profiles for insert with check (auth.uid() = id);
create policy "profiles self-update" on profiles for update using (auth.uid() = id);

-- Posts: readable by all signed-in, writable by author.
create policy "posts readable" on posts for select using (auth.role() = 'authenticated');
create policy "posts self-insert" on posts for insert with check (auth.uid() = author_id);
create policy "posts self-update" on posts for update using (auth.uid() = author_id);
create policy "posts self-delete" on posts for delete using (auth.uid() = author_id);

-- Reactions: self-managed.
create policy "reactions readable" on cigar_reactions for select using (auth.role() = 'authenticated');
create policy "reactions self-insert" on cigar_reactions for insert with check (auth.uid() = user_id);
create policy "reactions self-delete" on cigar_reactions for delete using (auth.uid() = user_id);
