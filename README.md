<p align="center">
  <img src="images/banner.svg" alt="Maduro — a social club for cigar enthusiasts" width="100%"/>
</p>

# Maduro

A social app for cigar enthusiasts. TikTok-style For You feed, cigar-shaped reactions, auto-detection of cigar lounges via Apple Maps, and a separate ad portal for verified business accounts.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-informational)
![Backend](https://img.shields.io/badge/backend-Supabase-3ECF8E)

## Features

- **For You feed** — vertical, full-screen paging feed of videos and photos with looping playback.
- **Cigar reactions** — a cigar icon replaces the heart; tap to "light it" and the ember glows red.
- **Cigar catalog** — tag the exact brand, line, and vitola from a curated list of popular cigars.
- **Cigar detail + reviews** — Airbnb-style review screen with a big rating, laurel wreaths, and community reviews.
- **Search** — searchable cigar index that pushes into detail pages.
- **Auto location** — Apple MapKit (`MKLocalSearch`) finds nearby cigar lounges, tobacconists, and shops and auto-suggests them when you post.
- **21+ age gate** — DOB picker at signup, enforced client-side.
- **Business accounts** — verified badge and the ability to run ads from a separate portal.
- **Ads** — injected every 4–10 posts with a minimum 4-post gap; served from the user's own ad portal (no AdMob / Meta).
- **Animated splash** — custom SwiftUI ember + smoke background; no external assets or Lottie.
- **Persistent session** — auth state survives cold starts via `UserDefaults`-backed `SessionStore`.

## Stack

- **UI:** SwiftUI, iOS 17+
- **Backend:** Supabase (auth, Postgres, storage)
- **Location:** Apple MapKit + CoreLocation
- **Media:** `AVQueuePlayer` + `AVPlayerLooper` for muted looping video
- **Project:** xcodegen (`project.yml` is the source of truth)

## Screens

- **Splash** — animated cigar-smoke background, logo, wordmark, and email / Apple continue buttons.
- **Email auth** — sign-in by default; toggle to sign-up with animated field transitions.
- **Age gate** — DOB, display name, and personal/business account type.
- **For You** — vertical paging feed with cigar reactions, captions, and injected sponsored posts.
- **Comments** — bottom-sheet thread with centered title and a full-width composer.
- **Search** — searchable cigar catalog → detail.
- **Cigar detail** — rating, stats, review list.
- **Profile** — Airbnb "Meet your host" style hero card with fact rows.

## Design rules

- Reactions are a cigar icon — never a heart.
- Location search is Apple Maps only.
- Ads are served only from the user's own ad portal — no AdMob or Meta SDKs.
- Age gate uses DOB, not a "21+" checkbox.
- App Store positioning is community/review — no in-app tobacco purchase flows.

## Out of v1 scope

LIVE, Shop, Local, Following, and Explore tabs. DMs / Inbox. Ad portal UI (separate project). Business billing. Follow graph (counts shown as 0 for now).

## Secrets

Never commit secret-bearing files. The `.gitignore` covers `Config.swift`, `.env*`, `*Secrets*`, `AuthKey_*.p8`, and similar patterns. If you add a new kind of secret, add it to `.gitignore` first.
