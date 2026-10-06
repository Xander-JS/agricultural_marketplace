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
  /// **'Posiciona la parte frontal de tu documento dentro del marco. Asegúrate de tener buena iluminación y que todo el texto sea legible.'**
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
  /// **'Ahora voltea tu documento y posiciona la parte trasera dentro del marco. Asegúrate de que la banda magnética o código de barras sea completamente visible.'**
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
  /// **'Código claro'**
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
  /// **'Centra tu rostro dentro de la guía. Parpadea suavemente y mantente quieto con luz natural equilibrada.'**
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
