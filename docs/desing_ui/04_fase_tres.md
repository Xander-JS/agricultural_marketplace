Use the **Impeccable** skill to execute **Phase 7B (Part 3): Transition Animations and Loading in the Dashboard, Commercial Catalog Redesign, AI Cost/Profitability Calculator, and Frosted Glass Floating Windows (iOS Frosted Glass)** in `agricultural_marketplace`.

## 1. CONTEXT, LIBRARIES AND STRICT RULES
- **Libraries installed in `pubspec.yaml`:** Actively use `lucide_icons_flutter`, `google_fonts`, `flutter_animate`, `shimmer`, and `cupertino_icons`.
- **Gold Rule of Contrast and Currency:** All prices in Colombian pesos (`COP`) and quantities in kilograms (`kg`) must use `FontFeature.tabularFigures()` for perfect banking alignment. No text can be white on a light background or dark on a dark background. Zero mentions of the word "simulated".
- **PROHIBITED TO BREAK TESTS OR LOGIC:** Keep 536+ tests passing at 100%. DO NOT alter mathematical formulas (`availableStock`, `CropCostCalculator`, margin over selling price), Supabase calls, or delete any existing `Key(...)`.

---

## 2. LOADING ANIMATION AND TRANSITION BETWEEN BAR SECTIONS (`lib/features/dashboard/screens/main_dashboard_screen.dart`)
When the farmer or buyer switches between the bottom bar sections (`AppBottomNavigation`: Marketplace, Costs, Deals, Purchases, Profile), the transition should feel like a native iPhone app:
1. In `MainDashboardScreen`, wrap the active tab body in an `AnimatedSwitcher` (duration `220ms`, curve `Curves.easeOutCubic`) that combines a `FadeTransition` with a slight vertical slide (`SlideTransition` from `Offset(0, 0.02)` to `Offset.zero`).
2. Verify that in each section (`MarketplaceScreen`, `CostsScreen`, `DealsScreen`, `PurchasesScreen`, `FarmerProfileScreen`), when the state is `isLoading == true`, the **Skeleton Loader with `Shimmer`** (`AppLoading` / `loading_content.dart`) with the structural silhouette of the cards is shown immediately, and upon loading completion, the items enter smoothly.
3. Add iOS-style bounce physics (`BouncingScrollPhysics`) to main lists and a primary-colored styled `RefreshIndicator`.

---

## 3. COMMERCIAL CATALOG, HARVEST CARDS AND DETAIL (`lib/features/crop/`)
Refactor `marketplace_screen.dart`, `crop_card.dart`, `crop_status_badge.dart`, `crop_detail_screen.dart`, and `publish_crop_screen.dart`:
1. **`MarketplaceScreen` (Farmer View and Buyer View):**
   - **iOS-style header:** Integrates the compact `KusBrandLogo`, title with strong typographic hierarchy, and a quick action button to publish a lot (manual or with `LucideIcons.mic` AI voice assistant).
   - **Buyer Search Bar and Filters:** Style the search bar as a `CupertinoSearchTextField` (`surfaceVariant` background, `LucideIcons.search` icon, `12px` radius) and sorting chips (*Most recent*, *Lowest price*, *Highest price*, *Reputation ★*) as touch pills that switch to `primary` background with `onPrimary` text when active.
   - **Empty State:** When there are no crops or the search yields no results, display a centered card with a `LucideIcons.wheatOff` or `LucideIcons.searchX` icon inside a soft circle, explanatory text, and a button to clear filters.
2. **`CropCard` (High-Impact Product Card):**
   - Apple Store / Instacart style card: `surface` background, `BorderRadius.circular(18)`, fine `1px` border of `border` color, zero dirty gray shadows.
   - **Image with Shimmer and Safe Contrast Badges:** While the crop photo loads, display `Shimmer`. Over the corner of the photo, place badges (`Early Sale` or lot status) inside a blur capsule (`BackdropFilter` blur + dark translucent background `#000000` at 65% + white text) so it is perfectly readable even if the crop photo is bright white.
   - **Data Hierarchy:** Bold title, location and distance chip (`LucideIcons.mapPin` + `Pasto • 12 km`), producer reputation badge (`★ 4.8` in amber color `#D97706` / `#FBBF24`), available stock in `kg`, and price per kilogram (`$ 2.400 / kg`) highlighted in `primary` color.
