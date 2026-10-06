import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_content.dart';
import '../models/registration_data.dart';
import '../services/registration_service.dart';
import '../../login/screens/login_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final RegistrationData data;
  const ProcessingScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final RegistrationService _service = RegistrationService();

  late String _statusMessage;
  bool _hasError = false;
  bool _isSpinning = true;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize text using localization
    if (!_hasError) {
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

      // Simular tiempo de carga sin llamar a Supabase
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _statusMessage = '¡Cargado con éxito!'; // Mensaje de cargado
          _isSpinning = false;
        });
      }

      // Navigate to Login Screen (Simulando que terminó y ahora debe iniciar sesión)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = '${l10n.processing_error_prefix}${e.toString()}';
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
    });
    _submitData();
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
        onBack: _hasError ? () => Navigator.of(context).pop() : null,
        retryText: l10n.processing_retry,
        backText: l10n.processing_back,
      ),
    );
  }
}
