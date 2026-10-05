import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../services/verification_service.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({Key? key}) : super(key: key);

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final VerificationService _service = VerificationService();

  late Future<VerificationStatusData> _statusFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _statusFuture = _service.getCurrentVerificationStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _statusFuture = _service.getCurrentVerificationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loadingBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: FutureBuilder<VerificationStatusData>(
              future: _statusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final data = snapshot.data!;
                return _buildStatusState(data);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _controller,
          child: Image.asset(
            'assets/images/logo_lg.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.eco, color: Colors.white, size: 80),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Consultando estado...',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    // Remove "Exception: " prefix if present
    final cleanError = error.replaceAll('Exception: ', '');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 80),
        const SizedBox(height: 32),
        Text(
          'Ha ocurrido un error',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          cleanError,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.loadingBackground,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildStatusState(VerificationStatusData data) {
    // Determine the text, icon, and colors based on status
    String title = '';
    String description = '';
    IconData iconData = Icons.info_outline;
    Color statusColor = Colors.grey;

    switch (data.status) {
      case 'pendiente':
        title = 'Pendiente de Documentos';
        description = 'Has completado el registro inicial mediante número telefónico. Aún debes enviar tus documentos para verificar tu identidad y acceder a todas las funcionalidades.';
        iconData = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case 'en_revision_ia':
        title = 'En Revisión';
        description = 'Tus documentos fueron enviados y están siendo validados por nuestro sistema y equipo de moderación. No puedes modificar los documentos mientras estén en revisión.';
        iconData = Icons.analytics_outlined;
        statusColor = AppColors.info;
        break;
      case 'aprobado':
        title = 'Verificación Aprobada';
        description = 'El moderador validó satisfactoriamente tu identidad. Tu perfil aparece como verificado y tienes acceso a las funcionalidades correspondientes a tu rol.';
        iconData = Icons.check_circle_outline;
        statusColor = AppColors.success;
        break;
      case 'rechazado':
        title = 'Verificación Rechazada';
        description = data.rejectionReason ?? 'La verificación no fue aprobada debido a inconsistencias en la documentación. Por favor, corrige la información y vuelve a intentar.';
        iconData = Icons.cancel_outlined;
        statusColor = AppColors.error;
        break;
      case 'suspendido':
        title = 'Cuenta Suspendida';
        description = 'Tu cuenta ha sido suspendida mediante una acción administrativa temporalmente. Se restringen las funcionalidades comerciales.';
        iconData = Icons.block;
        statusColor = AppColors.error;
        break;
      default:
        title = 'Estado Desconocido';
        description = 'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.';
        iconData = Icons.help_outline;
        statusColor = Colors.grey;
    }

    // Determine if we should show the success text mentioned in instructions
    final showSuccessText =
        data.status == 'pendiente' || data.status == 'en_revision_ia';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Keep the spinning animation alive if it's processing, else stop or show static
        if (data.status == 'en_revision_ia' || data.status == 'pendiente')
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
          Image.asset(
            'assets/images/logo_lg.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.eco, color: Colors.white, size: 80),
          ),

        const SizedBox(height: 32),

        if (showSuccessText) ...[
          Text(
            'Tu registro fue exitoso y estamos revisando tu información...',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 48),
        ],

        // The Mini Cuadro
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: statusColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        if (data.status == 'rechazado' || data.status == 'pendiente')
          ElevatedButton(
            onPressed: () {
              // Navegar para corregir la información (por implementar en el futuro)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de re-carga en desarrollo.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Subir Documentos'),
          )
        else if (data.status == 'aprobado')
          ElevatedButton(
            onPressed: () {
              // Navegar a la app principal (por implementar en el futuro)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navegando a la aplicación principal...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Entrar a la aplicación'),
          )
        else
          TextButton(
            onPressed: _retry,
            child: const Text(
              'Actualizar estado',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
