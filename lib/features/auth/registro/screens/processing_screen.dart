import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/registration_data.dart';
import '../services/registration_service.dart';

class ProcessingScreen extends StatefulWidget {
  final RegistrationData data;
  const ProcessingScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final RegistrationService _service = RegistrationService();

  String _statusMessage = 'Procesando tu información...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _submitData();
  }

  Future<void> _submitData() async {
    try {
      if (!widget.data.isPersonalInfoValid ||
          !widget.data.isRoleValid ||
          !widget.data.isDocumentTypeValid ||
          !widget.data.isDocumentFrontValid ||
          !widget.data.isDocumentBackValid ||
          !widget.data.isSelfieValid) {
        throw Exception('Faltan datos requeridos para el registro.');
      }

      setState(() {
        _statusMessage = 'Creando usuario...';
      });

      await _service.registerUser(
        phone: widget.data.phone!,
        firstName: widget.data.firstName!,
        lastName: widget.data.lastName!,
        role: widget.data.role!,
        documentType: widget.data.documentType!,
        documentFront: widget.data.documentFront!,
        documentBack: widget.data.documentBack!,
        selfie: widget.data.selfie!,
      );

      setState(() {
        _statusMessage = '¡Registro completado con éxito!';
        _controller.stop();
      });

      // Navigate to success or home
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Temporarily pop to root or show a success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Registro Exitoso'),
              content: const Text('Tus datos han sido enviados a revisión.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Ocurrió un error:\n${e.toString()}';
        _controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loadingBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasError)
                RotationTransition(
                  turns: _controller,
                  child: Image.asset(
                    'assets/images/logo_lg.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.eco, color: Colors.white, size: 80),
                  ),
                )
              else
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 80,
                ),

              const SizedBox(height: 32),

              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),

              if (_hasError) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _statusMessage = 'Reintentando...';
                      _controller.repeat();
                    });
                    _submitData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.loadingBackground,
                  ),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Volver atrás',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
