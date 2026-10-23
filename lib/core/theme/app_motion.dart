import 'package:flutter/widgets.dart';

/// Motion tokens for KUS.
///
/// UI motion stays under 300ms and uses strong ease-out curves: elements
/// respond immediately and settle softly. Press feedback is asymmetric
/// (quick press, slightly slower release). Everything collapses to
/// [Duration.zero] movement when the user enables Reduce Motion.
abstract final class AppMotion {
  // ---------------------------------------------------------
  // Durations
  // ---------------------------------------------------------
  static const Duration press = Duration(milliseconds: 110);
  static const Duration release = Duration(milliseconds: 220);
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 280);

  /// Brand entrances (splash, welcome) are seen rarely, so they may take a
  /// little longer than UI feedback.
  static const Duration entrance = Duration(milliseconds: 420);

  /// One full shimmer sweep across a skeleton.
  static const Duration shimmerPeriod = Duration(milliseconds: 1400);

  /// Cross-fade and short rise of a bottom-bar section when it becomes
  /// active.
  static const Duration tabSwitch = Duration(milliseconds: 220);

  /// Gap between consecutive items of a staggered list entrance.
  static const Duration staggerStep = Duration(milliseconds: 45);

  /// Only the first few items of a list stagger; the rest would arrive
  /// after the user has already started reading.
  static const int staggerMaxItems = 6;

  // ---------------------------------------------------------
  // Curves
  // ---------------------------------------------------------
  /// Strong ease-out, cubic-bezier(0.23, 1, 0.32, 1).
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out for elements moving on screen.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS sheet/drawer curve, cubic-bezier(0.32, 0.72, 0, 1).
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Scale applied to pressable surfaces while a pointer is down.
  static const double pressedScale = 0.97;

  /// iOS rubber-band scrolling that still allows pull-to-refresh when the
  /// content is shorter than the viewport.
  static const ScrollPhysics scrollPhysics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  /// True when the platform asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when Reduce Motion is on.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
