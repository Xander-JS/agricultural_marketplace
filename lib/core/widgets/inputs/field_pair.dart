import 'package:flutter/material.dart';

import '../../theme/app_dimensions.dart';

/// Two form fields side by side, stacked when the user's text size is
/// large enough that half-width fields would truncate their labels.
class FieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const FieldPair({super.key, required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: AppDimensions.space12),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppDimensions.space12),
        Expanded(child: second),
      ],
    );
  }
}
