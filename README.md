# Maduro

A social app for cigar enthusiasts. TikTok-style For You feed, cigar-shaped reactions, auto-detection of cigar lounges via Apple Maps, and a separate ad portal for verified business accounts.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-informational)
![Backend](https://img.shields.io/badge/backend-Supabase-3ECF8E)

## Features

- **For You feed** — vertical swipeable video/photo posts.
- **Cigar reaction** — a cigar icon replaces the heart/like.
- **Auto location** — Apple Maps (MKLocalSearch) finds cigar lounges, shops, and tobacconists near you and auto-suggests them when you post.
- **Cigar tagging** — tag the exact brand/line/vitola from a curated catalog.
- **Age gate** — date-of-birth check at signup, 21+ only.
- **Business accounts** — verified badge + ability to run ads from a separate portal.
- **Free tier ads** — injected every 4–10 posts, minimum 4-post gap between ads.

## Stack

- iOS 17+ SwiftUI app
- Supabase for auth, database, storage
- Apple MapKit for location + nearby-store search
- TestFlight distribution via `scripts/ship.sh`

## Local setup

```bash
# 1. Install tooling
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3. Create your local config (gitignored)
cp Maduro/Config.swift.example Maduro/Config.swift
# edit Maduro/Config.swift with your Supabase URL + anon key

# 4. Open
open Maduro.xcodeproj
```

## Shipping

After every change:

```bash
git add -A
git commit -m "..."
git push origin main
./scripts/ship.sh
```

`ship.sh` bumps the build number, archives, exports, and uploads to TestFlight. Requires `scripts/asc-config.env` (gitignored) — copy from `scripts/asc-config.env.example` and fill in your App Store Connect API key.

## Secrets

Never commit secret-bearing files. The `.gitignore` covers `Config.swift`, `.env*`, `*Secrets*`, `AuthKey_*.p8`, etc. If you add a new kind of secret, add it to `.gitignore` first.
