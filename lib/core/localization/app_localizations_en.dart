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
  String get complete_registration_title => 'Complete your registration';

  @override
  String get complete_registration_description =>
      'Your sign-in account already exists, but it has no profile or verification request yet. Enter your information and upload the three images. Previous data and documents are not reused.';

  @override
  String get complete_registration_contact => 'Phone or email';

  @override
  String get complete_registration_contact_hint =>
      '3151234567 or email@example.com';

  @override
  String get complete_registration_full_name => 'Full name';

  @override
  String get complete_registration_full_name_hint => 'First and last names';

  @override
  String get complete_registration_role => 'Account type';

  @override
  String get complete_registration_documents => 'Identity documents';

  @override
  String get complete_registration_submit => 'Complete registration';

  @override
  String get complete_registration_success =>
      'Registration completed. Your request is pending manual review.';

  @override
  String get complete_registration_invalid_data =>
      'Complete all fields and attach the front, back, and selfie images.';

  @override
  String get complete_registration_unauthorized =>
      'Your session is not active. Sign in again to continue.';

  @override
  String get complete_registration_profile_error =>
      'We could not save your profile. Please try again.';

  @override
  String get complete_registration_documents_error =>
      'We could not save your documents. Check your connection and try again.';

  @override
  String get complete_registration_in_progress =>
      'A document submission is already in progress.';

  @override
  String get complete_registration_unknown_error =>
      'We could not complete your registration. Please try again.';

  @override
  String get complete_registration_missing_documents =>
      'You must attach the front, back, and selfie images before continuing.';

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
  String get reputation_title => 'Reputation';

  @override
  String get reputation_average_label => 'Average rating';

  @override
  String get reputation_reviews_received => 'Reviews received';

  @override
  String get reputation_no_ratings => 'No ratings yet';

  @override
  String get reputation_new => 'New';

  @override
  String get reputation_loading => 'Loading reputation...';

  @override
  String get reputation_load_error => 'Could not load reputation.';

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
  String get market_search_hint => 'Search by title or crop type';

  @override
  String get market_search_clear => 'Clear search';

  @override
  String get market_sort_recent => 'Most recent first';

  @override
  String get market_sort_price_asc => 'Lowest price first';

  @override
  String get market_sort_price_desc => 'Highest price first';

  @override
  String get market_sort_reputation => 'Highest reputation first';

  @override
  String get market_no_results => 'No crops were found matching these criteria';

  @override
  String get market_clear_filters => 'Clear filters';

  @override
  String get market_own_profile => 'My profile';

  @override
  String get publish_title_new => 'Publish Crop';

  @override
  String get publish_title_edit => 'Edit Crop';

  @override
  String get publish_unauthorized_title => 'Unauthorized Access';

  @override
  String get publish_unauthorized_desc =>
      'Only registered and verified farmers can publish crops.';

  @override
  String get publish_validation_incomplete =>
      'Please complete the required fields correctly.';

  @override
  String get publish_harvest_date_required =>
      'You must indicate the estimated harvest date for pre-sale.';

  @override
  String get publish_not_authenticated => 'Not authenticated';

  @override
  String get publish_access_farmer_only =>
      'Access denied: only farmers can publish crops.';

  @override
  String get publish_access_other_crop =>
      'Access denied: you cannot edit a crop belonging to another producer.';

  @override
  String get publish_success_active => 'Crop published successfully!';

  @override
  String get publish_success_draft => 'Draft saved.';

  @override
  String publish_save_error(String error) {
    return 'Error saving: $error';
  }

  @override
  String get publish_section_general => '1. General Information';

  @override
  String get publish_section_prices => '2. Prices and Quantities';

  @override
  String get publish_section_location => '3. Location';

  @override
  String get publish_section_sale_mode => '4. Sale Method';

  @override
  String get publish_section_images => '5. Images';

  @override
  String get publish_field_title => 'Listing title';

  @override
  String get publish_field_crop_type =>
      'Product type (e.g. Papa Capira, Café Castillo)';

  @override
  String get publish_field_description => 'Crop description';

  @override
  String get publish_field_price => 'Price per kg (\$)';

  @override
  String get publish_field_stock => 'Total avail. (kg)';

  @override
  String get publish_field_min_order => 'Minimum order (kg)';

  @override
  String get publish_field_department => 'Department';

  @override
  String get publish_field_municipality => 'Municipality';

  @override
  String get publish_early_sale_title => 'Is it a pre-sale?';

  @override
  String get publish_early_sale_desc =>
      'Useful if the crop is not ready yet but you want to secure sales.';

  @override
  String get publish_field_estimated_yield => 'Est. yield (kg)';

  @override
  String get publish_field_harvest_date => 'Harvest date';

  @override
  String get publish_select_date => 'Select...';

  @override
  String get publish_current_images => 'Current listing images:';

  @override
  String get publish_add_images => 'Add Images';

  @override
  String get publish_save_draft => 'Save Draft';

  @override
  String get publish_submit => 'Publish';

  @override
  String get publish_validation_required => 'Required';

  @override
  String get publish_validation_greater_zero => 'Greater than 0';

  @override
  String get publish_validation_non_negative => 'Greater than or equal to 0';

  @override
  String get publish_voice_banner_title => 'Voice-created draft';

  @override
  String get publish_voice_banner_desc =>
      'Review the recognized data. Nothing will be published until you confirm the form.';

  @override
  String publish_voice_confirm(String fields) {
    return 'Confirm: $fields';
  }

  @override
  String publish_voice_missing(String fields) {
    return 'Missing or to complete: $fields.';
  }

  @override
  String get publish_voice_label_title => 'Title';

  @override
  String get publish_voice_label_description => 'Description';

  @override
  String get publish_voice_label_location => 'Location';

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
  String get crop_detail_estimated_distance => 'Estimated distance';

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
  String counter_offer_subtitle_crop(String crop) {
    return 'Modify the terms of the offer for $crop.';
  }

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
  String get deal_detail_rate_farmer => 'Rate producer';

  @override
  String get deal_detail_rate_buyer => 'Rate buyer';

  @override
  String get deal_detail_rate_title => 'Rate deal';

  @override
  String get deal_detail_rate_subtitle =>
      'Your rating helps build trust in the community.';

  @override
  String get deal_detail_rate_target => 'You are rating';

  @override
  String get deal_detail_rate_stars_label => 'Your rating';

  @override
  String get deal_detail_rate_stars_required => 'Select 1 to 5 stars';

  @override
  String get deal_detail_rate_comment_label => 'Comment (optional)';

  @override
  String get deal_detail_rate_comment_hint => 'Tell us about your experience';

  @override
  String get deal_detail_rate_submit => 'Submit rating';

  @override
  String get deal_detail_rate_success => 'Rating submitted successfully';

  @override
  String get deal_detail_rate_error =>
      'Could not submit your rating. Please try again.';

  @override
  String get deal_detail_rate_loading => 'Checking rating...';

  @override
  String get deal_detail_rated => 'Deal rated';

  @override
  String get deal_detail_rated_desc =>
      'You already submitted your rating for this deal.';

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
  String offer_sheet_base_price(String price) {
    return 'Base: $price';
  }

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
  String get moderation_error_title => 'Could not load requests';

  @override
  String get moderation_error_processing => 'Error processing the request';

  @override
  String get moderation_error_rejecting => 'Error rejecting the request';

  @override
  String get moderation_error_updating => 'Error updating the request';

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

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_close => 'Close';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_save_changes => 'Save changes';

  @override
  String get common_back => 'Back';

  @override
  String get common_understood => 'Understood';

  @override
  String get common_accept => 'Accept';

  @override
  String get common_not_available => 'Not available';

  @override
  String get common_simulated => 'SIMULATED';

  @override
  String get common_field_required => 'Required field';

  @override
  String get common_greater_than_zero => 'Must be greater than 0';

  @override
  String common_unexpected_error(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get common_operation_error =>
      'The operation could not be completed. Please try again.';

  @override
  String common_error_prefix(String error) {
    return 'An error occurred: $error';
  }

  @override
  String product_card_variety(String variety) {
    return 'Variety: $variety';
  }

  @override
  String get product_card_view_details => 'View details';

  @override
  String get seller_details_reliability => 'Reliability';

  @override
  String get seller_details_volume => 'Available Volume';

  @override
  String get seller_details_min_order => 'Minimum Order';

  @override
  String get seller_details_condition => 'Condition & Logistics';

  @override
  String get otp_error_incomplete => 'Please enter all 6 digits';

  @override
  String get otp_resend_simulated => 'Code resent (Simulated)';

  @override
  String get personal_info_phone_invalid => 'Invalid phone number';

  @override
  String get personal_info_password_min => 'At least 6 characters';

  @override
  String get processing_confirmation_required =>
      'Account created. Please confirm your contact method to continue.';

  @override
  String get verification_status_simulated_review =>
      'Simulated review in progress; your account is awaiting moderator approval.';

  @override
  String get auth_gate_invalid_role =>
      'The profile role is invalid or undefined.';

  @override
  String get auth_gate_checking => 'Checking status...';

  @override
  String get auth_gate_generic_error_title => 'An error has occurred';

  @override
  String get auth_gate_unknown_status =>
      'We could not determine the verification status. Please contact support.';

  @override
  String get costs_title => 'Costs';

  @override
  String get costs_intro =>
      'Keep track of the expenses\nassociated with your crops.';

  @override
  String costs_per_kg_calculated(String amount) {
    return 'Cost per kg: $amount';
  }

  @override
  String get costs_per_kg_no_costs => 'Cost per kg: no costs recorded';

  @override
  String get costs_per_kg_invalid_total => 'Cost per kg: invalid total';

  @override
  String get costs_per_kg_invalid_quantity => 'Cost per kg: invalid quantity';

  @override
  String get costs_per_kg_pending_yield =>
      'Cost per kg: estimated yield pending';

  @override
  String get costs_total => 'Total costs';

  @override
  String get costs_view => 'View costs';

  @override
  String get costs_empty_title => 'You must create a crop first';

  @override
  String get costs_empty_desc =>
      'To keep a cost record, you need at least one registered crop.';

  @override
  String get costs_create_crop => 'Create crop';

  @override
  String get costs_add => 'Add cost';

  @override
  String get costs_add_title => 'Add Cost';

  @override
  String get costs_edit_title => 'Edit Cost';

  @override
  String get costs_category => 'Category';

  @override
  String get costs_description => 'Description';

  @override
  String get costs_description_hint => 'E.g.: Harvest labor';

  @override
  String get costs_description_required => 'Please enter a description';

  @override
  String get costs_value => 'Amount';

  @override
  String get costs_value_hint => 'E.g.: 150000 or 150000.50';

  @override
  String get costs_value_required => 'Please enter an amount';

  @override
  String get costs_value_invalid => 'Enter a numeric amount greater than 0';

  @override
  String get costs_save => 'Save cost';

  @override
  String get costs_update => 'Update cost';

  @override
  String get costs_added => 'Cost added successfully';

  @override
  String get costs_updated => 'Cost updated successfully';

  @override
  String costs_save_error(String error) {
    return 'Error saving: $error';
  }

  @override
  String get costs_delete_title => 'Delete this cost?';

  @override
  String get costs_delete_desc => 'This action cannot be undone.';

  @override
  String get costs_deleted => 'Cost deleted';

  @override
  String costs_delete_error(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get costs_estimated_per_kg => 'Estimated cost per kg';

  @override
  String costs_quantity_used(String quantity, String source) {
    return 'Quantity used: $quantity ($source)';
  }

  @override
  String costs_source_field(String field) {
    return 'Field: $field';
  }

  @override
  String get costs_profitability_title => 'Margin and suggested price';

  @override
  String get costs_profitability_subtitle =>
      'Calculate profit and margin, and compare with simulated references.';

  @override
  String get costs_empty_detail_title => 'You have no costs recorded yet';

  @override
  String get costs_empty_detail_desc =>
      'Add the expenses related to this crop for better control.';

  @override
  String get profitability_title => 'Margin and suggested price';

  @override
  String get profitability_cost_per_kg => 'Production cost per kg';

  @override
  String profitability_used_quantity(
    String quantity,
    String source,
    String field,
  ) {
    return 'Quantity used: $quantity ($source) · $field';
  }

  @override
  String get profitability_current_price => 'Current published price';

  @override
  String get profitability_invalid_current_price =>
      'The current price is invalid. You can enter a temporary price for the simulation.';

  @override
  String get profitability_unavailable_title =>
      'Margin and suggested price cannot be calculated';

  @override
  String get profitability_unavailable_desc =>
      'Fix the costs or crop data to continue. Estimated values are not shown to avoid misleading results.';

  @override
  String get profitability_evaluate_title => 'Evaluate your selling price';

  @override
  String get profitability_selling_price => 'Selling price per kg';

  @override
  String get profitability_edit_note =>
      'You can edit this value for the simulation; it does not save or change the published price.';

  @override
  String get profitability_temporary_price =>
      'Temporary simulation price; it has not been saved.';

  @override
  String get profitability_invalid_price =>
      'Enter a valid selling price greater than 0.';

  @override
  String get profitability_loss_per_kg => 'Estimated loss per kg';

  @override
  String get profitability_profit_per_kg => 'Estimated profit per kg';

  @override
  String get profitability_margin_over_price => 'Margin over the selling price';

  @override
  String get profitability_loss_message =>
      'The evaluated price is below the production cost.';

  @override
  String get profitability_low_margin =>
      'The margin is below the prototype\'s 15% reference.';

  @override
  String get profitability_margin_formula =>
      'Margin = (price − cost) / price × 100';

  @override
  String get profitability_suggested_title =>
      'Suggested price based on target margin';

  @override
  String get profitability_target_margin => 'Target margin (%)';

  @override
  String get profitability_margin_note =>
      'The margin applies to the selling price; it is not a markup on cost.';

  @override
  String get profitability_invalid_margin =>
      'Enter a margin between 0% and less than 100%.';

  @override
  String get profitability_orientation =>
      'Guidance price. It does not modify or publish the crop price.';

  @override
  String get profitability_regional_reference => 'Simulated regional reference';

  @override
  String get profitability_reference_missing =>
      'No simulated reference is configured for this crop.';

  @override
  String get profitability_reference_crop => 'Reference crop';

  @override
  String get profitability_reference_region => 'Region';

  @override
  String get profitability_reference_price => 'Simulated reference price';

  @override
  String get profitability_reference_type => 'Data type';

  @override
  String get profitability_reference_simulated => 'Simulated for the prototype';

  @override
  String get profitability_reference_difference =>
      'Difference from the simulated reference';

  @override
  String get profitability_reference_difference_note =>
      'The difference is calculated as evaluated price − reference.';

  @override
  String get crop_detail_less_than_km => '< 1 km';

  @override
  String crop_detail_km(String km) {
    return '$km km';
  }

  @override
  String get crop_detail_owner_edit_denied =>
      'Access denied: only the owning producer can modify this listing.';

  @override
  String crop_detail_error(String error) {
    return 'Error: $error';
  }

  @override
  String get crop_detail_other_edit_denied =>
      'Access denied: you cannot edit other users\' listings.';

  @override
  String get crop_detail_other_delete_denied =>
      'Access denied: you cannot delete other users\' listings.';

  @override
  String get crop_detail_delete_title => 'Delete Listing';

  @override
  String get crop_detail_delete_confirm =>
      'Are you sure you want to delete this listing? This action cannot be undone.';

  @override
  String get crop_detail_deleted => 'Listing deleted successfully';

  @override
  String get crop_detail_own_offer_error =>
      'You cannot make an offer on your own crop.';

  @override
  String get crop_detail_out_of_stock =>
      'This crop is sold out or has no available stock.';

  @override
  String get crop_detail_verification_required => 'Verification required';

  @override
  String get crop_detail_verification_desc =>
      'To make offers and negotiate with farmers, your profile must be verified and approved by a moderator.';

  @override
  String get crop_detail_offer_sent => 'Offer sent successfully.';

  @override
  String get crop_detail_view_deals => 'View Deals';

  @override
  String get crop_detail_total_available => 'Total Available';

  @override
  String crop_detail_price_matches_reference(String price) {
    return 'Price matches the regional reference ($price/kg)';
  }

  @override
  String crop_detail_price_vs_reference(
    String sign,
    String amount,
    String percent,
    String reference,
  ) {
    return '$sign$amount/kg ($sign$percent%) vs regional reference ($reference/kg)';
  }

  @override
  String crop_detail_regional_reference_region(String region) {
    return 'Regional reference ($region)';
  }

  @override
  String crop_detail_producer_with_location(String producer, String location) {
    return '$producer ($location)';
  }

  @override
  String get crop_status_draft => 'Draft';

  @override
  String get crop_status_active => 'Active';

  @override
  String get crop_status_paused => 'Paused';

  @override
  String get crop_status_exhausted => 'Sold out';

  @override
  String offer_sheet_min_stock(String min, String stock) {
    return 'Min: $min | Stock: $stock';
  }

  @override
  String get units_title => 'Unit Equivalences';

  @override
  String get units_close => 'Close';

  @override
  String get units_reference_quantity => 'Reference quantity (available)';

  @override
  String get units_calculate_quantity => 'Calculate quantity (kg)';

  @override
  String get units_input_hint => 'E.g. 500';

  @override
  String get units_approximate_equivalents =>
      'Approximate traditional equivalents';

  @override
  String units_equivalence_rate(String unit, String value) {
    return '1 $unit = $value';
  }

  @override
  String get units_disclaimer =>
      'Approximate conversions for informational purposes only. They do not modify inventory, prices, or orders.';

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
    return 'An error occurred: $error';
  }

  @override
  String get deals_producer => 'Producer';

  @override
  String get deals_buyer => 'Buyer';

  @override
  String deals_producer_with_location(String location) {
    return 'Producer ($location)';
  }

  @override
  String deals_counterpart_name(String label, String name) {
    return '$label: $name';
  }

  @override
  String get deal_detail_offer_history => 'Offer history';

  @override
  String get deal_detail_rating_sent => 'Rating sent successfully';

  @override
  String get deal_detail_generic_error =>
      'The operation could not be completed. Please try again.';

  @override
  String get deal_detail_the_farmer => 'The producer';

  @override
  String get deal_detail_the_buyer => 'The buyer';

  @override
  String get deal_detail_authorized => 'Authorized';

  @override
  String get deal_detail_private => 'Private';

  @override
  String get deal_detail_location_authorized_status => 'Authorized';

  @override
  String get deal_detail_location_private_status => 'Private';

  @override
  String deal_detail_permissions_update_error(String error) {
    return 'Error updating permissions: $error';
  }

  @override
  String get deal_detail_share_farm_location_permission =>
      'Share the farm location';

  @override
  String get deal_detail_contact_farmer => 'Producer contact information';

  @override
  String get deal_detail_contact_buyer => 'Buyer contact information';

  @override
  String get deal_detail_phone_whatsapp => 'Authorized phone / WhatsApp:';

  @override
  String get deal_detail_call => 'Call';

  @override
  String get deal_detail_whatsapp => 'WhatsApp';

  @override
  String get deal_detail_copy => 'Copy';

  @override
  String get deal_detail_phone => 'Phone';

  @override
  String deal_detail_contact_not_shared(String role) {
    return '$role has not authorized sharing their phone or WhatsApp.';
  }

  @override
  String get deal_detail_location_authorized => 'Authorized physical location:';

  @override
  String deal_detail_coordinates(String lat, String lon) {
    return 'Coordinates: $lat, $lon';
  }

  @override
  String get deal_detail_view_location => 'View location details';

  @override
  String deal_detail_location_not_shared(String role) {
    return '$role has not authorized sharing their physical location.';
  }

  @override
  String get deal_detail_my_permissions => 'Your permissions for this deal:';

  @override
  String deal_detail_phone_permission(String status) {
    return 'Phone: $status';
  }

  @override
  String deal_detail_location_permission(String status) {
    return 'Location: $status';
  }

  @override
  String get deal_detail_modify => 'Modify';

  @override
  String deal_detail_copied(String label, String text) {
    return '$label copied to clipboard: $text';
  }

  @override
  String deal_detail_phone_copied(String phone) {
    return 'Phone $phone copied. Ready to dial from your phone.';
  }

  @override
  String deal_detail_whatsapp_copied(String phone) {
    return 'WhatsApp contact $phone copied. Open WhatsApp to start a conversation.';
  }

  @override
  String get deal_detail_municipality_department =>
      'Municipality / Department:';

  @override
  String get deal_detail_geo_coordinates => 'Geographic coordinates:';

  @override
  String deal_detail_lat_lon(String lat, String lon) {
    return 'Lat: $lat\nLon: $lon';
  }

  @override
  String get deal_detail_location_verified =>
      'Verified location for the delivery of this batch.';

  @override
  String get deal_detail_coordinates_label => 'Coordinates';

  @override
  String get deal_detail_copy_coordinates => 'Copy coordinates';

  @override
  String get deal_detail_you => 'You';

  @override
  String deal_detail_delivery(String method) {
    return 'Delivery: $method';
  }

  @override
  String get deal_detail_cancel_proposal => 'Cancel proposal';

  @override
  String deal_detail_consent_save_error(String error) {
    return 'Warning: initial consent could not be saved: $error';
  }

  @override
  String get deal_detail_agreed_success => 'Deal agreed successfully';

  @override
  String get deal_detail_permissions_updated =>
      'Contact permissions updated successfully';

  @override
  String get deal_detail_reject_confirm_desc_extended =>
      'This action cannot be undone and the deal will close.';

  @override
  String get deal_detail_rejected => 'The deal has been rejected';

  @override
  String get deal_detail_cancel_confirm_title => 'Cancel this agreement?';

  @override
  String get deal_detail_cancel_proposal_title => 'Cancel this proposal?';

  @override
  String get deal_detail_cancel_confirm_desc =>
      'This action will cancel the agreed deal, release reserved stock, and close the negotiation.';

  @override
  String get deal_detail_cancel_proposal_desc =>
      'This action will cancel the submitted proposal, release reserved stock, and close the negotiation.';

  @override
  String get deal_detail_cancel_agreed_btn => 'Cancel agreement';

  @override
  String get deal_detail_cancel_proposal_btn => 'Cancel proposal';

  @override
  String get deal_detail_cancelled_success =>
      'Agreement cancelled successfully';

  @override
  String get deal_detail_proposal_cancelled_success =>
      'Proposal cancelled successfully';

  @override
  String get deal_detail_complete_confirm_title => 'Complete this deal?';

  @override
  String get deal_detail_complete_confirm_desc =>
      'This action will confirm the physical delivery of the product and record the final sale in inventory.';

  @override
  String get deal_detail_complete => 'Complete';

  @override
  String get deal_detail_completed => 'Deal completed successfully';

  @override
  String get deal_detail_rating_error =>
      'The rating could not be sent. Please try again.';

  @override
  String get deal_detail_stars_required => 'Select 1 to 5 stars';

  @override
  String get deal_detail_comment_optional => 'Comment (optional)';

  @override
  String get deal_detail_comment_hint => 'Tell us about your experience';

  @override
  String get deal_detail_submit_rating => 'Submit rating';

  @override
  String get deal_detail_accept_terms_title => 'Accept offer and agree deal';

  @override
  String get deal_detail_accept_terms_desc =>
      'When formalizing the agreement, the agreed inventory will be reserved in the system. Select which contact details you authorize to share with the counterpart to coordinate physical delivery:';

  @override
  String get deal_detail_share_phone => 'Share my phone and WhatsApp';

  @override
  String get deal_detail_share_phone_desc =>
      'Allows the counterpart to call or message you on WhatsApp to coordinate.';

  @override
  String get deal_detail_share_location => 'Share my delivery location';

  @override
  String get deal_detail_share_farm_location => 'Share the farm location';

  @override
  String get deal_detail_share_location_desc =>
      'Allows viewing the municipality and coordinates to plan the delivery route.';

  @override
  String get deal_detail_confirm_agreement => 'Confirm agreement';

  @override
  String get deal_detail_my_permissions_title => 'My contact permissions';

  @override
  String get deal_detail_my_permissions_desc =>
      'Control which private details you authorize the counterpart to see to coordinate this deal. You can revoke or grant permissions at any time:';

  @override
  String get deal_detail_share_phone_desc_permission =>
      'The counterpart will be able to see your number for calls or messages.';

  @override
  String get deal_detail_share_location_desc_permission =>
      'The counterpart will be able to see the municipality and coordinates for logistics.';

  @override
  String get moderation_reject_sheet_title => 'Reject Request';

  @override
  String get moderation_reject_reason_desc =>
      'Enter the rejection reason so the user can correct it:';

  @override
  String get moderation_lbl_email => 'Email:';

  @override
  String get moderation_lbl_user_id => 'User ID:';

  @override
  String get moderation_queue_refresh => 'Refresh';

  @override
  String get moderation_status_pending => 'Pending';

  @override
  String get moderation_status_approved => 'Approved';

  @override
  String get moderation_status_rejected => 'Rejected';

  @override
  String get moderation_status_suspended => 'Suspended';

  @override
  String get moderation_status_unknown => 'Unknown';

  @override
  String get profile_title => 'My Profile';

  @override
  String get profile_my_farm => 'My Farm';

  @override
  String get profile_settings => 'Settings';

  @override
  String get profile_load_data_error => 'The data could not be loaded.';

  @override
  String get profile_location => 'Location';

  @override
  String get profile_whatsapp => 'WhatsApp';

  @override
  String get profile_stats_heading => 'Statistics';

  @override
  String get profile_published => 'Published';

  @override
  String get profile_negotiating => 'Negotiating';

  @override
  String get profile_closed_female => 'Closed';

  @override
  String get profile_closed_male => 'Closed';

  @override
  String profile_update_error(String error) {
    return 'Error updating data: $error';
  }

  @override
  String profile_photo_error(String error) {
    return 'Error uploading image: $error';
  }

  @override
  String get profile_reputation_title => 'Reputation';

  @override
  String get profile_reputation_loading => 'Loading reputation...';

  @override
  String get profile_reputation_error => 'Reputation could not be loaded.';

  @override
  String purchases_error_prefix(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get purchases_merchant_role => 'Merchant Role';

  @override
  String get purchase_card_producer_local => 'Local producer';

  @override
  String purchase_card_producer_municipality(String municipality) {
    return 'Producer ($municipality)';
  }

  @override
  String get purchase_card_agreed_crop => 'Agreed crop';

  @override
  String get purchase_card_quantity => 'Quantity';

  @override
  String get purchase_card_price_per_kg => 'Price / kg';

  @override
  String get purchase_card_total_agreed => 'Agreed total';

  @override
  String get ai_close => 'Close';

  @override
  String get ai_title => 'Publish by voice';

  @override
  String get ai_subtitle =>
      'Tell us what you want to sell. You will review everything before publishing.';

  @override
  String get ai_examples_title => 'You can mention:';

  @override
  String get ai_examples_desc =>
      'Crop name, quantity and unit (kg, sack, arroba, crate, box or ton), and price per kg or per unit.';

  @override
  String get ai_example_text =>
      'Example: “I have 50 sacks of potatoes at 2,000 pesos per kilo.”';

  @override
  String get ai_unavailable_title =>
      'Automatic interpretation is not available in this environment because AI_API_KEY is missing.';

  @override
  String get ai_unavailable_desc =>
      'You can dictate and review the transcript, or continue manually.';

  @override
  String get ai_preparing => 'Preparing the microphone...';

  @override
  String get ai_permission_title => 'Microphone permission denied';

  @override
  String get ai_permission_desc =>
      'We cannot access the microphone. Enable the permission in system settings or continue manually.';

  @override
  String get ai_voice_unavailable_title => 'Voice recognition unavailable';

  @override
  String get ai_voice_unavailable_desc =>
      'This device does not offer the voice recognition service required by the app. You can publish manually.';

  @override
  String get ai_transcribing => 'Transcribing what you said...';

  @override
  String get ai_interpreting => 'Interpreting the data with AI...';

  @override
  String get ai_intro =>
      'Tap the microphone and describe your crop in your own words. Nothing will be published automatically.';

  @override
  String get ai_start => 'Start speaking';

  @override
  String get ai_manual => 'I prefer to fill out the form manually';

  @override
  String get ai_retry_mic => 'Retry microphone';

  @override
  String get ai_continue_manual => 'Continue manually';

  @override
  String get ai_listening => 'Listening...';

  @override
  String get ai_listening_hint => 'Speak now. You can stop when you are done.';

  @override
  String get ai_stop_review => 'Stop and review';

  @override
  String get ai_review_transcript_title => 'Review the transcript';

  @override
  String get ai_review_transcript_desc =>
      'If the microphone misheard any word, correct it before interpreting the data.';

  @override
  String get ai_transcript_label => 'Transcript';

  @override
  String get ai_interpret => 'Interpret with AI';

  @override
  String get ai_record_again => 'Record again';

  @override
  String get ai_recognized_title => 'Recognized data';

  @override
  String get ai_recognized_desc =>
      'This data will be pre-filled in the form. You can still correct it and must complete what is missing.';

  @override
  String get ai_no_data_desc =>
      'No usable data was identified. You can retry the interpretation, record again, or continue manually.';

  @override
  String get ai_warnings => 'Warnings';

  @override
  String get ai_confirm_data => 'Confirm this data';

  @override
  String get ai_missing_data => 'Missing data to complete';

  @override
  String get ai_review_continue => 'Review and continue';

  @override
  String get ai_retry_interpret => 'Retry interpretation';

  @override
  String get ai_crop => 'Crop';

  @override
  String get ai_quantity => 'Quantity';

  @override
  String get ai_price => 'Price';

  @override
  String get ai_note => 'Note';

  @override
  String get ai_no_data => 'No data identified.';

  @override
  String get ai_failed_title => 'Could not complete';

  @override
  String get ai_failed_desc =>
      'A problem occurred. Try again or continue manually.';

  @override
  String get ai_error_mic_start =>
      'The microphone could not be started. Check the permission or continue manually.';

  @override
  String get ai_error_mic_stop =>
      'Voice recognition could not be stopped. Try again or continue manually.';

  @override
  String get ai_error_no_speech =>
      'No voice was recognized. Move closer to the microphone, try again, or continue manually.';

  @override
  String get ai_error_no_speech_retry =>
      'No voice was recognized. Try speaking closer to the microphone or continue manually.';

  @override
  String get ai_error_empty_transcript =>
      'The transcript is empty. Record again or type what you want to publish.';

  @override
  String get ai_error_not_configured =>
      'AI interpretation is not configured. AI_API_KEY is missing. You can continue manually.';

  @override
  String get ai_error_interpret =>
      'The transcript could not be interpreted. Try again or continue manually.';
}
