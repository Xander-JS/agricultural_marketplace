import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../brand/kus_brand_logo.dart';

/// Un contenedor responsivo para la web que presenta la aplicación dentro de
/// un marco de smartphone (simulador móvil) cuando se visualiza en pantallas de
/// escritorio o monitores anchos (Vercel, Chrome, Safari, etc.).
///
/// Si el usuario abre el enlace desde un teléfono móvil real (ancho <= 540px)
/// o en plataformas nativas (Android/iOS/Desktop VM), se renderiza a pantalla
/// completa sin marcos ni sobrecarga.
///
/// En escritorio, permite alternar con un clic entre el "Modo Celular" (proporciones
/// móviles estándar 412 × 880) y la "Pantalla Completa".
class WebPhoneFrame extends StatefulWidget {
  final MediaQueryData scaledMedia;
  final Widget child;

  const WebPhoneFrame({
    super.key,
    required this.scaledMedia,
    required this.child,
  });

  @override
  State<WebPhoneFrame> createState() => _WebPhoneFrameState();
}

class _WebPhoneFrameState extends State<WebPhoneFrame> {
  bool _isFrameEnabled = true;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // En dispositivos móviles reales, tablets pequeñas o tests automatizados (no web),
    // la aplicación se muestra normal a pantalla completa sin ningún marco.
    if (!kIsWeb || media.size.width <= 540) {
      return MediaQuery(
        data: widget.scaledMedia,
        child: widget.child,
      );
    }

    // Modo Pantalla Completa en escritorio (cuando el usuario desactiva el marco)
    if (!_isFrameEnabled) {
      return MediaQuery(
        data: widget.scaledMedia,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            _buildFloatingSwitchToPhoneButton(context),
          ],
        ),
      );
    }

    // Modo Simulador de Celular en escritorio
    return _buildDesktopPhoneStage(context, media);
  }

  /// Construye el escenario de escritorio con el marco de smartphone centrado.
  Widget _buildDesktopPhoneStage(BuildContext context, MediaQueryData media) {
    const double phoneWidth = 412.0;
    final bool hasTopBar = media.size.height >= 720;
    final bool hasFooter = media.size.height >= 800;

    final double topMargin = hasTopBar ? 16.0 : 8.0;
    final double bottomMargin = hasFooter ? 16.0 : 8.0;
    final double availableHeight =
        media.size.height - (hasTopBar ? 70.0 : 0.0) - (hasFooter ? 48.0 : 0.0) - topMargin - bottomMargin;

    final double phoneHeight = availableHeight.clamp(560.0, 890.0);

    // Sobrescribimos el MediaQuery interior para que todos los componentes, modales,
    // diálogos y scaffolds se adapten a las dimensiones exactas del celular con sus
    // safe areas de status bar (44px) y home indicator (24px).
    final phoneMedia = widget.scaledMedia.copyWith(
      size: Size(phoneWidth, phoneHeight),
      padding: const EdgeInsets.only(top: 44.0, bottom: 24.0),
      viewPadding: const EdgeInsets.only(top: 44.0, bottom: 24.0),
    );

    return Material(
      color: const Color(0xFF070E0A),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.25,
            colors: [
              Color(0xFF0F2618), // Brillo sutil verde corporativo Kus
              Color(0xFF08120B),
              Color(0xFF040805),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (hasTopBar) _buildDesktopHeader(context),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
                      child: _buildPhoneHardwareFrame(
                        context: context,
                        phoneWidth: phoneWidth,
                        phoneHeight: phoneHeight,
                        phoneMedia: phoneMedia,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasFooter) _buildDesktopFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra superior exterior para escritorio con marca Kus y botón de pantalla completa.
  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          const KusBrandLogo(
            variant: KusBrandLogoVariant.compact,
            onBrandStage: true,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightBrandPrimary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.smartphone,
                  size: 14,
                  color: Color(0xFF86EFAC),
                ),
                SizedBox(width: 6),
                Text(
                  'VISTA MÓVIL',
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Botón para alternar a pantalla completa
          InkWell(
            onTap: () {
              setState(() {
                _isFrameEnabled = false;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.maximize2,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pantalla completa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hardware físico del smartphone: chasis de titanio, botones laterales,
  /// Dynamic Island y barra de inicio.
  Widget _buildPhoneHardwareFrame({
    required BuildContext context,
    required double phoneWidth,
    required double phoneHeight,
    required MediaQueryData phoneMedia,
  }) {
    const double chassisPadding = 11.0;
    final double outerWidth = phoneWidth + (chassisPadding * 2);
    final double outerHeight = phoneHeight + (chassisPadding * 2);

    return SizedBox(
      width: outerWidth + 12.0, // espacio para botones laterales sobresalientes
      height: outerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Botones laterales (Volumen izquierda, Bloqueo derecha)
          Positioned(
            left: 2.0,
            top: 130.0,
            child: _buildHardwareButton(width: 4, height: 46),
          ),
          Positioned(
            left: 2.0,
            top: 188.0,
            child: _buildHardwareButton(width: 4, height: 46),
          ),
          Positioned(
            right: 2.0,
            top: 150.0,
            child: _buildHardwareButton(width: 4, height: 68),
          ),

          // Chasis exterior del smartphone
          Container(
            width: outerWidth,
            height: outerHeight,
            padding: const EdgeInsets.all(chassisPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF141A16),
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                color: const Color(0xFF28382E),
                width: 2.0,
              ),
              boxShadow: [
                // Sombra profunda
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 44.0,
                  spreadRadius: 4.0,
                  offset: const Offset(0, 20),
                ),
                // Halo verde sutil Kus
                BoxShadow(
                  color: AppColors.lightBrandPrimary.withValues(alpha: 0.35),
                  blurRadius: 75.0,
                  spreadRadius: -4.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(39.0),
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(37.5),
                child: SizedBox(
                  width: phoneWidth,
                  height: phoneHeight,
                  child: MediaQuery(
                    data: phoneMedia,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Contenido vivo de la aplicación
                        widget.child,

                        // Dynamic Island (IgnorePointer para no bloquear toques)
                        Positioned(
                          top: 10.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: Container(
                                width: 112.0,
                                height: 26.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 12.0),
                                      width: 9.0,
                                      height: 9.0,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D1B13),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1E3A2A),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Barra inferior Home Indicator
                        Positioned(
                          bottom: 8.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: Container(
                                width: 132.0,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón lateral físico decorativo del celular
  Widget _buildHardwareButton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF28382E),
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }

  /// Pie de página exterior discreto
  Widget _buildDesktopFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        '🌾 Diseñado para smartphones (proporciones 9:19.5). Abre este enlace desde tu celular para la experiencia nativa.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Botón flotante para regresar al "Modo Celular" cuando se está en pantalla completa
  Widget _buildFloatingSwitchToPhoneButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isFrameEnabled = true;
            });
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightBrandPrimary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF86EFAC).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.smartphone,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Modo Celular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
