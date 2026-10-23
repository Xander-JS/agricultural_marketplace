import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';
import 'app_entrance.dart';

/// Staggered list entrance: each item fades in and rises 10px,
/// [AppMotion.staggerStep] after the previous one.
///
/// Built on [AppEntrance], whose delay lives inside the animation timeline,
/// so a list that mounts and settles never leaves timers behind. Only the
/// first [AppMotion.staggerMaxItems] items animate and only while
/// [enabled]; screens turn it off once the first page has landed so items
/// recycled by a lazy list never replay the entrance. Reduce Motion is
/// honored by [AppEntrance].
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final bool enabled;
  final Widget child;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || index >= AppMotion.staggerMaxItems) return child;

    return AppEntrance(
      delay: AppMotion.staggerStep * index,
      duration: AppMotion.emphasized,
      offsetY: 10,
      child: child,
    );
  }
}
