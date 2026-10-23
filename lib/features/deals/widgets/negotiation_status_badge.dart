import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/badges/status_badge.dart';
import '../models/negotiation_status.dart';

/// Accent and mark of a negotiation status, shared by every surface that
/// shows one (deal list, deal detail, purchases).
///
/// Every label sits on the same neutral wash; hue lives only in the text
/// and its micro-icon: slate while pending, amber on a counter-offer,
/// brand green once agreed or completed, red when rejected or cancelled.
/// Red and amber use their AA-safe text tones so the small label stays
/// legible on the gray wash.
({Color accent, IconData icon}) negotiationStatusStyle(
  BuildContext context,
  NegotiationStatus status,
) {
  final amber = context.appIsDark
      ? context.appSecondary
      : AppColors.warningTextLight;
  return switch (status) {
    NegotiationStatus.propuesta => (
      accent: context.appTextSecondary,
      icon: LucideIcons.clock,
    ),
    NegotiationStatus.contraofertada => (
      accent: amber,
      icon: LucideIcons.arrowLeftRight,
    ),
    NegotiationStatus.acordada => (
      accent: context.appPrimary,
      icon: LucideIcons.handshake,
    ),
    NegotiationStatus.completada => (
      accent: context.appPrimary,
      icon: LucideIcons.checkCheck,
    ),
    NegotiationStatus.rechazada => (
      accent: context.appErrorText,
      icon: LucideIcons.circleX,
    ),
    NegotiationStatus.cancelada => (
      accent: context.appErrorText,
      icon: LucideIcons.ban,
    ),
  };
}

/// [StatusBadge] for a negotiation. [label] overrides the status name where
/// a screen words it differently (purchases use "Acordada"/"Completada").
class NegotiationStatusBadge extends StatelessWidget {
  final NegotiationStatus status;
  final String? label;

  const NegotiationStatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final style = negotiationStatusStyle(context, status);

    return StatusBadge(
      text: label ?? status.toDisplayName(),
      icon: style.icon,
      backgroundColor: context.appSurfaceVariant,
      textColor: style.accent,
      borderColor: AppColors.transparent,
    );
  }
}