3. **`CropDetailScreen` and `PublishCropScreen`:**
   - **Carousel Gallery:** In `CropDetailScreen`, style the photo carousel with an iOS-style bottom dot indicator, publication date badge (*"Published on..."*), and, if applicable, a clearly differentiated estimated harvest date.
   - **Regional Reference Block (Nariño):** Present the price comparison against the Nariño reference as an informative market intelligence card (**"Nariño Regional Index • KUS AI"**) with a `LucideIcons.trendingUp` icon, `Info` semantic colors, and zero "simulated" words.
   - **Equivalences Trigger Button (Buyer):** Next to the quantity in `kg`, design an interactive pill-type button with a `LucideIcons.scale` icon (*"View equivalents in crates and baskets"*) that opens `UnitEquivalencesSheet`.

---

## 4. AI COST AND PROFITABILITY CALCULATOR (`lib/features/costs/`)
Refactor `costs_screen.dart`, `crop_costs_detail_screen.dart`, `add_crop_cost_screen.dart`, and `crop_profitability_screen.dart`:
1. **Expense Category Cards (`jornales`, `fertilizantes`, `transporte`, `otros`):**
   - Assign a professional `LucideIcons` icon inside a colored squircle container to each category:
     * `jornales`: `LucideIcons.users`
     * `fertilizantes`: `LucideIcons.flaskConical` / `LucideIcons.sprout`
     * `transporte`: `LucideIcons.truck`
     * `otros`: `LucideIcons.receiptText`
2. **Financial Summary and `CropProfitabilityScreen`:**
   - Design an *Apple Wallet / Robinhood* style summary panel highlighting **Total Cost**, the denominator used (`stock_total` vs `estimated_yield_kg`), and **Unit Cost per kg**.
   - On the profitability and suggested price screen, separate into clean cards: *Cost per kg*, *Target margin (%)*, *Suggested selling price*, and *Comparison with Nariño Regional Index*, using success green when there is profit and semantic coral red when the evaluated price generates a loss.

---

## 5. FROSTED GLASS FLOATING WINDOWS (`UnitEquivalencesSheet`, `MakeOfferSheet`, `VoiceCropAssistantSheet`)
Refactor `lib/features/crop/widgets/unit_equivalences_sheet.dart`, `lib/features/crop/widgets/make_offer_sheet.dart`, and `lib/features/ai_assistant/widgets/voice_crop_assistant_sheet.dart`:
1. **iOS Floating Anatomy in all 3 sheets:**
   - Top background with `BorderRadius.vertical(top: Radius.circular(28))`, `surface` surface, subtle `1px` top border, and drag handle (`36x5px`) in the top center.
2. **`UnitEquivalencesSheet` (Visual Converter for Buyer):**
   - Present the 4 equivalences (**Crates**, **Sacks**, **Boxes**, **Arrobas**) in a **2x2 grid or iOS-style grouped cards** (`surfaceVariant`, `16px` radius), each with its `LucideIcons` icon (`LucideIcons.shoppingBasket`, `LucideIcons.package`, `LucideIcons.box`, `LucideIcons.scale`), clear label, and large bold approximate value, plus a subtle note indicating that baseline negotiation is done in `kg`.
3. **`VoiceCropAssistantSheet` (AI Bimodal Voice Assistant):**
   - Design an immersive **Siri / Apple Intelligence** style interface: when listening or processing, the central microphone button (`LucideIcons.mic` / `LucideIcons.sparkles`) shows soft pulse concentric rings with `flutter_animate`.
   - Display clear guidance text for the farmer, transcription in a styled bubble, and detected fields in the draft with status chips (identified vs. pending review) before proceeding to `PublishCropScreen`.
4. **`MakeOfferSheet` (Commercial Offer Sheet):**
   - Quantity (`kg`) and price per `kg` (`COP`) fields with clean numeric keyboards, delivery method selector (`At farm`, `Agreed point`, `Carrier`) with `LucideIcons` icons, and a bottom card that live-calculates the **Total Offer in COP** before pressing the submit button.

---

## 6. MANDATORY VERIFICATION
1. Run `flutter analyze` and verify **0 errors and 0 warnings**.
2. Run `flutter test` and confirm that the **536+ tests pass at 100%**.
3. Give me a detailed summary of the files updated in this Part 3.