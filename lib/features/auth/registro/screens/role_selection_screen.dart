import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../../widgets/selectable_option_card.dart';
import '../models/registration_data.dart';
import 'document_selection_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final RegistrationData data;
  const RoleSelectionScreen({super.key, required this.data});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.data.role;
  }

  void _onNext() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRole != null) {
      widget.data.role = _selectedRole;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentSelectionScreen(data: widget.data),
        ),
      );
    } else {
      showAppSnackBar(
        context,
        l10n.role_selection_error_no_role,
        tone: StatusTone.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepScaffold(
      title: l10n.role_selection_header_title,
      step: 2,
      lead: l10n.role_selection_title,
      bottom: PrimaryActionButton(
        onPressed: _onNext,
        text: l10n.common_continue,
      ),
      children: [
        SelectableOptionCard(
          icon: LucideIcons.sprout,
          title: l10n.role_selection_producer,
          tagline: l10n.role_selection_producer_subtitle,
          description: l10n.role_selection_producer_description,
          descriptionIcon: LucideIcons.chartNoAxesCombined,
          selected: _selectedRole == 'agricultor',
          onTap: () => setState(() => _selectedRole = 'agricultor'),
        ),
        const SizedBox(height: AppDimensions.space12),
        SelectableOptionCard(
          icon: LucideIcons.briefcaseBusiness,
          title: l10n.role_selection_buyer,
          tagline: l10n.role_selection_buyer_subtitle,
          description: l10n.role_selection_buyer_description,
          descriptionIcon: LucideIcons.truck,
          selected: _selectedRole == 'comprador',
          onTap: () => setState(() => _selectedRole = 'comprador'),
        ),
        const SizedBox(height: AppDimensions.space24),
        StepFootnote(
          icon: LucideIcons.shieldCheck,
          text: l10n.role_selection_kyc_notice,
        ),
      ],
    );
  }
}
