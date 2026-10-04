import 'package:flutter/widgets.dart';

/// Centralized dimensions, paddings, margins, border radii, and icon/component sizes.
abstract final class AppDimensions {
  // ---------------------------------------------------------
  // Base Spacing Scale
  // ---------------------------------------------------------
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;

  // ---------------------------------------------------------
  // Padding & Insets Helpers
  // ---------------------------------------------------------
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingAll4 = EdgeInsets.all(space4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(space8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(space12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(space16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(space20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(space24);

  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space20,
  );
  static const EdgeInsets paddingScreenHorizontal = EdgeInsets.symmetric(
    horizontal: space16,
  );

  static const EdgeInsets paddingCard = EdgeInsets.all(space16);
  static const EdgeInsets paddingDialog = EdgeInsets.all(space24);

  static const EdgeInsets paddingButtonSmall = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space8,
  );
  static const EdgeInsets paddingButtonMedium = EdgeInsets.symmetric(
    horizontal: space20,
    vertical: space12,
  );
  static const EdgeInsets paddingButtonLarge = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space16,
  );

  // ---------------------------------------------------------
  // Border Radius Values
  // ---------------------------------------------------------
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // BorderRadius Helpers
  static final BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // ---------------------------------------------------------
  // Component Dimensions & Heights
  // ---------------------------------------------------------
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  static const double inputHeight = 52.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavBarHeight = 64.0;
  static const double cardElevation = 1.0;
  static const double dialogElevation = 6.0;

  // ---------------------------------------------------------
  // Icon Sizes
  // ---------------------------------------------------------
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 40.0;

  // ---------------------------------------------------------
  // Border & Divider Widths
  // ---------------------------------------------------------
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double dividerThickness = 1.0;
}
