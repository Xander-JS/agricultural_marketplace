Use the **Impeccable** skill to perform **Phase 7B (Part 1): iOS Global Visual System Redesign (Apple HIG), KUS Brand Identity, Removal of Simulation Labels and Atomic Components with Shimmer/Animations** in the `agricultural_marketplace` Flutter project.

## 1. CONTEXT AND UNBREAKABLE CONSTRAINTS
- The following libraries are already installed in `pubspec.yaml`: `lucide_icons_flutter`, `google_fonts`, `flutter_animate`, `shimmer`, and `cupertino_icons`. Use them actively.
- **PROHIBITED TO BREAK TESTS OR LOGIC:** The project has 536 tests passing at 100%. DO NOT modify Supabase calls, models, services, constructors required by tests, or delete any existing `Key(...)` in the widgets.
- **ZERO BURNED COLORS AND ZERO BURNED TEXT:** Every new or modified text must go into `lib/core/localization/app_es.arb` and `lib/core/localization/app_en.arb` (and regenerate/update the `app_localizations*.dart` files). Every color must come from `AppColors` / `AppThemeColors`.

---

## 2. OFFICIAL BRAND IDENTITY: "KUS" (KumpaSumaq / Kumaq)
1. **Replacement of the app name in localization (`app_es.arb` and `app_en.arb`):**
   - The official platform name is **KUS** (commercial synthesis of **KumpaSumaq** / **Kumaq**).
   - Update the application title in `main.dart` and the welcome/header keys in `.arb` to reflect the **KUS** brand and the commercial slogan **"KumpaSumaq • Direct Agricultural Trade"**.
2. **Create the Atomic Logo Widget (`lib/core/widgets/brand/kus_brand_logo.dart`):**
   - Use the existing assets in `assets/images/`: `app_movil_only_sm.png`, `app_movil_only_lg.png`, `app_movil_only_xl.png`, and `app_movil_icon.png`.
   - Design a versatile `KusBrandLogo` widget (with `compact`, `header`, and `hero` variants) that combines the isotype from `assets/images/app_movil_only_*.png` inside an iOS-style squircle container (`BorderRadius.circular(14)`, with a subtle border and adaptive background to guarantee perfect contrast on both light and dark backgrounds or over the `TopoHeader`) along with the typographic logotype **"KUS"** rendered with `GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, letterSpacing: -0.8)` and an optional badge or subtitle **"KUMPA SUMAQ"**.
   - Integrate it into `SplashScreen`, `WelcomeScreen`, `TopoHeader` (`LoginScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen`), and `CustomAppBar`.

---

## 3. TOTAL REMOVAL OF THE WORD "SIMULATED" (PRESENTATION OF REAL AI)
For the final presentation of the project, the interface must NOT show the word "simulado", "simulada", "ficticio", or "demostración" on any screen.
1. In `lib/core/localization/app_es.arb`, `app_en.arb`, and their generated files (`app_localizations_es.dart`, `app_localizations_en.dart`), as well as in any default text in:
   - `lib/features/moderation/widgets/simulated_document_diagnosis_card.dart`
   - `lib/features/auth/verificacion/screens/verification_status_screen.dart`
   - `lib/features/costs/screens/crop_profitability_screen.dart`
   - `lib/features/crop/screens/crop_detail_screen.dart`
   - `lib/features/costs/data/simulated_regional_price_references.dart` (only the visible texts/disclaimers, keeping class and method names intact so as not to break tests; if a test checks a specific text, update the test expectation only if essential or check first what the test verifies). *Critical note: First check with grep in `test/` which exact strings of "simulado" are validated by asserts in `test/` to adjust or maintain 100% compatibility with the test suite.*
2. Replace user-visible terminology with executive AI language:
   - Instead of *"Diagnóstico SIMULADO"* -> **"AI Biometric & Document Analysis • KUS Vision"**.
   - Instead of *"Diagnóstico simulado en revisión..."* -> **"Preliminary AI analysis completed; your account is under final review by a moderator."**
   - Instead of *"Referencia simulada para demostración; no corresponde a un precio oficial..."* -> **"Regional reference index (Nariño) • KUS AI market projection."**

---

