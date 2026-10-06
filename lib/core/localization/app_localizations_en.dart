// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome_title => 'Welcome';

  @override
  String get welcome_description =>
      'Connect directly with producers and buyers to trade agricultural products easily, securely, and transparently.';

  @override
  String get welcome_continue => 'Continue';

  @override
  String get personal_info_title => 'Personal information';

  @override
  String get personal_info_phone => 'Phone number';

  @override
  String get personal_info_first_name => 'First name';

  @override
  String get personal_info_last_name => 'Last name';

  @override
  String get personal_info_verification_description =>
      'We\'ll send a 6-digit verification code to confirm your number on the next step.';

  @override
  String get personal_info_active => 'Active';

  @override
  String get personal_info_required => 'Required';

  @override
  String get personal_info_phone_hint => '(555) 000-0000';

  @override
  String get personal_info_first_name_hint => 'e.g. John';

  @override
  String get personal_info_last_name_hint => 'e.g. Appleseed';

  @override
  String get role_selection_header_title => 'Account Credentials';

  @override
  String get role_selection_title =>
      'Choose the role that best describes your activity on the platform.';

  @override
  String get role_selection_producer => 'Producer';

  @override
  String get role_selection_producer_subtitle => 'Sell & distribute';

  @override
  String get role_selection_producer_description =>
      'Direct marketplace listing & analytics';

  @override
  String get role_selection_buyer => 'Buyer';

  @override
  String get role_selection_buyer_subtitle => 'Source & purchase';

  @override
  String get role_selection_buyer_description =>
      'Transparent logistics & batch provenance';

  @override
  String get role_selection_kyc_notice =>
      'KYC Verification applies after role selection';

  @override
  String get role_selection_error_no_role => 'Please select a role';

  @override
  String get document_selection_header_title => 'Verification Code';

  @override
  String get document_selection_title => 'Document Verification';

  @override
  String get document_selection_description =>
      'We need to confirm your legal identity before activating your account.';

  @override
  String get document_selection_select_id => 'SELECT YOUR ID TYPE';

  @override
  String get document_selection_cc => 'CC';

  @override
  String get document_selection_cc_desc => 'Cédula de Ciudadanía / National ID';

  @override
  String get document_selection_driver_license => 'Driver\'s License';

  @override
  String get document_selection_driver_license_desc =>
      'Official state or national driving permit';

  @override
  String get document_selection_encryption_notice =>
      '256-bit encrypted identity verification';

  @override
  String get document_selection_error_no_doc => 'Please select a document type';

  @override
  String get capture_front_header_title => 'Verification Code';

  @override
  String get capture_front_title => 'Capture Front Side';

  @override
  String get capture_front_description =>
      'Position the front side of your document within the frame. Ensure good lighting and that all text is clearly readable.';

  @override
  String get capture_front_identity_verification => 'Identity Verification';

  @override
  String get capture_front_aligning => 'Hold still — aligning document...';

  @override
  String get capture_front_auto_capture => 'Auto-capture ready';

  @override
  String get capture_front_tip_light => 'Good light';

  @override
  String get capture_front_tip_fit => 'Fit frame';

  @override
  String get capture_front_tip_glare => 'No glare';

  @override
  String get capture_front_tap_to_capture => 'Tap button below to capture';

  @override
  String get capture_back_header_title => 'Verification Code';

  @override
  String get capture_back_title => 'Capture Back Side';

  @override
  String get capture_back_description =>
      'Now flip your document and position the back side within the frame. Make sure the magnetic stripe or barcode is fully visible.';

  @override
  String get capture_back_steady => 'Back side detected — hold steady';

  @override
  String get capture_back_tip_light => 'Good light';

  @override
  String get capture_back_tip_fit => 'Fit frame';

  @override
  String get capture_back_tip_barcode => 'Barcode clear';

  @override
  String get capture_back_tap_to_capture => 'Tap button below to capture';

  @override
  String get facial_verification_header_title => 'Verification Code';

  @override
  String get facial_verification_title => 'Facial Verification';

  @override
  String get facial_verification_description =>
      'Center your face within the guide. Blink gently and hold still in balanced natural light.';

  @override
  String get facial_verification_face_detected =>
      'Face detected • Perfect match';

  @override
  String get facial_verification_liveness => 'Live Liveness Detection Active';

  @override
  String get facial_verification_tip_light => 'Good light';

  @override
  String get facial_verification_tip_glasses => 'No glasses';

  @override
  String get facial_verification_tip_straight => 'Look straight';

  @override
  String get facial_verification_encryption_notice =>
      'Biometric data is 256-bit encrypted and never shared.';

  @override
  String get processing_missing_data =>
      'Missing required data for registration.';

  @override
  String get processing_creating_user => 'Creating user...';

  @override
  String get processing_success => 'Registration completed successfully!';

  @override
  String get processing_error_prefix => 'An error occurred:\n';

  @override
  String get processing_default_message => 'Processing your information...';

  @override
  String get processing_retry => 'Retry';

  @override
  String get processing_retrying => 'Retrying...';

  @override
  String get processing_back => 'Go back';

  @override
  String get login_title => 'Sign in';

  @override
  String get login_phone => 'Phone';

  @override
  String get login_phone_hint => 'demo@email.com';

  @override
  String get login_password => 'Password';

  @override
  String get login_password_hint => '••••••••••••';

  @override
  String get login_remember_me => 'Remember Me';

  @override
  String get login_forgot_password => 'Forgot Password?';

  @override
  String get login_login_button => 'Sign in';

  @override
  String get login_no_account => 'Don\'t have an Account ? ';

  @override
  String get login_register => 'Sign up';

  @override
  String get login_required => 'Required';

  @override
  String get verification_status_checking => 'Checking status...';

  @override
  String get verification_status_error_title => 'An error occurred';

  @override
  String get verification_status_retry => 'Retry';

  @override
  String get verification_status_pending_title => 'Pending Documents';

  @override
  String get verification_status_pending_desc =>
      'You have completed the initial registration via phone number. You still need to submit your documents to verify your identity and access all features.';

  @override
  String get verification_status_review_title => 'Under Review';

  @override
  String get verification_status_review_desc =>
      'Your documents have been submitted and are being validated by our system and moderation team. You cannot modify your documents while they are under review.';

  @override
  String get verification_status_approved_title => 'Verification Approved';

  @override
  String get verification_status_approved_desc =>
      'The moderator successfully validated your identity. Your profile appears as verified and you have access to the features corresponding to your role.';

  @override
  String get verification_status_rejected_title => 'Verification Rejected';

  @override
  String get verification_status_rejected_desc =>
      'The verification was not approved due to inconsistencies in the documentation. Please correct the information and try again.';

  @override
  String get verification_status_suspended_title => 'Account Suspended';

  @override
  String get verification_status_suspended_desc =>
      'Your account has been temporarily suspended by an administrative action. Commercial features are restricted.';

  @override
  String get verification_status_unknown_title => 'Unknown Status';

  @override
  String get verification_status_unknown_desc =>
      'We could not determine the verification status. Please contact support.';

  @override
  String get verification_status_success_msg =>
      'Your registration was successful and we are reviewing your information...';

  @override
  String get verification_status_upload_docs => 'Upload Documents';

  @override
  String get verification_status_enter_app => 'Enter application';

  @override
  String get verification_status_update_status => 'Update status';

  @override
  String get verification_status_default_reject_reason =>
      'The verification was not approved due to inconsistencies in the documentation. Please correct the information and try again.';

  @override
  String get otp_verification_title => 'Enter Your code';

  @override
  String get otp_verification_subtitle =>
      'A 6 digit code has been sent to your cell phone.';

  @override
  String get otp_verification_didnt_receive => 'Didn\'t receive the code? ';

  @override
  String get otp_verification_resend => 'Resend.';

  @override
  String get otp_verification_appbar_title => 'SMS Verification';
}
