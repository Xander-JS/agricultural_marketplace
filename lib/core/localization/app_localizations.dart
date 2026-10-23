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
  /// **'Bienvenido a KUS'**
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
  /// **'Después verificaremos tu identidad con tu documento y una selfie. Un moderador revisa cada cuenta antes de activarla.'**
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
  /// **'Tipo de cuenta'**
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
  /// **'La verificación de identidad empieza después de elegir tu rol.'**
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
  /// **'Tipo de identificación'**
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
  /// **'Código legible'**
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

  /// No description provided for @complete_registration_title.
  ///
  /// In es, this message translates to:
  /// **'Completa tu registro'**
  String get complete_registration_title;

  /// No description provided for @complete_registration_description.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de acceso ya existe, pero aún no tiene perfil ni solicitud de verificación. Ingresa tus datos y sube las tres imágenes. No se reutilizan datos ni documentos anteriores.'**
  String get complete_registration_description;

  /// No description provided for @complete_registration_contact.
  ///
  /// In es, this message translates to:
  /// **'Teléfono o correo'**
  String get complete_registration_contact;

  /// No description provided for @complete_registration_contact_hint.
  ///
  /// In es, this message translates to:
  /// **'3151234567 o correo@ejemplo.com'**
  String get complete_registration_contact_hint;

  /// No description provided for @complete_registration_full_name.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get complete_registration_full_name;

  /// No description provided for @complete_registration_full_name_hint.
  ///
  /// In es, this message translates to:
  /// **'Nombres y apellidos'**
  String get complete_registration_full_name_hint;

  /// No description provided for @complete_registration_role.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get complete_registration_role;

  /// No description provided for @complete_registration_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos de identidad'**
  String get complete_registration_documents;

  /// No description provided for @complete_registration_submit.
  ///
  /// In es, this message translates to:
  /// **'Completar registro'**
  String get complete_registration_submit;

  /// No description provided for @complete_registration_success.
  ///
  /// In es, this message translates to:
  /// **'Registro completado. Tu solicitud está pendiente de revisión manual.'**
  String get complete_registration_success;

  /// No description provided for @complete_registration_invalid_data.
  ///
  /// In es, this message translates to:
  /// **'Completa todos los campos y adjunta el frente, el reverso y la selfie.'**
  String get complete_registration_invalid_data;

  /// No description provided for @complete_registration_unauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión no está activa. Inicia sesión nuevamente para continuar.'**
  String get complete_registration_unauthorized;

  /// No description provided for @complete_registration_profile_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu perfil. Inténtalo de nuevo.'**
  String get complete_registration_profile_error;

  /// No description provided for @complete_registration_documents_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar los documentos. Revisa tu conexión e inténtalo de nuevo.'**
  String get complete_registration_documents_error;

  /// No description provided for @complete_registration_in_progress.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un envío de documentos en curso.'**
  String get complete_registration_in_progress;

  /// No description provided for @complete_registration_unknown_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el registro. Inténtalo de nuevo.'**
  String get complete_registration_unknown_error;

  /// No description provided for @complete_registration_missing_documents.
  ///
  /// In es, this message translates to:
  /// **'Debes adjuntar el frente, el reverso y la selfie antes de continuar.'**
  String get complete_registration_missing_documents;

  /// No description provided for @login_title.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login_title;

  /// No description provided for @login_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono o correo'**
  String get login_phone;

  /// No description provided for @login_phone_hint.
  ///
  /// In es, this message translates to:
  /// **'315 000 0000'**
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
  /// **'Análisis preliminar de IA completado; tu cuenta está en revisión final por parte de un moderador.'**
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
  /// **'Tu solicitud de registro fue enviada y está siendo revisada por nuestros equipos de moderación.'**
  String get verification_status_success_msg;

  /// No description provided for @verification_status_submitted_title.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get verification_status_submitted_title;

  /// No description provided for @verification_status_submitted_desc.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta queda pendiente de aprobación. Las funciones comerciales se habilitan en cuanto un moderador la apruebe; desliza hacia abajo para consultar el avance.'**
  String get verification_status_submitted_desc;

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
  /// **'Actividad comercial'**
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

  /// No description provided for @reputation_title.
  ///
  /// In es, this message translates to:
  /// **'Reputación'**
  String get reputation_title;

  /// No description provided for @reputation_average_label.
  ///
  /// In es, this message translates to:
  /// **'Calificación promedio'**
  String get reputation_average_label;

  /// No description provided for @reputation_reviews_received.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones recibidas'**
  String get reputation_reviews_received;

  /// No description provided for @reputation_no_ratings.
  ///
  /// In es, this message translates to:
  /// **'Sin calificaciones aún'**
  String get reputation_no_ratings;

  /// No description provided for @reputation_new.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get reputation_new;

  /// No description provided for @reputation_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando reputación...'**
  String get reputation_loading;

  /// No description provided for @reputation_load_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la reputación.'**
  String get reputation_load_error;

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

  /// No description provided for @market_search_hint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título o tipo de cultivo'**
  String get market_search_hint;

  /// No description provided for @market_search_clear.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get market_search_clear;

  /// No description provided for @market_sort_recent.
  ///
  /// In es, this message translates to:
  /// **'Más recientes'**
  String get market_sort_recent;

  /// No description provided for @market_sort_price_asc.
  ///
  /// In es, this message translates to:
  /// **'Menor precio'**
  String get market_sort_price_asc;

  /// No description provided for @market_sort_price_desc.
  ///
  /// In es, this message translates to:
  /// **'Mayor precio'**
  String get market_sort_price_desc;

  /// No description provided for @market_sort_reputation.
  ///
  /// In es, this message translates to:
  /// **'Mejor reputación'**
  String get market_sort_reputation;

  /// No description provided for @market_no_results.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cosechas que coincidan con estos criterios'**
  String get market_no_results;

  /// No description provided for @market_clear_filters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get market_clear_filters;

  /// No description provided for @market_own_profile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get market_own_profile;

  /// No description provided for @publish_title_new.
  ///
  /// In es, this message translates to:
  /// **'Publicar Cosecha'**
  String get publish_title_new;

  /// No description provided for @publish_title_edit.
  ///
  /// In es, this message translates to:
  /// **'Editar Cosecha'**
  String get publish_title_edit;

  /// No description provided for @publish_unauthorized_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso No Autorizado'**
  String get publish_unauthorized_title;

  /// No description provided for @publish_unauthorized_desc.
  ///
  /// In es, this message translates to:
  /// **'Solo los agricultores registrados y verificados pueden publicar cosechas.'**
  String get publish_unauthorized_desc;

  /// No description provided for @publish_validation_incomplete.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa los campos obligatorios correctamente.'**
  String get publish_validation_incomplete;

  /// No description provided for @publish_harvest_date_required.
  ///
  /// In es, this message translates to:
  /// **'Debes indicar la fecha estimada de cosecha para venta anticipada.'**
  String get publish_harvest_date_required;

  /// No description provided for @publish_not_authenticated.
  ///
  /// In es, this message translates to:
  /// **'No autenticado'**
  String get publish_not_authenticated;

  /// No description provided for @publish_access_farmer_only.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: solo los agricultores pueden publicar cosechas.'**
  String get publish_access_farmer_only;

  /// No description provided for @publish_access_other_crop.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: no puedes editar una cosecha perteneciente a otro productor.'**
  String get publish_access_other_crop;

  /// No description provided for @publish_success_active.
  ///
  /// In es, this message translates to:
  /// **'¡Cosecha publicada exitosamente!'**
  String get publish_success_active;

  /// No description provided for @publish_success_draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador guardado.'**
  String get publish_success_draft;

  /// No description provided for @publish_save_error.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String publish_save_error(String error);

  /// No description provided for @publish_section_general.
  ///
  /// In es, this message translates to:
  /// **'Información general'**
  String get publish_section_general;

  /// No description provided for @publish_section_prices.
  ///
  /// In es, this message translates to:
  /// **'Precios y cantidades'**
  String get publish_section_prices;

  /// No description provided for @publish_section_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get publish_section_location;

  /// No description provided for @publish_section_sale_mode.
  ///
  /// In es, this message translates to:
  /// **'Modalidad de venta'**
  String get publish_section_sale_mode;

  /// No description provided for @publish_section_images.
  ///
  /// In es, this message translates to:
  /// **'Imágenes'**
  String get publish_section_images;

  /// No description provided for @publish_field_title.
  ///
  /// In es, this message translates to:
  /// **'Título de la publicación'**
  String get publish_field_title;

  /// No description provided for @publish_field_crop_type.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Producto (Ej: Papa Capira, Café Castillo)'**
  String get publish_field_crop_type;

  /// No description provided for @publish_field_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción de la cosecha'**
  String get publish_field_description;

  /// No description provided for @publish_field_price.
  ///
  /// In es, this message translates to:
  /// **'Precio por kg (\$)'**
  String get publish_field_price;

  /// No description provided for @publish_field_stock.
  ///
  /// In es, this message translates to:
  /// **'Total Disp. (kg)'**
  String get publish_field_stock;

  /// No description provided for @publish_field_min_order.
  ///
  /// In es, this message translates to:
  /// **'Pedido mínimo (kg)'**
  String get publish_field_min_order;

  /// No description provided for @publish_field_department.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get publish_field_department;

  /// No description provided for @publish_field_municipality.
  ///
  /// In es, this message translates to:
  /// **'Municipio'**
  String get publish_field_municipality;

  /// No description provided for @publish_early_sale_title.
  ///
  /// In es, this message translates to:
  /// **'¿Es Venta Anticipada?'**
  String get publish_early_sale_title;

  /// No description provided for @publish_early_sale_desc.
  ///
  /// In es, this message translates to:
  /// **'Útil si la cosecha aún no está lista pero quieres asegurar ventas.'**
  String get publish_early_sale_desc;

  /// No description provided for @publish_field_estimated_yield.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento est. (kg)'**
  String get publish_field_estimated_yield;

  /// No description provided for @publish_field_harvest_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Cosecha'**
  String get publish_field_harvest_date;

  /// No description provided for @publish_select_date.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar...'**
  String get publish_select_date;

  /// No description provided for @publish_current_images.
  ///
  /// In es, this message translates to:
  /// **'Imágenes actuales de la publicación:'**
  String get publish_current_images;

  /// No description provided for @publish_add_images.
  ///
  /// In es, this message translates to:
  /// **'Añadir Imágenes'**
  String get publish_add_images;

  /// No description provided for @publish_save_draft.
  ///
  /// In es, this message translates to:
  /// **'Guardar Borrador'**
  String get publish_save_draft;

  /// No description provided for @publish_submit.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publish_submit;

  /// No description provided for @publish_validation_required.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get publish_validation_required;

  /// No description provided for @publish_validation_greater_zero.
  ///
  /// In es, this message translates to:
  /// **'Mayor a 0'**
  String get publish_validation_greater_zero;

  /// No description provided for @publish_validation_non_negative.
  ///
  /// In es, this message translates to:
  /// **'Mayor o igual a 0'**
  String get publish_validation_non_negative;

  /// No description provided for @publish_voice_banner_title.
  ///
  /// In es, this message translates to:
  /// **'Borrador creado por voz'**
  String get publish_voice_banner_title;

  /// No description provided for @publish_voice_banner_desc.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos reconocidos. No se publicará nada hasta que confirmes el formulario.'**
  String get publish_voice_banner_desc;

  /// No description provided for @publish_voice_confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirma: {fields}'**
  String publish_voice_confirm(String fields);

  /// No description provided for @publish_voice_missing.
  ///
  /// In es, this message translates to:
  /// **'Faltan o debes completar: {fields}.'**
  String publish_voice_missing(String fields);

  /// No description provided for @publish_voice_label_title.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get publish_voice_label_title;

  /// No description provided for @publish_voice_label_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get publish_voice_label_description;

  /// No description provided for @publish_voice_label_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get publish_voice_label_location;

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

  /// No description provided for @crop_detail_view_equivalences.
  ///
  /// In es, this message translates to:
  /// **'Ver equivalencias'**
  String get crop_detail_view_equivalences;

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

  /// No description provided for @crop_detail_estimated_distance.
  ///
  /// In es, this message translates to:
  /// **'Distancia estimada'**
  String get crop_detail_estimated_distance;

  /// No description provided for @crop_detail_publication_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha de publicación'**
  String get crop_detail_publication_date;

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

  /// No description provided for @counter_offer_subtitle_crop.
  ///
  /// In es, this message translates to:
  /// **'Modifica los términos de la oferta para {crop}.'**
  String counter_offer_subtitle_crop(String crop);

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

  /// No description provided for @deal_agreed_desc.
  ///
  /// In es, this message translates to:
  /// **'Trato acordado. Coordina la entrega física para completar la operación.'**
  String get deal_agreed_desc;

  /// No description provided for @deal_complete_btn.
  ///
  /// In es, this message translates to:
  /// **'Confirmar entrega y completar trato'**
  String get deal_complete_btn;

  /// No description provided for @deal_cancel_agreed.
  ///
  /// In es, this message translates to:
  /// **'Cancelar acuerdo'**
  String get deal_cancel_agreed;

  /// No description provided for @deal_complete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Completar este trato?'**
  String get deal_complete_confirm_title;

  /// No description provided for @deal_complete_confirm_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.'**
  String get deal_complete_confirm_desc;

  /// No description provided for @deal_complete_confirm_btn.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get deal_complete_confirm_btn;

  /// No description provided for @deal_completed_success.
  ///
  /// In es, this message translates to:
  /// **'Trato completado exitosamente'**
  String get deal_completed_success;

  /// No description provided for @deal_detail_error.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error'**
  String get deal_detail_error;

  /// No description provided for @deal_detail_not_found.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el trato.'**
  String get deal_detail_not_found;

  /// No description provided for @deal_detail_quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get deal_detail_quantity;

  /// No description provided for @deal_detail_price_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Precio por kg'**
  String get deal_detail_price_per_kg;

  /// No description provided for @deal_detail_delivery_method.
  ///
  /// In es, this message translates to:
  /// **'Método de entrega'**
  String get deal_detail_delivery_method;

  /// No description provided for @deal_detail_status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get deal_detail_status;

  /// No description provided for @deal_detail_rate_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'La calificación de tratos estará disponible pronto.'**
  String get deal_detail_rate_coming_soon;

  /// No description provided for @deal_detail_rate_farmer.
  ///
  /// In es, this message translates to:
  /// **'Calificar productor'**
  String get deal_detail_rate_farmer;

  /// No description provided for @deal_detail_rate_buyer.
  ///
  /// In es, this message translates to:
  /// **'Calificar comprador'**
  String get deal_detail_rate_buyer;

  /// No description provided for @deal_detail_rate_title.
  ///
  /// In es, this message translates to:
  /// **'Calificar trato'**
  String get deal_detail_rate_title;

  /// No description provided for @deal_detail_rate_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu calificación ayuda a construir confianza en la comunidad.'**
  String get deal_detail_rate_subtitle;

  /// No description provided for @deal_detail_rate_target.
  ///
  /// In es, this message translates to:
  /// **'Calificas a'**
  String get deal_detail_rate_target;

  /// No description provided for @deal_detail_rate_stars_label.
  ///
  /// In es, this message translates to:
  /// **'Tu calificación'**
  String get deal_detail_rate_stars_label;

  /// No description provided for @deal_detail_rate_stars_required.
  ///
  /// In es, this message translates to:
  /// **'Selecciona de 1 a 5 estrellas'**
  String get deal_detail_rate_stars_required;

  /// No description provided for @deal_detail_rate_comment_label.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get deal_detail_rate_comment_label;

  /// No description provided for @deal_detail_rate_comment_hint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos cómo fue tu experiencia'**
  String get deal_detail_rate_comment_hint;

  /// No description provided for @deal_detail_rate_submit.
  ///
  /// In es, this message translates to:
  /// **'Enviar calificación'**
  String get deal_detail_rate_submit;

  /// No description provided for @deal_detail_rate_success.
  ///
  /// In es, this message translates to:
  /// **'Calificación enviada correctamente'**
  String get deal_detail_rate_success;

  /// No description provided for @deal_detail_rate_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la calificación. Inténtalo de nuevo.'**
  String get deal_detail_rate_error;

  /// No description provided for @deal_detail_rate_loading.
  ///
  /// In es, this message translates to:
  /// **'Verificando calificación...'**
  String get deal_detail_rate_loading;

  /// No description provided for @deal_detail_rated.
  ///
  /// In es, this message translates to:
  /// **'Trato calificado'**
  String get deal_detail_rated;

  /// No description provided for @deal_detail_rated_desc.
  ///
  /// In es, this message translates to:
  /// **'Ya enviaste tu calificación para este trato.'**
  String get deal_detail_rated_desc;

  /// No description provided for @deal_detail_proposal_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Propuesta cancelada'**
  String get deal_detail_proposal_cancelled;

  /// No description provided for @deals_unknown_crop.
  ///
  /// In es, this message translates to:
  /// **'Cosecha desconocida'**
  String get deals_unknown_crop;

  /// No description provided for @deals_counterpart_producer.
  ///
  /// In es, this message translates to:
  /// **'Productor'**
  String get deals_counterpart_producer;

  /// No description provided for @deals_counterpart_buyer_label.
  ///
  /// In es, this message translates to:
  /// **'Comprador'**
  String get deals_counterpart_buyer_label;

  /// No description provided for @deals_status_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get deals_status_pending;

  /// No description provided for @deals_status_counteroffer.
  ///
  /// In es, this message translates to:
  /// **'Contraoferta'**
  String get deals_status_counteroffer;

  /// No description provided for @deals_status_agreed.
  ///
  /// In es, this message translates to:
  /// **'Acordado'**
  String get deals_status_agreed;

  /// No description provided for @deals_status_completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get deals_status_completed;

  /// No description provided for @deals_status_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get deals_status_rejected;

  /// No description provided for @deals_status_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get deals_status_cancelled;

  /// No description provided for @offer_sheet_base_price.
  ///
  /// In es, this message translates to:
  /// **'Base: {price}'**
  String offer_sheet_base_price(String price);

  /// No description provided for @offer_sheet_min_order.
  ///
  /// In es, this message translates to:
  /// **'Mín'**
  String get offer_sheet_min_order;

  /// No description provided for @offer_sheet_available_stock.
  ///
  /// In es, this message translates to:
  /// **'Stock disp.'**
  String get offer_sheet_available_stock;

  /// No description provided for @offer_sheet_unapproved_error.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta debe estar verificada y aprobada para realizar ofertas comerciales.'**
  String get offer_sheet_unapproved_error;

  /// No description provided for @crop_unapproved_warning.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta debe estar verificada y aprobada para realizar ofertas comerciales.'**
  String get crop_unapproved_warning;

  /// No description provided for @crop_unapproved_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'Verificación requerida'**
  String get crop_unapproved_dialog_title;

  /// No description provided for @crop_unapproved_dialog_desc.
  ///
  /// In es, this message translates to:
  /// **'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.'**
  String get crop_unapproved_dialog_desc;

  /// No description provided for @crop_unapproved_dialog_action.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get crop_unapproved_dialog_action;

  /// No description provided for @recovery_title.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recovery_title;

  /// No description provided for @recovery_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el correo electrónico asociado a tu cuenta para recibir las instrucciones de restablecimiento.'**
  String get recovery_subtitle;

  /// No description provided for @recovery_email_label.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get recovery_email_label;

  /// No description provided for @recovery_email_hint.
  ///
  /// In es, this message translates to:
  /// **'ejemplo@correo.com'**
  String get recovery_email_hint;

  /// No description provided for @recovery_email_required.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo electrónico.'**
  String get recovery_email_required;

  /// No description provided for @recovery_email_invalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get recovery_email_invalid;

  /// No description provided for @recovery_phone_not_supported.
  ///
  /// In es, this message translates to:
  /// **'La recuperación por enlace requiere un correo electrónico. Si te registraste únicamente con un número de teléfono, por favor contacta al administrador.'**
  String get recovery_phone_not_supported;

  /// No description provided for @recovery_send_button.
  ///
  /// In es, this message translates to:
  /// **'Enviar instrucciones'**
  String get recovery_send_button;

  /// No description provided for @recovery_sending.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get recovery_sending;

  /// No description provided for @recovery_generic_success.
  ///
  /// In es, this message translates to:
  /// **'Si los datos corresponden a una cuenta registrada, se enviarán las instrucciones para restablecer tu contraseña.'**
  String get recovery_generic_success;

  /// No description provided for @recovery_back_to_login.
  ///
  /// In es, this message translates to:
  /// **'Volver a Iniciar Sesión'**
  String get recovery_back_to_login;

  /// No description provided for @recovery_network_error.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.'**
  String get recovery_network_error;

  /// No description provided for @recovery_generic_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar la solicitud. Por favor intenta más tarde.'**
  String get recovery_generic_error;

  /// No description provided for @reset_password_title.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get reset_password_title;

  /// No description provided for @reset_password_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nueva contraseña para acceder a tu cuenta.'**
  String get reset_password_subtitle;

  /// No description provided for @reset_password_new_label.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get reset_password_new_label;

  /// No description provided for @reset_password_new_hint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get reset_password_new_hint;

  /// No description provided for @reset_password_confirm_label.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nueva contraseña'**
  String get reset_password_confirm_label;

  /// No description provided for @reset_password_confirm_hint.
  ///
  /// In es, this message translates to:
  /// **'Repite tu nueva contraseña'**
  String get reset_password_confirm_hint;

  /// No description provided for @reset_password_length_error.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get reset_password_length_error;

  /// No description provided for @reset_password_mismatch_error.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get reset_password_mismatch_error;

  /// No description provided for @reset_password_required_error.
  ///
  /// In es, this message translates to:
  /// **'Este campo es requerido.'**
  String get reset_password_required_error;

  /// No description provided for @reset_password_submit_button.
  ///
  /// In es, this message translates to:
  /// **'Actualizar contraseña'**
  String get reset_password_submit_button;

  /// No description provided for @reset_password_updating.
  ///
  /// In es, this message translates to:
  /// **'Actualizando...'**
  String get reset_password_updating;

  /// No description provided for @reset_password_success.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada exitosamente. Por favor, inicia sesión con tu nueva contraseña.'**
  String get reset_password_success;

  /// No description provided for @reset_password_invalid_session.
  ///
  /// In es, this message translates to:
  /// **'El enlace de recuperación es inválido o ha caducado. Por favor, solicita uno nuevo.'**
  String get reset_password_invalid_session;

  /// No description provided for @reset_password_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get reset_password_cancel;

  /// No description provided for @verification_status_reupload_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidad de re-carga en desarrollo.'**
  String get verification_status_reupload_coming_soon;

  /// No description provided for @moderation_queue_title.
  ///
  /// In es, this message translates to:
  /// **'Cola de Moderación'**
  String get moderation_queue_title;

  /// No description provided for @moderation_error_title.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las solicitudes'**
  String get moderation_error_title;

  /// No description provided for @moderation_error_processing.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar la solicitud'**
  String get moderation_error_processing;

  /// No description provided for @moderation_error_rejecting.
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar la solicitud'**
  String get moderation_error_rejecting;

  /// No description provided for @moderation_error_updating.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar la solicitud'**
  String get moderation_error_updating;

  /// No description provided for @moderation_queue_empty_title.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes'**
  String get moderation_queue_empty_title;

  /// No description provided for @moderation_queue_empty_desc.
  ///
  /// In es, this message translates to:
  /// **'Todas las solicitudes de verificación han sido resueltas o no hay envíos pendientes.'**
  String get moderation_queue_empty_desc;

  /// No description provided for @moderation_unauthorized_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso No Autorizado'**
  String get moderation_unauthorized_title;

  /// No description provided for @moderation_unauthorized_desc.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no posee privilegios de moderación para acceder a esta consola.'**
  String get moderation_unauthorized_desc;

  /// No description provided for @moderation_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Solicitud'**
  String get moderation_detail_title;

  /// No description provided for @moderation_lbl_role.
  ///
  /// In es, this message translates to:
  /// **'Rol:'**
  String get moderation_lbl_role;

  /// No description provided for @moderation_lbl_submitted.
  ///
  /// In es, this message translates to:
  /// **'Enviado:'**
  String get moderation_lbl_submitted;

  /// No description provided for @moderation_documents_title.
  ///
  /// In es, this message translates to:
  /// **'Documentos Presentados'**
  String get moderation_documents_title;

  /// No description provided for @moderation_storage_notice.
  ///
  /// In es, this message translates to:
  /// **'Los documentos se consultan mediante enlaces firmados temporales del almacenamiento privado. No se comparten públicamente.'**
  String get moderation_storage_notice;

  /// No description provided for @moderation_doc_front.
  ///
  /// In es, this message translates to:
  /// **'Cédula (Frente)'**
  String get moderation_doc_front;

  /// No description provided for @moderation_doc_back.
  ///
  /// In es, this message translates to:
  /// **'Cédula (Dorso)'**
  String get moderation_doc_back;

  /// No description provided for @moderation_doc_selfie.
  ///
  /// In es, this message translates to:
  /// **'Selfie Facial'**
  String get moderation_doc_selfie;

  /// No description provided for @moderation_previous_rejection.
  ///
  /// In es, this message translates to:
  /// **'Motivo de Rechazo Registrado'**
  String get moderation_previous_rejection;

  /// No description provided for @moderation_already_resolved.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya fue resuelta y no admite nuevas modificaciones inmediatas.'**
  String get moderation_already_resolved;

  /// No description provided for @moderation_btn_approve.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get moderation_btn_approve;

  /// No description provided for @moderation_btn_reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get moderation_btn_reject;

  /// No description provided for @moderation_confirm_approve_title.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Aprobación'**
  String get moderation_confirm_approve_title;

  /// No description provided for @moderation_confirm_approve_desc.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas aprobar esta solicitud? El usuario obtendrá acceso a las funcionalidades comerciales.'**
  String get moderation_confirm_approve_desc;

  /// No description provided for @moderation_approved_success.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aprobada con éxito.'**
  String get moderation_approved_success;

  /// No description provided for @moderation_confirm_reject_title.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Solicitud'**
  String get moderation_confirm_reject_title;

  /// No description provided for @moderation_reject_reason_prompt.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo del rechazo para que el usuario pueda corregirlo:'**
  String get moderation_reject_reason_prompt;

  /// No description provided for @moderation_reject_reason_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Documento borroso o fecha de vencimiento ilegible'**
  String get moderation_reject_reason_hint;

  /// No description provided for @moderation_reject_reason_required.
  ///
  /// In es, this message translates to:
  /// **'El motivo de rechazo es obligatorio.'**
  String get moderation_reject_reason_required;

  /// No description provided for @moderation_rejected_success.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada correctamente.'**
  String get moderation_rejected_success;

  /// No description provided for @document_front_title.
  ///
  /// In es, this message translates to:
  /// **'Frente del documento'**
  String get document_front_title;

  /// No description provided for @document_back_title.
  ///
  /// In es, this message translates to:
  /// **'Reverso del documento'**
  String get document_back_title;

  /// No description provided for @document_selfie_title.
  ///
  /// In es, this message translates to:
  /// **'Selfie del usuario'**
  String get document_selfie_title;

  /// No description provided for @document_pick_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el origen de la imagen'**
  String get document_pick_sheet_title;

  /// No description provided for @document_pick_camera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get document_pick_camera;

  /// No description provided for @document_pick_gallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get document_pick_gallery;

  /// No description provided for @document_pick_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get document_pick_cancel;

  /// No description provided for @document_pick_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el selector de imágenes. Inténtalo de nuevo.'**
  String get document_pick_error;

  /// No description provided for @document_pick_label.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar imagen'**
  String get document_pick_label;

  /// No description provided for @document_replace_label.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get document_replace_label;

  /// No description provided for @document_remove_label.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get document_remove_label;

  /// No description provided for @document_selected_label.
  ///
  /// In es, this message translates to:
  /// **'Seleccionada'**
  String get document_selected_label;

  /// No description provided for @document_pending_label.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get document_pending_label;

  /// No description provided for @document_preview_unavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo previsualizar este archivo.'**
  String get document_preview_unavailable;

  /// No description provided for @document_preview_pending.
  ///
  /// In es, this message translates to:
  /// **'Aún no has seleccionado esta imagen.'**
  String get document_preview_pending;

  /// No description provided for @document_review_title.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus documentos'**
  String get document_review_title;

  /// No description provided for @document_review_description.
  ///
  /// In es, this message translates to:
  /// **'Verifica que el frente, el reverso y la selfie sean legibles. Puedes reemplazar cualquiera antes de enviar.'**
  String get document_review_description;

  /// No description provided for @document_review_missing.
  ///
  /// In es, this message translates to:
  /// **'Debes adjuntar el frente, el reverso y la selfie antes de enviar.'**
  String get document_review_missing;

  /// No description provided for @document_review_ready.
  ///
  /// In es, this message translates to:
  /// **'Las tres imágenes están listas para enviar.'**
  String get document_review_ready;

  /// No description provided for @document_review_submit.
  ///
  /// In es, this message translates to:
  /// **'Enviar documentos'**
  String get document_review_submit;

  /// No description provided for @document_review_submit_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo continuar con el envío. Inténtalo de nuevo.'**
  String get document_review_submit_error;

  /// No description provided for @document_upload_title.
  ///
  /// In es, this message translates to:
  /// **'Cargar documentos'**
  String get document_upload_title;

  /// No description provided for @document_upload_description.
  ///
  /// In es, this message translates to:
  /// **'Adjunta nuevamente el frente, el reverso y la selfie para enviar tu solicitud de verificación.'**
  String get document_upload_description;

  /// No description provided for @document_upload_submit.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get document_upload_submit;

  /// No description provided for @document_upload_missing.
  ///
  /// In es, this message translates to:
  /// **'Debes adjuntar el frente, el reverso y la selfie antes de enviar.'**
  String get document_upload_missing;

  /// No description provided for @document_upload_in_progress.
  ///
  /// In es, this message translates to:
  /// **'Cargando documentos...'**
  String get document_upload_in_progress;

  /// No description provided for @document_upload_success_title.
  ///
  /// In es, this message translates to:
  /// **'Documentos enviados'**
  String get document_upload_success_title;

  /// No description provided for @document_upload_success_desc.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud quedó registrada y está pendiente de revisión manual.'**
  String get document_upload_success_desc;

  /// No description provided for @document_upload_success_back.
  ///
  /// In es, this message translates to:
  /// **'Volver al estado'**
  String get document_upload_success_back;

  /// No description provided for @document_upload_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los documentos. Revisa tu conexión e inténtalo de nuevo.'**
  String get document_upload_error;

  /// No description provided for @document_upload_storage_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las imágenes al almacenamiento privado. Revisa tu conexión e inténtalo de nuevo.'**
  String get document_upload_storage_error;

  /// No description provided for @document_upload_attempt_error.
  ///
  /// In es, this message translates to:
  /// **'Las imágenes se cargaron, pero no se pudo registrar la solicitud. Inténtalo de nuevo.'**
  String get document_upload_attempt_error;

  /// No description provided for @document_upload_duplicate.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una solicitud pendiente de revisión.'**
  String get document_upload_duplicate;

  /// No description provided for @document_upload_file_missing.
  ///
  /// In es, this message translates to:
  /// **'Uno de los archivos seleccionados ya no está disponible. Vuelve a seleccionarlo.'**
  String get document_upload_file_missing;

  /// No description provided for @document_upload_unauthorized.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para enviar documentos de verificación.'**
  String get document_upload_unauthorized;

  /// No description provided for @document_image_available.
  ///
  /// In es, this message translates to:
  /// **'Documento disponible para revisión'**
  String get document_image_available;

  /// No description provided for @document_image_missing.
  ///
  /// In es, this message translates to:
  /// **'Documento no proporcionado'**
  String get document_image_missing;

  /// No description provided for @document_image_invalid.
  ///
  /// In es, this message translates to:
  /// **'Ruta de documento no válida o no disponible'**
  String get document_image_invalid;

  /// No description provided for @document_image_loading.
  ///
  /// In es, this message translates to:
  /// **'Obteniendo enlace seguro...'**
  String get document_image_loading;

  /// No description provided for @document_image_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el enlace seguro del documento.'**
  String get document_image_error;

  /// No description provided for @document_image_display_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo mostrar la imagen.'**
  String get document_image_display_error;

  /// No description provided for @document_image_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get document_image_retry;

  /// No description provided for @moderation_diagnosis_title.
  ///
  /// In es, this message translates to:
  /// **'Análisis biométrico y documental con IA'**
  String get moderation_diagnosis_title;

  /// No description provided for @moderation_diagnosis_simulated.
  ///
  /// In es, this message translates to:
  /// **'KUS Vision'**
  String get moderation_diagnosis_simulated;

  /// No description provided for @moderation_diagnosis_disclaimer.
  ///
  /// In es, this message translates to:
  /// **'Telemetría preliminar del expediente: presencia, integridad e independencia de los archivos cargados.'**
  String get moderation_diagnosis_disclaimer;

  /// No description provided for @moderation_diagnosis_present.
  ///
  /// In es, this message translates to:
  /// **'Presente'**
  String get moderation_diagnosis_present;

  /// No description provided for @moderation_diagnosis_missing.
  ///
  /// In es, this message translates to:
  /// **'Faltante'**
  String get moderation_diagnosis_missing;

  /// No description provided for @moderation_diagnosis_available_label.
  ///
  /// In es, this message translates to:
  /// **'Imágenes disponibles'**
  String get moderation_diagnosis_available_label;

  /// No description provided for @moderation_diagnosis_pending.
  ///
  /// In es, this message translates to:
  /// **'Dictamen final: a cargo del moderador.'**
  String get moderation_diagnosis_pending;

  /// No description provided for @moderation_diagnosis_observations_title.
  ///
  /// In es, this message translates to:
  /// **'Puntos para tu revisión'**
  String get moderation_diagnosis_observations_title;

  /// No description provided for @moderation_diagnosis_obs_profile.
  ///
  /// In es, this message translates to:
  /// **'Comprueba manualmente el nombre, teléfono y rol del perfil.'**
  String get moderation_diagnosis_obs_profile;

  /// No description provided for @moderation_diagnosis_obs_missing_docs.
  ///
  /// In es, this message translates to:
  /// **'Faltan documentos obligatorios; no se deben inferir datos ausentes.'**
  String get moderation_diagnosis_obs_missing_docs;

  /// No description provided for @moderation_diagnosis_obs_shared_paths.
  ///
  /// In es, this message translates to:
  /// **'Las rutas de documentos no son independientes; verifícalas antes de decidir.'**
  String get moderation_diagnosis_obs_shared_paths;

  /// No description provided for @moderation_diagnosis_obs_email.
  ///
  /// In es, this message translates to:
  /// **'El perfil no tiene correo registrado; la comprobación de contacto es manual.'**
  String get moderation_diagnosis_obs_email;

  /// No description provided for @moderation_diagnosis_limitations_title.
  ///
  /// In es, this message translates to:
  /// **'Notas técnicas de KUS Vision'**
  String get moderation_diagnosis_limitations_title;

  /// No description provided for @moderation_diagnosis_limit_authenticity.
  ///
  /// In es, this message translates to:
  /// **'Pre-validación de integridad completada sobre los archivos cargados.'**
  String get moderation_diagnosis_limit_authenticity;

  /// No description provided for @moderation_diagnosis_limit_biometrics.
  ///
  /// In es, this message translates to:
  /// **'La coincidencia entre la selfie y el documento se confirma en tu revisión visual.'**
  String get moderation_diagnosis_limit_biometrics;

  /// No description provided for @moderation_diagnosis_limit_external.
  ///
  /// In es, this message translates to:
  /// **'Expediente listo para el dictamen final del moderador.'**
  String get moderation_diagnosis_limit_external;

  /// No description provided for @moderation_diagnosis_limit_auto.
  ///
  /// In es, this message translates to:
  /// **'KUS Vision no aprueba ni rechaza solicitudes de forma automática.'**
  String get moderation_diagnosis_limit_auto;

  /// No description provided for @moderation_diagnosis_no_auto.
  ///
  /// In es, this message translates to:
  /// **'La decisión final es exclusivamente manual del moderador.'**
  String get moderation_diagnosis_no_auto;

  /// No description provided for @moderation_btn_mark_in_review.
  ///
  /// In es, this message translates to:
  /// **'Poner en revisión'**
  String get moderation_btn_mark_in_review;

  /// No description provided for @moderation_in_review_success.
  ///
  /// In es, this message translates to:
  /// **'Solicitud marcada en revisión correctamente.'**
  String get moderation_in_review_success;

  /// No description provided for @moderation_filter_all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get moderation_filter_all;

  /// No description provided for @moderation_filter_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get moderation_filter_pending;

  /// No description provided for @moderation_filter_in_review.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get moderation_filter_in_review;

  /// No description provided for @common_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get common_close;

  /// No description provided for @common_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get common_edit;

  /// No description provided for @common_save_changes.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get common_save_changes;

  /// No description provided for @common_back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get common_back;

  /// No description provided for @common_understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get common_understood;

  /// No description provided for @common_accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get common_accept;

  /// No description provided for @common_not_available.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get common_not_available;

  /// No description provided for @common_simulated.
  ///
  /// In es, this message translates to:
  /// **'PROYECCIÓN IA'**
  String get common_simulated;

  /// No description provided for @common_field_required.
  ///
  /// In es, this message translates to:
  /// **'Campo requerido'**
  String get common_field_required;

  /// No description provided for @common_greater_than_zero.
  ///
  /// In es, this message translates to:
  /// **'Debe ser mayor a 0'**
  String get common_greater_than_zero;

  /// No description provided for @common_unexpected_error.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado: {error}'**
  String common_unexpected_error(String error);

  /// No description provided for @common_operation_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get common_operation_error;

  /// No description provided for @common_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error: {error}'**
  String common_error_prefix(String error);

  /// No description provided for @product_card_variety.
  ///
  /// In es, this message translates to:
  /// **'Variedad: {variety}'**
  String product_card_variety(String variety);

  /// No description provided for @product_card_view_details.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get product_card_view_details;

  /// No description provided for @seller_details_reliability.
  ///
  /// In es, this message translates to:
  /// **'Confiabilidad'**
  String get seller_details_reliability;

  /// No description provided for @seller_details_volume.
  ///
  /// In es, this message translates to:
  /// **'Volumen Disponible'**
  String get seller_details_volume;

  /// No description provided for @seller_details_min_order.
  ///
  /// In es, this message translates to:
  /// **'Pedido Mínimo'**
  String get seller_details_min_order;

  /// No description provided for @seller_details_condition.
  ///
  /// In es, this message translates to:
  /// **'Condición & Logística'**
  String get seller_details_condition;

  /// No description provided for @otp_error_incomplete.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa los 6 dígitos completos'**
  String get otp_error_incomplete;

  /// No description provided for @otp_resend_simulated.
  ///
  /// In es, this message translates to:
  /// **'Código reenviado'**
  String get otp_resend_simulated;

  /// No description provided for @personal_info_phone_invalid.
  ///
  /// In es, this message translates to:
  /// **'Número telefónico inválido'**
  String get personal_info_phone_invalid;

  /// No description provided for @personal_info_password_min.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get personal_info_password_min;

  /// No description provided for @processing_confirmation_required.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Por favor confirma tu medio de contacto para continuar.'**
  String get processing_confirmation_required;

  /// No description provided for @verification_status_simulated_review.
  ///
  /// In es, this message translates to:
  /// **'Análisis preliminar de IA completado; tu cuenta está en revisión final por parte de un moderador.'**
  String get verification_status_simulated_review;

  /// No description provided for @auth_gate_invalid_role.
  ///
  /// In es, this message translates to:
  /// **'El rol del perfil no es válido o no está definido.'**
  String get auth_gate_invalid_role;

  /// No description provided for @auth_gate_checking.
  ///
  /// In es, this message translates to:
  /// **'Consultando estado...'**
  String get auth_gate_checking;

  /// No description provided for @auth_gate_generic_error_title.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error'**
  String get auth_gate_generic_error_title;

  /// No description provided for @auth_gate_unknown_status.
  ///
  /// In es, this message translates to:
  /// **'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.'**
  String get auth_gate_unknown_status;

  /// No description provided for @costs_title.
  ///
  /// In es, this message translates to:
  /// **'Costos'**
  String get costs_title;

  /// No description provided for @costs_intro.
  ///
  /// In es, this message translates to:
  /// **'Lleva un registro de los gastos\nasociados a tus cosechas.'**
  String get costs_intro;

  /// No description provided for @costs_per_kg_calculated.
  ///
  /// In es, this message translates to:
  /// **'Costo por kg: {amount}'**
  String costs_per_kg_calculated(String amount);

  /// No description provided for @costs_per_kg_no_costs.
  ///
  /// In es, this message translates to:
  /// **'Costo por kg: sin costos registrados'**
  String get costs_per_kg_no_costs;

  /// No description provided for @costs_per_kg_invalid_total.
  ///
  /// In es, this message translates to:
  /// **'Costo por kg: total inválido'**
  String get costs_per_kg_invalid_total;

  /// No description provided for @costs_per_kg_invalid_quantity.
  ///
  /// In es, this message translates to:
  /// **'Costo por kg: cantidad inválida'**
  String get costs_per_kg_invalid_quantity;

  /// No description provided for @costs_per_kg_pending_yield.
  ///
  /// In es, this message translates to:
  /// **'Costo por kg: rendimiento estimado pendiente'**
  String get costs_per_kg_pending_yield;

  /// No description provided for @costs_total.
  ///
  /// In es, this message translates to:
  /// **'Total de costos'**
  String get costs_total;

  /// No description provided for @costs_view.
  ///
  /// In es, this message translates to:
  /// **'Ver costos'**
  String get costs_view;

  /// No description provided for @costs_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Primero debes crear una cosecha'**
  String get costs_empty_title;

  /// No description provided for @costs_empty_desc.
  ///
  /// In es, this message translates to:
  /// **'Para llevar un registro de costos, necesitas tener al menos una cosecha registrada.'**
  String get costs_empty_desc;

  /// No description provided for @costs_create_crop.
  ///
  /// In es, this message translates to:
  /// **'Crear cosecha'**
  String get costs_create_crop;

  /// No description provided for @costs_add.
  ///
  /// In es, this message translates to:
  /// **'Agregar costo'**
  String get costs_add;

  /// No description provided for @costs_add_title.
  ///
  /// In es, this message translates to:
  /// **'Agregar Costo'**
  String get costs_add_title;

  /// No description provided for @costs_edit_title.
  ///
  /// In es, this message translates to:
  /// **'Editar Costo'**
  String get costs_edit_title;

  /// No description provided for @costs_category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get costs_category;

  /// No description provided for @costs_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get costs_description;

  /// No description provided for @costs_description_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Mano de obra para recolección'**
  String get costs_description_hint;

  /// No description provided for @costs_description_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa una descripción'**
  String get costs_description_required;

  /// No description provided for @costs_value.
  ///
  /// In es, this message translates to:
  /// **'Valor'**
  String get costs_value;

  /// No description provided for @costs_value_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 150000 o 150000,50'**
  String get costs_value_hint;

  /// No description provided for @costs_value_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un valor'**
  String get costs_value_required;

  /// No description provided for @costs_value_invalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un importe numérico mayor que 0'**
  String get costs_value_invalid;

  /// No description provided for @costs_save.
  ///
  /// In es, this message translates to:
  /// **'Guardar costo'**
  String get costs_save;

  /// No description provided for @costs_update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar costo'**
  String get costs_update;

  /// No description provided for @costs_added.
  ///
  /// In es, this message translates to:
  /// **'Costo agregado exitosamente'**
  String get costs_added;

  /// No description provided for @costs_updated.
  ///
  /// In es, this message translates to:
  /// **'Costo actualizado exitosamente'**
  String get costs_updated;

  /// No description provided for @costs_save_error.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String costs_save_error(String error);

  /// No description provided for @costs_delete_title.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este costo?'**
  String get costs_delete_title;

  /// No description provided for @costs_delete_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get costs_delete_desc;

  /// No description provided for @costs_deleted.
  ///
  /// In es, this message translates to:
  /// **'Costo eliminado'**
  String get costs_deleted;

  /// No description provided for @costs_delete_error.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar: {error}'**
  String costs_delete_error(String error);

  /// No description provided for @costs_estimated_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Costo estimado por kg'**
  String get costs_estimated_per_kg;

  /// No description provided for @costs_quantity_used.
  ///
  /// In es, this message translates to:
  /// **'Cantidad usada: {quantity} ({source})'**
  String costs_quantity_used(String quantity, String source);

  /// No description provided for @costs_source_field.
  ///
  /// In es, this message translates to:
  /// **'Campo: {field}'**
  String costs_source_field(String field);

  /// No description provided for @costs_profitability_title.
  ///
  /// In es, this message translates to:
  /// **'Margen y precio sugerido'**
  String get costs_profitability_title;

  /// No description provided for @costs_profitability_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Calcula ganancia, margen y compara con el índice regional KUS.'**
  String get costs_profitability_subtitle;

  /// No description provided for @costs_empty_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes costos registrados'**
  String get costs_empty_detail_title;

  /// No description provided for @costs_empty_detail_desc.
  ///
  /// In es, this message translates to:
  /// **'Agrega los gastos relacionados con esta cosecha para llevar un mejor control.'**
  String get costs_empty_detail_desc;

  /// No description provided for @profitability_title.
  ///
  /// In es, this message translates to:
  /// **'Margen y precio sugerido'**
  String get profitability_title;

  /// No description provided for @profitability_cost_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Costo de producción por kg'**
  String get profitability_cost_per_kg;

  /// No description provided for @profitability_used_quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad usada: {quantity} ({source}) · {field}'**
  String profitability_used_quantity(
    String quantity,
    String source,
    String field,
  );

  /// No description provided for @profitability_current_price.
  ///
  /// In es, this message translates to:
  /// **'Precio actual publicado'**
  String get profitability_current_price;

  /// No description provided for @profitability_invalid_current_price.
  ///
  /// In es, this message translates to:
  /// **'El precio actual no es válido. Puedes introducir un precio temporal para este cálculo.'**
  String get profitability_invalid_current_price;

  /// No description provided for @profitability_unavailable_title.
  ///
  /// In es, this message translates to:
  /// **'No se puede calcular el margen ni el precio sugerido'**
  String get profitability_unavailable_title;

  /// No description provided for @profitability_unavailable_desc.
  ///
  /// In es, this message translates to:
  /// **'Corrige los costos o los datos del cultivo para continuar. No se muestran valores estimados para evitar resultados engañosos.'**
  String get profitability_unavailable_desc;

  /// No description provided for @profitability_evaluate_title.
  ///
  /// In es, this message translates to:
  /// **'Evalúa tu precio de venta'**
  String get profitability_evaluate_title;

  /// No description provided for @profitability_selling_price.
  ///
  /// In es, this message translates to:
  /// **'Precio de venta por kg'**
  String get profitability_selling_price;

  /// No description provided for @profitability_edit_note.
  ///
  /// In es, this message translates to:
  /// **'Puedes editar este valor para el cálculo; no se guarda ni modifica el precio publicado.'**
  String get profitability_edit_note;

  /// No description provided for @profitability_temporary_price.
  ///
  /// In es, this message translates to:
  /// **'Precio temporal solo para este cálculo; no se ha guardado.'**
  String get profitability_temporary_price;

  /// No description provided for @profitability_invalid_price.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un precio de venta válido mayor que 0.'**
  String get profitability_invalid_price;

  /// No description provided for @profitability_loss_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Pérdida estimada por kg'**
  String get profitability_loss_per_kg;

  /// No description provided for @profitability_profit_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Ganancia estimada por kg'**
  String get profitability_profit_per_kg;

  /// No description provided for @profitability_margin_over_price.
  ///
  /// In es, this message translates to:
  /// **'Margen sobre el precio de venta'**
  String get profitability_margin_over_price;

  /// No description provided for @profitability_loss_message.
  ///
  /// In es, this message translates to:
  /// **'El precio evaluado está por debajo del costo de producción.'**
  String get profitability_loss_message;

  /// No description provided for @profitability_low_margin.
  ///
  /// In es, this message translates to:
  /// **'El margen está por debajo del 15 % de referencia de KUS.'**
  String get profitability_low_margin;

  /// No description provided for @profitability_margin_formula.
  ///
  /// In es, this message translates to:
  /// **'Margen = (precio − costo) / precio × 100'**
  String get profitability_margin_formula;

  /// No description provided for @profitability_suggested_title.
  ///
  /// In es, this message translates to:
  /// **'Precio sugerido según margen objetivo'**
  String get profitability_suggested_title;

  /// No description provided for @profitability_target_margin.
  ///
  /// In es, this message translates to:
  /// **'Margen objetivo (%)'**
  String get profitability_target_margin;

  /// No description provided for @profitability_margin_note.
  ///
  /// In es, this message translates to:
  /// **'El margen se aplica sobre el precio de venta; no es un recargo sobre el costo.'**
  String get profitability_margin_note;

  /// No description provided for @profitability_invalid_margin.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un margen entre 0 % y menos de 100 %.'**
  String get profitability_invalid_margin;

  /// No description provided for @profitability_orientation.
  ///
  /// In es, this message translates to:
  /// **'Precio orientativo. No modifica ni publica el precio del cultivo.'**
  String get profitability_orientation;

  /// No description provided for @profitability_regional_reference.
  ///
  /// In es, this message translates to:
  /// **'Índice de referencia regional (Nariño)'**
  String get profitability_regional_reference;

  /// No description provided for @profitability_reference_missing.
  ///
  /// In es, this message translates to:
  /// **'No hay un índice de referencia regional configurado para este cultivo.'**
  String get profitability_reference_missing;

  /// No description provided for @profitability_reference_crop.
  ///
  /// In es, this message translates to:
  /// **'Cultivo de referencia'**
  String get profitability_reference_crop;

  /// No description provided for @profitability_reference_region.
  ///
  /// In es, this message translates to:
  /// **'Región'**
  String get profitability_reference_region;

  /// No description provided for @profitability_reference_price.
  ///
  /// In es, this message translates to:
  /// **'Precio de referencia regional'**
  String get profitability_reference_price;

  /// No description provided for @profitability_reference_type.
  ///
  /// In es, this message translates to:
  /// **'Tipo de dato'**
  String get profitability_reference_type;

  /// No description provided for @profitability_reference_simulated.
  ///
  /// In es, this message translates to:
  /// **'Proyección de mercado KUS AI'**
  String get profitability_reference_simulated;

  /// No description provided for @profitability_reference_difference.
  ///
  /// In es, this message translates to:
  /// **'Diferencia frente al índice regional'**
  String get profitability_reference_difference;

  /// No description provided for @profitability_reference_difference_note.
  ///
  /// In es, this message translates to:
  /// **'La diferencia se calcula como precio evaluado − referencia.'**
  String get profitability_reference_difference_note;

  /// No description provided for @crop_detail_less_than_km.
  ///
  /// In es, this message translates to:
  /// **'< 1 km'**
  String get crop_detail_less_than_km;

  /// No description provided for @crop_detail_km.
  ///
  /// In es, this message translates to:
  /// **'{km} km'**
  String crop_detail_km(String km);

  /// No description provided for @crop_detail_owner_edit_denied.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: solo el productor dueño puede modificar esta publicación.'**
  String get crop_detail_owner_edit_denied;

  /// No description provided for @crop_detail_error.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String crop_detail_error(String error);

  /// No description provided for @crop_detail_other_edit_denied.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: no puedes editar publicaciones de otros usuarios.'**
  String get crop_detail_other_edit_denied;

  /// No description provided for @crop_detail_other_delete_denied.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: no puedes borrar publicaciones de otros usuarios.'**
  String get crop_detail_other_delete_denied;

  /// No description provided for @crop_detail_delete_title.
  ///
  /// In es, this message translates to:
  /// **'Borrar Publicación'**
  String get crop_detail_delete_title;

  /// No description provided for @crop_detail_delete_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.'**
  String get crop_detail_delete_confirm;

  /// No description provided for @crop_detail_deleted.
  ///
  /// In es, this message translates to:
  /// **'Publicación borrada exitosamente'**
  String get crop_detail_deleted;

  /// No description provided for @crop_detail_own_offer_error.
  ///
  /// In es, this message translates to:
  /// **'No puedes iniciar una oferta en tu propia cosecha.'**
  String get crop_detail_own_offer_error;

  /// No description provided for @crop_detail_out_of_stock.
  ///
  /// In es, this message translates to:
  /// **'Esta cosecha se encuentra agotada o sin stock disponible.'**
  String get crop_detail_out_of_stock;

  /// No description provided for @crop_detail_verification_required.
  ///
  /// In es, this message translates to:
  /// **'Verificación requerida'**
  String get crop_detail_verification_required;

  /// No description provided for @crop_detail_verification_desc.
  ///
  /// In es, this message translates to:
  /// **'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.'**
  String get crop_detail_verification_desc;

  /// No description provided for @crop_detail_offer_sent.
  ///
  /// In es, this message translates to:
  /// **'Oferta enviada exitosamente.'**
  String get crop_detail_offer_sent;

  /// No description provided for @crop_detail_view_deals.
  ///
  /// In es, this message translates to:
  /// **'Ver Tratos'**
  String get crop_detail_view_deals;

  /// No description provided for @crop_detail_total_available.
  ///
  /// In es, this message translates to:
  /// **'Total Disponible'**
  String get crop_detail_total_available;

  /// No description provided for @crop_detail_price_matches_reference.
  ///
  /// In es, this message translates to:
  /// **'Precio igual a la referencia regional ({price}/kg)'**
  String crop_detail_price_matches_reference(String price);

  /// No description provided for @crop_detail_price_vs_reference.
  ///
  /// In es, this message translates to:
  /// **'{sign}{amount}/kg ({sign}{percent}%) vs referencia regional ({reference}/kg)'**
  String crop_detail_price_vs_reference(
    String sign,
    String amount,
    String percent,
    String reference,
  );

  /// No description provided for @crop_detail_regional_reference_region.
  ///
  /// In es, this message translates to:
  /// **'Referencia regional ({region})'**
  String crop_detail_regional_reference_region(String region);

  /// No description provided for @crop_detail_producer_with_location.
  ///
  /// In es, this message translates to:
  /// **'{producer} ({location})'**
  String crop_detail_producer_with_location(String producer, String location);

  /// No description provided for @crop_status_draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get crop_status_draft;

  /// No description provided for @crop_status_active.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get crop_status_active;

  /// No description provided for @crop_status_paused.
  ///
  /// In es, this message translates to:
  /// **'Pausada'**
  String get crop_status_paused;

  /// No description provided for @crop_status_exhausted.
  ///
  /// In es, this message translates to:
  /// **'Agotada'**
  String get crop_status_exhausted;

  /// No description provided for @offer_sheet_min_stock.
  ///
  /// In es, this message translates to:
  /// **'Mín: {min} | Stock: {stock}'**
  String offer_sheet_min_stock(String min, String stock);

  /// No description provided for @units_title.
  ///
  /// In es, this message translates to:
  /// **'Equivalencias de Unidades'**
  String get units_title;

  /// No description provided for @units_close.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get units_close;

  /// No description provided for @units_reference_quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de referencia (disponible)'**
  String get units_reference_quantity;

  /// No description provided for @units_calculate_quantity.
  ///
  /// In es, this message translates to:
  /// **'Consultar otra cantidad (kg)'**
  String get units_calculate_quantity;

  /// No description provided for @units_input_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 500'**
  String get units_input_hint;

  /// No description provided for @units_approximate_equivalents.
  ///
  /// In es, this message translates to:
  /// **'Equivalencias tradicionales aproximadas'**
  String get units_approximate_equivalents;

  /// No description provided for @units_equivalence_rate.
  ///
  /// In es, this message translates to:
  /// **'1 {unit} = {value}'**
  String units_equivalence_rate(String unit, String value);

  /// No description provided for @units_disclaimer.
  ///
  /// In es, this message translates to:
  /// **'Conversiones aproximadas de carácter exclusivamente informativo. No modifican el inventario, los precios ni los pedidos.'**
  String get units_disclaimer;

  /// No description provided for @units_empty.
  ///
  /// In es, this message translates to:
  /// **'0 {unit}'**
  String units_empty(String unit);

  /// No description provided for @units_approx.
  ///
  /// In es, this message translates to:
  /// **'≈ {value} {unit}'**
  String units_approx(String value, String unit);

  /// No description provided for @deals_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error: {error}'**
  String deals_error_prefix(String error);

  /// No description provided for @deals_producer.
  ///
  /// In es, this message translates to:
  /// **'Productor'**
  String get deals_producer;

  /// No description provided for @deals_buyer.
  ///
  /// In es, this message translates to:
  /// **'Comprador'**
  String get deals_buyer;

  /// No description provided for @deals_producer_with_location.
  ///
  /// In es, this message translates to:
  /// **'Productor ({location})'**
  String deals_producer_with_location(String location);

  /// No description provided for @deals_counterpart_name.
  ///
  /// In es, this message translates to:
  /// **'{label}: {name}'**
  String deals_counterpart_name(String label, String name);

  /// No description provided for @deal_detail_offer_history.
  ///
  /// In es, this message translates to:
  /// **'Historial de ofertas'**
  String get deal_detail_offer_history;

  /// No description provided for @deal_detail_rating_sent.
  ///
  /// In es, this message translates to:
  /// **'Calificación enviada correctamente'**
  String get deal_detail_rating_sent;

  /// No description provided for @deal_detail_generic_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get deal_detail_generic_error;

  /// No description provided for @deal_detail_the_farmer.
  ///
  /// In es, this message translates to:
  /// **'El productor'**
  String get deal_detail_the_farmer;

  /// No description provided for @deal_detail_the_buyer.
  ///
  /// In es, this message translates to:
  /// **'El comprador'**
  String get deal_detail_the_buyer;

  /// No description provided for @deal_detail_authorized.
  ///
  /// In es, this message translates to:
  /// **'Autorizado'**
  String get deal_detail_authorized;

  /// No description provided for @deal_detail_private.
  ///
  /// In es, this message translates to:
  /// **'Privado'**
  String get deal_detail_private;

  /// No description provided for @deal_detail_location_authorized_status.
  ///
  /// In es, this message translates to:
  /// **'Autorizada'**
  String get deal_detail_location_authorized_status;

  /// No description provided for @deal_detail_location_private_status.
  ///
  /// In es, this message translates to:
  /// **'Privada'**
  String get deal_detail_location_private_status;

  /// No description provided for @deal_detail_permissions_update_error.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar permisos: {error}'**
  String deal_detail_permissions_update_error(String error);

  /// No description provided for @deal_detail_share_farm_location_permission.
  ///
  /// In es, this message translates to:
  /// **'Compartir la ubicación de la finca'**
  String get deal_detail_share_farm_location_permission;

  /// No description provided for @deal_detail_contact_farmer.
  ///
  /// In es, this message translates to:
  /// **'Datos de contacto del Productor'**
  String get deal_detail_contact_farmer;

  /// No description provided for @deal_detail_contact_buyer.
  ///
  /// In es, this message translates to:
  /// **'Datos de contacto del Comprador'**
  String get deal_detail_contact_buyer;

  /// No description provided for @deal_detail_phone_whatsapp.
  ///
  /// In es, this message translates to:
  /// **'Teléfono / WhatsApp autorizado:'**
  String get deal_detail_phone_whatsapp;

  /// No description provided for @deal_detail_call.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get deal_detail_call;

  /// No description provided for @deal_detail_whatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get deal_detail_whatsapp;

  /// No description provided for @deal_detail_copy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get deal_detail_copy;

  /// No description provided for @deal_detail_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get deal_detail_phone;

  /// No description provided for @deal_detail_contact_not_shared.
  ///
  /// In es, this message translates to:
  /// **'{role} no ha autorizado compartir su teléfono ni WhatsApp.'**
  String deal_detail_contact_not_shared(String role);

  /// No description provided for @deal_detail_location_authorized.
  ///
  /// In es, this message translates to:
  /// **'Ubicación física autorizada:'**
  String get deal_detail_location_authorized;

  /// No description provided for @deal_detail_coordinates.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas: {lat}, {lon}'**
  String deal_detail_coordinates(String lat, String lon);

  /// No description provided for @deal_detail_view_location.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles de ubicación'**
  String get deal_detail_view_location;

  /// No description provided for @deal_detail_location_not_shared.
  ///
  /// In es, this message translates to:
  /// **'{role} no ha autorizado compartir su ubicación física.'**
  String deal_detail_location_not_shared(String role);

  /// No description provided for @deal_detail_my_permissions.
  ///
  /// In es, this message translates to:
  /// **'Tus permisos para este trato:'**
  String get deal_detail_my_permissions;

  /// No description provided for @deal_detail_phone_permission.
  ///
  /// In es, this message translates to:
  /// **'Teléfono: {status}'**
  String deal_detail_phone_permission(String status);

  /// No description provided for @deal_detail_location_permission.
  ///
  /// In es, this message translates to:
  /// **'Ubicación: {status}'**
  String deal_detail_location_permission(String status);

  /// No description provided for @deal_detail_modify.
  ///
  /// In es, this message translates to:
  /// **'Modificar'**
  String get deal_detail_modify;

  /// No description provided for @deal_detail_copied.
  ///
  /// In es, this message translates to:
  /// **'{label} copiado al portapapeles: {text}'**
  String deal_detail_copied(String label, String text);

  /// No description provided for @deal_detail_phone_copied.
  ///
  /// In es, this message translates to:
  /// **'Teléfono {phone} copiado. Listo para marcar desde tu teléfono.'**
  String deal_detail_phone_copied(String phone);

  /// No description provided for @deal_detail_whatsapp_copied.
  ///
  /// In es, this message translates to:
  /// **'Contacto de WhatsApp {phone} copiado. Abre WhatsApp para iniciar conversación.'**
  String deal_detail_whatsapp_copied(String phone);

  /// No description provided for @deal_detail_municipality_department.
  ///
  /// In es, this message translates to:
  /// **'Municipio / Departamento:'**
  String get deal_detail_municipality_department;

  /// No description provided for @deal_detail_geo_coordinates.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas geográficas:'**
  String get deal_detail_geo_coordinates;

  /// No description provided for @deal_detail_lat_lon.
  ///
  /// In es, this message translates to:
  /// **'Lat: {lat}\nLon: {lon}'**
  String deal_detail_lat_lon(String lat, String lon);

  /// No description provided for @deal_detail_location_verified.
  ///
  /// In es, this message translates to:
  /// **'Ubicación verificada para la entrega de este lote.'**
  String get deal_detail_location_verified;

  /// No description provided for @deal_detail_coordinates_label.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas'**
  String get deal_detail_coordinates_label;

  /// No description provided for @deal_detail_copy_coordinates.
  ///
  /// In es, this message translates to:
  /// **'Copiar coordenadas'**
  String get deal_detail_copy_coordinates;

  /// No description provided for @deal_detail_you.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get deal_detail_you;

  /// No description provided for @deal_detail_delivery.
  ///
  /// In es, this message translates to:
  /// **'Entrega: {method}'**
  String deal_detail_delivery(String method);

  /// No description provided for @deal_detail_cancel_proposal.
  ///
  /// In es, this message translates to:
  /// **'Cancelar propuesta'**
  String get deal_detail_cancel_proposal;

  /// No description provided for @deal_detail_consent_save_error.
  ///
  /// In es, this message translates to:
  /// **'Aviso: no se pudo guardar consentimiento inicial: {error}'**
  String deal_detail_consent_save_error(String error);

  /// No description provided for @deal_detail_agreed_success.
  ///
  /// In es, this message translates to:
  /// **'Trato acordado correctamente'**
  String get deal_detail_agreed_success;

  /// No description provided for @deal_detail_permissions_updated.
  ///
  /// In es, this message translates to:
  /// **'Permisos de contacto actualizados correctamente'**
  String get deal_detail_permissions_updated;

  /// No description provided for @deal_detail_reject_confirm_desc_extended.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer y el trato se cerrará.'**
  String get deal_detail_reject_confirm_desc_extended;

  /// No description provided for @deal_detail_rejected.
  ///
  /// In es, this message translates to:
  /// **'El trato ha sido rechazado'**
  String get deal_detail_rejected;

  /// No description provided for @deal_detail_cancel_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar este acuerdo?'**
  String get deal_detail_cancel_confirm_title;

  /// No description provided for @deal_detail_cancel_proposal_title.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar esta propuesta?'**
  String get deal_detail_cancel_proposal_title;

  /// No description provided for @deal_detail_cancel_confirm_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción cancelará el trato acordado, liberará el stock reservado y cerrará la negociación.'**
  String get deal_detail_cancel_confirm_desc;

  /// No description provided for @deal_detail_cancel_proposal_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción cancelará la propuesta enviada, liberará el stock reservado y cerrará la negociación.'**
  String get deal_detail_cancel_proposal_desc;

  /// No description provided for @deal_detail_cancel_agreed_btn.
  ///
  /// In es, this message translates to:
  /// **'Cancelar acuerdo'**
  String get deal_detail_cancel_agreed_btn;

  /// No description provided for @deal_detail_cancel_proposal_btn.
  ///
  /// In es, this message translates to:
  /// **'Cancelar propuesta'**
  String get deal_detail_cancel_proposal_btn;

  /// No description provided for @deal_detail_cancelled_success.
  ///
  /// In es, this message translates to:
  /// **'Acuerdo cancelado correctamente'**
  String get deal_detail_cancelled_success;

  /// No description provided for @deal_detail_proposal_cancelled_success.
  ///
  /// In es, this message translates to:
  /// **'Propuesta cancelada correctamente'**
  String get deal_detail_proposal_cancelled_success;

  /// No description provided for @deal_detail_complete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Completar este trato?'**
  String get deal_detail_complete_confirm_title;

  /// No description provided for @deal_detail_complete_confirm_desc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.'**
  String get deal_detail_complete_confirm_desc;

  /// No description provided for @deal_detail_complete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get deal_detail_complete;

  /// No description provided for @deal_detail_completed.
  ///
  /// In es, this message translates to:
  /// **'Trato completado exitosamente'**
  String get deal_detail_completed;

  /// No description provided for @deal_detail_rating_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la calificación. Inténtalo de nuevo.'**
  String get deal_detail_rating_error;

  /// No description provided for @deal_detail_stars_required.
  ///
  /// In es, this message translates to:
  /// **'Selecciona de 1 a 5 estrellas'**
  String get deal_detail_stars_required;

  /// No description provided for @deal_detail_comment_optional.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get deal_detail_comment_optional;

  /// No description provided for @deal_detail_comment_hint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos cómo fue tu experiencia'**
  String get deal_detail_comment_hint;

  /// No description provided for @deal_detail_submit_rating.
  ///
  /// In es, this message translates to:
  /// **'Enviar calificación'**
  String get deal_detail_submit_rating;

  /// No description provided for @deal_detail_accept_terms_title.
  ///
  /// In es, this message translates to:
  /// **'Aceptar oferta y acordar trato'**
  String get deal_detail_accept_terms_title;

  /// No description provided for @deal_detail_accept_terms_desc.
  ///
  /// In es, this message translates to:
  /// **'Al formalizar el acuerdo, el inventario pactado se reservará en el sistema. Selecciona qué datos de contacto autorizas compartir con la contraparte para coordinar la entrega física:'**
  String get deal_detail_accept_terms_desc;

  /// No description provided for @deal_detail_share_phone.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi teléfono y WhatsApp'**
  String get deal_detail_share_phone;

  /// No description provided for @deal_detail_share_phone_desc.
  ///
  /// In es, this message translates to:
  /// **'Permite a la contraparte llamarte o escribirte por WhatsApp para coordinar.'**
  String get deal_detail_share_phone_desc;

  /// No description provided for @deal_detail_share_location.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi ubicación de entrega'**
  String get deal_detail_share_location;

  /// No description provided for @deal_detail_share_farm_location.
  ///
  /// In es, this message translates to:
  /// **'Compartir la ubicación de la finca'**
  String get deal_detail_share_farm_location;

  /// No description provided for @deal_detail_share_location_desc.
  ///
  /// In es, this message translates to:
  /// **'Permite ver el municipio y coordenadas para planificar la ruta de entrega.'**
  String get deal_detail_share_location_desc;

  /// No description provided for @deal_detail_confirm_agreement.
  ///
  /// In es, this message translates to:
  /// **'Confirmar acuerdo'**
  String get deal_detail_confirm_agreement;

  /// No description provided for @deal_detail_my_permissions_title.
  ///
  /// In es, this message translates to:
  /// **'Mis permisos de contacto'**
  String get deal_detail_my_permissions_title;

  /// No description provided for @deal_detail_my_permissions_desc.
  ///
  /// In es, this message translates to:
  /// **'Controla qué datos privados autorizas ver a la contraparte para coordinar este trato. Puedes revocar o conceder permisos en cualquier momento:'**
  String get deal_detail_my_permissions_desc;

  /// No description provided for @deal_detail_share_phone_desc_permission.
  ///
  /// In es, this message translates to:
  /// **'La contraparte podrá ver tu número para llamadas o mensajes.'**
  String get deal_detail_share_phone_desc_permission;

  /// No description provided for @deal_detail_share_location_desc_permission.
  ///
  /// In es, this message translates to:
  /// **'La contraparte podrá ver municipio y coordenadas para la logística.'**
  String get deal_detail_share_location_desc_permission;

  /// No description provided for @moderation_reject_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Solicitud'**
  String get moderation_reject_sheet_title;

  /// No description provided for @moderation_reject_reason_desc.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo del rechazo para que el usuario pueda corregirlo:'**
  String get moderation_reject_reason_desc;

  /// No description provided for @moderation_lbl_email.
  ///
  /// In es, this message translates to:
  /// **'Email:'**
  String get moderation_lbl_email;

  /// No description provided for @moderation_lbl_user_id.
  ///
  /// In es, this message translates to:
  /// **'User ID:'**
  String get moderation_lbl_user_id;

  /// No description provided for @moderation_queue_refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get moderation_queue_refresh;

  /// No description provided for @moderation_status_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get moderation_status_pending;

  /// No description provided for @moderation_status_approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get moderation_status_approved;

  /// No description provided for @moderation_status_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get moderation_status_rejected;

  /// No description provided for @moderation_status_suspended.
  ///
  /// In es, this message translates to:
  /// **'Suspendido'**
  String get moderation_status_suspended;

  /// No description provided for @moderation_status_unknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get moderation_status_unknown;

  /// No description provided for @profile_title.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get profile_title;

  /// No description provided for @profile_my_farm.
  ///
  /// In es, this message translates to:
  /// **'Mi Finca'**
  String get profile_my_farm;

  /// No description provided for @profile_settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profile_settings;

  /// No description provided for @profile_load_data_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los datos.'**
  String get profile_load_data_error;

  /// No description provided for @profile_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get profile_location;

  /// No description provided for @profile_whatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get profile_whatsapp;

  /// No description provided for @profile_stats_heading.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get profile_stats_heading;

  /// No description provided for @profile_published.
  ///
  /// In es, this message translates to:
  /// **'Publicados'**
  String get profile_published;

  /// No description provided for @profile_negotiating.
  ///
  /// In es, this message translates to:
  /// **'Negociando'**
  String get profile_negotiating;

  /// No description provided for @profile_closed_female.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get profile_closed_female;

  /// No description provided for @profile_closed_male.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get profile_closed_male;

  /// No description provided for @profile_update_error.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar dato: {error}'**
  String profile_update_error(String error);

  /// No description provided for @profile_photo_error.
  ///
  /// In es, this message translates to:
  /// **'Error al subir imagen: {error}'**
  String profile_photo_error(String error);

  /// No description provided for @profile_reputation_title.
  ///
  /// In es, this message translates to:
  /// **'Reputación'**
  String get profile_reputation_title;

  /// No description provided for @profile_reputation_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando reputación...'**
  String get profile_reputation_loading;

  /// No description provided for @profile_reputation_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la reputación.'**
  String get profile_reputation_error;

  /// No description provided for @purchases_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error: {error}'**
  String purchases_error_prefix(String error);

  /// No description provided for @purchases_merchant_role.
  ///
  /// In es, this message translates to:
  /// **'Rol Comerciante'**
  String get purchases_merchant_role;

  /// No description provided for @purchase_card_producer_local.
  ///
  /// In es, this message translates to:
  /// **'Productor local'**
  String get purchase_card_producer_local;

  /// No description provided for @purchase_card_producer_municipality.
  ///
  /// In es, this message translates to:
  /// **'Productor ({municipality})'**
  String purchase_card_producer_municipality(String municipality);

  /// No description provided for @purchase_card_agreed_crop.
  ///
  /// In es, this message translates to:
  /// **'Cosecha acordada'**
  String get purchase_card_agreed_crop;

  /// No description provided for @purchase_card_quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get purchase_card_quantity;

  /// No description provided for @purchase_card_price_per_kg.
  ///
  /// In es, this message translates to:
  /// **'Precio / kg'**
  String get purchase_card_price_per_kg;

  /// No description provided for @purchase_card_total_agreed.
  ///
  /// In es, this message translates to:
  /// **'Total pactado'**
  String get purchase_card_total_agreed;

  /// No description provided for @ai_close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get ai_close;

  /// No description provided for @ai_title.
  ///
  /// In es, this message translates to:
  /// **'Publicar por voz'**
  String get ai_title;

  /// No description provided for @ai_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué quieres vender. Revisarás todo antes de publicar.'**
  String get ai_subtitle;

  /// No description provided for @ai_examples_title.
  ///
  /// In es, this message translates to:
  /// **'Puedes mencionar:'**
  String get ai_examples_title;

  /// No description provided for @ai_examples_desc.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cultivo, cantidad y unidad (kg, bulto, arroba, canastilla, caja o tonelada), y precio por kg o por unidad.'**
  String get ai_examples_desc;

  /// No description provided for @ai_example_text.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: “Tengo 50 bultos de papa a 2.000 pesos el kilo”.'**
  String get ai_example_text;

  /// No description provided for @ai_unavailable_title.
  ///
  /// In es, this message translates to:
  /// **'La interpretación automática no está disponible en este entorno porque falta AI_API_KEY.'**
  String get ai_unavailable_title;

  /// No description provided for @ai_unavailable_desc.
  ///
  /// In es, this message translates to:
  /// **'Puedes dictar y revisar la transcripción, o continuar manualmente.'**
  String get ai_unavailable_desc;

  /// No description provided for @ai_preparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando el micrófono...'**
  String get ai_preparing;

  /// No description provided for @ai_permission_title.
  ///
  /// In es, this message translates to:
  /// **'Permiso de micrófono denegado'**
  String get ai_permission_title;

  /// No description provided for @ai_permission_desc.
  ///
  /// In es, this message translates to:
  /// **'No podemos acceder al micrófono. Habilita el permiso en los ajustes del sistema o continúa manualmente.'**
  String get ai_permission_desc;

  /// No description provided for @ai_voice_unavailable_title.
  ///
  /// In es, this message translates to:
  /// **'Reconocimiento de voz no disponible'**
  String get ai_voice_unavailable_title;

  /// No description provided for @ai_voice_unavailable_desc.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no ofrece el servicio de reconocimiento de voz que necesita la aplicación. Puedes publicar manualmente.'**
  String get ai_voice_unavailable_desc;

  /// No description provided for @ai_transcribing.
  ///
  /// In es, this message translates to:
  /// **'Transcribiendo lo que dijiste...'**
  String get ai_transcribing;

  /// No description provided for @ai_interpreting.
  ///
  /// In es, this message translates to:
  /// **'Interpretando los datos con IA...'**
  String get ai_interpreting;

  /// No description provided for @ai_intro.
  ///
  /// In es, this message translates to:
  /// **'Pulsa el micrófono y describe tu cosecha con tus propias palabras. No se publicará nada automáticamente.'**
  String get ai_intro;

  /// No description provided for @ai_start.
  ///
  /// In es, this message translates to:
  /// **'Comenzar a hablar'**
  String get ai_start;

  /// No description provided for @ai_manual.
  ///
  /// In es, this message translates to:
  /// **'Prefiero llenar el formulario manualmente'**
  String get ai_manual;

  /// No description provided for @ai_retry_mic.
  ///
  /// In es, this message translates to:
  /// **'Reintentar micrófono'**
  String get ai_retry_mic;

  /// No description provided for @ai_continue_manual.
  ///
  /// In es, this message translates to:
  /// **'Continuar manualmente'**
  String get ai_continue_manual;

  /// No description provided for @ai_listening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando...'**
  String get ai_listening;

  /// No description provided for @ai_listening_hint.
  ///
  /// In es, this message translates to:
  /// **'Habla ahora. Puedes detenerte cuando termines.'**
  String get ai_listening_hint;

  /// No description provided for @ai_stop_review.
  ///
  /// In es, this message translates to:
  /// **'Detener y revisar'**
  String get ai_stop_review;

  /// No description provided for @ai_review_transcript_title.
  ///
  /// In es, this message translates to:
  /// **'Revisa la transcripción'**
  String get ai_review_transcript_title;

  /// No description provided for @ai_review_transcript_desc.
  ///
  /// In es, this message translates to:
  /// **'Si el micrófono entendió mal alguna palabra, corrígela antes de interpretar los datos.'**
  String get ai_review_transcript_desc;

  /// No description provided for @ai_transcript_label.
  ///
  /// In es, this message translates to:
  /// **'Transcripción'**
  String get ai_transcript_label;

  /// No description provided for @ai_interpret.
  ///
  /// In es, this message translates to:
  /// **'Interpretar con IA'**
  String get ai_interpret;

  /// No description provided for @ai_record_again.
  ///
  /// In es, this message translates to:
  /// **'Grabar de nuevo'**
  String get ai_record_again;

  /// No description provided for @ai_recognized_title.
  ///
  /// In es, this message translates to:
  /// **'Datos reconocidos'**
  String get ai_recognized_title;

  /// No description provided for @ai_recognized_desc.
  ///
  /// In es, this message translates to:
  /// **'Estos datos se precargarán en el formulario. Todavía puedes corregirlos y debes completar lo que falte.'**
  String get ai_recognized_desc;

  /// No description provided for @ai_no_data_desc.
  ///
  /// In es, this message translates to:
  /// **'No se identificaron datos utilizables. Puedes reintentar la interpretación, grabar de nuevo o continuar manualmente.'**
  String get ai_no_data_desc;

  /// No description provided for @ai_warnings.
  ///
  /// In es, this message translates to:
  /// **'Advertencias'**
  String get ai_warnings;

  /// No description provided for @ai_confirm_data.
  ///
  /// In es, this message translates to:
  /// **'Confirma estos datos'**
  String get ai_confirm_data;

  /// No description provided for @ai_missing_data.
  ///
  /// In es, this message translates to:
  /// **'Faltan datos por completar'**
  String get ai_missing_data;

  /// No description provided for @ai_review_continue.
  ///
  /// In es, this message translates to:
  /// **'Revisar y continuar'**
  String get ai_review_continue;

  /// No description provided for @ai_retry_interpret.
  ///
  /// In es, this message translates to:
  /// **'Reintentar interpretación'**
  String get ai_retry_interpret;

  /// No description provided for @ai_crop.
  ///
  /// In es, this message translates to:
  /// **'Cultivo'**
  String get ai_crop;

  /// No description provided for @ai_quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get ai_quantity;

  /// No description provided for @ai_price.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get ai_price;

  /// No description provided for @ai_note.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get ai_note;

  /// No description provided for @ai_no_data.
  ///
  /// In es, this message translates to:
  /// **'Sin datos identificados.'**
  String get ai_no_data;

  /// No description provided for @ai_failed_title.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar'**
  String get ai_failed_title;

  /// No description provided for @ai_failed_desc.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema. Intenta de nuevo o continúa manualmente.'**
  String get ai_failed_desc;

  /// No description provided for @ai_error_mic_start.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el micrófono. Comprueba el permiso o continúa manualmente.'**
  String get ai_error_mic_start;

  /// No description provided for @ai_error_mic_stop.
  ///
  /// In es, this message translates to:
  /// **'No se pudo detener el reconocimiento de voz. Vuelve a intentarlo o continúa manualmente.'**
  String get ai_error_mic_stop;

  /// No description provided for @ai_error_no_speech.
  ///
  /// In es, this message translates to:
  /// **'No se reconoció voz. Acércate al micrófono, intenta de nuevo o continúa manualmente.'**
  String get ai_error_no_speech;

  /// No description provided for @ai_error_no_speech_retry.
  ///
  /// In es, this message translates to:
  /// **'No se reconoció voz. Intenta hablar más cerca del micrófono o continúa manualmente.'**
  String get ai_error_no_speech_retry;

  /// No description provided for @ai_error_empty_transcript.
  ///
  /// In es, this message translates to:
  /// **'La transcripción está vacía. Graba de nuevo o escribe lo que deseas publicar.'**
  String get ai_error_empty_transcript;

  /// No description provided for @ai_error_not_configured.
  ///
  /// In es, this message translates to:
  /// **'La interpretación con IA no está configurada. Falta AI_API_KEY. Puedes continuar manualmente.'**
  String get ai_error_not_configured;

  /// No description provided for @ai_error_interpret.
  ///
  /// In es, this message translates to:
  /// **'No se pudo interpretar la transcripción. Intenta de nuevo o continúa manualmente.'**
  String get ai_error_interpret;

  /// No description provided for @app_title.
  ///
  /// In es, this message translates to:
  /// **'KUS'**
  String get app_title;

  /// No description provided for @brand_name.
  ///
  /// In es, this message translates to:
  /// **'KUS'**
  String get brand_name;

  /// No description provided for @brand_tagline.
  ///
  /// In es, this message translates to:
  /// **'KUMPA SUMAQ'**
  String get brand_tagline;

  /// No description provided for @brand_slogan.
  ///
  /// In es, this message translates to:
  /// **'KumpaSumaq • Comercio agrícola directo'**
  String get brand_slogan;

  /// No description provided for @brand_logo_semantics.
  ///
  /// In es, this message translates to:
  /// **'Logotipo de KUS'**
  String get brand_logo_semantics;

  /// No description provided for @profitability_reference_notice.
  ///
  /// In es, this message translates to:
  /// **'Índice de referencia regional (Nariño) • Proyección de mercado KUS AI.'**
  String get profitability_reference_notice;

  /// No description provided for @loading_skeleton_semantics.
  ///
  /// In es, this message translates to:
  /// **'Cargando contenido'**
  String get loading_skeleton_semantics;

  /// No description provided for @user_avatar_semantics.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get user_avatar_semantics;

  /// No description provided for @product_card_image_unavailable.
  ///
  /// In es, this message translates to:
  /// **'Imagen no disponible'**
  String get product_card_image_unavailable;

  /// No description provided for @registration_step_counter.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String registration_step_counter(int current, int total);

  /// No description provided for @common_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get common_continue;

  /// No description provided for @auth_remember_me_semantics.
  ///
  /// In es, this message translates to:
  /// **'Recordar mi sesión en este dispositivo'**
  String get auth_remember_me_semantics;

  /// No description provided for @capture_scan_button.
  ///
  /// In es, this message translates to:
  /// **'Escanear documento'**
  String get capture_scan_button;

  /// No description provided for @capture_retake.
  ///
  /// In es, this message translates to:
  /// **'Volver a tomar'**
  String get capture_retake;

  /// No description provided for @capture_document_captured.
  ///
  /// In es, this message translates to:
  /// **'Documento capturado'**
  String get capture_document_captured;

  /// No description provided for @capture_front_guide_chip.
  ///
  /// In es, this message translates to:
  /// **'Encuadra el frente'**
  String get capture_front_guide_chip;

  /// No description provided for @capture_back_guide_chip.
  ///
  /// In es, this message translates to:
  /// **'Encuadra el reverso'**
  String get capture_back_guide_chip;

  /// No description provided for @capture_guide_semantics.
  ///
  /// In es, this message translates to:
  /// **'Guía de encuadre del documento'**
  String get capture_guide_semantics;

  /// No description provided for @facial_verification_guide_chip.
  ///
  /// In es, this message translates to:
  /// **'Centra tu rostro'**
  String get facial_verification_guide_chip;

  /// No description provided for @facial_verification_captured.
  ///
  /// In es, this message translates to:
  /// **'Selfie capturada'**
  String get facial_verification_captured;

  /// No description provided for @facial_verification_capture_button.
  ///
  /// In es, this message translates to:
  /// **'Tomar selfie'**
  String get facial_verification_capture_button;

  /// No description provided for @verification_status_track_received.
  ///
  /// In es, this message translates to:
  /// **'Solicitud recibida'**
  String get verification_status_track_received;

  /// No description provided for @verification_status_track_ai.
  ///
  /// In es, this message translates to:
  /// **'Validación biométrica y documental'**
  String get verification_status_track_ai;

  /// No description provided for @verification_status_track_moderator.
  ///
  /// In es, this message translates to:
  /// **'Decisión del moderador'**
  String get verification_status_track_moderator;

  /// No description provided for @verification_status_reason_label.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get verification_status_reason_label;

  /// No description provided for @verification_status_resubmit.
  ///
  /// In es, this message translates to:
  /// **'Corregir y reenviar documentos'**
  String get verification_status_resubmit;

  /// No description provided for @moderation_queue_count.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin solicitudes} =1{1 solicitud} other{{count} solicitudes}}'**
  String moderation_queue_count(int count);

  /// No description provided for @moderation_diagnosis_files_independent.
  ///
  /// In es, this message translates to:
  /// **'Archivos independientes'**
  String get moderation_diagnosis_files_independent;

  /// No description provided for @moderation_diagnosis_contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto del perfil'**
  String get moderation_diagnosis_contact;

  /// No description provided for @moderation_diagnosis_legibility.
  ///
  /// In es, this message translates to:
  /// **'Legibilidad y rostro'**
  String get moderation_diagnosis_legibility;

  /// No description provided for @moderation_diagnosis_value_verified.
  ///
  /// In es, this message translates to:
  /// **'Verificado'**
  String get moderation_diagnosis_value_verified;

  /// No description provided for @moderation_diagnosis_value_review.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get moderation_diagnosis_value_review;

  /// No description provided for @moderation_diagnosis_value_email.
  ///
  /// In es, this message translates to:
  /// **'Correo registrado'**
  String get moderation_diagnosis_value_email;

  /// No description provided for @moderation_diagnosis_value_no_email.
  ///
  /// In es, this message translates to:
  /// **'Sin correo'**
  String get moderation_diagnosis_value_no_email;

  /// No description provided for @moderation_diagnosis_value_visual.
  ///
  /// In es, this message translates to:
  /// **'Revisión visual'**
  String get moderation_diagnosis_value_visual;

  /// No description provided for @moderation_diagnosis_decision_title.
  ///
  /// In es, this message translates to:
  /// **'Tu dictamen'**
  String get moderation_diagnosis_decision_title;

  /// No description provided for @moderation_doc_view_semantics.
  ///
  /// In es, this message translates to:
  /// **'Ampliar documento'**
  String get moderation_doc_view_semantics;

  /// No description provided for @market_buyer_lot_count.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin cosechas disponibles} =1{1 cosecha disponible} other{{count} cosechas disponibles}}'**
  String market_buyer_lot_count(int count);

  /// No description provided for @market_farmer_lot_count.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin publicaciones} =1{1 publicación} other{{count} publicaciones}}'**
  String market_farmer_lot_count(int count);

  /// No description provided for @market_voice_quick_action.
  ///
  /// In es, this message translates to:
  /// **'Publicar con asistente de voz'**
  String get market_voice_quick_action;

  /// No description provided for @market_no_results_desc.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro cultivo o vuelve al orden predeterminado.'**
  String get market_no_results_desc;

  /// No description provided for @crop_detail_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get crop_detail_description;

  /// No description provided for @crop_detail_equivalences_pill.
  ///
  /// In es, this message translates to:
  /// **'Ver en canastillas y bultos'**
  String get crop_detail_equivalences_pill;

  /// No description provided for @crop_detail_regional_index_title.
  ///
  /// In es, this message translates to:
  /// **'Índice Regional Nariño • KUS AI'**
  String get crop_detail_regional_index_title;

  /// No description provided for @units_kg_baseline_note.
  ///
  /// In es, this message translates to:
  /// **'La negociación siempre se pacta en kilogramos.'**
  String get units_kg_baseline_note;

  /// No description provided for @offer_sheet_delivery_point.
  ///
  /// In es, this message translates to:
  /// **'Punto acordado'**
  String get offer_sheet_delivery_point;

  /// No description provided for @offer_sheet_delivery_carrier.
  ///
  /// In es, this message translates to:
  /// **'Transportadora'**
  String get offer_sheet_delivery_carrier;

  /// No description provided for @offer_sheet_total_breakdown.
  ///
  /// In es, this message translates to:
  /// **'{quantity} × {price} por kg'**
  String offer_sheet_total_breakdown(String quantity, String price);

  /// No description provided for @ai_field_identified.
  ///
  /// In es, this message translates to:
  /// **'Identificado'**
  String get ai_field_identified;

  /// No description provided for @ai_field_review.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get ai_field_review;

  /// No description provided for @costs_expenses_title.
  ///
  /// In es, this message translates to:
  /// **'Gastos registrados'**
  String get costs_expenses_title;

  /// No description provided for @deals_tab_in_progress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get deals_tab_in_progress;

  /// No description provided for @deals_awaiting_you.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 trato espera tu respuesta} other{{count} tratos esperan tu respuesta}}'**
  String deals_awaiting_you(int count);

  /// No description provided for @deals_total_count.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin tratos} =1{1 trato} other{{count} tratos}}'**
  String deals_total_count(int count);

  /// No description provided for @deals_filter_empty.
  ///
  /// In es, this message translates to:
  /// **'No hay tratos en esta vista'**
  String get deals_filter_empty;

  /// No description provided for @deals_filter_empty_desc.
  ///
  /// In es, this message translates to:
  /// **'Cambia de sección para ver el resto de tus negociaciones.'**
  String get deals_filter_empty_desc;

  /// No description provided for @deal_detail_total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get deal_detail_total;

  /// No description provided for @deal_detail_vs_previous.
  ///
  /// In es, this message translates to:
  /// **'{amount} vs. oferta anterior'**
  String deal_detail_vs_previous(String amount);

  /// No description provided for @deal_detail_same_price.
  ///
  /// In es, this message translates to:
  /// **'Mismo precio que la oferta anterior'**
  String get deal_detail_same_price;

  /// No description provided for @deal_detail_your_turn_bar.
  ///
  /// In es, this message translates to:
  /// **'Es tu turno de responder'**
  String get deal_detail_your_turn_bar;

  /// No description provided for @deal_detail_contact_released.
  ///
  /// In es, this message translates to:
  /// **'Contacto comercial liberado'**
  String get deal_detail_contact_released;

  /// No description provided for @deal_detail_privacy_note.
  ///
  /// In es, this message translates to:
  /// **'Tú decides qué datos ve la contraparte. Puedes cambiarlo en cualquier momento.'**
  String get deal_detail_privacy_note;

  /// No description provided for @deal_rating_label_1.
  ///
  /// In es, this message translates to:
  /// **'Muy mala'**
  String get deal_rating_label_1;

  /// No description provided for @deal_rating_label_2.
  ///
  /// In es, this message translates to:
  /// **'Mala'**
  String get deal_rating_label_2;

  /// No description provided for @deal_rating_label_3.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get deal_rating_label_3;

  /// No description provided for @deal_rating_label_4.
  ///
  /// In es, this message translates to:
  /// **'Buena'**
  String get deal_rating_label_4;

  /// No description provided for @deal_rating_label_5.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get deal_rating_label_5;

  /// No description provided for @counter_offer_current_offer.
  ///
  /// In es, this message translates to:
  /// **'Oferta vigente'**
  String get counter_offer_current_offer;

  /// No description provided for @counter_offer_vs_current.
  ///
  /// In es, this message translates to:
  /// **'{amount} vs. oferta vigente'**
  String counter_offer_vs_current(String amount);

  /// No description provided for @purchases_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Acuerdos con productores verificados'**
  String get purchases_subtitle;

  /// No description provided for @purchases_total_caption.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{En 1 compra} other{En {count} compras}}'**
  String purchases_total_caption(int count);

  /// No description provided for @purchases_filter_empty.
  ///
  /// In es, this message translates to:
  /// **'No hay compras en esta vista'**
  String get purchases_filter_empty;

  /// No description provided for @profile_verified_badge.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada'**
  String get profile_verified_badge;

  /// No description provided for @profile_contact_autosave.
  ///
  /// In es, this message translates to:
  /// **'Los cambios se guardan al salir del campo.'**
  String get profile_contact_autosave;

  /// No description provided for @profile_appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get profile_appearance;

  /// No description provided for @profile_theme_light.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get profile_theme_light;

  /// No description provided for @profile_theme_dark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get profile_theme_dark;

  /// No description provided for @profile_language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profile_language;

  /// No description provided for @profile_language_es.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get profile_language_es;

  /// No description provided for @profile_language_en.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get profile_language_en;

  /// No description provided for @profile_change_photo.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get profile_change_photo;

  /// No description provided for @verification_status_support_line.
  ///
  /// In es, this message translates to:
  /// **'Validación biométrica y documental en curso — Te avisaremos en cuanto la decisión esté lista.'**
  String get verification_status_support_line;

  /// No description provided for @verification_status_track_current.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get verification_status_track_current;

  /// No description provided for @verification_status_ring_semantics.
  ///
  /// In es, this message translates to:
  /// **'Progreso de la revisión. Etapa actual: {stage}'**
  String verification_status_ring_semantics(String stage);

  /// No description provided for @verification_status_rejected_empathy.
  ///
  /// In es, this message translates to:
  /// **'No te preocupes: puedes corregir los documentos señalados y enviarlos de nuevo. Tu solicitud volverá a revisión en cuanto los recibamos.'**
  String get verification_status_rejected_empathy;
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