## 4. iOS-STYLE GLOBAL DESIGN SYSTEM ("APPLE AGRI-FINTECH") AND WCAG AAA CONTRAST
Refactor `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart`:
1. **Semantic Palette with Guaranteed Contrast (Zero white text on light background):**
   - **Light Mode (`Light`):**
     * `background`: `#F4F6F4` (iOS System Grouped Background, never pure white so cards stand out).
     * `surface` (Cards/Modals): `#FFFFFF` with a fine `1px` border of color `#E2E8F0` and `elevation: 0`.
     * `surfaceVariant` (Inputs/Inactive Chips): `#E8ECE9`.
     * `primary`: `#14532D` (Institutional Forest Green) -> Text over primary (`onPrimary`): `#FFFFFF` (Pure white).
     * `primarySoft`: `#DCFCE7` -> Text over `primarySoft`: `#14532D`.
     * `secondary` (Harvest Amber): `#D97706` | `accentAi` (Sapphire Blue AI): `#0284C7`.
     * `textPrimary`: `#111827` | `textSecondary`: `#4B5563` | `textMuted`: `#6B7280`.
   - **Dark Mode (`Dark` - Inverse with high contrast):**
     * `background`: `#0B110E` (Forest Obsidian).
     * `surface` (Cards/Modals): `#151F1A` with a fine `1px` border of color `#26352D` and `elevation: 0`.
     * `surfaceVariant`: `#1F2D26`.
     * `primary`: `#34D399` (Apple Luminous Emerald) -> Text over primary (`onPrimary`): `#062E1E` (Deep Charcoal Green, NEVER white on bright mint green).
     * `primarySoft`: `#064E3B` -> Text over `primarySoft`: `#6EE7B7`.
     * `secondary`: `#FBBF24` | `accentAi`: `#38BDF8`.
     * `textPrimary`: `#F3F4F6` | `textSecondary`: `#9CA3AF` | `textMuted`: `#6B7280`.
   - **Semantic States (Mandatory triad: Soft background + 1px border + Strong text/icon):**
     * `Error`: Light (`bg: #FEF2F2`, `border: #FECACA`, `fg: #DC2626`) | Dark (`bg: #2A1215`, `border: #7F1D1D`, `fg: #F87171`).
     * `Info / AI`: Light (`bg: #F0F9FF`, `border: #BAE6FD`, `fg: #0284C7`) | Dark (`bg: #0C2536`, `border: #0369A1`, `fg: #38BDF8`).
     * `Warning`: Light (`bg: #FFFBEB`, `border: #FDE68A`, `fg: #D97706`) | Dark (`bg: #29200B`, `border: #78350F`, `fg: #FBBF24`).
     * `Success`: Light (`bg: #F0FDF4`, `border: #BBF7D0`, `fg: #15803D`) | Dark (`bg: #0D2818`, `border: #14532D`, `fg: #4ADE80`).
2. **Typography and iOS Geometry in `AppTheme`:**
   - Configure `GoogleFonts.plusJakartaSansTextTheme()` as the typographic base, activating `FontFeature.tabularFigures()` on numerical and price styles for perfect financial alignment.
   - Configure `BottomSheetThemeData` with `backgroundColor: Colors.transparent` or surface with `BorderRadius.vertical(top: Radius.circular(28))`, and `SnackBarThemeData` with `behavior: SnackBarBehavior.floating`, rounded borders (`16px`), and elegant iOS capsule-style margins.
   - Configure iOS-style page transitions (`CupertinoPageTransitionsBuilder`) for Android and iOS in `PageTransitionsTheme`.

---

## 5. REFACTORING OF ATOMIC COMPONENTS (`lib/core/widgets/`) AND CONTEXTUAL LOADERS
Update all shared components in `lib/core/widgets/` while preserving their constructors, properties, and `Key`s:
1. **`app_bottom_navigation.dart`:**
   - iOS bottom bar style with glass effect (`ClipRRect` + `BackdropFilter` subtle blur or surface with top border of `1px`), professional `LucideIcons` iconography (`LucideIcons.store` / `LucideIcons.sprout`, `LucideIcons.chartNoAxesCombined`, `LucideIcons.handshake`, `LucideIcons.packageCheck`, `CupertinoIcons.person_crop_circle`), and a `200ms` scale/color micro-animation when selecting a tab.
2. **`loading_content.dart` and `loading_indicator.dart` (Component Loaders):**
   - In `loading_indicator.dart`: Use a refined iOS-style indicator (`CupertinoActivityIndicator` or styled spinner with primary color).
   - In `loading_content.dart`: Implement a **Skeleton Loader with `Shimmer`** that renders aesthetic skeleton cards (simulating headers and content blocks with `16px` borders) instead of an empty screen with a spinning circle, keeping any `CircularProgressIndicator` hidden or compatible if a widget test looks for it by type. *(Check in `test/` if any test does `find.byType(CircularProgressIndicator)` and, if so, include a styled `18px` `CircularProgressIndicator` in the Shimmer header so the test passes 100% while the user sees the full Shimmer Skeleton).*
3. **`primary_action_button.dart` and `camera_button.dart`:**
   - Comfortable height (`52px`), `BorderRadius.circular(14)`, strict contrast pair (`primary` + `onPrimary`), subtle tactile feedback, and integrated micro-loader when in `isLoading` state.
4. **`status_badge.dart`, `altitude_badge.dart`, `tip_pill.dart`:**
   - Apply the semantic triad (Soft background + `1px` border + High contrast text + Small `LucideIcons` icon). Never white text on a light background.
5. **`custom_text_field.dart`:**
   - iOS grouped input style: `surfaceVariant` fill, `14px` radius, transparent border at rest, and `1.5px` border of `primary` color when focused (`focusedBorder`), with clean icons.
6. **`user_avatar.dart` and `product_card.dart` / `seller_details_box.dart`:**
   - For network images (`Image.network`), show an elegant `Shimmer` effect in `loadingBuilder` while downloading bytes from Supabase Storage and a clean fallback with `LucideIcons` in `errorBuilder`.

---

## 6. MANDATORY VERIFICATION
1. Run `flutter analyze` and fix any warnings or errors.
2. Run `flutter test` and verify that the **536+ tests continue passing at 100%**. If any unit/widget test literally looked for the substring `"simulado"` or `find.byType(CircularProgressIndicator)`, precisely adjust so that both the new professional UI and the test suite are green.
3. Give me a detailed summary of the files updated in this Part 1.