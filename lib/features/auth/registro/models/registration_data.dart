import 'dart:io';

class RegistrationData {
  String? phone;
  String? firstName;
  String? lastName;
  String? password;
  String? email;
  String? role; // 'agricultor' or 'comprador'
  String? documentType; // 'CC' or 'Driver License'
  File? documentFront;
  File? documentBack;
  File? selfie;

  bool get isPasswordValid => password != null && password!.length >= 6;

  bool get isPersonalInfoValid =>
      phone != null &&
      phone!.trim().isNotEmpty &&
      firstName != null &&
      firstName!.trim().isNotEmpty &&
      lastName != null &&
      lastName!.trim().isNotEmpty &&
      isPasswordValid;

  bool get isRoleValid =>
      role != null && (role == 'agricultor' || role == 'comprador');

  bool get isDocumentTypeValid =>
      documentType != null && documentType!.isNotEmpty;

  bool get isDocumentFrontValid => documentFront != null;

  bool get isDocumentBackValid => documentBack != null;

  bool get isSelfieValid => selfie != null;
}
