import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_content.dart';
import '../../verificacion/screens/verification_status_screen.dart';
import '../../verificacion/services/verification_service.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/document_image_picker.dart';
import '../../verificacion/widgets/review_ring.dart';
import '../models/registration_data.dart';
import '../services/registration_service.dart';

class ProcessingScreen extends StatefulWidget {
  final RegistrationData data;
  final RegistrationService? registrationService;
  final VerificationService? verificationService;

  const ProcessingScreen({
    super.key,
    required this.data,
    this.registrationService,
    this.verificationService,
  });

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
          _statusMessage =
              result.message ?? l10n.processing_confirmation_required;
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

        // La solicitud ya quedó guardada: las copias locales sobran.
        clearPersistedDocumentImages();

        final delay = result.documentsUploaded ? 1000 : 2200;
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted) _openVerificationStatus();
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

  /// Reemplaza toda la pila por la pantalla de espera de verificación.
  ///
  /// No se vuelve a la raíz con `popUntil`: durante el `signUp` el AuthGate
  /// raíz recibe `signedIn` antes de que exista el perfil y queda mostrando
  /// "Completa tu registro". Al reemplazar la pila ese estado obsoleto se
  /// descarta y el usuario no puede volver al formulario con el botón atrás.
  void _openVerificationStatus() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (routeContext) => VerificationStatusScreen(
          verificationService: widget.verificationService,
          // Tras la aprobación un AuthGate nuevo resuelve el rol y abre el
          // panel principal con su manejo de sesión habitual.
          onVerificationApproved: (_) => _restartAtAuthGate(routeContext),
          onSignOut: () async {
            await _signOut();
            if (routeContext.mounted) _restartAtAuthGate(routeContext);
          },
        ),
      ),
      (route) => false,
    );
  }

  static void _restartAtAuthGate(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  static Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
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
        // Same contour ring as the waiting screen, on its first stage, so
        // the hand-off after submitting reads as one continuous path.
        workingVisual: ReviewRing(
          stage: 0,
          semanticsLabel: l10n.verification_status_ring_semantics(
            l10n.verification_status_track_received,
          ),
          child: const KusBrandLogo(
            variant: KusBrandLogoVariant.hero,
            showWordmark: false,
            onBrandStage: true,
            markSize: 84,
          ),
        ),
      ),
    );
  }
}
