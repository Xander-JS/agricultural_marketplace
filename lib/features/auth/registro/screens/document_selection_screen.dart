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
import 'capture_front_screen.dart';

class DocumentSelectionScreen extends StatefulWidget {
  final RegistrationData data;
  const DocumentSelectionScreen({super.key, required this.data});

  @override
  State<DocumentSelectionScreen> createState() =>
      _DocumentSelectionScreenState();
}

class _DocumentSelectionScreenState extends State<DocumentSelectionScreen> {
  String? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.data.documentType;
  }

  void _onNext() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDocument != null) {
      widget.data.documentType = _selectedDocument;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptureFrontScreen(data: widget.data),
        ),
      );
    } else {
      showAppSnackBar(
        context,
        l10n.document_selection_error_no_doc,
        tone: StatusTone.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepScaffold(
      title: l10n.document_selection_header_title,
      step: 3,
      lead: l10n.document_selection_description,
      bottom: PrimaryActionButton(
        onPressed: _onNext,
        text: l10n.common_continue,
      ),
      children: [
        GroupHeading(l10n.document_selection_select_id),
        SelectableOptionCard(
          icon: LucideIcons.idCard,
          title: l10n.document_selection_cc,
          tagline: l10n.document_selection_cc_desc,
          selected: _selectedDocument == 'CC',
          onTap: () => setState(() => _selectedDocument = 'CC'),
        ),
        const SizedBox(height: AppDimensions.space12),
        SelectableOptionCard(
          icon: LucideIcons.car,
          title: l10n.document_selection_driver_license,
          tagline: l10n.document_selection_driver_license_desc,
          selected: _selectedDocument == 'Driver License',
          onTap: () => setState(() => _selectedDocument = 'Driver License'),
        ),
        const SizedBox(height: AppDimensions.space24),
        StepFootnote(
          icon: LucideIcons.lock,
          text: l10n.document_selection_encryption_notice,
        ),
      ],
    );
  }
}
