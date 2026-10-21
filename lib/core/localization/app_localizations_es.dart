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
  String get complete_registration_title => 'Completa tu registro';

  @override
  String get complete_registration_description =>
      'Tu cuenta de acceso ya existe, pero aún no tiene perfil ni solicitud de verificación. Ingresa tus datos y sube las tres imágenes. No se reutilizan datos ni documentos anteriores.';

  @override
  String get complete_registration_contact => 'Teléfono o correo';

  @override
  String get complete_registration_contact_hint =>
      '3151234567 o correo@ejemplo.com';

  @override
  String get complete_registration_full_name => 'Nombre completo';

  @override
  String get complete_registration_full_name_hint => 'Nombres y apellidos';

  @override
  String get complete_registration_role => 'Tipo de cuenta';

  @override
  String get complete_registration_documents => 'Documentos de identidad';

  @override
  String get complete_registration_submit => 'Completar registro';

  @override
  String get complete_registration_success =>
      'Registro completado. Tu solicitud está pendiente de revisión manual.';

  @override
  String get complete_registration_invalid_data =>
      'Completa todos los campos y adjunta el frente, el reverso y la selfie.';

  @override
  String get complete_registration_unauthorized =>
      'Tu sesión no está activa. Inicia sesión nuevamente para continuar.';

  @override
  String get complete_registration_profile_error =>
      'No se pudo guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get complete_registration_documents_error =>
      'No se pudieron guardar los documentos. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get complete_registration_in_progress =>
      'Ya hay un envío de documentos en curso.';

  @override
  String get complete_registration_unknown_error =>
      'No se pudo completar el registro. Inténtalo de nuevo.';

  @override
  String get complete_registration_missing_documents =>
      'Debes adjuntar el frente, el reverso y la selfie antes de continuar.';

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
      'Diagnóstico simulado en revisión; tu cuenta está a la espera de aprobación por un moderador.';

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
  String get reputation_title => 'Reputación';

  @override
  String get reputation_average_label => 'Calificación promedio';

  @override
  String get reputation_reviews_received => 'Calificaciones recibidas';

  @override
  String get reputation_no_ratings => 'Sin calificaciones aún';

  @override
  String get reputation_new => 'Nuevo';

  @override
  String get reputation_loading => 'Cargando reputación...';

  @override
  String get reputation_load_error => 'No se pudo cargar la reputación.';

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
  String get market_search_hint => 'Buscar por título o tipo de cultivo';

  @override
  String get market_search_clear => 'Borrar búsqueda';

  @override
  String get market_sort_recent => 'Más recientes';

  @override
  String get market_sort_price_asc => 'Menor precio';

  @override
  String get market_sort_price_desc => 'Mayor precio';

  @override
  String get market_sort_reputation => 'Mejor reputación';

  @override
  String get market_no_results =>
      'No se encontraron cosechas que coincidan con estos criterios';

  @override
  String get market_clear_filters => 'Limpiar filtros';

  @override
  String get market_own_profile => 'Mi perfil';

  @override
  String get publish_title_new => 'Publicar Cosecha';

  @override
  String get publish_title_edit => 'Editar Cosecha';

  @override
  String get publish_unauthorized_title => 'Acceso No Autorizado';

  @override
  String get publish_unauthorized_desc =>
      'Solo los agricultores registrados y verificados pueden publicar cosechas.';

  @override
  String get publish_validation_incomplete =>
      'Por favor, completa los campos obligatorios correctamente.';

  @override
  String get publish_harvest_date_required =>
      'Debes indicar la fecha estimada de cosecha para venta anticipada.';

  @override
  String get publish_not_authenticated => 'No autenticado';

  @override
  String get publish_access_farmer_only =>
      'Acceso denegado: solo los agricultores pueden publicar cosechas.';

  @override
  String get publish_access_other_crop =>
      'Acceso denegado: no puedes editar una cosecha perteneciente a otro productor.';

  @override
  String get publish_success_active => '¡Cosecha publicada exitosamente!';

  @override
  String get publish_success_draft => 'Borrador guardado.';

  @override
  String publish_save_error(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get publish_section_general => '1. Información General';

  @override
  String get publish_section_prices => '2. Precios y Cantidades';

  @override
  String get publish_section_location => '3. Ubicación';

  @override
  String get publish_section_sale_mode => '4. Modalidad de Venta';

  @override
  String get publish_section_images => '5. Imágenes';

  @override
  String get publish_field_title => 'Título de la publicación';

  @override
  String get publish_field_crop_type =>
      'Tipo de Producto (Ej: Papa Capira, Café Castillo)';

  @override
  String get publish_field_description => 'Descripción de la cosecha';

  @override
  String get publish_field_price => 'Precio por kg (\$)';

  @override
  String get publish_field_stock => 'Total Disp. (kg)';

  @override
  String get publish_field_min_order => 'Pedido mínimo (kg)';

  @override
  String get publish_field_department => 'Departamento';

  @override
  String get publish_field_municipality => 'Municipio';

  @override
  String get publish_early_sale_title => '¿Es Venta Anticipada?';

  @override
  String get publish_early_sale_desc =>
      'Útil si la cosecha aún no está lista pero quieres asegurar ventas.';

  @override
  String get publish_field_estimated_yield => 'Rendimiento est. (kg)';

  @override
  String get publish_field_harvest_date => 'Fecha de Cosecha';

  @override
  String get publish_select_date => 'Seleccionar...';

  @override
  String get publish_current_images => 'Imágenes actuales de la publicación:';

  @override
  String get publish_add_images => 'Añadir Imágenes';

  @override
  String get publish_save_draft => 'Guardar Borrador';

  @override
  String get publish_submit => 'Publicar';

  @override
  String get publish_validation_required => 'Requerido';

  @override
  String get publish_validation_greater_zero => 'Mayor a 0';

  @override
  String get publish_validation_non_negative => 'Mayor o igual a 0';

  @override
  String get publish_voice_banner_title => 'Borrador creado por voz';

  @override
  String get publish_voice_banner_desc =>
      'Revisa los datos reconocidos. No se publicará nada hasta que confirmes el formulario.';

  @override
  String publish_voice_confirm(String fields) {
    return 'Confirma: $fields';
  }

  @override
  String publish_voice_missing(String fields) {
    return 'Faltan o debes completar: $fields.';
  }

  @override
  String get publish_voice_label_title => 'Título';

  @override
  String get publish_voice_label_description => 'Descripción';

  @override
  String get publish_voice_label_location => 'Ubicación';

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
  String get crop_detail_estimated_distance => 'Distancia estimada';

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
  String counter_offer_subtitle_crop(String crop) {
    return 'Modifica los términos de la oferta para $crop.';
  }

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
  String get deal_detail_rate_title => 'Calificar trato';

  @override
  String get deal_detail_rate_subtitle =>
      'Tu calificación ayuda a construir confianza en la comunidad.';

  @override
  String get deal_detail_rate_target => 'Calificas a';

  @override
  String get deal_detail_rate_stars_label => 'Tu calificación';

  @override
  String get deal_detail_rate_stars_required => 'Selecciona de 1 a 5 estrellas';

  @override
  String get deal_detail_rate_comment_label => 'Comentario (opcional)';

  @override
  String get deal_detail_rate_comment_hint =>
      'Cuéntanos cómo fue tu experiencia';

  @override
  String get deal_detail_rate_submit => 'Enviar calificación';

  @override
  String get deal_detail_rate_success => 'Calificación enviada correctamente';

  @override
  String get deal_detail_rate_error =>
      'No se pudo enviar la calificación. Inténtalo de nuevo.';

  @override
  String get deal_detail_rate_loading => 'Verificando calificación...';

  @override
  String get deal_detail_rated => 'Trato calificado';

  @override
  String get deal_detail_rated_desc =>
      'Ya enviaste tu calificación para este trato.';

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
  String offer_sheet_base_price(String price) {
    return 'Base: $price';
  }

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
  String get moderation_error_title => 'No se pudieron cargar las solicitudes';

  @override
  String get moderation_error_processing => 'Error al procesar la solicitud';

  @override
  String get moderation_error_rejecting => 'Error al rechazar la solicitud';

  @override
  String get moderation_error_updating => 'Error al actualizar la solicitud';

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
      'Los documentos se consultan mediante enlaces firmados temporales del almacenamiento privado. No se comparten públicamente.';

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

  @override
  String get document_front_title => 'Frente del documento';

  @override
  String get document_back_title => 'Reverso del documento';

  @override
  String get document_selfie_title => 'Selfie del usuario';

  @override
  String get document_pick_sheet_title => 'Selecciona el origen de la imagen';

  @override
  String get document_pick_camera => 'Tomar foto';

  @override
  String get document_pick_gallery => 'Elegir de galería';

  @override
  String get document_pick_cancel => 'Cancelar';

  @override
  String get document_pick_error =>
      'No se pudo abrir el selector de imágenes. Inténtalo de nuevo.';

  @override
  String get document_pick_label => 'Seleccionar imagen';

  @override
  String get document_replace_label => 'Reemplazar';

  @override
  String get document_remove_label => 'Quitar';

  @override
  String get document_selected_label => 'Seleccionada';

  @override
  String get document_pending_label => 'Pendiente';

  @override
  String get document_preview_unavailable =>
      'No se pudo previsualizar este archivo.';

  @override
  String get document_preview_pending => 'Aún no has seleccionado esta imagen.';

  @override
  String get document_review_title => 'Revisa tus documentos';

  @override
  String get document_review_description =>
      'Verifica que el frente, el reverso y la selfie sean legibles. Puedes reemplazar cualquiera antes de enviar.';

  @override
  String get document_review_missing =>
      'Debes adjuntar el frente, el reverso y la selfie antes de enviar.';

  @override
  String get document_review_ready =>
      'Las tres imágenes están listas para enviar.';

  @override
  String get document_review_submit => 'Enviar documentos';

  @override
  String get document_review_submit_error =>
      'No se pudo continuar con el envío. Inténtalo de nuevo.';

  @override
  String get document_upload_title => 'Cargar documentos';

  @override
  String get document_upload_description =>
      'Adjunta nuevamente el frente, el reverso y la selfie para enviar tu solicitud de verificación.';

  @override
  String get document_upload_submit => 'Enviar solicitud';

  @override
  String get document_upload_missing =>
      'Debes adjuntar el frente, el reverso y la selfie antes de enviar.';

  @override
  String get document_upload_in_progress => 'Cargando documentos...';

  @override
  String get document_upload_success_title => 'Documentos enviados';

  @override
  String get document_upload_success_desc =>
      'Tu solicitud quedó registrada y está pendiente de revisión manual.';

  @override
  String get document_upload_success_back => 'Volver al estado';

  @override
  String get document_upload_error =>
      'No se pudieron cargar los documentos. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get document_upload_storage_error =>
      'No se pudieron cargar las imágenes al almacenamiento privado. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get document_upload_attempt_error =>
      'Las imágenes se cargaron, pero no se pudo registrar la solicitud. Inténtalo de nuevo.';

  @override
  String get document_upload_duplicate =>
      'Ya existe una solicitud pendiente de revisión.';

  @override
  String get document_upload_file_missing =>
      'Uno de los archivos seleccionados ya no está disponible. Vuelve a seleccionarlo.';

  @override
  String get document_upload_unauthorized =>
      'Debes iniciar sesión para enviar documentos de verificación.';

  @override
  String get document_image_available => 'Documento disponible para revisión';

  @override
  String get document_image_missing => 'Documento no proporcionado';

  @override
  String get document_image_invalid =>
      'Ruta de documento no válida o no disponible';

  @override
  String get document_image_loading => 'Obteniendo enlace seguro...';

  @override
  String get document_image_error =>
      'No se pudo obtener el enlace seguro del documento.';

  @override
  String get document_image_display_error => 'No se pudo mostrar la imagen.';

  @override
  String get document_image_retry => 'Reintentar';

  @override
  String get moderation_diagnosis_title => 'Diagnóstico documental';

  @override
  String get moderation_diagnosis_simulated => 'SIMULADO';

  @override
  String get moderation_diagnosis_disclaimer =>
      'Informe demostrativo basado únicamente en la presencia y validez básica de las rutas de documentos. No verifica la autenticidad ni la identidad.';

  @override
  String get moderation_diagnosis_present => 'Presente';

  @override
  String get moderation_diagnosis_missing => 'Faltante';

  @override
  String get moderation_diagnosis_available_label =>
      'Imágenes disponibles para revisión:';

  @override
  String get moderation_diagnosis_pending =>
      'Resultado general: pendiente de revisión humana.';

  @override
  String get moderation_diagnosis_observations_title =>
      'Observaciones para revisión manual';

  @override
  String get moderation_diagnosis_obs_profile =>
      'Comprueba manualmente el nombre, teléfono y rol del perfil.';

  @override
  String get moderation_diagnosis_obs_missing_docs =>
      'Faltan documentos obligatorios; no se deben inferir datos ausentes.';

  @override
  String get moderation_diagnosis_obs_shared_paths =>
      'Las rutas de documentos no son independientes; verifícalas antes de decidir.';

  @override
  String get moderation_diagnosis_obs_email =>
      'El perfil no tiene correo registrado; la comprobación de contacto es manual.';

  @override
  String get moderation_diagnosis_limitations_title =>
      'Limitaciones del diagnóstico';

  @override
  String get moderation_diagnosis_limit_authenticity =>
      'No verifica la autenticidad del documento.';

  @override
  String get moderation_diagnosis_limit_biometrics =>
      'No realiza coincidencia biométrica ni prueba de vida.';

  @override
  String get moderation_diagnosis_limit_external =>
      'No consulta bases gubernamentales ni servicios externos de IA.';

  @override
  String get moderation_diagnosis_limit_auto =>
      'No aprueba ni rechaza automáticamente la solicitud.';

  @override
  String get moderation_diagnosis_no_auto =>
      'La decisión final es exclusivamente manual del moderador.';

  @override
  String get moderation_btn_mark_in_review => 'Poner en revisión';

  @override
  String get moderation_in_review_success =>
      'Solicitud marcada en revisión correctamente.';

  @override
  String get moderation_filter_all => 'Todos';

  @override
  String get moderation_filter_pending => 'Pendientes';

  @override
  String get moderation_filter_in_review => 'En revisión';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_save_changes => 'Guardar cambios';

  @override
  String get common_back => 'Volver';

  @override
  String get common_understood => 'Entendido';

  @override
  String get common_accept => 'Aceptar';

  @override
  String get common_not_available => 'No disponible';

  @override
  String get common_simulated => 'SIMULADA';

  @override
  String get common_field_required => 'Campo requerido';

  @override
  String get common_greater_than_zero => 'Debe ser mayor a 0';

  @override
  String common_unexpected_error(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get common_operation_error =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String common_error_prefix(String error) {
    return 'Ocurrió un error: $error';
  }

  @override
  String product_card_variety(String variety) {
    return 'Variedad: $variety';
  }

  @override
  String get product_card_view_details => 'Ver detalles';

  @override
  String get seller_details_reliability => 'Confiabilidad';

  @override
  String get seller_details_volume => 'Volumen Disponible';

  @override
  String get seller_details_min_order => 'Pedido Mínimo';

  @override
  String get seller_details_condition => 'Condición & Logística';

  @override
  String get otp_error_incomplete =>
      'Por favor, ingresa los 6 dígitos completos';

  @override
  String get otp_resend_simulated => 'Código reenviado (Simulado)';

  @override
  String get personal_info_phone_invalid => 'Número telefónico inválido';

  @override
  String get personal_info_password_min => 'Mínimo 6 caracteres';

  @override
  String get processing_confirmation_required =>
      'Cuenta creada. Por favor confirma tu medio de contacto para continuar.';

  @override
  String get verification_status_simulated_review =>
      'Diagnóstico simulado en revisión; tu cuenta está a la espera de aprobación por un moderador.';

  @override
  String get auth_gate_invalid_role =>
      'El rol del perfil no es válido o no está definido.';

  @override
  String get auth_gate_checking => 'Consultando estado...';

  @override
  String get auth_gate_generic_error_title => 'Ha ocurrido un error';

  @override
  String get auth_gate_unknown_status =>
      'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.';

  @override
  String get costs_title => 'Costos';

  @override
  String get costs_intro =>
      'Lleva un registro de los gastos\nasociados a tus cosechas.';

  @override
  String costs_per_kg_calculated(String amount) {
    return 'Costo por kg: $amount';
  }

  @override
  String get costs_per_kg_no_costs => 'Costo por kg: sin costos registrados';

  @override
  String get costs_per_kg_invalid_total => 'Costo por kg: total inválido';

  @override
  String get costs_per_kg_invalid_quantity => 'Costo por kg: cantidad inválida';

  @override
  String get costs_per_kg_pending_yield =>
      'Costo por kg: rendimiento estimado pendiente';

  @override
  String get costs_total => 'Total de costos';

  @override
  String get costs_view => 'Ver costos';

  @override
  String get costs_empty_title => 'Primero debes crear una cosecha';

  @override
  String get costs_empty_desc =>
      'Para llevar un registro de costos, necesitas tener al menos una cosecha registrada.';

  @override
  String get costs_create_crop => 'Crear cosecha';

  @override
  String get costs_add => 'Agregar costo';

  @override
  String get costs_add_title => 'Agregar Costo';

  @override
  String get costs_edit_title => 'Editar Costo';

  @override
  String get costs_category => 'Categoría';

  @override
  String get costs_description => 'Descripción';

  @override
  String get costs_description_hint => 'Ej: Mano de obra para recolección';

  @override
  String get costs_description_required => 'Por favor ingresa una descripción';

  @override
  String get costs_value => 'Valor';

  @override
  String get costs_value_hint => 'Ej: 150000 o 150000,50';

  @override
  String get costs_value_required => 'Por favor ingresa un valor';

  @override
  String get costs_value_invalid => 'Ingresa un importe numérico mayor que 0';

  @override
  String get costs_save => 'Guardar costo';

  @override
  String get costs_update => 'Actualizar costo';

  @override
  String get costs_added => 'Costo agregado exitosamente';

  @override
  String get costs_updated => 'Costo actualizado exitosamente';

  @override
  String costs_save_error(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get costs_delete_title => '¿Eliminar este costo?';

  @override
  String get costs_delete_desc => 'Esta acción no se puede deshacer.';

  @override
  String get costs_deleted => 'Costo eliminado';

  @override
  String costs_delete_error(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get costs_estimated_per_kg => 'Costo estimado por kg';

  @override
  String costs_quantity_used(String quantity, String source) {
    return 'Cantidad usada: $quantity ($source)';
  }

  @override
  String costs_source_field(String field) {
    return 'Campo: $field';
  }

  @override
  String get costs_profitability_title => 'Margen y precio sugerido';

  @override
  String get costs_profitability_subtitle =>
      'Calcula ganancia, margen y compara con referencias simuladas.';

  @override
  String get costs_empty_detail_title => 'Aún no tienes costos registrados';

  @override
  String get costs_empty_detail_desc =>
      'Agrega los gastos relacionados con esta cosecha para llevar un mejor control.';

  @override
  String get profitability_title => 'Margen y precio sugerido';

  @override
  String get profitability_cost_per_kg => 'Costo de producción por kg';

  @override
  String profitability_used_quantity(
    String quantity,
    String source,
    String field,
  ) {
    return 'Cantidad usada: $quantity ($source) · $field';
  }

  @override
  String get profitability_current_price => 'Precio actual publicado';

  @override
  String get profitability_invalid_current_price =>
      'El precio actual no es válido. Puedes introducir un precio temporal para la simulación.';

  @override
  String get profitability_unavailable_title =>
      'No se puede calcular el margen ni el precio sugerido';

  @override
  String get profitability_unavailable_desc =>
      'Corrige los costos o los datos del cultivo para continuar. No se muestran valores estimados para evitar resultados engañosos.';

  @override
  String get profitability_evaluate_title => 'Evalúa tu precio de venta';

  @override
  String get profitability_selling_price => 'Precio de venta por kg';

  @override
  String get profitability_edit_note =>
      'Puedes editar este valor para la simulación; no se guarda ni modifica el precio publicado.';

  @override
  String get profitability_temporary_price =>
      'Precio temporal para simulación; no se ha guardado.';

  @override
  String get profitability_invalid_price =>
      'Ingresa un precio de venta válido mayor que 0.';

  @override
  String get profitability_loss_per_kg => 'Pérdida estimada por kg';

  @override
  String get profitability_profit_per_kg => 'Ganancia estimada por kg';

  @override
  String get profitability_margin_over_price =>
      'Margen sobre el precio de venta';

  @override
  String get profitability_loss_message =>
      'El precio evaluado está por debajo del costo de producción.';

  @override
  String get profitability_low_margin =>
      'El margen está por debajo del 15 % de referencia del prototipo.';

  @override
  String get profitability_margin_formula =>
      'Margen = (precio − costo) / precio × 100';

  @override
  String get profitability_suggested_title =>
      'Precio sugerido según margen objetivo';

  @override
  String get profitability_target_margin => 'Margen objetivo (%)';

  @override
  String get profitability_margin_note =>
      'El margen se aplica sobre el precio de venta; no es un recargo sobre el costo.';

  @override
  String get profitability_invalid_margin =>
      'Ingresa un margen entre 0 % y menos de 100 %.';

  @override
  String get profitability_orientation =>
      'Precio orientativo. No modifica ni publica el precio del cultivo.';

  @override
  String get profitability_regional_reference => 'Referencia regional simulada';

  @override
  String get profitability_reference_missing =>
      'No hay una referencia simulada configurada para este cultivo.';

  @override
  String get profitability_reference_crop => 'Cultivo de referencia';

  @override
  String get profitability_reference_region => 'Región';

  @override
  String get profitability_reference_price => 'Precio de referencia simulado';

  @override
  String get profitability_reference_type => 'Tipo de dato';

  @override
  String get profitability_reference_simulated => 'Simulado para el prototipo';

  @override
  String get profitability_reference_difference =>
      'Diferencia frente a la referencia simulada';

  @override
  String get profitability_reference_difference_note =>
      'La diferencia se calcula como precio evaluado − referencia.';

  @override
  String get crop_detail_less_than_km => '< 1 km';

  @override
  String crop_detail_km(String km) {
    return '$km km';
  }

  @override
  String get crop_detail_owner_edit_denied =>
      'Acceso denegado: solo el productor dueño puede modificar esta publicación.';

  @override
  String crop_detail_error(String error) {
    return 'Error: $error';
  }

  @override
  String get crop_detail_other_edit_denied =>
      'Acceso denegado: no puedes editar publicaciones de otros usuarios.';

  @override
  String get crop_detail_other_delete_denied =>
      'Acceso denegado: no puedes borrar publicaciones de otros usuarios.';

  @override
  String get crop_detail_delete_title => 'Borrar Publicación';

  @override
  String get crop_detail_delete_confirm =>
      '¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.';

  @override
  String get crop_detail_deleted => 'Publicación borrada exitosamente';

  @override
  String get crop_detail_own_offer_error =>
      'No puedes iniciar una oferta en tu propia cosecha.';

  @override
  String get crop_detail_out_of_stock =>
      'Esta cosecha se encuentra agotada o sin stock disponible.';

  @override
  String get crop_detail_verification_required => 'Verificación requerida';

  @override
  String get crop_detail_verification_desc =>
      'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.';

  @override
  String get crop_detail_offer_sent => 'Oferta enviada exitosamente.';

  @override
  String get crop_detail_view_deals => 'Ver Tratos';

  @override
  String get crop_detail_total_available => 'Total Disponible';

  @override
  String crop_detail_price_matches_reference(String price) {
    return 'Precio igual a la referencia regional ($price/kg)';
  }

  @override
  String crop_detail_price_vs_reference(
    String sign,
    String amount,
    String percent,
    String reference,
  ) {
    return '$sign$amount/kg ($sign$percent%) vs referencia regional ($reference/kg)';
  }

  @override
  String crop_detail_regional_reference_region(String region) {
    return 'Referencia regional ($region)';
  }

  @override
  String crop_detail_producer_with_location(String producer, String location) {
    return '$producer ($location)';
  }

  @override
  String get crop_status_draft => 'Borrador';

  @override
  String get crop_status_active => 'Activa';

  @override
  String get crop_status_paused => 'Pausada';

  @override
  String get crop_status_exhausted => 'Agotada';

  @override
  String offer_sheet_min_stock(String min, String stock) {
    return 'Mín: $min | Stock: $stock';
  }

  @override
  String get units_title => 'Equivalencias de Unidades';

  @override
  String get units_close => 'Entendido';

  @override
  String get units_reference_quantity => 'Cantidad de referencia (disponible)';

  @override
  String get units_calculate_quantity => 'Consultar otra cantidad (kg)';

  @override
  String get units_input_hint => 'Ej. 500';

  @override
  String get units_approximate_equivalents =>
      'Equivalencias tradicionales aproximadas';

  @override
  String units_equivalence_rate(String unit, String value) {
    return '1 $unit = $value';
  }

  @override
  String get units_disclaimer =>
      'Conversiones aproximadas de carácter exclusivamente informativo. No modifican el inventario, los precios ni los pedidos.';

  @override
  String units_empty(String unit) {
    return '0 $unit';
  }

  @override
  String units_approx(String value, String unit) {
    return '≈ $value $unit';
  }

  @override
  String deals_error_prefix(String error) {
    return 'Ocurrió un error: $error';
  }

  @override
  String get deals_producer => 'Productor';

  @override
  String get deals_buyer => 'Comprador';

  @override
  String deals_producer_with_location(String location) {
    return 'Productor ($location)';
  }

  @override
  String deals_counterpart_name(String label, String name) {
    return '$label: $name';
  }

  @override
  String get deal_detail_offer_history => 'Historial de ofertas';

  @override
  String get deal_detail_rating_sent => 'Calificación enviada correctamente';

  @override
  String get deal_detail_generic_error =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get deal_detail_the_farmer => 'El productor';

  @override
  String get deal_detail_the_buyer => 'El comprador';

  @override
  String get deal_detail_authorized => 'Autorizado';

  @override
  String get deal_detail_private => 'Privado';

  @override
  String get deal_detail_location_authorized_status => 'Autorizada';

  @override
  String get deal_detail_location_private_status => 'Privada';

  @override
  String deal_detail_permissions_update_error(String error) {
    return 'Error al actualizar permisos: $error';
  }

  @override
  String get deal_detail_share_farm_location_permission =>
      'Compartir la ubicación de la finca';

  @override
  String get deal_detail_contact_farmer => 'Datos de contacto del Productor';

  @override
  String get deal_detail_contact_buyer => 'Datos de contacto del Comprador';

  @override
  String get deal_detail_phone_whatsapp => 'Teléfono / WhatsApp autorizado:';

  @override
  String get deal_detail_call => 'Llamar';

  @override
  String get deal_detail_whatsapp => 'WhatsApp';

  @override
  String get deal_detail_copy => 'Copiar';

  @override
  String get deal_detail_phone => 'Teléfono';

  @override
  String deal_detail_contact_not_shared(String role) {
    return '$role no ha autorizado compartir su teléfono ni WhatsApp.';
  }

  @override
  String get deal_detail_location_authorized => 'Ubicación física autorizada:';

  @override
  String deal_detail_coordinates(String lat, String lon) {
    return 'Coordenadas: $lat, $lon';
  }

  @override
  String get deal_detail_view_location => 'Ver detalles de ubicación';

  @override
  String deal_detail_location_not_shared(String role) {
    return '$role no ha autorizado compartir su ubicación física.';
  }

  @override
  String get deal_detail_my_permissions => 'Tus permisos para este trato:';

  @override
  String deal_detail_phone_permission(String status) {
    return 'Teléfono: $status';
  }

  @override
  String deal_detail_location_permission(String status) {
    return 'Ubicación: $status';
  }

  @override
  String get deal_detail_modify => 'Modificar';

  @override
  String deal_detail_copied(String label, String text) {
    return '$label copiado al portapapeles: $text';
  }

  @override
  String deal_detail_phone_copied(String phone) {
    return 'Teléfono $phone copiado. Listo para marcar desde tu teléfono.';
  }

  @override
  String deal_detail_whatsapp_copied(String phone) {
    return 'Contacto de WhatsApp $phone copiado. Abre WhatsApp para iniciar conversación.';
  }

  @override
  String get deal_detail_municipality_department => 'Municipio / Departamento:';

  @override
  String get deal_detail_geo_coordinates => 'Coordenadas geográficas:';

  @override
  String deal_detail_lat_lon(String lat, String lon) {
    return 'Lat: $lat\nLon: $lon';
  }

  @override
  String get deal_detail_location_verified =>
      'Ubicación verificada para la entrega de este lote.';

  @override
  String get deal_detail_coordinates_label => 'Coordenadas';

  @override
  String get deal_detail_copy_coordinates => 'Copiar coordenadas';

  @override
  String get deal_detail_you => 'Tú';

  @override
  String deal_detail_delivery(String method) {
    return 'Entrega: $method';
  }

  @override
  String get deal_detail_cancel_proposal => 'Cancelar propuesta';

  @override
  String deal_detail_consent_save_error(String error) {
    return 'Aviso: no se pudo guardar consentimiento inicial: $error';
  }

  @override
  String get deal_detail_agreed_success => 'Trato acordado correctamente';

  @override
  String get deal_detail_permissions_updated =>
      'Permisos de contacto actualizados correctamente';

  @override
  String get deal_detail_reject_confirm_desc_extended =>
      'Esta acción no se puede deshacer y el trato se cerrará.';

  @override
  String get deal_detail_rejected => 'El trato ha sido rechazado';

  @override
  String get deal_detail_cancel_confirm_title => '¿Cancelar este acuerdo?';

  @override
  String get deal_detail_cancel_proposal_title => '¿Cancelar esta propuesta?';

  @override
  String get deal_detail_cancel_confirm_desc =>
      'Esta acción cancelará el trato acordado, liberará el stock reservado y cerrará la negociación.';

  @override
  String get deal_detail_cancel_proposal_desc =>
      'Esta acción cancelará la propuesta enviada, liberará el stock reservado y cerrará la negociación.';

  @override
  String get deal_detail_cancel_agreed_btn => 'Cancelar acuerdo';

  @override
  String get deal_detail_cancel_proposal_btn => 'Cancelar propuesta';

  @override
  String get deal_detail_cancelled_success => 'Acuerdo cancelado correctamente';

  @override
  String get deal_detail_proposal_cancelled_success =>
      'Propuesta cancelada correctamente';

  @override
  String get deal_detail_complete_confirm_title => '¿Completar este trato?';

  @override
  String get deal_detail_complete_confirm_desc =>
      'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.';

  @override
  String get deal_detail_complete => 'Completar';

  @override
  String get deal_detail_completed => 'Trato completado exitosamente';

  @override
  String get deal_detail_rating_error =>
      'No se pudo enviar la calificación. Inténtalo de nuevo.';

  @override
  String get deal_detail_stars_required => 'Selecciona de 1 a 5 estrellas';

  @override
  String get deal_detail_comment_optional => 'Comentario (opcional)';

  @override
  String get deal_detail_comment_hint => 'Cuéntanos cómo fue tu experiencia';

  @override
  String get deal_detail_submit_rating => 'Enviar calificación';

  @override
  String get deal_detail_accept_terms_title => 'Aceptar oferta y acordar trato';

  @override
  String get deal_detail_accept_terms_desc =>
      'Al formalizar el acuerdo, el inventario pactado se reservará en el sistema. Selecciona qué datos de contacto autorizas compartir con la contraparte para coordinar la entrega física:';

  @override
  String get deal_detail_share_phone => 'Compartir mi teléfono y WhatsApp';

  @override
  String get deal_detail_share_phone_desc =>
      'Permite a la contraparte llamarte o escribirte por WhatsApp para coordinar.';

  @override
  String get deal_detail_share_location => 'Compartir mi ubicación de entrega';

  @override
  String get deal_detail_share_farm_location =>
      'Compartir la ubicación de la finca';

  @override
  String get deal_detail_share_location_desc =>
      'Permite ver el municipio y coordenadas para planificar la ruta de entrega.';

  @override
  String get deal_detail_confirm_agreement => 'Confirmar acuerdo';

  @override
  String get deal_detail_my_permissions_title => 'Mis permisos de contacto';

  @override
  String get deal_detail_my_permissions_desc =>
      'Controla qué datos privados autorizas ver a la contraparte para coordinar este trato. Puedes revocar o conceder permisos en cualquier momento:';

  @override
  String get deal_detail_share_phone_desc_permission =>
      'La contraparte podrá ver tu número para llamadas o mensajes.';

  @override
  String get deal_detail_share_location_desc_permission =>
      'La contraparte podrá ver municipio y coordenadas para la logística.';

  @override
  String get moderation_reject_sheet_title => 'Rechazar Solicitud';

  @override
  String get moderation_reject_reason_desc =>
      'Indica el motivo del rechazo para que el usuario pueda corregirlo:';

  @override
  String get moderation_lbl_email => 'Email:';

  @override
  String get moderation_lbl_user_id => 'User ID:';

  @override
  String get moderation_queue_refresh => 'Actualizar';

  @override
  String get moderation_status_pending => 'Pendiente';

  @override
  String get moderation_status_approved => 'Aprobado';

  @override
  String get moderation_status_rejected => 'Rechazado';

  @override
  String get moderation_status_suspended => 'Suspendido';

  @override
  String get moderation_status_unknown => 'Desconocido';

  @override
  String get profile_title => 'Mi Perfil';

  @override
  String get profile_my_farm => 'Mi Finca';

  @override
  String get profile_settings => 'Configuración';

  @override
  String get profile_load_data_error => 'No se pudieron cargar los datos.';

  @override
  String get profile_location => 'Ubicación';

  @override
  String get profile_whatsapp => 'WhatsApp';

  @override
  String get profile_stats_heading => 'Estadísticas';

  @override
  String get profile_published => 'Publicados';

  @override
  String get profile_negotiating => 'Negociando';

  @override
  String get profile_closed_female => 'Cerradas';

  @override
  String get profile_closed_male => 'Cerrados';

  @override
  String profile_update_error(String error) {
    return 'Error al actualizar dato: $error';
  }

  @override
  String profile_photo_error(String error) {
    return 'Error al subir imagen: $error';
  }

  @override
  String get profile_reputation_title => 'Reputación';

  @override
  String get profile_reputation_loading => 'Cargando reputación...';

  @override
  String get profile_reputation_error => 'No se pudo cargar la reputación.';

  @override
  String purchases_error_prefix(String error) {
    return 'Ocurrió un error: $error';
  }

  @override
  String get purchases_merchant_role => 'Rol Comerciante';

  @override
  String get purchase_card_producer_local => 'Productor local';

  @override
  String purchase_card_producer_municipality(String municipality) {
    return 'Productor ($municipality)';
  }

  @override
  String get purchase_card_agreed_crop => 'Cosecha acordada';

  @override
  String get purchase_card_quantity => 'Cantidad';

  @override
  String get purchase_card_price_per_kg => 'Precio / kg';

  @override
  String get purchase_card_total_agreed => 'Total pactado';

  @override
  String get ai_close => 'Cerrar';

  @override
  String get ai_title => 'Publicar por voz';

  @override
  String get ai_subtitle =>
      'Cuéntanos qué quieres vender. Revisarás todo antes de publicar.';

  @override
  String get ai_examples_title => 'Puedes mencionar:';

  @override
  String get ai_examples_desc =>
      'Nombre del cultivo, cantidad y unidad (kg, bulto, arroba, canastilla, caja o tonelada), y precio por kg o por unidad.';

  @override
  String get ai_example_text =>
      'Ejemplo: “Tengo 50 bultos de papa a 2.000 pesos el kilo”.';

  @override
  String get ai_unavailable_title =>
      'La interpretación automática no está disponible en este entorno porque falta AI_API_KEY.';

  @override
  String get ai_unavailable_desc =>
      'Puedes dictar y revisar la transcripción, o continuar manualmente.';

  @override
  String get ai_preparing => 'Preparando el micrófono...';

  @override
  String get ai_permission_title => 'Permiso de micrófono denegado';

  @override
  String get ai_permission_desc =>
      'No podemos acceder al micrófono. Habilita el permiso en los ajustes del sistema o continúa manualmente.';

  @override
  String get ai_voice_unavailable_title =>
      'Reconocimiento de voz no disponible';

  @override
  String get ai_voice_unavailable_desc =>
      'Este dispositivo no ofrece el servicio de reconocimiento de voz que necesita la aplicación. Puedes publicar manualmente.';

  @override
  String get ai_transcribing => 'Transcribiendo lo que dijiste...';

  @override
  String get ai_interpreting => 'Interpretando los datos con IA...';

  @override
  String get ai_intro =>
      'Pulsa el micrófono y describe tu cosecha con tus propias palabras. No se publicará nada automáticamente.';

  @override
  String get ai_start => 'Comenzar a hablar';

  @override
  String get ai_manual => 'Prefiero llenar el formulario manualmente';

  @override
  String get ai_retry_mic => 'Reintentar micrófono';

  @override
  String get ai_continue_manual => 'Continuar manualmente';

  @override
  String get ai_listening => 'Escuchando...';

  @override
  String get ai_listening_hint =>
      'Habla ahora. Puedes detenerte cuando termines.';

  @override
  String get ai_stop_review => 'Detener y revisar';

  @override
  String get ai_review_transcript_title => 'Revisa la transcripción';

  @override
  String get ai_review_transcript_desc =>
      'Si el micrófono entendió mal alguna palabra, corrígela antes de interpretar los datos.';

  @override
  String get ai_transcript_label => 'Transcripción';

  @override
  String get ai_interpret => 'Interpretar con IA';

  @override
  String get ai_record_again => 'Grabar de nuevo';

  @override
  String get ai_recognized_title => 'Datos reconocidos';

  @override
  String get ai_recognized_desc =>
      'Estos datos se precargarán en el formulario. Todavía puedes corregirlos y debes completar lo que falte.';

  @override
  String get ai_no_data_desc =>
      'No se identificaron datos utilizables. Puedes reintentar la interpretación, grabar de nuevo o continuar manualmente.';

  @override
  String get ai_warnings => 'Advertencias';

  @override
  String get ai_confirm_data => 'Confirma estos datos';

  @override
  String get ai_missing_data => 'Faltan datos por completar';

  @override
  String get ai_review_continue => 'Revisar y continuar';

  @override
  String get ai_retry_interpret => 'Reintentar interpretación';

  @override
  String get ai_crop => 'Cultivo';

  @override
  String get ai_quantity => 'Cantidad';

  @override
  String get ai_price => 'Precio';

  @override
  String get ai_note => 'Nota';

  @override
  String get ai_no_data => 'Sin datos identificados.';

  @override
  String get ai_failed_title => 'No se pudo completar';

  @override
  String get ai_failed_desc =>
      'Ocurrió un problema. Intenta de nuevo o continúa manualmente.';

  @override
  String get ai_error_mic_start =>
      'No se pudo iniciar el micrófono. Comprueba el permiso o continúa manualmente.';

  @override
  String get ai_error_mic_stop =>
      'No se pudo detener el reconocimiento de voz. Vuelve a intentarlo o continúa manualmente.';

  @override
  String get ai_error_no_speech =>
      'No se reconoció voz. Acércate al micrófono, intenta de nuevo o continúa manualmente.';

  @override
  String get ai_error_no_speech_retry =>
      'No se reconoció voz. Intenta hablar más cerca del micrófono o continúa manualmente.';

  @override
  String get ai_error_empty_transcript =>
      'La transcripción está vacía. Graba de nuevo o escribe lo que deseas publicar.';

  @override
  String get ai_error_not_configured =>
      'La interpretación con IA no está configurada. Falta AI_API_KEY. Puedes continuar manualmente.';

  @override
  String get ai_error_interpret =>
      'No se pudo interpretar la transcripción. Intenta de nuevo o continúa manualmente.';
}
