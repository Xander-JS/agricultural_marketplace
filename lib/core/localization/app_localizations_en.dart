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
      'Position the front side of your document within the frame.';

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
      'Turn your document and position the back side within the frame.';

  @override
  String get capture_back_steady => 'Back side detected — hold steady';

  @override
  String get capture_back_tip_light => 'Good light';

  @override
  String get capture_back_tip_fit => 'Fit frame';

  @override
  String get capture_back_tip_barcode => 'clear code';

  @override
  String get capture_back_tap_to_capture => 'Tap button below to capture';

  @override
  String get facial_verification_header_title => 'Verification Code';

  @override
  String get facial_verification_title => 'Facial Verification';

  @override
  String get facial_verification_description =>
      'We need to take a scan of your face to verify that you are a real person.';

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
  String get facial_verification_start_button => 'Start';

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

  @override
  String get nav_market => 'Market';

  @override
  String get nav_my_market => 'My Market';

  @override
  String get nav_deals => 'Deals';

  @override
  String get nav_costs => 'Costs';

  @override
  String get nav_purchases => 'Purchases';

  @override
  String get nav_my_farm => 'My Farm';

  @override
  String get purchases_title => 'Purchases';

  @override
  String get purchases_placeholder_title => 'Purchases Module';

  @override
  String get purchases_placeholder_desc =>
      'Here you can check your agreed purchases and completed transaction history.';

  @override
  String get profile_title_farmer => 'My Farm';

  @override
  String get profile_title_buyer => 'My Profile';

  @override
  String get profile_stats_title => 'Statistics';

  @override
  String get profile_stat_published => 'Published';

  @override
  String get profile_stat_negotiating => 'Negotiating';

  @override
  String get profile_stat_closed_farmer => 'Closed';

  @override
  String get profile_stat_closed_buyer => 'Closed';

  @override
  String get profile_settings_title => 'Settings';

  @override
  String get profile_contact_info => 'Contact Information';

  @override
  String get profile_email => 'Email';

  @override
  String get profile_phone => 'Phone Number';

  @override
  String get profile_negotiation_options => 'Negotiation Options';

  @override
  String get profile_enable_early_sale => 'Enable Pre-Sale';

  @override
  String get profile_visibility_negotiation => 'Visibility during negotiation';

  @override
  String get profile_visibility_phone => 'Phone';

  @override
  String get profile_visibility_location => 'Location';

  @override
  String get profile_visibility_whatsapp => 'WhatsApp';

  @override
  String get profile_accessibility => 'Accessibility';

  @override
  String get profile_dark_mode => 'Dark Mode';

  @override
  String get profile_english_language => 'English Language';

  @override
  String get profile_logout => 'Log Out';

  @override
  String get profile_logout_confirm_title => 'Log Out?';

  @override
  String get profile_logout_confirm_desc =>
      'Are you sure you want to log out of your account?';

  @override
  String get profile_cancel => 'Cancel';

  @override
  String get profile_updated_photo => 'Profile picture updated';

  @override
  String get profile_save_settings_error => 'Error saving settings';

  @override
  String get profile_load_error => 'Error loading profile';

  @override
  String get profile_no_data => 'Could not load data.';

  @override
  String get market_title => 'Market';

  @override
  String get market_title_farmer => 'My Market';

  @override
  String get market_publish_btn => 'Publish';

  @override
  String get market_empty_farmer_title => 'You have no published crops yet';

  @override
  String get market_empty_farmer_desc =>
      'Start offering your products in the agricultural marketplace by creating your first post.';

  @override
  String get market_publish_first => 'Publish my first crop';

  @override
  String get market_empty_buyer_title => 'No crops available';

  @override
  String get market_empty_buyer_desc =>
      'Currently there are no agricultural products available for negotiation. Try refreshing later.';

  @override
  String get market_retry => 'Retry';

  @override
  String get market_refresh => 'Refresh';

  @override
  String get market_publish_options_title => 'How do you want to publish?';

  @override
  String get market_publish_manual => 'Manual Publication';

  @override
  String get market_publish_manual_desc => 'Fill in the form step by step';

  @override
  String get market_publish_voice => 'Voice Note Publication';

  @override
  String get market_publish_voice_desc =>
      'Tell us what you want to publish (AI Powered)';

  @override
  String get market_ai_coming_soon => 'AI feature coming soon...';

  @override
  String get crop_card_available => 'Available';

  @override
  String get crop_card_price_per_kg => 'Price / kg';

  @override
  String get crop_detail_title => 'Crop Details';

  @override
  String get crop_detail_delete_tooltip => 'Delete';

  @override
  String get crop_detail_edit_tooltip => 'Edit';

  @override
  String get crop_detail_confirm_delete_title => 'Delete Crop';

  @override
  String get crop_detail_confirm_delete_desc =>
      'Are you sure you want to delete this publication? This action cannot be undone.';

  @override
  String get crop_detail_delete_success => 'Publication deleted successfully';

  @override
  String get crop_detail_delete_error => 'Error deleting publication';

  @override
  String get crop_detail_status_updated => 'Status updated';

  @override
  String get crop_detail_price_per_kg => 'Price per kg';

  @override
  String get crop_detail_available_stock => 'Total Available';

  @override
  String get crop_detail_view_equivalences => 'View equivalences';

  @override
  String get crop_detail_min_order => 'Minimum Order';

  @override
  String get crop_detail_location => 'Location';

  @override
  String get crop_detail_publication_date => 'Publication date';

  @override
  String get crop_detail_early_sale => 'Pre-Sale';

  @override
  String get crop_detail_estimated_harvest => 'Est. harvest date';

  @override
  String get crop_detail_estimated_yield => 'Estimated yield';

  @override
  String get crop_detail_quick_actions => 'Quick Actions';

  @override
  String get crop_detail_pause_crop => 'Pause Publication';

  @override
  String get crop_detail_activate_crop => 'Activate Publication';

  @override
  String get crop_detail_view_negotiations => 'View Negotiations';

  @override
  String get crop_detail_negotiations_coming_soon =>
      'Coming soon: View negotiations';

  @override
  String get crop_detail_make_offer => 'Make offer / Negotiate';

  @override
  String get crop_detail_farmer_info => 'Farmer Information';

  @override
  String get crop_detail_producer => 'Producer';

  @override
  String get crop_detail_contact => 'Contact';

  @override
  String get offer_sheet_title => 'New Offer';

  @override
  String get offer_sheet_subtitle =>
      'Start a negotiation proposal for this crop';

  @override
  String get offer_sheet_quantity_label => 'Quantity (kg)';

  @override
  String get offer_sheet_price_label => 'Proposed price per kg';

  @override
  String get offer_sheet_delivery_label => 'Delivery method';

  @override
  String get offer_sheet_delivery_farm => 'On farm';

  @override
  String get offer_sheet_delivery_hub => 'Collection point';

  @override
  String get offer_sheet_delivery_destination => 'Final destination';

  @override
  String get offer_sheet_delivery_agree => 'Agree with producer';

  @override
  String get offer_sheet_message_label => 'Message for producer (Optional)';

  @override
  String get offer_sheet_message_hint =>
      'Explain details of your proposal or delivery requirements';

  @override
  String get offer_sheet_estimated_total => 'Estimated total';

  @override
  String get offer_sheet_submit_btn => 'Send proposal';

  @override
  String get offer_sheet_submitting => 'Sending...';

  @override
  String get offer_sheet_success => 'Proposal sent successfully';

  @override
  String get offer_sheet_existing_negotiation =>
      'You already have an active negotiation for this crop';

  @override
  String get offer_sheet_val_required => 'Required field';

  @override
  String get offer_sheet_val_positive => 'Must be greater than 0';

  @override
  String get offer_sheet_val_min_order =>
      'Quantity does not meet minimum order required';

  @override
  String get offer_sheet_val_max_stock => 'Quantity exceeds available stock';

  @override
  String get deals_title => 'Deals';

  @override
  String get deals_tab_all => 'All';

  @override
  String get deals_tab_pending => 'Pending';

  @override
  String get deals_tab_in_negotiation => 'Negotiating';

  @override
  String get deals_tab_agreed => 'Agreed';

  @override
  String get deals_tab_history => 'History';

  @override
  String get deals_your_turn => 'Your turn';

  @override
  String get deals_waiting_response => 'Waiting for response';

  @override
  String get deals_see_deal => 'View deal →';

  @override
  String get deals_empty_farmer_title => 'You have no deals yet';

  @override
  String get deals_empty_farmer_desc =>
      'When a buyer makes an offer on one of your crops, it will appear here.';

  @override
  String get deals_empty_buyer_title => 'You have no deals yet';

  @override
  String get deals_empty_buyer_desc =>
      'When you make an offer on the marketplace for a crop, you can track and negotiate it here.';

  @override
  String get deals_explore_market => 'Explore market';

  @override
  String get deals_view_crops => 'View my crops';

  @override
  String get deal_detail_title => 'Deal Details';

  @override
  String get deal_counterpart_buyer => 'Buyer';

  @override
  String get deal_counterpart_farmer => 'Producer';

  @override
  String get deal_history_title => 'Offer History';

  @override
  String get deal_waiting_buyer => 'Waiting for buyer response';

  @override
  String get deal_waiting_farmer => 'Waiting for producer response';

  @override
  String get deal_accept_offer => 'Accept offer';

  @override
  String get deal_counter_offer => 'Counteroffer';

  @override
  String get deal_reject_deal => 'Reject deal';

  @override
  String get deal_cancel_deal => 'Cancel proposal';

  @override
  String get deal_accept_success => 'Deal agreed successfully';

  @override
  String get deal_reject_success => 'The deal has been rejected';

  @override
  String get deal_reject_confirm_title => 'Reject this deal?';

  @override
  String get deal_reject_confirm_desc =>
      'This action cannot be undone and the deal will be closed.';

  @override
  String get counter_offer_title => 'Counteroffer';

  @override
  String get counter_offer_subtitle =>
      'Modify the terms of the offer for the selected crop.';

  @override
  String get counter_offer_quantity_label => 'Quantity (kg)';

  @override
  String get counter_offer_price_label => 'Proposed price per kg';

  @override
  String get counter_offer_delivery_label => 'Delivery method';

  @override
  String get counter_offer_message_label => 'Message (Optional)';

  @override
  String get counter_offer_message_hint =>
      'Explain the reason for your counteroffer';

  @override
  String get counter_offer_send_btn => 'Send counteroffer';

  @override
  String get counter_offer_success => 'Counteroffer sent successfully';

  @override
  String get purchases_tab_all => 'All';

  @override
  String get purchases_tab_agreed => 'Agreed';

  @override
  String get purchases_tab_completed => 'Completed';

  @override
  String get purchases_empty_title => 'No purchases yet';

  @override
  String get purchases_empty_desc =>
      'Here you will see deals you have agreed on with farmers and your completed purchase history.';

  @override
  String get purchases_empty_action => 'Explore market';

  @override
  String get purchases_total_agreed => 'Active deals';

  @override
  String get purchases_total_invested => 'Total agreed';

  @override
  String get purchases_total_volume => 'Total volume';

  @override
  String get purchases_view_detail => 'View deal details →';

  @override
  String get purchases_delivery_method => 'Delivery';

  @override
  String get purchases_status_agreed => 'Agreed';

  @override
  String get purchases_status_completed => 'Completed';

  @override
  String get deal_agreed_desc =>
      'Deal agreed. Coordinate physical delivery to complete the transaction.';

  @override
  String get deal_complete_btn => 'Confirm delivery and complete deal';

  @override
  String get deal_cancel_agreed => 'Cancel agreement';

  @override
  String get deal_complete_confirm_title => 'Complete this deal?';

  @override
  String get deal_complete_confirm_desc =>
      'This action will confirm physical product delivery and record the final sale in inventory.';

  @override
  String get deal_complete_confirm_btn => 'Complete';

  @override
  String get deal_completed_success => 'Deal completed successfully';

  @override
  String get deal_detail_error => 'An error occurred';

  @override
  String get deal_detail_not_found => 'Deal not found.';

  @override
  String get deal_detail_quantity => 'Quantity';

  @override
  String get deal_detail_price_per_kg => 'Price per kg';

  @override
  String get deal_detail_delivery_method => 'Delivery method';

  @override
  String get deal_detail_status => 'Status';

  @override
  String get deal_detail_rate_coming_soon =>
      'Deal reviews will be available soon.';

  @override
  String get deal_detail_rate_farmer => 'Rate farmer';

  @override
  String get deal_detail_rate_buyer => 'Rate buyer';

  @override
  String get deal_detail_proposal_cancelled => 'Proposal cancelled';

  @override
  String get deals_unknown_crop => 'Unknown crop';

  @override
  String get deals_counterpart_producer => 'Producer';

  @override
  String get deals_counterpart_buyer_label => 'Buyer';

  @override
  String get deals_status_pending => 'Pending';

  @override
  String get deals_status_counteroffer => 'Counteroffer';

  @override
  String get deals_status_agreed => 'Agreed';

  @override
  String get deals_status_completed => 'Completed';

  @override
  String get deals_status_rejected => 'Rejected';

  @override
  String get deals_status_cancelled => 'Cancelled';

  @override
  String get offer_sheet_base_price => 'Base';

  @override
  String get offer_sheet_min_order => 'Min';

  @override
  String get offer_sheet_available_stock => 'Avail. stock';

  @override
  String get offer_sheet_unapproved_error =>
      'Your account must be verified and approved to make commercial offers.';

  @override
  String get crop_unapproved_warning =>
      'Your account must be verified and approved to make commercial offers.';

  @override
  String get crop_unapproved_dialog_title => 'Verification required';

  @override
  String get crop_unapproved_dialog_desc =>
      'To make offers and negotiate with farmers, your profile must be verified and approved by a moderator.';

  @override
  String get crop_unapproved_dialog_action => 'Understood';

  @override
  String get recovery_title => 'Reset Password';

  @override
  String get recovery_subtitle =>
      'Enter the email associated with your account to receive reset instructions.';

  @override
  String get recovery_email_label => 'Email address';

  @override
  String get recovery_email_hint => 'example@email.com';

  @override
  String get recovery_email_required => 'Enter your email address.';

  @override
  String get recovery_email_invalid => 'Enter a valid email address.';

  @override
  String get recovery_phone_not_supported =>
      'Recovery via link requires an email address. If you only registered with a phone number, please contact support.';

  @override
  String get recovery_send_button => 'Send Instructions';

  @override
  String get recovery_sending => 'Sending...';

  @override
  String get recovery_generic_success =>
      'If the information corresponds to a registered account, instructions to reset your password will be sent.';

  @override
  String get recovery_back_to_login => 'Back to Sign In';

  @override
  String get recovery_network_error =>
      'Connection error. Please check your internet connection and try again.';

  @override
  String get recovery_generic_error =>
      'Could not process your request. Please try again later.';

  @override
  String get reset_password_title => 'New Password';

  @override
  String get reset_password_subtitle =>
      'Enter your new password to access your account.';

  @override
  String get reset_password_new_label => 'New Password';

  @override
  String get reset_password_new_hint => 'Minimum 6 characters';

  @override
  String get reset_password_confirm_label => 'Confirm New Password';

  @override
  String get reset_password_confirm_hint => 'Repeat your new password';

  @override
  String get reset_password_length_error =>
      'Password must be at least 6 characters long.';

  @override
  String get reset_password_mismatch_error => 'Passwords do not match.';

  @override
  String get reset_password_required_error => 'This field is required.';

  @override
  String get reset_password_submit_button => 'Update Password';

  @override
  String get reset_password_updating => 'Updating...';

  @override
  String get reset_password_success =>
      'Password updated successfully. Please sign in with your new password.';

  @override
  String get reset_password_invalid_session =>
      'The recovery link is invalid or has expired. Please request a new one.';

  @override
  String get reset_password_cancel => 'Cancel';

  @override
  String get verification_status_reupload_coming_soon =>
      'Document re-upload feature in development.';

  @override
  String get moderation_queue_title => 'Moderation Queue';

  @override
  String get moderation_queue_empty_title => 'No pending requests';

  @override
  String get moderation_queue_empty_desc =>
      'All verification requests have been resolved or there are no pending submissions.';

  @override
  String get moderation_unauthorized_title => 'Unauthorized Access';

  @override
  String get moderation_unauthorized_desc =>
      'Your account does not possess moderation privileges to access this console.';

  @override
  String get moderation_detail_title => 'Request Details';

  @override
  String get moderation_lbl_role => 'Role:';

  @override
  String get moderation_lbl_submitted => 'Submitted:';

  @override
  String get moderation_documents_title => 'Submitted Documents';

  @override
  String get moderation_storage_notice =>
      'Documents are retrieved through temporary signed links from private storage. They are not shared publicly.';

  @override
  String get moderation_doc_front => 'ID Card (Front)';

  @override
  String get moderation_doc_back => 'ID Card (Back)';

  @override
  String get moderation_doc_selfie => 'Facial Selfie';

  @override
  String get moderation_previous_rejection => 'Registered Rejection Reason';

  @override
  String get moderation_already_resolved =>
      'This request has already been resolved and does not accept new immediate changes.';

  @override
  String get moderation_btn_approve => 'Approve';

  @override
  String get moderation_btn_reject => 'Reject';

  @override
  String get moderation_confirm_approve_title => 'Confirm Approval';

  @override
  String get moderation_confirm_approve_desc =>
      'Are you sure you want to approve this request? The user will gain access to commercial features.';

  @override
  String get moderation_approved_success => 'Request approved successfully.';

  @override
  String get moderation_confirm_reject_title => 'Reject Request';

  @override
  String get moderation_reject_reason_prompt =>
      'Please specify the reason for rejection so the user can correct it:';

  @override
  String get moderation_reject_reason_hint =>
      'E.g., Blurry document or illegible expiration date';

  @override
  String get moderation_reject_reason_required =>
      'Rejection reason is required.';

  @override
  String get moderation_rejected_success => 'Request rejected successfully.';

  @override
  String get document_front_title => 'Document front';

  @override
  String get document_back_title => 'Document back';

  @override
  String get document_selfie_title => 'User selfie';

  @override
  String get document_pick_sheet_title => 'Select the image source';

  @override
  String get document_pick_camera => 'Take photo';

  @override
  String get document_pick_gallery => 'Choose from gallery';

  @override
  String get document_pick_cancel => 'Cancel';

  @override
  String get document_pick_error =>
      'The image picker could not be opened. Please try again.';

  @override
  String get document_pick_label => 'Select image';

  @override
  String get document_replace_label => 'Replace';

  @override
  String get document_remove_label => 'Remove';

  @override
  String get document_selected_label => 'Selected';

  @override
  String get document_pending_label => 'Pending';

  @override
  String get document_preview_unavailable =>
      'This file could not be previewed.';

  @override
  String get document_preview_pending =>
      'You have not selected this image yet.';

  @override
  String get document_review_title => 'Review your documents';

  @override
  String get document_review_description =>
      'Make sure the front, back, and selfie are legible. You can replace any of them before submitting.';

  @override
  String get document_review_missing =>
      'You must attach the front, back, and selfie before submitting.';

  @override
  String get document_review_ready => 'All three images are ready to submit.';

  @override
  String get document_review_submit => 'Submit documents';

  @override
  String get document_review_submit_error =>
      'The submission could not continue. Please try again.';

  @override
  String get document_upload_title => 'Upload documents';

  @override
  String get document_upload_description =>
      'Attach the front, back, and selfie again to submit your verification request.';

  @override
  String get document_upload_submit => 'Submit request';

  @override
  String get document_upload_missing =>
      'You must attach the front, back, and selfie before submitting.';

  @override
  String get document_upload_in_progress => 'Uploading documents...';

  @override
  String get document_upload_success_title => 'Documents submitted';

  @override
  String get document_upload_success_desc =>
      'Your request was registered and is pending manual review.';

  @override
  String get document_upload_success_back => 'Back to status';

  @override
  String get document_upload_error =>
      'The documents could not be uploaded. Check your connection and try again.';

  @override
  String get document_upload_storage_error =>
      'The images could not be uploaded to private storage. Check your connection and try again.';

  @override
  String get document_upload_attempt_error =>
      'The images were uploaded, but the request could not be registered. Please try again.';

  @override
  String get document_upload_duplicate =>
      'A pending review request already exists.';

  @override
  String get document_upload_file_missing =>
      'One of the selected files is no longer available. Please select it again.';

  @override
  String get document_upload_unauthorized =>
      'You must sign in to submit verification documents.';

  @override
  String get document_image_available => 'Document available for review';

  @override
  String get document_image_missing => 'Document not provided';

  @override
  String get document_image_invalid => 'Invalid or unavailable document path';

  @override
  String get document_image_loading => 'Requesting secure link...';

  @override
  String get document_image_error =>
      'The document\'s secure link could not be obtained.';

  @override
  String get document_image_display_error =>
      'The image could not be displayed.';

  @override
  String get document_image_retry => 'Retry';

  @override
  String get moderation_diagnosis_title => 'Document diagnosis';

  @override
  String get moderation_diagnosis_simulated => 'SIMULATED';

  @override
  String get moderation_diagnosis_disclaimer =>
      'Demonstrative report based only on the presence and basic validity of document paths. It does not verify authenticity or identity.';

  @override
  String get moderation_diagnosis_present => 'Present';

  @override
  String get moderation_diagnosis_missing => 'Missing';

  @override
  String get moderation_diagnosis_available_label =>
      'Images available for review:';

  @override
  String get moderation_diagnosis_pending =>
      'Overall result: pending human review.';

  @override
  String get moderation_diagnosis_observations_title =>
      'Observations for manual review';

  @override
  String get moderation_diagnosis_obs_profile =>
      'Manually check the profile name, phone, and role.';

  @override
  String get moderation_diagnosis_obs_missing_docs =>
      'Required documents are missing; do not infer absent data.';

  @override
  String get moderation_diagnosis_obs_shared_paths =>
      'Document paths are not independent; verify them before deciding.';

  @override
  String get moderation_diagnosis_obs_email =>
      'The profile has no registered email; contact verification is manual.';

  @override
  String get moderation_diagnosis_limitations_title => 'Diagnosis limitations';

  @override
  String get moderation_diagnosis_limit_authenticity =>
      'It does not verify document authenticity.';

  @override
  String get moderation_diagnosis_limit_biometrics =>
      'It does not perform biometric matching or liveness checks.';

  @override
  String get moderation_diagnosis_limit_external =>
      'It does not query government databases or external AI services.';

  @override
  String get moderation_diagnosis_limit_auto =>
      'It does not automatically approve or reject the request.';

  @override
  String get moderation_diagnosis_no_auto =>
      'The final decision is made exclusively by the moderator.';

  @override
  String get moderation_btn_mark_in_review => 'Put in review';

  @override
  String get moderation_in_review_success =>
      'Request marked as in review successfully.';

  @override
  String get moderation_filter_all => 'All';

  @override
  String get moderation_filter_pending => 'Pending';

  @override
  String get moderation_filter_in_review => 'In review';
}
