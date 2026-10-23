import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/delivery_methods.dart';
import '../../../core/localization/app_localizations.dart';

/// Icon and short localized label for a delivery method, whatever form it
/// arrives in (UI label, database value or free text).
({IconData icon, String label}) deliveryPresentation(
  AppLocalizations l10n,
  String method,
) {
  return switch (DeliveryMethod.fromString(method)) {
    DeliveryMethod.enFinca => (
      icon: LucideIcons.tractor,
      label: l10n.offer_sheet_delivery_farm,
    ),
    DeliveryMethod.puntoAcordado => (
      icon: LucideIcons.mapPinned,
      label: l10n.offer_sheet_delivery_point,
    ),
    DeliveryMethod.transportadora => (
      icon: LucideIcons.truck,
      label: l10n.offer_sheet_delivery_carrier,
    ),
  };
}

/// Text to show for a stored delivery method: database codes (`en_finca`)
/// become their localized label; anything the parties wrote themselves is
/// shown as written.
String deliveryDisplayLabel(AppLocalizations l10n, String method) {
  final raw = method.trim();
  final isDbCode = DeliveryMethod.values.any((m) => m.dbValue == raw);
  return isDbCode ? deliveryPresentation(l10n, raw).label : raw;
}
