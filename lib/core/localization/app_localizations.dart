import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @welcome_title.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcome_title;

  /// No description provided for @welcome_description.
  ///
  /// In es, this message translates to:
  /// **'Conecta directamente con productores y compradores para comercializar productos agrícolas de forma fácil, segura y transparente.'**
  String get welcome_description;

  /// No description provided for @welcome_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get welcome_continue;

  /// No description provided for @personal_info_title.
  ///
  /// In es, this message translates to:
  /// **'Información personal'**
  String get personal_info_title;

  /// No description provided for @personal_info_phone.
  ///
  /// In es, this message translates to:
  /// **'Número telefónico'**
  String get personal_info_phone;

  /// No description provided for @personal_info_first_name.
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get personal_info_first_name;

  /// No description provided for @personal_info_last_name.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get personal_info_last_name;

  /// No description provided for @personal_info_verification_description.
  ///
  /// In es, this message translates to:
  /// **'En el siguiente paso enviaremos un código de verificación de 6 dígitos para confirmar tu número.'**
  String get personal_info_verification_description;

  /// No description provided for @personal_info_active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get personal_info_active;

  /// No description provided for @personal_info_required.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get personal_info_required;

  /// No description provided for @personal_info_phone_hint.
  ///
  /// In es, this message translates to:
  /// **'315-000-0000'**
  String get personal_info_phone_hint;

  /// No description provided for @personal_info_first_name_hint.
  ///
  /// In es, this message translates to:
  /// **'ej. Juan'**
  String get personal_info_first_name_hint;

  /// No description provided for @personal_info_last_name_hint.
  ///
  /// In es, this message translates to:
  /// **'ej. Pérez'**
  String get personal_info_last_name_hint;

  /// No description provided for @role_selection_header_title.
  ///
  /// In es, this message translates to:
  /// **'Selección tipo'**
  String get role_selection_header_title;

  /// No description provided for @role_selection_title.
  ///
  /// In es, this message translates to:
  /// **'Elige el rol que mejor describe tu actividad en la plataforma.'**
  String get role_selection_title;

  /// No description provided for @role_selection_producer.
  ///
  /// In es, this message translates to:
  /// **'Productor'**
  String get role_selection_producer;

  /// No description provided for @role_selection_producer_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Vende y distribuye'**
  String get role_selection_producer_subtitle;

  /// No description provided for @role_selection_producer_description.
  ///
  /// In es, this message translates to:
  /// **'Publicación directa en el mercado y análisis'**
  String get role_selection_producer_description;

  /// No description provided for @role_selection_buyer.
  ///
  /// In es, this message translates to:
  /// **'Comprador'**
  String get role_selection_buyer;

  /// No description provided for @role_selection_buyer_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Busca y compra'**
  String get role_selection_buyer_subtitle;

  /// No description provided for @role_selection_buyer_description.
  ///
  /// In es, this message translates to:
  /// **'Logística transparente y procedencia de lotes'**
  String get role_selection_buyer_description;

  /// No description provided for @role_selection_kyc_notice.
  ///
  /// In es, this message translates to:
  /// **'La verificación KYC aplica después de la selección del rol'**
  String get role_selection_kyc_notice;

  /// No description provided for @role_selection_error_no_role.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona un rol'**
  String get role_selection_error_no_role;

  /// No description provided for @document_selection_header_title.
  ///
  /// In es, this message translates to:
  /// **'Identificación documento'**
  String get document_selection_header_title;

  /// No description provided for @document_selection_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación de documento'**
  String get document_selection_title;

  /// No description provided for @document_selection_description.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos confirmar tu identidad legal antes de activar tu cuenta.'**
  String get document_selection_description;

  /// No description provided for @document_selection_select_id.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONA TU TIPO DE IDENTIFICACIÓN'**
  String get document_selection_select_id;

  /// No description provided for @document_selection_cc.
  ///
  /// In es, this message translates to:
  /// **'CC'**
  String get document_selection_cc;

  /// No description provided for @document_selection_cc_desc.
  ///
  /// In es, this message translates to:
  /// **'Cédula de Ciudadanía / National ID'**
  String get document_selection_cc_desc;

  /// No description provided for @document_selection_driver_license.
  ///
  /// In es, this message translates to:
  /// **'Licencia de Conducir'**
  String get document_selection_driver_license;

  /// No description provided for @document_selection_driver_license_desc.
  ///
  /// In es, this message translates to:
  /// **'Permiso de conducir oficial'**
  String get document_selection_driver_license_desc;

  /// No description provided for @document_selection_encryption_notice.
  ///
  /// In es, this message translates to:
  /// **'Verificación de identidad encriptada de 256 bits'**
  String get document_selection_encryption_notice;

  /// No description provided for @document_selection_error_no_doc.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona un tipo de documento'**
  String get document_selection_error_no_doc;

  /// No description provided for @capture_front_header_title.
  ///
  /// In es, this message translates to:
  /// **'Identificación documento'**
  String get capture_front_header_title;

  /// No description provided for @capture_front_title.
  ///
  /// In es, this message translates to:
  /// **'Capturar parte frontal'**
  String get capture_front_title;

  /// No description provided for @capture_front_description.
  ///
  /// In es, this message translates to:
  /// **'Posiciona la parte frontal de tu documento dentro del marco.'**
  String get capture_front_description;

  /// No description provided for @capture_front_identity_verification.
  ///
  /// In es, this message translates to:
  /// **'Verificación de Identidad'**
  String get capture_front_identity_verification;

  /// No description provided for @capture_front_aligning.
  ///
  /// In es, this message translates to:
  /// **'Mantente quieto — alineando documento...'**
  String get capture_front_aligning;

  /// No description provided for @capture_front_auto_capture.
  ///
  /// In es, this message translates to:
  /// **'Captura automática lista'**
  String get capture_front_auto_capture;

  /// No description provided for @capture_front_tip_light.
  ///
  /// In es, this message translates to:
  /// **'Buena luz'**
  String get capture_front_tip_light;

  /// No description provided for @capture_front_tip_fit.
  ///
  /// In es, this message translates to:
  /// **'Encuadrar'**
  String get capture_front_tip_fit;

  /// No description provided for @capture_front_tip_glare.
  ///
  /// In es, this message translates to:
  /// **'Sin reflejos'**
  String get capture_front_tip_glare;

  /// No description provided for @capture_front_tap_to_capture.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón abajo para capturar'**
  String get capture_front_tap_to_capture;

  /// No description provided for @capture_back_header_title.
  ///
  /// In es, this message translates to:
  /// **'Identificación documento'**
  String get capture_back_header_title;

  /// No description provided for @capture_back_title.
  ///
  /// In es, this message translates to:
  /// **'Capturar parte trasera'**
  String get capture_back_title;

  /// No description provided for @capture_back_description.
  ///
  /// In es, this message translates to:
  /// **'Gira tu documento y posiciona la parte trasera dentro del marco.'**
  String get capture_back_description;

  /// No description provided for @capture_back_steady.
  ///
  /// In es, this message translates to:
  /// **'Parte trasera detectada — mantente firme'**
  String get capture_back_steady;

  /// No description provided for @capture_back_tip_light.
  ///
  /// In es, this message translates to:
  /// **'Buena luz'**
  String get capture_back_tip_light;

  /// No description provided for @capture_back_tip_fit.
  ///
  /// In es, this message translates to:
  /// **'Encuadrar'**
  String get capture_back_tip_fit;

  /// No description provided for @capture_back_tip_barcode.
  ///
  /// In es, this message translates to:
  /// **'codigo claro'**
  String get capture_back_tip_barcode;

  /// No description provided for @capture_back_tap_to_capture.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón abajo para capturar'**
  String get capture_back_tap_to_capture;

  /// No description provided for @facial_verification_header_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación facial'**
  String get facial_verification_header_title;

  /// No description provided for @facial_verification_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación Facial'**
  String get facial_verification_title;

  /// No description provided for @facial_verification_description.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos escanear tu rostro para verificar que eres una persona real.'**
  String get facial_verification_description;

  /// No description provided for @facial_verification_face_detected.
  ///
  /// In es, this message translates to:
  /// **'Rostro detectado • Coincidencia perfecta'**
  String get facial_verification_face_detected;

  /// No description provided for @facial_verification_liveness.
  ///
  /// In es, this message translates to:
  /// **'Detección de vida activa'**
  String get facial_verification_liveness;

  /// No description provided for @facial_verification_tip_light.
  ///
  /// In es, this message translates to:
  /// **'Buena luz'**
  String get facial_verification_tip_light;

  /// No description provided for @facial_verification_tip_glasses.
  ///
  /// In es, this message translates to:
  /// **'Sin lentes'**
  String get facial_verification_tip_glasses;

  /// No description provided for @facial_verification_tip_straight.
  ///
  /// In es, this message translates to:
  /// **'Mira al frente'**
  String get facial_verification_tip_straight;

  /// No description provided for @facial_verification_encryption_notice.
  ///
  /// In es, this message translates to:
  /// **'Los datos biométricos están encriptados a 256 bits y nunca se comparten.'**
  String get facial_verification_encryption_notice;

  /// No description provided for @facial_verification_start_button.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get facial_verification_start_button;

  /// No description provided for @processing_missing_data.
  ///
  /// In es, this message translates to:
  /// **'Faltan datos requeridos para el registro.'**
  String get processing_missing_data;

  /// No description provided for @processing_creating_user.
  ///
  /// In es, this message translates to:
  /// **'Creando usuario...'**
  String get processing_creating_user;

  /// No description provided for @processing_success.
  ///
  /// In es, this message translates to:
  /// **'¡Registro completado con éxito!'**
  String get processing_success;

  /// No description provided for @processing_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error:\n'**
  String get processing_error_prefix;

  /// No description provided for @processing_default_message.
  ///
  /// In es, this message translates to:
  /// **'Procesando tu información...'**
  String get processing_default_message;

  /// No description provided for @processing_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get processing_retry;

  /// No description provided for @processing_retrying.
  ///
  /// In es, this message translates to:
  /// **'Reintentando...'**
  String get processing_retrying;

  /// No description provided for @processing_back.
  ///
  /// In es, this message translates to:
  /// **'Volver atrás'**
  String get processing_back;

  /// No description provided for @login_title.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login_title;

  /// No description provided for @login_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get login_phone;

  /// No description provided for @login_phone_hint.
  ///
  /// In es, this message translates to:
  /// **'demo@email.com'**
  String get login_phone_hint;

  /// No description provided for @login_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get login_password;

  /// No description provided for @login_password_hint.
  ///
  /// In es, this message translates to:
  /// **'••••••••••••'**
  String get login_password_hint;

  /// No description provided for @login_remember_me.
  ///
  /// In es, this message translates to:
  /// **'Recuérdame'**
  String get login_remember_me;

  /// No description provided for @login_forgot_password.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get login_forgot_password;

  /// No description provided for @login_login_button.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login_login_button;

  /// No description provided for @login_no_account.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta? '**
  String get login_no_account;

  /// No description provided for @login_register.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get login_register;

  /// No description provided for @login_required.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get login_required;

  /// No description provided for @verification_status_checking.
  ///
  /// In es, this message translates to:
  /// **'Consultando estado...'**
  String get verification_status_checking;

  /// No description provided for @verification_status_error_title.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error'**
  String get verification_status_error_title;

  /// No description provided for @verification_status_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get verification_status_retry;

  /// No description provided for @verification_status_pending_title.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de Documentos'**
  String get verification_status_pending_title;

  /// No description provided for @verification_status_pending_desc.
  ///
  /// In es, this message translates to:
  /// **'Has completado el registro inicial mediante número telefónico. Aún debes enviar tus documentos para verificar tu identidad y acceder a todas las funcionalidades.'**
  String get verification_status_pending_desc;

  /// No description provided for @verification_status_review_title.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get verification_status_review_title;

  /// No description provided for @verification_status_review_desc.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos fueron enviados y están siendo validados por nuestro sistema y equipo de moderación. No puedes modificar los documentos mientras estén en revisión.'**
  String get verification_status_review_desc;

  /// No description provided for @verification_status_approved_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación Aprobada'**
  String get verification_status_approved_title;

  /// No description provided for @verification_status_approved_desc.
  ///
  /// In es, this message translates to:
  /// **'El moderador validó satisfactoriamente tu identidad. Tu perfil aparece como verificado y tienes acceso a las funcionalidades correspondientes a tu rol.'**
  String get verification_status_approved_desc;

  /// No description provided for @verification_status_rejected_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación Rechazada'**
  String get verification_status_rejected_title;

  /// No description provided for @verification_status_rejected_desc.
  ///
  /// In es, this message translates to:
  /// **'La verificación no fue aprobada debido a inconsistencias en la documentación. Por favor, corrige la información y vuelve a intentar.'**
  String get verification_status_rejected_desc;

  /// No description provided for @verification_status_suspended_title.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Suspendida'**
  String get verification_status_suspended_title;

  /// No description provided for @verification_status_suspended_desc.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ha sido suspendida mediante una acción administrativa temporalmente. Se restringen las funcionalidades comerciales.'**
  String get verification_status_suspended_desc;

  /// No description provided for @verification_status_unknown_title.
  ///
  /// In es, this message translates to:
  /// **'Estado Desconocido'**
  String get verification_status_unknown_title;

  /// No description provided for @verification_status_unknown_desc.
  ///
  /// In es, this message translates to:
  /// **'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.'**
  String get verification_status_unknown_desc;

  /// No description provided for @verification_status_success_msg.
  ///
  /// In es, this message translates to:
  /// **'Tu registro fue exitoso y estamos revisando tu información...'**
  String get verification_status_success_msg;

  /// No description provided for @verification_status_upload_docs.
  ///
  /// In es, this message translates to:
  /// **'Subir Documentos'**
  String get verification_status_upload_docs;

  /// No description provided for @verification_status_enter_app.
  ///
  /// In es, this message translates to:
  /// **'Entrar a la aplicación'**
  String get verification_status_enter_app;

  /// No description provided for @verification_status_update_status.
  ///
  /// In es, this message translates to:
  /// **'Actualizar estado'**
  String get verification_status_update_status;

  /// No description provided for @verification_status_default_reject_reason.
  ///
  /// In es, this message translates to:
  /// **'La verificación no fue aprobada debido a inconsistencias en la documentación. Por favor, corrige la información y vuelve a intentar.'**
  String get verification_status_default_reject_reason;

  /// No description provided for @otp_verification_title.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu código'**
  String get otp_verification_title;

  /// No description provided for @otp_verification_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Se ha enviado un código de 6 dígitos a tu celular.'**
  String get otp_verification_subtitle;

  /// No description provided for @otp_verification_didnt_receive.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste el código? '**
  String get otp_verification_didnt_receive;

  /// No description provided for @otp_verification_resend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar.'**
  String get otp_verification_resend;

  /// No description provided for @otp_verification_appbar_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación SMS'**
  String get otp_verification_appbar_title;

  /// No description provided for @nav_market.
  ///
  /// In es, this message translates to:
  /// **'Mercado'**
  String get nav_market;

  /// No description provided for @nav_my_market.
  ///
  /// In es, this message translates to:
  /// **'Mi mercado'**
  String get nav_my_market;

  /// No description provided for @nav_deals.
  ///
  /// In es, this message translates to:
  /// **'Tratos'**
  String get nav_deals;

  /// No description provided for @nav_costs.
  ///
  /// In es, this message translates to:
  /// **'Costos'**
  String get nav_costs;

  /// No description provided for @nav_purchases.
  ///
  /// In es, this message translates to:
  /// **'Compras'**
  String get nav_purchases;

  /// No description provided for @nav_my_farm.
  ///
  /// In es, this message translates to:
  /// **'Mi Finca'**
  String get nav_my_farm;

  /// No description provided for @purchases_title.
  ///
  /// In es, this message translates to:
  /// **'Compras'**
  String get purchases_title;

  /// No description provided for @purchases_placeholder_title.
  ///
  /// In es, this message translates to:
  /// **'Módulo de Compras'**
  String get purchases_placeholder_title;

  /// No description provided for @purchases_placeholder_desc.
  ///
  /// In es, this message translates to:
  /// **'Aquí podrás consultar tus compras acordadas y el historial de operaciones completadas.'**
  String get purchases_placeholder_desc;

  /// No description provided for @profile_title_farmer.
  ///
  /// In es, this message translates to:
  /// **'Mi Finca'**
  String get profile_title_farmer;

  /// No description provided for @profile_title_buyer.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get profile_title_buyer;

  /// No description provided for @profile_stats_title.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get profile_stats_title;

  /// No description provided for @profile_stat_published.
  ///
  /// In es, this message translates to:
  /// **'Publicados'**
  String get profile_stat_published;

  /// No description provided for @profile_stat_negotiating.
  ///
  /// In es, this message translates to:
  /// **'Negociando'**
  String get profile_stat_negotiating;

  /// No description provided for @profile_stat_closed_farmer.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get profile_stat_closed_farmer;

  /// No description provided for @profile_stat_closed_buyer.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get profile_stat_closed_buyer;

  /// No description provided for @profile_settings_title.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profile_settings_title;

  /// No description provided for @profile_contact_info.
  ///
  /// In es, this message translates to:
  /// **'Información de contacto'**
  String get profile_contact_info;

  /// No description provided for @profile_email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get profile_email;

  /// No description provided for @profile_phone.
  ///
  /// In es, this message translates to:
  /// **'Número de teléfono'**
  String get profile_phone;

  /// No description provided for @profile_negotiation_options.
  ///
  /// In es, this message translates to:
  /// **'Opciones de negociación'**
  String get profile_negotiation_options;

  /// No description provided for @profile_enable_early_sale.
  ///
  /// In es, this message translates to:
  /// **'Habilitar precompra'**
  String get profile_enable_early_sale;

  /// No description provided for @profile_visibility_negotiation.
  ///
  /// In es, this message translates to:
  /// **'Visibilidad durante una negociación'**
  String get profile_visibility_negotiation;

  /// No description provided for @profile_visibility_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profile_visibility_phone;

  /// No description provided for @profile_visibility_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get profile_visibility_location;

  /// No description provided for @profile_visibility_whatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get profile_visibility_whatsapp;

  /// No description provided for @profile_accessibility.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get profile_accessibility;

  /// No description provided for @profile_dark_mode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get profile_dark_mode;

  /// No description provided for @profile_english_language.
  ///
  /// In es, this message translates to:
  /// **'Idioma inglés'**
  String get profile_english_language;

  /// No description provided for @profile_logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profile_logout;

  /// No description provided for @profile_logout_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get profile_logout_confirm_title;

  /// No description provided for @profile_logout_confirm_desc.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir de tu cuenta?'**
  String get profile_logout_confirm_desc;

  /// No description provided for @profile_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profile_cancel;

  /// No description provided for @profile_updated_photo.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil actualizada'**
  String get profile_updated_photo;

  /// No description provided for @profile_save_settings_error.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar configuración'**
  String get profile_save_settings_error;

  /// No description provided for @profile_load_error.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el perfil'**
  String get profile_load_error;

  /// No description provided for @profile_no_data.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los datos.'**
  String get profile_no_data;

  /// No description provided for @market_title.
  ///
  /// In es, this message translates to:
  /// **'Mercado'**
  String get market_title;

  /// No description provided for @market_title_farmer.
  ///
  /// In es, this message translates to:
  /// **'Mi Mercado'**
  String get market_title_farmer;

  /// No description provided for @market_publish_btn.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get market_publish_btn;

  /// No description provided for @market_empty_farmer_title.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes cosechas publicadas'**
  String get market_empty_farmer_title;

  /// No description provided for @market_empty_farmer_desc.
  ///
  /// In es, this message translates to:
  /// **'Comienza a ofrecer tus productos en el mercado agrícola creando tu primera publicación.'**
  String get market_empty_farmer_desc;

  /// No description provided for @market_publish_first.
  ///
  /// In es, this message translates to:
  /// **'Publicar mi primera cosecha'**
  String get market_publish_first;

  /// No description provided for @market_empty_buyer_title.
  ///
  /// In es, this message translates to:
  /// **'No hay cosechas disponibles'**
  String get market_empty_buyer_title;

  /// No description provided for @market_empty_buyer_desc.
  ///
  /// In es, this message translates to:
  /// **'En este momento no hay productos agrícolas disponibles para negociar. Intenta actualizar más tarde.'**
  String get market_empty_buyer_desc;

  /// No description provided for @market_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get market_retry;

  /// No description provided for @market_refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get market_refresh;

  /// No description provided for @market_publish_options_title.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo deseas publicar?'**
  String get market_publish_options_title;

  /// No description provided for @market_publish_manual.
  ///
  /// In es, this message translates to:
  /// **'Publicación Manual'**
  String get market_publish_manual;

  /// No description provided for @market_publish_manual_desc.
  ///
  /// In es, this message translates to:
  /// **'Llena el formulario paso a paso'**
  String get market_publish_manual_desc;

  /// No description provided for @market_publish_voice.
  ///
  /// In es, this message translates to:
  /// **'Publicación por Nota de Voz'**
  String get market_publish_voice;

  /// No description provided for @market_publish_voice_desc.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué quieres publicar (Con IA)'**
  String get market_publish_voice_desc;

  /// No description provided for @market_ai_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'Función de IA próximamente...'**
  String get market_ai_coming_soon;

  /// No description provided for @crop_card_available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get crop_card_available;

  /// No description provided for @crop_card_price_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Precio / kg'**
  String get crop_card_price_per_kg;

  /// No description provided for @crop_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Cosecha'**
  String get crop_detail_title;

  /// No description provided for @crop_detail_delete_tooltip.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get crop_detail_delete_tooltip;

  /// No description provided for @crop_detail_edit_tooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get crop_detail_edit_tooltip;

  /// No description provided for @crop_detail_confirm_delete_title.
  ///
  /// In es, this message translates to:
  /// **'Borrar Publicación'**
  String get crop_detail_confirm_delete_title;

  /// No description provided for @crop_detail_confirm_delete_desc.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.'**
  String get crop_detail_confirm_delete_desc;

  /// No description provided for @crop_detail_delete_success.
  ///
  /// In es, this message translates to:
  /// **'Publicación borrada exitosamente'**
  String get crop_detail_delete_success;

  /// No description provided for @crop_detail_delete_error.
  ///
  /// In es, this message translates to:
  /// **'Error al borrar'**
  String get crop_detail_delete_error;

  /// No description provided for @crop_detail_status_updated.
  ///
  /// In es, this message translates to:
  /// **'Estado actualizado'**
  String get crop_detail_status_updated;

  /// No description provided for @crop_detail_price_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Precio por kg'**
  String get crop_detail_price_per_kg;

  /// No description provided for @crop_detail_available_stock.
  ///
  /// In es, this message translates to:
  /// **'Total Disponible'**
  String get crop_detail_available_stock;

  /// No description provided for @crop_detail_min_order.
  ///
  /// In es, this message translates to:
  /// **'Pedido Mínimo'**
  String get crop_detail_min_order;

  /// No description provided for @crop_detail_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get crop_detail_location;

  /// No description provided for @crop_detail_early_sale.
  ///
  /// In es, this message translates to:
  /// **'Venta Anticipada'**
  String get crop_detail_early_sale;

  /// No description provided for @crop_detail_estimated_harvest.
  ///
  /// In es, this message translates to:
  /// **'Fecha est. de cosecha'**
  String get crop_detail_estimated_harvest;

  /// No description provided for @crop_detail_estimated_yield.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento estimado'**
  String get crop_detail_estimated_yield;

  /// No description provided for @crop_detail_quick_actions.
  ///
  /// In es, this message translates to:
  /// **'Acciones Rápidas'**
  String get crop_detail_quick_actions;

  /// No description provided for @crop_detail_pause_crop.
  ///
  /// In es, this message translates to:
  /// **'Pausar Publicación'**
  String get crop_detail_pause_crop;

  /// No description provided for @crop_detail_activate_crop.
  ///
  /// In es, this message translates to:
  /// **'Activar Publicación'**
  String get crop_detail_activate_crop;

  /// No description provided for @crop_detail_view_negotiations.
  ///
  /// In es, this message translates to:
  /// **'Ver Negociaciones'**
  String get crop_detail_view_negotiations;

  /// No description provided for @crop_detail_negotiations_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente: Ver negociaciones'**
  String get crop_detail_negotiations_coming_soon;

  /// No description provided for @crop_detail_make_offer.
  ///
  /// In es, this message translates to:
  /// **'Hacer oferta / Negociar'**
  String get crop_detail_make_offer;

  /// No description provided for @crop_detail_farmer_info.
  ///
  /// In es, this message translates to:
  /// **'Información del Productor'**
  String get crop_detail_farmer_info;

  /// No description provided for @crop_detail_producer.
  ///
  /// In es, this message translates to:
  /// **'Productor'**
  String get crop_detail_producer;

  /// No description provided for @crop_detail_contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get crop_detail_contact;

  /// No description provided for @offer_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Nueva Oferta'**
  String get offer_sheet_title;

  /// No description provided for @offer_sheet_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia una propuesta de negociación para este producto'**
  String get offer_sheet_subtitle;

  /// No description provided for @offer_sheet_quantity_label.
  ///
  /// In es, this message translates to:
  /// **'Cantidad (kg)'**
  String get offer_sheet_quantity_label;

  /// No description provided for @offer_sheet_price_label.
  ///
  /// In es, this message translates to:
  /// **'Precio propuesto por kg'**
  String get offer_sheet_price_label;

  /// No description provided for @offer_sheet_delivery_label.
  ///
  /// In es, this message translates to:
  /// **'Método de entrega'**
  String get offer_sheet_delivery_label;

  /// No description provided for @offer_sheet_delivery_farm.
  ///
  /// In es, this message translates to:
  /// **'En finca'**
  String get offer_sheet_delivery_farm;

  /// No description provided for @offer_sheet_delivery_hub.
  ///
  /// In es, this message translates to:
  /// **'Punto de acopio'**
  String get offer_sheet_delivery_hub;

  /// No description provided for @offer_sheet_delivery_destination.
  ///
  /// In es, this message translates to:
  /// **'Destino final'**
  String get offer_sheet_delivery_destination;

  /// No description provided for @offer_sheet_delivery_agree.
  ///
  /// In es, this message translates to:
  /// **'A acordar con el productor'**
  String get offer_sheet_delivery_agree;

  /// No description provided for @offer_sheet_message_label.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para el productor (Opcional)'**
  String get offer_sheet_message_label;

  /// No description provided for @offer_sheet_message_hint.
  ///
  /// In es, this message translates to:
  /// **'Explica detalles de tu propuesta o requerimientos de entrega'**
  String get offer_sheet_message_hint;

  /// No description provided for @offer_sheet_estimated_total.
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get offer_sheet_estimated_total;

  /// No description provided for @offer_sheet_submit_btn.
  ///
  /// In es, this message translates to:
  /// **'Enviar propuesta'**
  String get offer_sheet_submit_btn;

  /// No description provided for @offer_sheet_submitting.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get offer_sheet_submitting;

  /// No description provided for @offer_sheet_success.
  ///
  /// In es, this message translates to:
  /// **'Propuesta enviada exitosamente'**
  String get offer_sheet_success;

  /// No description provided for @offer_sheet_existing_negotiation.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una negociación activa para este cultivo'**
  String get offer_sheet_existing_negotiation;

  /// No description provided for @offer_sheet_val_required.
  ///
  /// In es, this message translates to:
  /// **'Campo requerido'**
  String get offer_sheet_val_required;

  /// No description provided for @offer_sheet_val_positive.
  ///
  /// In es, this message translates to:
  /// **'Debe ser mayor a 0'**
  String get offer_sheet_val_positive;

  /// No description provided for @offer_sheet_val_min_order.
  ///
  /// In es, this message translates to:
  /// **'La cantidad no cumple con el pedido mínimo'**
  String get offer_sheet_val_min_order;

  /// No description provided for @offer_sheet_val_max_stock.
  ///
  /// In es, this message translates to:
  /// **'La cantidad supera el stock disponible'**
  String get offer_sheet_val_max_stock;

  /// No description provided for @deals_title.
  ///
  /// In es, this message translates to:
  /// **'Tratos'**
  String get deals_title;

  /// No description provided for @deals_tab_all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get deals_tab_all;

  /// No description provided for @deals_tab_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get deals_tab_pending;

  /// No description provided for @deals_tab_in_negotiation.
  ///
  /// In es, this message translates to:
  /// **'En negociación'**
  String get deals_tab_in_negotiation;

  /// No description provided for @deals_tab_agreed.
  ///
  /// In es, this message translates to:
  /// **'Acordados'**
  String get deals_tab_agreed;

  /// No description provided for @deals_tab_history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get deals_tab_history;

  /// No description provided for @deals_your_turn.
  ///
  /// In es, this message translates to:
  /// **'Tu turno'**
  String get deals_your_turn;

  /// No description provided for @deals_waiting_response.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta'**
  String get deals_waiting_response;

  /// No description provided for @deals_see_deal.
  ///
  /// In es, this message translates to:
  /// **'Ver trato →'**
  String get deals_see_deal;

  /// No description provided for @deals_empty_farmer_title.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes tratos'**
  String get deals_empty_farmer_title;

  /// No description provided for @deals_empty_farmer_desc.
  ///
  /// In es, this message translates to:
  /// **'Cuando un comprador realice una oferta sobre una de tus cosechas, aparecerá aquí.'**
  String get deals_empty_farmer_desc;

  /// No description provided for @deals_empty_buyer_title.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes tratos'**
  String get deals_empty_buyer_title;

  /// No description provided for @deals_empty_buyer_desc.
  ///
  /// In es, this message translates to:
  /// **'Cuando realices una oferta en el mercado sobre una cosecha, podrás seguirla y negociar aquí.'**
  String get deals_empty_buyer_desc;

  /// No description provided for @deals_explore_market.
  ///
  /// In es, this message translates to:
  /// **'Explorar mercado'**
  String get deals_explore_market;

  /// No description provided for @deals_view_crops.
  ///
  /// In es, this message translates to:
  /// **'Ver mis cosechas'**
  String get deals_view_crops;

  /// No description provided for @deal_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle del trato'**
  String get deal_detail_title;

  /// No description provided for @deal_counterpart_buyer.
  ///
  /// In es, this message translates to:
  /// **'Comprador'**
  String get deal_counterpart_buyer;

  /// No description provided for @deal_counterpart_farmer.
  ///
  /// In es, this message translates to:
  /// **'Productor'**
  String get deal_counterpart_farmer;

  /// No description provided for @deal_history_title.
  ///
  /// In es, this message translates to:
  /// **'Historial de ofertas'**
  String get deal_history_title;

  /// No description provided for @deal_waiting_buyer.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta del comprador'**
  String get deal_waiting_buyer;

  /// No description provided for @deal_waiting_farmer.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta del productor'**
  String get deal_waiting_farmer;

  /// No description provided for @deal_accept_offer.
  ///
  /// In es, this message translates to:
  /// **'Aceptar oferta'**
  String get deal_accept_offer;

  /// No description provided for @deal_counter_offer.
  ///
  /// In es, this message translates to:
  /// **'Contraofertar'**
  String get deal_counter_offer;

  /// No description provided for @deal_reject_deal.
  ///
  /// In es, this message translates to:
  /// **'Rechazar trato'**
  String get deal_reject_deal;

  /// No description provided for @deal_cancel_deal.
  ///
  /// In es, this message translates to:
  /// **'Cancelar propuesta'**
  String get deal_cancel_deal;

  /// No description provided for @deal_accept_success.
  ///
  /// In es, this message translates to:
  /// **'Trato acordado correctamente'**
  String get deal_accept_success;

  /// No description provided for @deal_reject_success.
  ///
  /// In es, this message translates to:
  /// **'El trato ha sido rechazado'**
  String get deal_reject_success;

  /// No description provided for @deal_reject_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Rechazar este trato?'**
  String get deal_reject_confirm_title;

  /// No description provided for @deal_reject_confirm_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer y el trato se cerrará.'**
  String get deal_reject_confirm_desc;

  /// No description provided for @counter_offer_title.
  ///
  /// In es, this message translates to:
  /// **'Contraoferta'**
  String get counter_offer_title;

  /// No description provided for @counter_offer_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Modifica los términos de la oferta para la cosecha seleccionada.'**
  String get counter_offer_subtitle;

  /// No description provided for @counter_offer_quantity_label.
  ///
  /// In es, this message translates to:
  /// **'Cantidad (kg)'**
  String get counter_offer_quantity_label;

  /// No description provided for @counter_offer_price_label.
  ///
  /// In es, this message translates to:
  /// **'Precio propuesto por kg'**
  String get counter_offer_price_label;

  /// No description provided for @counter_offer_delivery_label.
  ///
  /// In es, this message translates to:
  /// **'Método de entrega'**
  String get counter_offer_delivery_label;

  /// No description provided for @counter_offer_message_label.
  ///
  /// In es, this message translates to:
  /// **'Mensaje (Opcional)'**
  String get counter_offer_message_label;

  /// No description provided for @counter_offer_message_hint.
  ///
  /// In es, this message translates to:
  /// **'Explica el motivo de tu contraoferta'**
  String get counter_offer_message_hint;

  /// No description provided for @counter_offer_send_btn.
  ///
  /// In es, this message translates to:
  /// **'Enviar contraoferta'**
  String get counter_offer_send_btn;

  /// No description provided for @counter_offer_success.
  ///
  /// In es, this message translates to:
  /// **'Contraoferta enviada exitosamente'**
  String get counter_offer_success;

  /// No description provided for @purchases_tab_all.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get purchases_tab_all;

  /// No description provided for @purchases_tab_agreed.
  ///
  /// In es, this message translates to:
  /// **'Acordadas'**
  String get purchases_tab_agreed;

  /// No description provided for @purchases_tab_completed.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get purchases_tab_completed;

  /// No description provided for @purchases_empty_title.
  ///
  /// In es, this message translates to:
  /// **'No tienes compras aún'**
  String get purchases_empty_title;

  /// No description provided for @purchases_empty_desc.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán los acuerdos que hayas cerrado con los productores agrícolas y tus compras completadas.'**
  String get purchases_empty_desc;

  /// No description provided for @purchases_empty_action.
  ///
  /// In es, this message translates to:
  /// **'Explorar mercado'**
  String get purchases_empty_action;

  /// No description provided for @purchases_total_agreed.
  ///
  /// In es, this message translates to:
  /// **'Acuerdos vigentes'**
  String get purchases_total_agreed;

  /// No description provided for @purchases_total_invested.
  ///
  /// In es, this message translates to:
  /// **'Total pactado'**
  String get purchases_total_invested;

  /// No description provided for @purchases_total_volume.
  ///
  /// In es, this message translates to:
  /// **'Volumen total'**
  String get purchases_total_volume;

  /// No description provided for @purchases_view_detail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle del acuerdo →'**
  String get purchases_view_detail;

  /// No description provided for @purchases_delivery_method.
  ///
  /// In es, this message translates to:
  /// **'Entrega'**
  String get purchases_delivery_method;

  /// No description provided for @purchases_status_agreed.
  ///
  /// In es, this message translates to:
  /// **'Acordada'**
  String get purchases_status_agreed;

  /// No description provided for @purchases_status_completed.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get purchases_status_completed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
