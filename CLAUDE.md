# Maduro — Claude working notes

## Project one-liner

iOS-only SwiftUI cigar social app. TikTok-style For You feed, cigar-shaped reactions, auto-detection of cigar lounges via Apple Maps, Supabase backend, TestFlight distribution.

## Per-change workflow (IMPORTANT)

After every code edit in this repo:

1. Run a quick build/smoke check if feasible.
2. `git add` only the specific files touched (never `git add -A` blindly — secrets are gitignored but be careful with new files).
3. Commit with a clear message.
4. `git push origin main` to https://github.com/divinedavis/Cigar-App.
5. Run `./scripts/ship.sh` to upload a new TestFlight build.

Do not batch multiple features across multiple sessions without shipping. Each edit is a complete unit.

## Secrets rule

Never commit files containing secrets — API keys, Supabase service role, signing certs, `.env`, `Config.swift` (with real values), `AuthKey_*.p8`, `*.xcconfig` with keys, or anything similar. The `.gitignore` covers known patterns. If you introduce a new type of secret file, add its pattern to `.gitignore` **before** the first commit that creates it.

## Repository layout

```
Cigar-App/
├── project.yml                # xcodegen spec — single source of truth for Xcode project
├── Maduro.xcodeproj/          # generated; committed so CI + ship.sh work without xcodegen install
├── Maduro/
│   ├── MaduroApp.swift        # @main entry
│   ├── MainTabView.swift      # live-broadcast chrome over the feed: top bar, viewer pill, message composer (Post/Search/Profile in overflow menu)
│   ├── AuthView.swift         # sign in / sign up with 21+ DOB gate
│   ├── ForYouView.swift       # vertical swipeable feed, live-broadcast-style chat overlay
│   ├── CreatePostView.swift   # media picker + cigar tag + store tag
│   ├── ProfileView.swift
│   ├── CigarReactionButton.swift  # cigar-shaped like button
│   ├── LocationManager.swift  # CoreLocation + MKLocalSearch for cigar lounges
│   ├── SupabaseManager.swift  # lazy global Supabase client
│   ├── Config.swift.example   # committed template
│   ├── Config.swift           # LOCAL ONLY (gitignored) — real URL/key
│   ├── CigarCatalog.swift     # seed list of popular cigars
│   ├── AdSlotPlanner.swift    # interleaves ads every 4–10 posts for free users
│   ├── SampleData.swift       # placeholder content until Supabase fetch is wired
│   ├── Models.swift
│   ├── SessionStore.swift
│   ├── Info.plist
│   ├── Maduro.entitlements
│   └── Assets.xcassets/
├── migrations/                # SQL migrations applied to the Supabase DB
│   ├── 001_explicit_grants.sql
│   └── 002_daily_feed_seed.sql # view_count/is_seed columns + daily pg_cron seeding
├── scripts/
│   ├── ship.sh                # archive + upload to TestFlight
│   └── asc-config.env.example # copy to asc-config.env (gitignored) with ASC creds
├── ExportOptions.plist        # app-store-connect export, team CG89RY4W6R
├── README.md
├── CLAUDE.md                  # this file
└── .gitignore
```

## Design rules

- **Reactions:** heart icon in the For You feed composer (`MainTabView` composer bar). The live-broadcast feed restyle (2026-05) switched from the cigar glyph to a heart at the user's request; the legacy `CigarReactionButton.swift` is now unused.
- **Location:** Apple Maps only (no Google Places). `MKLocalSearch` with keyword queries since there's no `tobacco_shop` POI category. Radius 400m. Deduplicate by coordinate.
- **Ads:** serve only from the user's own ad portal. No AdMob / Meta. Placement: random gap ∈ [4,10] posts, min gap 4. Subscribed users see no ads.
- **Age gate:** DOB picker at signup, computed age must be ≥ 21. Do not ship a "tick to confirm 21+" checkbox alone.
- **App Store positioning:** community/review app. Do not add in-app tobacco purchase flows — Apple rejects tobacco-sales apps.
- **Bundle ID:** `com.divinedavis.stogie`. Team: `CG89RY4W6R`.

## Feed seeding

The Supabase `posts` table is repopulated daily by a `pg_cron` job
(`maduro-daily-feed-seed`, 08:00 UTC) calling `public.seed_daily_feed()`.
Each run deletes the prior demo posts (`is_seed = true`) and inserts
100 video + 100 photo posts with `comment_count` 100–200 and
`view_count` 10k–300k. Real user posts (`is_seed = false`) are never
touched. See `migrations/002_daily_feed_seed.sql`. The eye pill in the
feed shows `view_count`.

## Out of v1 scope

LIVE, Shop, Local, Following, Explore tabs. DMs/Inbox. Ad portal UI (separate project). Business billing. Follow graph (show 0s for now).
