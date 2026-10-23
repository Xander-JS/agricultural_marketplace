Use the **Impeccable** skill to execute **Phase 7B (Part 4 — Final Closeout): iOS-Style Redesign of Negotiations (Offer Chat), Privacy Modals and Star Rating, Purchases Module, and Unified Profile** in `agricultural_marketplace`.

## 1. CONTEXT, LIBRARIES AND STRICT RULES
- **Libraries installed in `pubspec.yaml`:** Actively use `lucide_icons_flutter`, `google_fonts`, `flutter_animate`, `shimmer`, and `cupertino_icons`.
- **Identity and Contrast:** Maintain the **KUS (KumpaSumaq)** brand, the Institutional Emerald palette (`#14532D` in Light / `#34D399` in Dark), and the perfect contrast rule in both themes.
- **PROHIBITED TO BREAK TESTS OR LOGIC:** Keep 536+ tests passing at 100%. DO NOT alter `NegotiationService`, `PurchasesService`, `ProfileService`, `ReviewService`, stock reserve/discount rules, or delete any existing `Key(...)` in the widgets.

---

## 2. DEALS, OFFER TIMELINE AND COUNTER-OFFERS (`lib/features/deals/`)
Refactor `deals_screen.dart`, `deal_detail_screen.dart`, and `counter_offer_screen.dart`:
1. **`DealsScreen` (Negotiations List):**
   - Style the top tab filter (*All*, *In Progress*, *Agreed*, *Completed*) with an iPhone sliding segmented control appearance (`CupertinoSlidingSegmentedControl` or animated high-contrast pills).
   - Each deal card must display the crop photo/icon, counterparty name, status with `StatusBadge`, last offered price in `COP`, quantity in `kg`, and a clear visual indicator when it's the user's turn (`"Your turn to respond"` with a glowing dot in primary or amber color).
2. **`DealDetailScreen` (iMessage / Apple Pay Style Negotiation Bubbles):**
   - **Deal Summary Header:** Fixed or collapsible top card with crop data, delivery modality (`LucideIcons.truck` / `LucideIcons.mapPin`), and current agreement status.
   - **Offer and Counter-Offer Bubbles:**
     * Offers sent by the current user ("You") are aligned to the right with a styled container in `primarySoft` (subtle emerald border and high-contrast text).
     * Counterparty offers (Farmer or Buyer) are aligned to the left on `surface` background with `border` border.
     * Inside each bubble, highlight the amount per kg and subtotal in large tabular typography, the quantity in `kg`, the optional message, and the formatted time/date.
   - **Turn-Based Action Bottom Bar:** When `isMyTurn == true`, present a bottom bar with a crystal effect that cleanly groups the buttons for **Accept Offer** (primary green), **Counter-Offer** (`CounterOfferScreen`), and **Reject** (subtle semantic red).

---

## 3. PRIVACY AND RATING FLOATING WINDOWS (`_AcceptOfferConsentSheet`, `_EditConsentSheet`, `_RatingSheet` in `deal_detail_screen.dart`)
Style the 3 internal modal sheets of `deal_detail_screen.dart` with iOS Floating Sheet anatomy (`BorderRadius.vertical(top: Radius.circular(28))`, top `Drag Handle`, and `surface` background):
1. **Data Consent Modal (`_AcceptOfferConsentSheet` and `_EditConsentSheet`):**
   - Header with `LucideIcons.shieldCheck` icon inside a soft emerald container explaining that the producer controls their privacy when closing the deal.
   - Present options to share **Phone / WhatsApp** (`LucideIcons.messageCircle` / `LucideIcons.phone`) and **Pickup location** (`LucideIcons.mapPin`) in iOS Settings-styled grouped rows with smooth switches (`Switch.adaptive`) and clear confirmation.
   - In the agreed deal details, when data has been authorized, display them in a prominent **"Released Commercial Contact"** card with clear icons.
2. **Post-Sale Rating and Reputation Modal (`_RatingSheet` / `lib/features/review/`):**
   - Clean, celebratory design upon completing a transaction: 5 large interactive stars (`CupertinoIcons.star_fill` / `CupertinoIcons.star`) in Harvest Amber (`#D97706` / `#FBBF24`) with a subtle scale animation on tap, optional comment field (`CustomTextField`), and primary submit button with micro-loader.

---

## 4. MERCHANT PURCHASES MODULE (`lib/features/purchases/`)
Refactor `purchases_screen.dart` and `purchase_card.dart`:
1. **Top Metric Cards (Buyer KPIs):**
   - Design the 3 summary cards (**Active agreements**, **Total agreed in COP**, **Total volume in kg**) as compact iOS financial widgets with `LucideIcons.handshake`, `LucideIcons.wallet`, and `LucideIcons.scale` icons, using tabular numbers to prevent overflows.
2. **`PurchaseCard` and Empty State:**
   - Clean cards with a `1px` border, status badge (*Agreed* / *Completed*), clear breakdown of unit price, total quantity in `kg`, producer, and delivery method.
   - If there are no purchases yet, display an illustrated empty state with `LucideIcons.shoppingBag` and a direct button to explore the marketplace.

---

## 5. UNIFIED PROFILE AND iOS-STYLE CONFIGURATION (`lib/features/profile/screens/farmer_profile_screen.dart`)
Refactor `farmer_profile_screen.dart` to look identical to the iPhone **Settings / Apple ID** panel:
1. **Identity Header:**
   - Large centered or aligned `UserAvatar` with verified status ring, floating camera button (`LucideIcons.camera`) to update photo in the `avatars` bucket (preserving `Key('change_avatar_button')` and anti-cache reload), full name in `Plus Jakarta Sans Bold` typography, role insignia (**Farmer** or **Buyer**), verification status (`StatusBadge`), and **Average Reputation (`★ 4.8` and total evaluated deals)** card.
2. **Commercial Activity Cards:**
   - Display dynamic counters (*Published*, *Negotiating*, *Closed*) in a row of 3 clean statistical blocks with `surface` background and a `1px` border.
3. **Grouped Sections (*iOS Inset Grouped Lists*):**
   - **Contact Data:** Inline editing of phone and email with `LucideIcons.phone` and `LucideIcons.mail` icons.
   - **Farmer Commercial Preferences (`farmer_settings`):** Rows with icons inside colored squircles (iOS Settings style) and switches for *Enable Early Sale*, *Share Phone*, *Share WhatsApp*, and *Share Location*.
   - **Appearance and Language (`AppPreferencesService`):** Instant reactive controls to toggle between **Light Mode / Dark Mode** (`LucideIcons.moon` / `LucideIcons.sun`) and **Spanish / English** language selector (`LucideIcons.globe`).
   - **Sign Out:** Bottom button styled with semantic danger color (`error`) and `LucideIcons.logOut` icon.

---

## 6. FINAL AUDIT AND PHASE 7B CLOSEOUT
1. Review the entire application to confirm that **no screen is left without the new iOS style**, no text has low contrast in Light or Dark Mode, and no visible appearance of the word "simulated" remains.
2. Run `flutter analyze` and confirm **0 errors and 0 warnings**.
3. Run the complete suite with `flutter test` and confirm that the **536+ automated tests pass at 100%**.
4. Deliver the final Phase 7B closeout report summarizing all embellished modules and test results.