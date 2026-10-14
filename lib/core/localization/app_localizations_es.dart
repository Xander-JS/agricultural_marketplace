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
      'Posiciona la parte frontal de tu documento dentro del marco.';

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
      'Gira tu documento y posiciona la parte trasera dentro del marco.';

  @override
  String get capture_back_steady => 'Parte trasera detectada — mantente firme';

  @override
  String get capture_back_tip_light => 'Buena luz';

  @override
  String get capture_back_tip_fit => 'Encuadrar';

  @override
  String get capture_back_tip_barcode => 'codigo claro';

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

  @override
  String get nav_market => 'Mercado';

  @override
  String get nav_my_market => 'Mi mercado';

  @override
  String get nav_deals => 'Tratos';

  @override
  String get nav_costs => 'Costos';

  @override
  String get nav_purchases => 'Compras';

  @override
  String get nav_my_farm => 'Mi Finca';

  @override
  String get purchases_title => 'Compras';

  @override
  String get purchases_placeholder_title => 'Módulo de Compras';

  @override
  String get purchases_placeholder_desc =>
      'Aquí podrás consultar tus compras acordadas y el historial de operaciones completadas.';

  @override
  String get profile_title_farmer => 'Mi Finca';

  @override
  String get profile_title_buyer => 'Mi Perfil';

  @override
  String get profile_stats_title => 'Estadísticas';

  @override
  String get profile_stat_published => 'Publicados';

  @override
  String get profile_stat_negotiating => 'Negociando';

  @override
  String get profile_stat_closed_farmer => 'Cerradas';

  @override
  String get profile_stat_closed_buyer => 'Cerrados';

  @override
  String get profile_settings_title => 'Configuración';

  @override
  String get profile_contact_info => 'Información de contacto';

  @override
  String get profile_email => 'Correo electrónico';

  @override
  String get profile_phone => 'Número de teléfono';

  @override
  String get profile_negotiation_options => 'Opciones de negociación';

  @override
  String get profile_enable_early_sale => 'Habilitar precompra';

  @override
  String get profile_visibility_negotiation =>
      'Visibilidad durante una negociación';

  @override
  String get profile_visibility_phone => 'Teléfono';

  @override
  String get profile_visibility_location => 'Ubicación';

  @override
  String get profile_visibility_whatsapp => 'WhatsApp';

  @override
  String get profile_accessibility => 'Accesibilidad';

  @override
  String get profile_dark_mode => 'Modo oscuro';

  @override
  String get profile_english_language => 'Idioma inglés';

  @override
  String get profile_logout => 'Cerrar sesión';

  @override
  String get profile_logout_confirm_title => '¿Cerrar sesión?';

  @override
  String get profile_logout_confirm_desc =>
      '¿Estás seguro de que deseas salir de tu cuenta?';

  @override
  String get profile_cancel => 'Cancelar';

  @override
  String get profile_updated_photo => 'Foto de perfil actualizada';

  @override
  String get profile_save_settings_error => 'Error al guardar configuración';

  @override
  String get profile_load_error => 'Error al cargar el perfil';

  @override
  String get profile_no_data => 'No se pudieron cargar los datos.';

  @override
  String get market_title => 'Mercado';

  @override
  String get market_title_farmer => 'Mi Mercado';

  @override
  String get market_publish_btn => 'Publicar';

  @override
  String get market_empty_farmer_title => 'Aún no tienes cosechas publicadas';

  @override
  String get market_empty_farmer_desc =>
      'Comienza a ofrecer tus productos en el mercado agrícola creando tu primera publicación.';

  @override
  String get market_publish_first => 'Publicar mi primera cosecha';

  @override
  String get market_empty_buyer_title => 'No hay cosechas disponibles';

  @override
  String get market_empty_buyer_desc =>
      'En este momento no hay productos agrícolas disponibles para negociar. Intenta actualizar más tarde.';

  @override
  String get market_retry => 'Reintentar';

  @override
  String get market_refresh => 'Actualizar';

  @override
  String get market_publish_options_title => '¿Cómo deseas publicar?';

  @override
  String get market_publish_manual => 'Publicación Manual';

  @override
  String get market_publish_manual_desc => 'Llena el formulario paso a paso';

  @override
  String get market_publish_voice => 'Publicación por Nota de Voz';

  @override
  String get market_publish_voice_desc =>
      'Cuéntanos qué quieres publicar (Con IA)';

  @override
  String get market_ai_coming_soon => 'Función de IA próximamente...';

  @override
  String get crop_card_available => 'Disponible';

  @override
  String get crop_card_price_per_kg => 'Precio / kg';

  @override
  String get crop_detail_title => 'Detalle de Cosecha';

  @override
  String get crop_detail_delete_tooltip => 'Borrar';

  @override
  String get crop_detail_edit_tooltip => 'Editar';

  @override
  String get crop_detail_confirm_delete_title => 'Borrar Publicación';

  @override
  String get crop_detail_confirm_delete_desc =>
      '¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.';

  @override
  String get crop_detail_delete_success => 'Publicación borrada exitosamente';

  @override
  String get crop_detail_delete_error => 'Error al borrar';

  @override
  String get crop_detail_status_updated => 'Estado actualizado';

  @override
  String get crop_detail_price_per_kg => 'Precio por kg';

  @override
  String get crop_detail_available_stock => 'Total Disponible';

  @override
  String get crop_detail_min_order => 'Pedido Mínimo';

  @override
  String get crop_detail_location => 'Ubicación';

  @override
  String get crop_detail_early_sale => 'Venta Anticipada';

  @override
  String get crop_detail_estimated_harvest => 'Fecha est. de cosecha';

  @override
  String get crop_detail_estimated_yield => 'Rendimiento estimado';

  @override
  String get crop_detail_quick_actions => 'Acciones Rápidas';

  @override
  String get crop_detail_pause_crop => 'Pausar Publicación';

  @override
  String get crop_detail_activate_crop => 'Activar Publicación';

  @override
  String get crop_detail_view_negotiations => 'Ver Negociaciones';

  @override
  String get crop_detail_negotiations_coming_soon =>
      'Próximamente: Ver negociaciones';

  @override
  String get crop_detail_make_offer => 'Hacer oferta / Negociar';

  @override
  String get crop_detail_farmer_info => 'Información del Productor';

  @override
  String get crop_detail_producer => 'Productor';

  @override
  String get crop_detail_contact => 'Contacto';

  @override
  String get offer_sheet_title => 'Nueva Oferta';

  @override
  String get offer_sheet_subtitle =>
      'Inicia una propuesta de negociación para este producto';

  @override
  String get offer_sheet_quantity_label => 'Cantidad (kg)';

  @override
  String get offer_sheet_price_label => 'Precio propuesto por kg';

  @override
  String get offer_sheet_delivery_label => 'Método de entrega';

  @override
  String get offer_sheet_delivery_farm => 'En finca';

  @override
  String get offer_sheet_delivery_hub => 'Punto de acopio';

  @override
  String get offer_sheet_delivery_destination => 'Destino final';

  @override
  String get offer_sheet_delivery_agree => 'A acordar con el productor';

  @override
  String get offer_sheet_message_label =>
      'Mensaje para el productor (Opcional)';

  @override
  String get offer_sheet_message_hint =>
      'Explica detalles de tu propuesta o requerimientos de entrega';

  @override
  String get offer_sheet_estimated_total => 'Total estimado';

  @override
  String get offer_sheet_submit_btn => 'Enviar propuesta';

  @override
  String get offer_sheet_submitting => 'Enviando...';

  @override
  String get offer_sheet_success => 'Propuesta enviada exitosamente';

  @override
  String get offer_sheet_existing_negotiation =>
      'Ya tienes una negociación activa para este cultivo';

  @override
  String get offer_sheet_val_required => 'Campo requerido';

  @override
  String get offer_sheet_val_positive => 'Debe ser mayor a 0';

  @override
  String get offer_sheet_val_min_order =>
      'La cantidad no cumple con el pedido mínimo';

  @override
  String get offer_sheet_val_max_stock =>
      'La cantidad supera el stock disponible';
}
