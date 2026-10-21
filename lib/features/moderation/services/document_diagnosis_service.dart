import '../models/moderation_request.dart';

enum DocumentDiagnosisDocumentType { front, back, selfie }

enum DocumentDiagnosisObservation {
  manualProfileReview,
  missingDocuments,
  sharedDocumentPaths,
  emailNotProvided,
}

class DocumentDiagnosisDocument {
  final DocumentDiagnosisDocumentType type;
  final String? path;
  final bool isAvailable;

  const DocumentDiagnosisDocument({
    required this.type,
    required this.path,
    required this.isAvailable,
  });
}

/// Informe demostrativo de soporte para el moderador.
///
/// IMPORTANTE: este informe es explícitamente SIMULADO. Solo observa la
/// presencia y validez básica de rutas de documentos y datos disponibles del
/// perfil. No verifica autenticidad documental, no hace coincidencia biométrica,
/// no consulta bases gubernamentales ni servicios externos de IA y no puede
/// aprobar ni rechazar automáticamente una solicitud.
class DocumentDiagnosisReport {
  final List<DocumentDiagnosisDocument> documents;
  final List<DocumentDiagnosisObservation> observations;

  const DocumentDiagnosisReport({
    required this.documents,
    required this.observations,
  });

  bool get isSimulated => true;

  bool get requiresManualReview => true;

  bool get canAutoApprove => false;

  int get availableDocuments =>
      documents.where((document) => document.isAvailable).length;

  int get totalDocuments => documents.length;

  bool get hasAllRequiredDocuments =>
      totalDocuments > 0 && documents.every((document) => document.isAvailable);

  List<DocumentDiagnosisDocumentType> get missingDocumentTypes => documents
      .where((document) => !document.isAvailable)
      .map((document) => document.type)
      .toList(growable: false);
}

/// Valida únicamente la forma de la ruta relativa almacenada en Supabase.
/// No intenta abrir ni descargar el archivo y no registra su contenido.
abstract final class DocumentPathValidator {
  static bool isValid(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return false;
    if (value.startsWith('/')) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    if (value.contains('..') || value.contains('\\')) return false;
    return value.split('/').every((segment) => segment.isNotEmpty);
  }
}

class DocumentDiagnosisService {
  const DocumentDiagnosisService();

  DocumentDiagnosisReport build(ModerationRequest request) {
    final documents = <DocumentDiagnosisDocument>[
      DocumentDiagnosisDocument(
        type: DocumentDiagnosisDocumentType.front,
        path: request.documentFrontPath,
        isAvailable: DocumentPathValidator.isValid(request.documentFrontPath),
      ),
      DocumentDiagnosisDocument(
        type: DocumentDiagnosisDocumentType.back,
        path: request.documentBackPath,
        isAvailable: DocumentPathValidator.isValid(request.documentBackPath),
      ),
      DocumentDiagnosisDocument(
        type: DocumentDiagnosisDocumentType.selfie,
        path: request.selfiePath,
        isAvailable: DocumentPathValidator.isValid(request.selfiePath),
      ),
    ];

    final observations = <DocumentDiagnosisObservation>[
      DocumentDiagnosisObservation.manualProfileReview,
    ];

    if (documents.any((document) => !document.isAvailable)) {
      observations.add(DocumentDiagnosisObservation.missingDocuments);
    }

    final validPaths = documents
        .where((document) => document.isAvailable)
        .map((document) => document.path!.trim())
        .toList(growable: false);
    if (validPaths.toSet().length != validPaths.length) {
      observations.add(DocumentDiagnosisObservation.sharedDocumentPaths);
    }

    if (request.email == null || request.email!.trim().isEmpty) {
      observations.add(DocumentDiagnosisObservation.emailNotProvided);
    }

    return DocumentDiagnosisReport(
      documents: documents,
      observations: observations,
    );
  }
}
