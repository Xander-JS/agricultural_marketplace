import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/badges/status_badge.dart';
import '../models/negotiation_status.dart';

/// Tone and mark of a negotiation status, shared by every surface that
/// shows one (deal list, deal detail, purchases).
///
/// Live states carry a hue (pending blue, counter-offer amber, agreed
/// green, rejected red); closed history (completed, cancelled) stays
/// neutral so the eye lands on what still needs work.
({StatusBadgeTone? tone, IconData icon}) negotiationStatusStyle(
  NegotiationStatus status,
) {
  return switch (status) {
    NegotiationStatus.propuesta => (
      tone: StatusBadgeTone.info,
      icon: LucideIcons.clock,
    ),
    NegotiationStatus.contraofertada => (
      tone: StatusBadgeTone.warning,
      icon: LucideIcons.arrowLeftRight,
    ),
    NegotiationStatus.acordada => (
      tone: StatusBadgeTone.success,
      icon: LucideIcons.handshake,
    ),
    NegotiationStatus.completada => (tone: null, icon: LucideIcons.checkCheck),
    NegotiationStatus.rechazada => (
      tone: StatusBadgeTone.error,
      icon: LucideIcons.circleX,
    ),
    NegotiationStatus.cancelada => (tone: null, icon: LucideIcons.ban),
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
    final style = negotiationStatusStyle(status);
    final neutral = context.appNeutralTriad;

    return StatusBadge(
      text: label ?? status.toDisplayName(),
      icon: style.icon,
      tone: style.tone,
      backgroundColor: neutral.background,
      textColor: neutral.foreground,
      borderColor: neutral.border,
    );
  }
}
