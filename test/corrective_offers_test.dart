import 'package:flutter_test/flutter_test.dart';
import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/constants/delivery_methods.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_offer_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';

void main() {
  group('Etapa A — Corrección de Enums y Mapeo Centralizado', () {
    test('UserRole serializa exactamente los valores admitidos por el enum PostgreSQL user_role', () {
      expect(UserRole.agricultor.toDbValue(), equals('agricultor'));
      expect(UserRole.comprador.toDbValue(), equals('comprador'));
      expect(UserRole.moderador.toDbValue(), equals('moderador'));

      // Comprobar que NUNCA se serializa 'farmer' o 'buyer' hacia la base de datos
      expect(UserRole.agricultor.toDbValue(), isNot(equals('farmer')));
      expect(UserRole.comprador.toDbValue(), isNot(equals('buyer')));
    });

    test('UserRole.fromString normaliza variantes en inglés y español correctamente', () {
      // Agricultor
      expect(UserRole.fromString('farmer'), equals(UserRole.agricultor));
      expect(UserRole.fromString('agricultor'), equals(UserRole.agricultor));
      expect(UserRole.fromString('productor'), equals(UserRole.agricultor));
      expect(UserRole.fromString(' FARMER '), equals(UserRole.agricultor));

      // Comprador
      expect(UserRole.fromString('buyer'), equals(UserRole.comprador));
      expect(UserRole.fromString('comprador'), equals(UserRole.comprador));
      expect(UserRole.fromString('comerciante'), equals(UserRole.comprador));
      expect(UserRole.fromString(' BUYER '), equals(UserRole.comprador));

      // Moderador
      expect(UserRole.fromString('moderator'), equals(UserRole.moderador));
      expect(UserRole.fromString('moderador'), equals(UserRole.moderador));
    });

    test('UserRole helpers identifican roles de comprador y agricultor', () {
      expect(UserRole.isBuyerRole('comprador'), isTrue);
      expect(UserRole.isBuyerRole('comerciante'), isTrue);
      expect(UserRole.isBuyerRole('buyer'), isTrue);
      expect(UserRole.isBuyerRole('agricultor'), isFalse);
      expect(UserRole.isBuyerRole('farmer'), isFalse);

      expect(UserRole.isFarmerRole('agricultor'), isTrue);
      expect(UserRole.isFarmerRole('farmer'), isTrue);
      expect(UserRole.isFarmerRole('productor'), isTrue);
      expect(UserRole.isFarmerRole('comprador'), isFalse);
    });

    test('UserVerificationStatus normaliza y valida estado aprobado', () {
      expect(UserVerificationStatus.fromString('aprobado').isApproved, isTrue);
      expect(UserVerificationStatus.fromString('approved').isApproved, isTrue);

      expect(UserVerificationStatus.fromString('pendiente').isApproved, isFalse);
      expect(UserVerificationStatus.fromString('en_revision_ia').isApproved, isFalse);
      expect(UserVerificationStatus.fromString('rechazado').isApproved, isFalse);
      expect(UserVerificationStatus.fromString('suspendido').isApproved, isFalse);
    });

    test('DeliveryMethod mapea cadenas a enum PostgreSQL delivery_method', () {
      expect(DeliveryMethod.toDb('En finca'), equals('en_finca'));
      expect(DeliveryMethod.toDb('Punto de acopio / acordado'), equals('punto_acordado'));
      expect(DeliveryMethod.toDb('Transportadora / Bodega'), equals('transportadora'));
      expect(DeliveryMethod.toDb('Destino final'), equals('transportadora'));
    });
  });

  group('Etapa A — Modelo NegotiationModel y Gestión de Turnos', () {
    test('NegotiationModel evalúa turnos correctamente tanto con strings en español como en inglés', () {
      final negConDbValue = NegotiationModel(
        id: 'neg-db-1',
        cropId: 'crop-1',
        buyerId: 'buyer-1',
        status: NegotiationStatus.propuesta,
        currentResponder: 'agricultor', // Valor devuelto por PostgreSQL
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(negConDbDbTurn(negConDbValue, isBuyer: false), isTrue); // Turno del agricultor
      expect(negConDbDbTurn(negConDbValue, isBuyer: true), isFalse); // Comprador está esperando

      final negConLegacyValue = NegotiationModel(
        id: 'neg-legacy-1',
        cropId: 'crop-1',
        buyerId: 'buyer-1',
        status: NegotiationStatus.propuesta,
        currentResponder: 'farmer', // Valor legacy de Flutter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(negConLegacyValue.isFarmerTurn, isTrue);
      expect(negConLegacyValue.isBuyerTurn, isFalse);
      expect(negConLegacyValue.isMyTurn(isBuyer: false), isTrue);
      expect(negConLegacyValue.isMyTurn(isBuyer: true), isFalse);
    });

    test('NegotiationModel serializa current_responder con valor admitido por DB', () {
      final neg = NegotiationModel(
        id: 'neg-1',
        cropId: 'crop-1',
        buyerId: 'buyer-1',
        status: NegotiationStatus.propuesta,
        currentResponder: 'farmer', // Aunque internamente venga como farmer
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = neg.toJson();
      // Debe serializar a 'agricultor', NUNCA a 'farmer'
      expect(json['current_responder'], equals('agricultor'));
    });

    test('NegotiationOfferModel serializa delivery_method con valor admitido por PostgreSQL', () {
      final offer = NegotiationOfferModel(
        id: 'off-1',
        negotiationId: 'neg-1',
        senderId: 'buyer-1',
        quantityKg: 100,
        proposedPricePerKg: 15000,
        deliveryMethod: 'En finca', // Etiqueta UI
        createdAt: DateTime.now(),
      );

      final json = offer.toJson();
      expect(json['delivery_method'], equals('en_finca'));
    });
  });

  group('Etapa A — CropModel y Cálculo de Stock Disponible', () {
    test('CropModel.availableStock calcula según la fórmula oficial del sistema', () {
      // stock_disponible = stock_total - stock_comprometido - stock_vendido
      final crop = CropModel(
        id: 'crop-1',
        farmerId: 'farmer-1',
        title: 'Papa Pastusa',
        description: 'Cultivo de papa de primera calidad',
        cropType: 'Papa',
        pricePerKg: 3000,
        stockTotal: 1000,
        stockCommitted: 300,
        stockSold: 200,
        minOrderKg: 50,
        department: 'Boyacá',
        municipality: 'Tunja',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1000 - 300 - 200 = 500 kg disponibles
      expect(crop.availableStock, equals(500.0));
    });

    test('CropModel.availableStock nunca retorna valores negativos', () {
      final crop = CropModel(
        id: 'crop-2',
        farmerId: 'farmer-1',
        title: 'Cebolla Junca',
        description: 'Cebolla fresca',
        cropType: 'Cebolla',
        pricePerKg: 2000,
        stockTotal: 100,
        stockCommitted: 80,
        stockSold: 50, // 100 - 80 - 50 = -30
        minOrderKg: 10,
        department: 'Boyacá',
        municipality: 'Aquitania',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(crop.availableStock, equals(0.0));
    });
  });

  group('Etapa A & Etapa 5 — Prueba de Regresión de Payloads contra Error 22P02', () {
    test('buildInitialNegotiationPayload NUNCA envía "farmer" y asigna canónicamente "agricultor"', () {
      final now = DateTime.now().toIso8601String();
      final payload = NegotiationService.buildInitialNegotiationPayload(
        cropId: 'crop-uuid-1234',
        buyerId: 'buyer-uuid-5678',
        timestamp: now,
      );

      // Verificación de campos obligatorios
      expect(payload['crop_id'], equals('crop-uuid-1234'));
      expect(payload['buyer_id'], equals('buyer-uuid-5678'));
      expect(payload['status'], equals('propuesta'));
      expect(payload['created_at'], equals(now));
      expect(payload['updated_at'], equals(now));

      // Verificación estricta contra error 22P02:
      // Debe ser 'agricultor' (PostgreSQL enum user_role), NUNCA 'farmer'
      expect(payload['current_responder'], equals('agricultor'));
      expect(payload['current_responder'], isNot(equals('farmer')));
      expect(payload['current_responder'], isNot(equals('buyer')));

      // Comprobar que ningún valor en el payload contenga 'farmer'
      expect(payload.values.contains('farmer'), isFalse);
    });

    test('buildOfferPayload mapea métodos de entrega válidos hacia el enum PostgreSQL delivery_method', () {
      final now = DateTime.now().toIso8601String();

      // Opción: En finca
      final p1 = NegotiationService.buildOfferPayload(
        negotiationId: 'neg-1',
        senderId: 'buyer-1',
        quantityKg: 200,
        proposedPricePerKg: 3500,
        deliveryMethod: 'En finca',
        message: 'Entrega en lote',
        timestamp: now,
      );
      expect(p1['delivery_method'], equals('en_finca'));
      expect(p1['quantity_kg'], equals(200));
      expect(p1['proposed_price_per_kg'], equals(3500));
      expect(p1['message'], equals('Entrega en lote'));

      // Opción: Punto acordado
      final p2 = NegotiationService.buildOfferPayload(
        negotiationId: 'neg-2',
        senderId: 'buyer-1',
        quantityKg: 150,
        proposedPricePerKg: 4000,
        deliveryMethod: 'Punto de acopio / acordado',
        timestamp: now,
      );
      expect(p2['delivery_method'], equals('punto_acordado'));

      // Opción: Transportadora
      final p3 = NegotiationService.buildOfferPayload(
        negotiationId: 'neg-3',
        senderId: 'buyer-1',
        quantityKg: 100,
        proposedPricePerKg: 4500,
        deliveryMethod: 'Transportadora / Bodega',
        timestamp: now,
      );
      expect(p3['delivery_method'], equals('transportadora'));
    });

    test('buildCounterOfferNegotiationPayload normaliza nextResponderRole y no propaga "farmer"', () {
      final now = DateTime.now().toIso8601String();

      // Cuando el siguiente en responder es el agricultor
      final pFarmer = NegotiationService.buildCounterOfferNegotiationPayload(
        nextResponderRole: 'farmer',
        timestamp: now,
      );
      expect(pFarmer['current_responder'], equals('agricultor'));
      expect(pFarmer['current_responder'], isNot(equals('farmer')));
      expect(pFarmer['status'], equals('contraofertada'));

      // Cuando el siguiente en responder es el comprador
      final pBuyer = NegotiationService.buildCounterOfferNegotiationPayload(
        nextResponderRole: 'buyer',
        timestamp: now,
      );
      expect(pBuyer['current_responder'], equals('comprador'));
      expect(pBuyer['current_responder'], isNot(equals('buyer')));
    });

    test('UserRole.toDb mapea identificadores de usuario evitando strings incompatibles con profiles.role', () {
      expect(UserRole.toDb('farmer'), equals('agricultor'));
      expect(UserRole.toDb('buyer'), equals('comprador'));
      expect(UserRole.toDb('moderator'), equals('moderador'));
      expect(UserRole.toDb('comerciante'), equals('comprador'));
      expect(UserRole.toDb('productor'), equals('agricultor'));
    });
  });
}

bool negConDbDbTurn(NegotiationModel n, {required bool isBuyer}) {
  return n.isMyTurn(isBuyer: isBuyer);
}
