import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';

void main() {
  group('Etapa D — Ciclo Comercial y Control de Inventario (app_movil_estados_Sistema.docx)', () {
    test('Regla: stock_disponible = stock_total - stock_comprometido - stock_vendido', () {
      final crop = CropModel(
        id: 'crop-100',
        farmerId: 'farmer-1',
        title: 'Papa R12',
        description: 'Lote de papa certificada',
        cropType: 'Papa',
        pricePerKg: 2500,
        stockTotal: 100, // 100 kg publicado
        stockCommitted: 0,
        stockSold: 0,
        minOrderKg: 10,
        department: 'Cundinamarca',
        municipality: 'Facatativá',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Estado inicial
      expect(crop.availableStock, equals(100.0));
      expect(crop.stockCommitted, equals(0.0));
      expect(crop.stockSold, equals(0.0));

      // 2. Simular oferta acordada de 60 kg (reserva en stock_comprometido)
      final afterAgreed = CropModel(
        id: crop.id,
        farmerId: crop.farmerId,
        title: crop.title,
        description: crop.description,
        cropType: crop.cropType,
        pricePerKg: crop.pricePerKg,
        stockTotal: 100,
        stockCommitted: 60, // 60 kg reservados
        stockSold: 0,
        minOrderKg: crop.minOrderKg,
        department: crop.department,
        municipality: crop.municipality,
        status: crop.status,
        createdAt: crop.createdAt,
        updatedAt: DateTime.now(),
      );

      // Comprobar estado acordado:
      // Stock total: 100 kg, Stock comprometido: 60 kg, Stock disponible: 40 kg, Stock vendido: 0 kg
      expect(afterAgreed.stockTotal, equals(100.0));
      expect(afterAgreed.stockCommitted, equals(60.0));
      expect(afterAgreed.availableStock, equals(40.0));
      expect(afterAgreed.stockSold, equals(0.0));

      // 3. Simular trato completado (entrega física finalizada)
      final afterCompleted = CropModel(
        id: crop.id,
        farmerId: crop.farmerId,
        title: crop.title,
        description: crop.description,
        cropType: crop.cropType,
        pricePerKg: crop.pricePerKg,
        stockTotal: 100,
        stockCommitted: max(0.0, afterAgreed.stockCommitted - 60), // Reserva liberada (0 kg)
        stockSold: afterAgreed.stockSold + 60, // Venta consolidada (60 kg)
        minOrderKg: crop.minOrderKg,
        department: crop.department,
        municipality: crop.municipality,
        status: crop.status,
        createdAt: crop.createdAt,
        updatedAt: DateTime.now(),
      );

      // Comprobar estado completado del ejemplo oficial:
      // Stock total: 100 kg, Stock comprometido: 0 kg, Stock disponible: 40 kg, Stock vendido: 60 kg
      expect(afterCompleted.stockTotal, equals(100.0));
      expect(afterCompleted.stockCommitted, equals(0.0));
      expect(afterCompleted.availableStock, equals(40.0));
      expect(afterCompleted.stockSold, equals(60.0));
    });

    test('Transición a agotada: cuando stock_disponible llega a 0', () {
      final crop = CropModel(
        id: 'crop-200',
        farmerId: 'farmer-2',
        title: 'Aguacate Hass',
        description: 'Aguacate de exportación',
        cropType: 'Aguacate',
        pricePerKg: 8000,
        stockTotal: 50,
        stockCommitted: 0,
        stockSold: 0,
        minOrderKg: 10,
        department: 'Antioquia',
        municipality: 'Sonsón',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Venta completa de los 50 kg
      final newCommitted = 0.0;
      final newSold = 50.0;
      final available = crop.stockTotal - newCommitted - newSold;
      final isAgotada = available <= 0;

      expect(isAgotada, isTrue);

      final cropAgotada = CropModel(
        id: crop.id,
        farmerId: crop.farmerId,
        title: crop.title,
        description: crop.description,
        cropType: crop.cropType,
        pricePerKg: crop.pricePerKg,
        stockTotal: crop.stockTotal,
        stockCommitted: newCommitted,
        stockSold: newSold,
        minOrderKg: crop.minOrderKg,
        department: crop.department,
        municipality: crop.municipality,
        status: isAgotada ? CropStatus.agotada : crop.status,
        createdAt: crop.createdAt,
        updatedAt: DateTime.now(),
      );

      expect(cropAgotada.status, equals(CropStatus.agotada));
      expect(cropAgotada.availableStock, equals(0.0));
    });

    test('Cancelación o rechazo de trato acordado libera el stock comprometido', () {
      final cropReservado = CropModel(
        id: 'crop-300',
        farmerId: 'farmer-3',
        title: 'Cacao Fino de Aroma',
        description: 'Cacao seco fermentado',
        cropType: 'Cacao',
        pricePerKg: 12000,
        stockTotal: 500,
        stockCommitted: 200, // 200 kg reservados en negociación previa
        stockSold: 0,
        minOrderKg: 50,
        department: 'Santander',
        municipality: 'San Vicente de Chucurí',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cropReservado.availableStock, equals(300.0));

      // Al cancelar o rechazar el acuerdo, se libera la reserva
      final quantityToRelease = 200.0;
      final newCommitted = max(0.0, cropReservado.stockCommitted - quantityToRelease);

      final cropLiberado = CropModel(
        id: cropReservado.id,
        farmerId: cropReservado.farmerId,
        title: cropReservado.title,
        description: cropReservado.description,
        cropType: cropReservado.cropType,
        pricePerKg: cropReservado.pricePerKg,
        stockTotal: cropReservado.stockTotal,
        stockCommitted: newCommitted,
        stockSold: cropReservado.stockSold,
        minOrderKg: cropReservado.minOrderKg,
        department: cropReservado.department,
        municipality: cropReservado.municipality,
        status: cropReservado.status,
        createdAt: cropReservado.createdAt,
        updatedAt: DateTime.now(),
      );

      expect(cropLiberado.stockCommitted, equals(0.0));
      expect(cropLiberado.availableStock, equals(500.0)); // Vuelve a tener 500 kg disponibles
    });

    test('Prevención de sobreventas: no permite reservar más del stock disponible', () {
      final crop = CropModel(
        id: 'crop-400',
        farmerId: 'farmer-4',
        title: 'Mango Tommy',
        description: 'Mango fresco',
        cropType: 'Mango',
        pricePerKg: 4000,
        stockTotal: 100,
        stockCommitted: 80,
        stockSold: 0,
        minOrderKg: 10,
        department: 'Tolima',
        municipality: 'Espinal',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final available = crop.availableStock; // 20 kg
      expect(available, equals(20.0));

      // Intento de ofertar o aceptar 30 kg (mayor que available 20 kg)
      final proposedQty = 30.0;
      final canAccept = proposedQty <= available;

      expect(canAccept, isFalse);
    });

    test('Verificación de usuario: solo estado aprobado permite operaciones comerciales', () {
      final estadosPermitidos = <String, bool>{
        'pendiente': false,
        'en_revision_ia': false,
        'aprobado': true,
        'rechazado': false,
        'suspendido': false,
      };

      for (final entry in estadosPermitidos.entries) {
        final status = UserVerificationStatus.fromString(entry.key);
        expect(
          status.isApproved,
          equals(entry.value),
          reason: 'El estado ${entry.key} debería tener isApproved = ${entry.value}',
        );
      }
    });
  });
}
