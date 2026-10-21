import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_content.dart';
import '../models/registration_data.dart';
import '../services/registration_service.dart';

class ProcessingScreen extends StatefulWidget {
  final RegistrationData data;
  final RegistrationService? registrationService;

  const ProcessingScreen({
    Key? key,
    required this.data,
    this.registrationService,
  }) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late String _statusMessage;
  bool _hasError = false;
  bool _isSpinning = true;
  bool _requiresConfirmation = false;
  bool _isSubmitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasError && !_isSubmitted) {
      _isSubmitted = true;
      _statusMessage = AppLocalizations.of(context)!.processing_default_message;
      _submitData();
    }
  }

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!widget.data.isPersonalInfoValid ||
          !widget.data.isRoleValid ||
          !widget.data.isDocumentTypeValid ||
          !widget.data.isDocumentFrontValid ||
          !widget.data.isDocumentBackValid ||
          !widget.data.isSelfieValid) {
        throw Exception(l10n.processing_missing_data);
      }

      if (mounted) {
        setState(() {
          _statusMessage = l10n.processing_creating_user;
        });
      }

      final service = widget.registrationService ?? RegistrationService();
      final result = await service.registerUser(
        phone: widget.data.phone!,
        firstName: widget.data.firstName!,
        lastName: widget.data.lastName!,
        password: widget.data.password!,
        role: widget.data.role!,
        documentType: widget.data.documentType,
        documentFront: widget.data.documentFront,
        documentBack: widget.data.documentBack,
        selfie: widget.data.selfie,
        // verificationStatus no se pasa: el servicio siempre impone 'pendiente'
        // para respetar el trigger trg_protect_profiles_security_fields.
      );

      if (!mounted) return;

      if (result.requiresConfirmation) {
        setState(() {
          _statusMessage = result.message ?? 'Cuenta creada. Por favor confirma tu medio de contacto para continuar.';
          _isSpinning = false;
          _requiresConfirmation = true;
        });
      } else {
        setState(() {
          _statusMessage = result.documentsUploaded
              ? l10n.processing_success
              : (result.message ?? l10n.processing_success);
          _isSpinning = false;
        });

        // Retornar a la raíz donde AuthGate ya resolvió la sesión y el perfil
        final delay = result.documentsUploaded ? 1000 : 2200;
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage =
              '${l10n.processing_error_prefix}${e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '')}';
          _isSpinning = false;
        });
      }
    }
  }

  void _onRetry() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _hasError = false;
      _statusMessage = l10n.processing_retrying;
      _isSpinning = true;
      _requiresConfirmation = false;
    });
    _submitData();
  }

  void _onReturnToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppLoading(
      child: LoadingContent(
        message: _statusMessage,
        isError: _hasError,
        isSpinning: _isSpinning,
        onRetry: _hasError ? _onRetry : null,
        onBack: _hasError
            ? () => Navigator.of(context).pop()
            : (_requiresConfirmation ? _onReturnToLogin : null),
        retryText: l10n.processing_retry,
        backText: _requiresConfirmation
            ? l10n.login_title
            : l10n.processing_back,
      ),
    );
  }
}
