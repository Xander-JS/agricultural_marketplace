# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Flutter app shipped to Android and iOS with one iOS-leaning design language (Apple HIG conventions rendered on both platforms).

## Users

- **Agricultores (farmers):** smallholder producers in Nariño, Colombia who publish harvests, track production costs and profitability, and negotiate deals.
- **Compradores / comerciantes (buyers):** traders who browse the market, negotiate deals and follow purchases.
- **Moderadores:** staff who review identity documents and approve or reject accounts.

## Product Purpose

KUS lets farmers and buyers trade crops directly, without intermediaries, with verified identities on both sides. Success means a farmer can price a harvest with confidence and close a deal with a verified buyer.

## Positioning

Direct agricultural trade for the Nariño highlands: verified identities, cost-aware pricing for farmers, and regional price references in one app.

## Operating Context

- Spanish-first UI (English secondary), prices in COP.
- Used outdoors and on mid-range Android phones; connectivity can be weak in rural areas.
- The project is presented at a university project review.

## Capabilities and Constraints

- Backend: Supabase (auth, Postgres, storage). Calls, models, services and test-required constructors must not change during visual work.
- 536+ automated tests must stay green; existing widget `Key`s are contracts.
- All user-visible copy lives in `lib/core/localization/app_es.arb` / `app_en.arb`; all colors come from `AppColors` / `AppThemeColors`.

## Brand Commitments

- Name: **KUS** (commercial synthesis of KumpaSumaq / Kumaq). Slogan: "KumpaSumaq • Direct Agricultural Trade".
- Isotype assets: `assets/images/app_movil_only_{sm,lg,xl}.png`, `assets/images/app_movil_icon.png` (white silhouette, tinted per theme).
- User-facing screens never show the words "simulado", "simulada", "ficticio" or "demostración".

## Evidence on Hand

- Regional price references for Nariño are an internal projection catalogue, not official market quotes; no external source or observation date may be attributed to them.
- No testimonials, customer counts or market statistics exist; none may be invented.

## Product Principles

1. Trust before transaction: identity verification and human moderation stay visible.
2. Numbers must be legible: prices and costs read at a glance, aligned and unambiguous.
3. Field-ready: works for people with limited time, bright sunlight and modest devices.
4. Native feel over novelty: familiar iOS patterns beat invented controls.

## Accessibility & Inclusion

Target WCAG AAA contrast for body text where the palette allows; never light text on a light ground. Honor the system Reduce Motion setting.
