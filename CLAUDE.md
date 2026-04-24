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
│   ├── MainTabView.swift      # 3-tab shell (For You / Post / Profile)
│   ├── AuthView.swift         # sign in / sign up with 21+ DOB gate
│   ├── ForYouView.swift       # vertical swipeable feed, cigar reactions
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
├── scripts/
│   ├── ship.sh                # archive + upload to TestFlight
│   └── asc-config.env.example # copy to asc-config.env (gitignored) with ASC creds
├── ExportOptions.plist        # app-store-connect export, team CG89RY4W6R
├── README.md
├── CLAUDE.md                  # this file
└── .gitignore
```

## Design rules

- **Reactions:** cigar icon, never a heart. See `CigarReactionButton.swift`.
- **Location:** Apple Maps only (no Google Places). `MKLocalSearch` with keyword queries since there's no `tobacco_shop` POI category. Radius 400m. Deduplicate by coordinate.
- **Ads:** serve only from the user's own ad portal. No AdMob / Meta. Placement: random gap ∈ [4,10] posts, min gap 4. Subscribed users see no ads.
- **Age gate:** DOB picker at signup, computed age must be ≥ 21. Do not ship a "tick to confirm 21+" checkbox alone.
- **App Store positioning:** community/review app. Do not add in-app tobacco purchase flows — Apple rejects tobacco-sales apps.
- **Bundle ID:** `com.divinedavis.stogie`. Team: `CG89RY4W6R`.

## Out of v1 scope

LIVE, Shop, Local, Following, Explore tabs. DMs/Inbox. Ad portal UI (separate project). Business billing. Follow graph (show 0s for now).
