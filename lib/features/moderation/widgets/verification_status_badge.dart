import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/constants/user_roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/badges/status_badge.dart';

/// Badge for a verification status, shared by the queue and the detail.
///
/// Open states (pending, in review) stay graphite; only outcomes carry
/// hue: emerald for approved, the error ink for rejected or suspended.
StatusBadge verificationStatusBadge(
  BuildContext context,
  UserVerificationStatus status, {
  Key? key,
  String? label,
}) {
  final (StatusBadgeTone? tone, IconData icon) = switch (status) {
    UserVerificationStatus.pendiente => (null, LucideIcons.clock),
    UserVerificationStatus.enRevisionIa => (null, LucideIcons.scanEye),
    UserVerificationStatus.aprobado => (
      StatusBadgeTone.brand,
      LucideIcons.badgeCheck,
    ),
    UserVerificationStatus.rechazado => (
      StatusBadgeTone.error,
      LucideIcons.circleX,
    ),
    UserVerificationStatus.suspendido => (
      StatusBadgeTone.error,
      LucideIcons.ban,
    ),
    UserVerificationStatus.desconocido => (null, LucideIcons.circleHelp),
  };
  return StatusBadge(
    key: key,
    text: label ?? status.displayName,
    icon: icon,
    tone: tone,
    backgroundColor: context.appSurfaceVariant,
    textColor: context.appTextSecondary,
    borderColor: context.appBorder,
  );
}

/// Local date and time of a request, e.g. "20 oct 2026 · 14:32".
String formatModerationDate(BuildContext context, DateTime date) {
  DateFormatters.ensureInitialized();
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMM y · HH:mm', locale).format(date.toLocal());
}
