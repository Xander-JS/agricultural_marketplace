Use the **Impeccable** skill to execute **Phase 7B (Part 2): iOS-Style Redesign of Authentication, Password Recovery, Document Guide Scanner (`assets/images/`) and AI Moderation Panel** in `agricultural_marketplace`.

## 1. CONTEXT, LIBRARIES AND STRICT RULES
- **Libraries already installed in `pubspec.yaml`:** Actively use `lucide_icons_flutter`, `google_fonts`, `flutter_animate`, `shimmer`, and `cupertino_icons`.
- **Base Design System (created in Part 1):** Exclusively consume `AppColors`, `AppThemeColors`, the `Plus Jakarta Sans` typography, and the `KusBrandLogo` widget (`lib/core/widgets/brand/kus_brand_logo.dart`).
- **PROHIBITED TO BREAK TESTS OR LOGIC:** Keep 536+ tests passing at 100%. DO NOT alter services (`LoginService`, `RegistrationService`, `VerificationService`, `ModerationService`), models, navigation flows, or delete any existing `Key(...)` in the widgets.
- **ZERO BURNED TEXTS OR COLORS:** Every text must come from `AppLocalizations` (synchronized `app_es.arb` and `app_en.arb`) and no visible text can mention the word "simulated".

---

## 2. WELCOME, LOGIN AND PASSWORD RECOVERY (`lib/features/auth/login/` and `splash/welcome`)
Visually refactor `splash_screen.dart`, `welcome_screen.dart`, `topo_header.dart`, `login_screen.dart`, `forgot_password_screen.dart`, and `reset_password_screen.dart`:
1. **`TopoHeader` and KUS Brand Header:**
   - Style `TopoHeader` with an elegant, deep iOS-style gradient (using institutional green `#14532D` toward dark emerald tones with subtle topographic smooth curves) and center the `KusBrandLogo` widget in its `hero` variant (using `assets/images/app_movil_only_lg.png` or `xl.png` alongside the abbreviation **KUS — KumpaSumaq**).
2. **`LoginScreen`, `ForgotPasswordScreen` and `ResetPasswordScreen`:**
   - Organize forms inside iOS-style inset grouped cards (*Inset Grouped Cards*: `surface` background, `20px` radius, fine `1px` border of `border` color, zero messy shadows).
   - Use `LucideIcons` icons in text fields (`LucideIcons.phone`, `LucideIcons.mail`, `LucideIcons.lockKeyhole`, `LucideIcons.keyRound`).
   - In `ForgotPasswordScreen` and `ResetPasswordScreen`, add a clean illustrative header (icon inside a squircle with 15% `primarySoft` background) and status messages (error or submission confirmation) using the high-contrast triad (Soft background + 1px border + Strong text/icon).
   - Apply a subtle entry animation with `flutter_animate` (`fadeIn(duration: 220.ms).slideY(begin: 0.03, end: 0)`) to the form body.

---

## 3. MULTI-STEP REGISTRATION AND VISUAL DOCUMENT / FACE ID GUIDES (`lib/features/auth/registro/`)
Refactor `role_selection_screen.dart`, `personal_details_screen.dart`, `otp_verification_screen.dart`, `document_selection_screen.dart`, `document_selection_card.dart`, `capture_front_screen.dart`, `capture_back_screen.dart`, `facial_verification_screen.dart`, `document_upload_screen.dart`, `document_review_screen.dart`, `processing_screen.dart`, and `complete_registration_screen.dart`:
1. **Progress Bar (`step_progress_bar.dart`) and Role Selection:**
   - Style `StepProgressBar` as a fine, fluid iOS-style segmented bar with animated transition.
   - In `RoleSelectionScreen`, design the **Farmer / Producer** and **Commercial Buyer** cards with executive B2B aesthetics: large `LucideIcons` icons (`LucideIcons.sprout` and `LucideIcons.briefcaseBusiness`), a border that lights up in `primary` color when selected, and an iPhone-style check (`CupertinoIcons.checkmark_circle_fill`).
