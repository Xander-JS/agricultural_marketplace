import 'dart:io';

class RegistrationData {
  String? phone;
  String? firstName;
  String? lastName;
  String? role; // 'agricultor' or 'comprador'
  String? documentType; // 'CC' or 'Driver License'
  File? documentFront;
  File? documentBack;
  File? selfie;

  bool get isPersonalInfoValid =>
      phone != null &&
      phone!.isNotEmpty &&
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty;

  bool get isRoleValid => role != null && role!.isNotEmpty;

  bool get isDocumentTypeValid =>
      documentType != null && documentType!.isNotEmpty;

  bool get isDocumentFrontValid => documentFront != null;

  bool get isDocumentBackValid => documentBack != null;

  bool get isSelfieValid => selfie != null;
}
