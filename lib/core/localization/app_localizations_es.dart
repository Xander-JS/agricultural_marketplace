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
  String get crop_detail_view_equivalences => 'Ver equivalencias';

  @override
  String get crop_detail_min_order => 'Pedido Mínimo';

  @override
  String get crop_detail_location => 'Ubicación';

  @override
  String get crop_detail_publication_date => 'Fecha de publicación';

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

  @override
  String get deals_title => 'Tratos';

  @override
  String get deals_tab_all => 'Todos';

  @override
  String get deals_tab_pending => 'Pendientes';

  @override
  String get deals_tab_in_negotiation => 'En negociación';

  @override
  String get deals_tab_agreed => 'Acordados';

  @override
  String get deals_tab_history => 'Historial';

  @override
  String get deals_your_turn => 'Tu turno';

  @override
  String get deals_waiting_response => 'Esperando respuesta';

  @override
  String get deals_see_deal => 'Ver trato →';

  @override
  String get deals_empty_farmer_title => 'Aún no tienes tratos';

  @override
  String get deals_empty_farmer_desc =>
      'Cuando un comprador realice una oferta sobre una de tus cosechas, aparecerá aquí.';

  @override
  String get deals_empty_buyer_title => 'Aún no tienes tratos';

  @override
  String get deals_empty_buyer_desc =>
      'Cuando realices una oferta en el mercado sobre una cosecha, podrás seguirla y negociar aquí.';

  @override
  String get deals_explore_market => 'Explorar mercado';

  @override
  String get deals_view_crops => 'Ver mis cosechas';

  @override
  String get deal_detail_title => 'Detalle del trato';

  @override
  String get deal_counterpart_buyer => 'Comprador';

  @override
  String get deal_counterpart_farmer => 'Productor';

  @override
  String get deal_history_title => 'Historial de ofertas';

  @override
  String get deal_waiting_buyer => 'Esperando respuesta del comprador';

  @override
  String get deal_waiting_farmer => 'Esperando respuesta del productor';

  @override
  String get deal_accept_offer => 'Aceptar oferta';

  @override
  String get deal_counter_offer => 'Contraofertar';

  @override
  String get deal_reject_deal => 'Rechazar trato';

  @override
  String get deal_cancel_deal => 'Cancelar propuesta';

  @override
  String get deal_accept_success => 'Trato acordado correctamente';

  @override
  String get deal_reject_success => 'El trato ha sido rechazado';

  @override
  String get deal_reject_confirm_title => '¿Rechazar este trato?';

  @override
  String get deal_reject_confirm_desc =>
      'Esta acción no se puede deshacer y el trato se cerrará.';

  @override
  String get counter_offer_title => 'Contraoferta';

  @override
  String get counter_offer_subtitle =>
      'Modifica los términos de la oferta para la cosecha seleccionada.';

  @override
  String get counter_offer_quantity_label => 'Cantidad (kg)';

  @override
  String get counter_offer_price_label => 'Precio propuesto por kg';

  @override
  String get counter_offer_delivery_label => 'Método de entrega';

  @override
  String get counter_offer_message_label => 'Mensaje (Opcional)';

  @override
  String get counter_offer_message_hint =>
      'Explica el motivo de tu contraoferta';

  @override
  String get counter_offer_send_btn => 'Enviar contraoferta';

  @override
  String get counter_offer_success => 'Contraoferta enviada exitosamente';

  @override
  String get purchases_tab_all => 'Todas';

  @override
  String get purchases_tab_agreed => 'Acordadas';

  @override
  String get purchases_tab_completed => 'Completadas';

  @override
  String get purchases_empty_title => 'No tienes compras aún';

  @override
  String get purchases_empty_desc =>
      'Aquí aparecerán los acuerdos que hayas cerrado con los productores agrícolas y tus compras completadas.';

  @override
  String get purchases_empty_action => 'Explorar mercado';

  @override
  String get purchases_total_agreed => 'Acuerdos vigentes';

  @override
  String get purchases_total_invested => 'Total pactado';

  @override
  String get purchases_total_volume => 'Volumen total';

  @override
  String get purchases_view_detail => 'Ver detalle del acuerdo →';

  @override
  String get purchases_delivery_method => 'Entrega';

  @override
  String get purchases_status_agreed => 'Acordada';

  @override
  String get purchases_status_completed => 'Completada';

  @override
  String get deal_agreed_desc =>
      'Trato acordado. Coordina la entrega física para completar la operación.';

  @override
  String get deal_complete_btn => 'Confirmar entrega y completar trato';

  @override
  String get deal_cancel_agreed => 'Cancelar acuerdo';

  @override
  String get deal_complete_confirm_title => '¿Completar este trato?';

  @override
  String get deal_complete_confirm_desc =>
      'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.';

  @override
  String get deal_complete_confirm_btn => 'Completar';

  @override
  String get deal_completed_success => 'Trato completado exitosamente';

  @override
  String get deal_detail_error => 'Ocurrió un error';

  @override
  String get deal_detail_not_found => 'No se encontró el trato.';

  @override
  String get deal_detail_quantity => 'Cantidad';

  @override
  String get deal_detail_price_per_kg => 'Precio por kg';

  @override
  String get deal_detail_delivery_method => 'Método de entrega';

  @override
  String get deal_detail_status => 'Estado';

  @override
  String get deal_detail_rate_coming_soon =>
      'La calificación de tratos estará disponible pronto.';

  @override
  String get deal_detail_rate_farmer => 'Calificar productor';

  @override
  String get deal_detail_rate_buyer => 'Calificar comprador';

  @override
  String get deal_detail_proposal_cancelled => 'Propuesta cancelada';

  @override
  String get deals_unknown_crop => 'Cosecha desconocida';

  @override
  String get deals_counterpart_producer => 'Productor';

  @override
  String get deals_counterpart_buyer_label => 'Comprador';

  @override
  String get deals_status_pending => 'Pendiente';

  @override
  String get deals_status_counteroffer => 'Contraoferta';

  @override
  String get deals_status_agreed => 'Acordado';

  @override
  String get deals_status_completed => 'Completado';

  @override
  String get deals_status_rejected => 'Rechazado';

  @override
  String get deals_status_cancelled => 'Cancelado';

  @override
  String get offer_sheet_base_price => 'Base';

  @override
  String get offer_sheet_min_order => 'Mín';

  @override
  String get offer_sheet_available_stock => 'Stock disp.';

  @override
  String get offer_sheet_unapproved_error =>
      'Tu cuenta debe estar verificada y aprobada para realizar ofertas comerciales.';

  @override
  String get crop_unapproved_warning =>
      'Tu cuenta debe estar verificada y aprobada para realizar ofertas comerciales.';

  @override
  String get crop_unapproved_dialog_title => 'Verificación requerida';

  @override
  String get crop_unapproved_dialog_desc =>
      'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.';

  @override
  String get crop_unapproved_dialog_action => 'Entendido';

  @override
  String get recovery_title => 'Recuperar contraseña';

  @override
  String get recovery_subtitle =>
      'Ingresa el correo electrónico asociado a tu cuenta para recibir las instrucciones de restablecimiento.';

  @override
  String get recovery_email_label => 'Correo electrónico';

  @override
  String get recovery_email_hint => 'ejemplo@correo.com';

  @override
  String get recovery_email_required => 'Ingresa tu correo electrónico.';

  @override
  String get recovery_email_invalid => 'Ingresa un correo electrónico válido.';

  @override
  String get recovery_phone_not_supported =>
      'La recuperación por enlace requiere un correo electrónico. Si te registraste únicamente con un número de teléfono, por favor contacta al administrador.';

  @override
  String get recovery_send_button => 'Enviar instrucciones';

  @override
  String get recovery_sending => 'Enviando...';

  @override
  String get recovery_generic_success =>
      'Si los datos corresponden a una cuenta registrada, se enviarán las instrucciones para restablecer tu contraseña.';

  @override
  String get recovery_back_to_login => 'Volver a Iniciar Sesión';

  @override
  String get recovery_network_error =>
      'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.';

  @override
  String get recovery_generic_error =>
      'No se pudo procesar la solicitud. Por favor intenta más tarde.';

  @override
  String get reset_password_title => 'Nueva contraseña';

  @override
  String get reset_password_subtitle =>
      'Ingresa tu nueva contraseña para acceder a tu cuenta.';

  @override
  String get reset_password_new_label => 'Nueva contraseña';

  @override
  String get reset_password_new_hint => 'Mínimo 6 caracteres';

  @override
  String get reset_password_confirm_label => 'Confirmar nueva contraseña';

  @override
  String get reset_password_confirm_hint => 'Repite tu nueva contraseña';

  @override
  String get reset_password_length_error =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get reset_password_mismatch_error => 'Las contraseñas no coinciden.';

  @override
  String get reset_password_required_error => 'Este campo es requerido.';

  @override
  String get reset_password_submit_button => 'Actualizar contraseña';

  @override
  String get reset_password_updating => 'Actualizando...';

  @override
  String get reset_password_success =>
      'Contraseña actualizada exitosamente. Por favor, inicia sesión con tu nueva contraseña.';

  @override
  String get reset_password_invalid_session =>
      'El enlace de recuperación es inválido o ha caducado. Por favor, solicita uno nuevo.';

  @override
  String get reset_password_cancel => 'Cancelar';

  @override
  String get verification_status_reupload_coming_soon =>
      'Funcionalidad de re-carga en desarrollo.';

  @override
  String get moderation_queue_title => 'Cola de Moderación';

  @override
  String get moderation_queue_empty_title => 'No hay solicitudes pendientes';

  @override
  String get moderation_queue_empty_desc =>
      'Todas las solicitudes de verificación han sido resueltas o no hay envíos pendientes.';

  @override
  String get moderation_unauthorized_title => 'Acceso No Autorizado';

  @override
  String get moderation_unauthorized_desc =>
      'Tu cuenta no posee privilegios de moderación para acceder a esta consola.';

  @override
  String get moderation_detail_title => 'Detalle de Solicitud';

  @override
  String get moderation_lbl_role => 'Rol:';

  @override
  String get moderation_lbl_submitted => 'Enviado:';

  @override
  String get moderation_documents_title => 'Documentos Presentados';

  @override
  String get moderation_storage_notice =>
      'Archivos locales/simulados. La integración con Supabase Storage se completará en la Fase 2.';

  @override
  String get moderation_doc_front => 'Cédula (Frente)';

  @override
  String get moderation_doc_back => 'Cédula (Dorso)';

  @override
  String get moderation_doc_selfie => 'Selfie Facial';

  @override
  String get moderation_previous_rejection => 'Motivo de Rechazo Registrado';

  @override
  String get moderation_already_resolved =>
      'Esta solicitud ya fue resuelta y no admite nuevas modificaciones inmediatas.';

  @override
  String get moderation_btn_approve => 'Aprobar';

  @override
  String get moderation_btn_reject => 'Rechazar';

  @override
  String get moderation_confirm_approve_title => 'Confirmar Aprobación';

  @override
  String get moderation_confirm_approve_desc =>
      '¿Estás seguro de que deseas aprobar esta solicitud? El usuario obtendrá acceso a las funcionalidades comerciales.';

  @override
  String get moderation_approved_success => 'Solicitud aprobada con éxito.';

  @override
  String get moderation_confirm_reject_title => 'Rechazar Solicitud';

  @override
  String get moderation_reject_reason_prompt =>
      'Indica el motivo del rechazo para que el usuario pueda corregirlo:';

  @override
  String get moderation_reject_reason_hint =>
      'Ej. Documento borroso o fecha de vencimiento ilegible';

  @override
  String get moderation_reject_reason_required =>
      'El motivo de rechazo es obligatorio.';

  @override
  String get moderation_rejected_success =>
      'Solicitud rechazada correctamente.';
}