2. **"Apple Wallet / iOS Scanner" Style Design for `assets/images/` Guides:**
   - Document and facial capture screens use the guide assets: `assets/images/cc_frontal.png`, `assets/images/cc_reverso.png`, `assets/images/licencia_frontal.png`, `assets/images/licencia_reverso.png`, and `assets/images/face_id.png`.
   - Wrap each guide image inside a **Professional Scanner Viewfinder Frame**:
     * Container with `BorderRadius.circular(20)`, `surfaceVariant` background, `1.5px` border with highlighted corners in `primary` color (`#14532D` in light / `#34D399` in dark) and a floating high-contrast top chip with a `LucideIcons.scanLine` icon indicating the framing guide.
     * In `FacialVerificationScreen` (`assets/images/face_id.png`), present the guide image inside an iPhone-style biometric circular/oval frame, with a subtle emerald perimeter ring and clear tips (`TipPill` with guaranteed contrast).
     * When the user selects or takes their own photo, show the preview with clean cropping, a green success *"Document captured"* badge, and a styled secondary button to retake if they want to replace it.
3. **`ProcessingScreen` and `VerificationStatusScreen` (`lib/features/auth/verificacion/`):**
   - In `ProcessingScreen`: Replace the simple wait with a clean AI biometric/documentary verification animation featuring `KusBrandLogo` and an iOS-style micro-loader.
   - In `VerificationStatusScreen`: Design an executive status card for each case (`pending`, `ai_review`, `approved`, `rejected`, `suspended`) strictly using secure contrast pairs:
     * For `ai_review`: `LucideIcons.Cpu` / `LucideIcons.shieldCheck` icon in AI Sapphire Blue (`accentAi`), presenting the process as real AI-assisted validation under final review by moderation (zero mentions of "simulated").
     * For `rejected`: Clear alert with the rejection reason inside a semantic error container and a prominent primary button to correct and resubmit documents.

---

## 4. ADMIN / MODERATOR PANEL (`lib/features/moderation/`)
Refactor `moderation_queue_screen.dart`, `moderation_detail_screen.dart`, `document_image_preview.dart`, and `simulated_document_diagnosis_card.dart`:
1. **Moderation Queue (`ModerationQueueScreen`):**
   - Clean iOS-style header with request counter and `RefreshIndicator` support.
   - Each request in an executive card with `UserAvatar`, role chip (Farmer/Buyer), formatted date, status with `StatusBadge`, and `CupertinoIcons.chevron_right` arrow.
   - While loading the list, show the `loading_content.dart` `Shimmer` skeleton.
2. **Support Viewer (`DocumentImagePreview`) with Shimmer:**
   - Display the 3 images (Front, Back, and Selfie) in cards with `16px` borders. While downloading from Supabase Storage, show an elegant `Shimmer` placeholder; tapping an image allows viewing it clearly.
3. **Transformation of `SimulatedDocumentDiagnosisCard` into "KUS Vision AI" Panel:**
   - Keep the file and class name (`SimulatedDocumentDiagnosisCard`) and all its `Key`s so as not to break any tests, but **redesign its appearance as an Executive Telemetry and AI Verification Panel**:
     * Header with `LucideIcons.sparkles` / `LucideIcons.scanFace` icon in AI Sapphire Blue (`#0284C7` in light mode / `#38BDF8` in dark mode), soft `infoSurface` background, and `1px` border.
     * Present indicators (uploaded documents, profile data match, legibility, and review status) via clean iOS-style rows with verification icons (`LucideIcons.circleCheck`, `LucideIcons.clock`, `LucideIcons.triangleAlert`).
     * Manual action buttons for the moderator (**Approve Profile** in primary green and **Reject with reason** in semantic red) with integrated micro-loaders when executing the decision.

4. In `simulated_document_diagnosis_card.dart` (and its keys in `app_es.arb` / `app_en.arb`, updating any tests that validate those strings), also replace the limitation bullets so they sound like executive AI technical notes (e.g., "KUS Vision-assisted verification completed", "Biometric and document pre-validation ready for the moderator's final ruling"), and correct any white text on `appSuccess` in the screens of this phase by using `onPrimary` or the `AppColors` contrast pairs.

---

## 5. MANDATORY VERIFICATION
1. Run `flutter analyze` and ensure you have **0 errors and 0 warnings**.
2. Run `flutter test` and confirm that the **536+ automated tests pass at 100%**.
3. Give me a concise summary of the files updated in this Part 2.