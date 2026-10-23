import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// One option of an [AppSegmentedControl].
@immutable
class AppSegment {
  final String label;
  final IconData? icon;

  /// Marks the segment with a small Harvest Amber dot, e.g. a filter that
  /// holds deals waiting on the user.
  final bool showDot;

  const AppSegment({required this.label, this.icon, this.showDot = false});
}

/// iOS sliding segmented control on the KUS tokens.
///
/// The thumb slides on Cupertino's own spring, so a rapid second tap
/// retargets it mid-flight instead of restarting. The selected label gains
/// weight and ink; the rest stay on secondary text, which keeps every
/// segment legible in both modes.
class AppSegmentedControl<T extends Object> extends StatelessWidget {
  final T value;
  final Map<T, AppSegment> segments;
  final ValueChanged<T> onChanged;

  /// Compact controls sit at the trailing edge of a settings row.
  final bool compact;

  const AppSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<T>(
      groupValue: value,
      backgroundColor: context.appSurfaceVariant,
      thumbColor: context.appSegmentThumb,
      padding: const EdgeInsets.all(3),
      onValueChanged: (next) {
        if (next == null || next == value) return;
        HapticFeedback.selectionClick();
        onChanged(next);
      },
      children: {
        for (final entry in segments.entries)
          entry.key: _SegmentLabel(
            segment: entry.value,
            selected: entry.key == value,
            compact: compact,
          ),
      },
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final AppSegment segment;
  final bool selected;
  final bool compact;

  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.appTextPrimary : context.appTextSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimensions.space8 : AppDimensions.space4,
        vertical: compact ? 7 : 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (segment.icon != null) ...[
            Icon(segment.icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (segment.showDot) ...[
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.appWarning,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
