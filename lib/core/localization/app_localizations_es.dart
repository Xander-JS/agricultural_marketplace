// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcome_title => 'Bienvenido';

  @override
  String get welcome_description =>
      'Conecta directamente con productores y compradores para comercializar productos agrícolas de forma fácil, segura y transparente.';

  @override
  String get welcome_continue => 'Continuar';

  @override
  String get personal_info_title => 'Información personal';

  @override
  String get personal_info_phone => 'Número telefónico';

  @override
  String get personal_info_first_name => 'Nombres';

  @override
  String get personal_info_last_name => 'Apellidos';

  @override
  String get personal_info_verification_description =>
      'En el siguiente paso enviaremos un código de verificación de 6 dígitos para confirmar tu número.';

  @override
  String get personal_info_active => 'Activo';

  @override
  String get personal_info_required => 'Requerido';

  @override
  String get personal_info_phone_hint => '315-000-0000';

  @override
  String get personal_info_first_name_hint => 'ej. Juan';

  @override
  String get personal_info_last_name_hint => 'ej. Pérez';

  @override
  String get role_selection_header_title => 'Selección tipo';

  @override
  String get role_selection_title =>
      'Elige el rol que mejor describe tu actividad en la plataforma.';

  @override
  String get role_selection_producer => 'Productor';

  @override
  String get role_selection_producer_subtitle => 'Vende y distribuye';

  @override
  String get role_selection_producer_description =>
      'Publicación directa en el mercado y análisis';

  @override
  String get role_selection_buyer => 'Comprador';

  @override
  String get role_selection_buyer_subtitle => 'Busca y compra';

  @override
  String get role_selection_buyer_description =>
      'Logística transparente y procedencia de lotes';

  @override
  String get role_selection_kyc_notice =>
      'La verificación KYC aplica después de la selección del rol';

  @override
  String get role_selection_error_no_role => 'Por favor, selecciona un rol';

  @override
  String get document_selection_header_title => 'Identificación documento';

  @override
  String get document_selection_title => 'Verificación de documento';

  @override
  String get document_selection_description =>
      'Necesitamos confirmar tu identidad legal antes de activar tu cuenta.';

  @override
  String get document_selection_select_id =>
      'SELECCIONA TU TIPO DE IDENTIFICACIÓN';

  @override
  String get document_selection_cc => 'CC';

  @override
  String get document_selection_cc_desc => 'Cédula de Ciudadanía / National ID';

  @override
  String get document_selection_driver_license => 'Licencia de Conducir';

  @override
  String get document_selection_driver_license_desc =>
      'Permiso de conducir oficial';

  @override
  String get document_selection_encryption_notice =>
      'Verificación de identidad encriptada de 256 bits';

  @override
  String get document_selection_error_no_doc =>
      'Por favor, selecciona un tipo de documento';

  @override
  String get capture_front_header_title => 'Identificación documento';

  @override
  String get capture_front_title => 'Capturar parte frontal';

  @override
  String get capture_front_description =>
      'Posiciona la parte frontal de tu documento dentro del marco. Asegúrate de tener buena iluminación y que todo el texto sea legible.';

  @override
  String get capture_front_identity_verification => 'Verificación de Identidad';

  @override
  String get capture_front_aligning =>
      'Mantente quieto — alineando documento...';

  @override
  String get capture_front_auto_capture => 'Captura automática lista';

  @override
  String get capture_front_tip_light => 'Buena luz';

  @override
  String get capture_front_tip_fit => 'Encuadrar';

  @override
  String get capture_front_tip_glare => 'Sin reflejos';

  @override
  String get capture_front_tap_to_capture =>
      'Toca el botón abajo para capturar';

  @override
  String get capture_back_header_title => 'Identificación documento';

  @override
  String get capture_back_title => 'Capturar parte trasera';

  @override
  String get capture_back_description =>
      'Ahora voltea tu documento y posiciona la parte trasera dentro del marco. Asegúrate de que la banda magnética o código de barras sea completamente visible.';

  @override
  String get capture_back_steady => 'Parte trasera detectada — mantente firme';

  @override
  String get capture_back_tip_light => 'Buena luz';

  @override
  String get capture_back_tip_fit => 'Encuadrar';

  @override
  String get capture_back_tip_barcode => 'Código claro';

  @override
  String get capture_back_tap_to_capture => 'Toca el botón abajo para capturar';

  @override
  String get facial_verification_header_title => 'Verificación facial';

  @override
  String get facial_verification_title => 'Verificación Facial';

  @override
  String get facial_verification_description =>
      'Necesitamos escanear tu rostro para verificar que eres una persona real.';

  @override
  String get facial_verification_face_detected =>
      'Rostro detectado • Coincidencia perfecta';

  @override
  String get facial_verification_liveness => 'Detección de vida activa';

  @override
  String get facial_verification_tip_light => 'Buena luz';

  @override
  String get facial_verification_tip_glasses => 'Sin lentes';

  @override
  String get facial_verification_tip_straight => 'Mira al frente';

  @override
  String get facial_verification_encryption_notice =>
      'Los datos biométricos están encriptados a 256 bits y nunca se comparten.';

  @override
  String get facial_verification_start_button => 'Comenzar';

  @override
  String get processing_missing_data =>
      'Faltan datos requeridos para el registro.';

  @override
  String get processing_creating_user => 'Creando usuario...';

  @override
  String get processing_success => '¡Registro completado con éxito!';

  @override
  String get processing_error_prefix => 'Ocurrió un error:\n';

  @override
  String get processing_default_message => 'Procesando tu información...';

  @override
  String get processing_retry => 'Reintentar';

  @override
  String get processing_retrying => 'Reintentando...';

  @override
  String get processing_back => 'Volver atrás';

  @override
  String get login_title => 'Iniciar sesión';

  @override
  String get login_phone => 'Teléfono';

  @override
  String get login_phone_hint => 'demo@email.com';

  @override
  String get login_password => 'Contraseña';

  @override
  String get login_password_hint => '••••••••••••';

  @override
  String get login_remember_me => 'Recuérdame';

  @override
  String get login_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get login_login_button => 'Iniciar sesión';

  @override
  String get login_no_account => '¿No tienes una cuenta? ';

  @override
  String get login_register => 'Regístrate';

  @override
  String get login_required => 'Requerido';

  @override
  String get verification_status_checking => 'Consultando estado...';

  @override
  String get verification_status_error_title => 'Ha ocurrido un error';

  @override
  String get verification_status_retry => 'Reintentar';

  @override
  String get verification_status_pending_title => 'Pendiente de Documentos';

  @override
  String get verification_status_pending_desc =>
      'Has completado el registro inicial mediante número telefónico. Aún debes enviar tus documentos para verificar tu identidad y acceder a todas las funcionalidades.';

  @override
  String get verification_status_review_title => 'En Revisión';

  @override
  String get verification_status_review_desc =>
      'Tus documentos fueron enviados y están siendo validados por nuestro sistema y equipo de moderación. No puedes modificar los documentos mientras estén en revisión.';

  @override
  String get verification_status_approved_title => 'Verificación Aprobada';

  @override
  String get verification_status_approved_desc =>
      'El moderador validó satisfactoriamente tu identidad. Tu perfil aparece como verificado y tienes acceso a las funcionalidades correspondientes a tu rol.';

  @override
  String get verification_status_rejected_title => 'Verificación Rechazada';

  @override
  String get verification_status_rejected_desc =>
      'La verificación no fue aprobada debido a inconsistencias en la documentación. Por favor, corrige la información y vuelve a intentar.';

  @override
  String get verification_status_suspended_title => 'Cuenta Suspendida';

  @override
  String get verification_status_suspended_desc =>
      'Tu cuenta ha sido suspendida mediante una acción administrativa temporalmente. Se restringen las funcionalidades comerciales.';

  @override
  String get verification_status_unknown_title => 'Estado Desconocido';

  @override
  String get verification_status_unknown_desc =>
      'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.';

  @override
  String get verification_status_success_msg =>
      'Tu registro fue exitoso y estamos revisando tu información...';

  @override
  String get verification_status_upload_docs => 'Subir Documentos';

  @override
  String get verification_status_enter_app => 'Entrar a la aplicación';

  @override
  String get verification_status_update_status => 'Actualizar estado';

  @override
  String get verification_status_default_reject_reason =>
      'La verificación no fue aprobada debido a inconsistencias en la documentación. Por favor, corrige la información y vuelve a intentar.';

  @override
  String get otp_verification_title => 'Ingresa tu código';

  @override
  String get otp_verification_subtitle =>
      'Se ha enviado un código de 6 dígitos a tu celular.';

  @override
  String get otp_verification_didnt_receive => '¿No recibiste el código? ';

  @override
  String get otp_verification_resend => 'Reenviar.';

  @override
  String get otp_verification_appbar_title => 'Verificación SMS';
}
