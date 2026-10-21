import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/utils/unit_formatters.dart';
import 'package:agricultural_marketplace/features/ai_assistant/models/voice_crop_draft.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';

class FakeCropServiceForVoicePrefill extends CropService {
  CropModel? lastSavedCrop;

  @override
  Future<CropModel> saveCrop(
    CropModel crop, {
    List<File>? newImages,
    List<String>? removedImages,
  }) async {
    lastSavedCrop = crop;
    return crop;
  }

  @override
  String getPublicImageUrl(String imagePath) => imagePath;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        publishableKey: 'placeholder-anon-key',
      );
    } catch (_) {}
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  VoiceCropDraft voiceDraft() {
    return VoiceCropDraft(
      transcript: 'Tengo 100 bultos de papa a 2200 pesos el kilo',
      cropType: 'Papa',
      quantity: 100,
      unit: VoiceCropUnit.fromTraditional(TraditionalUnit.bulto),
      quantityKg: 5000,
      pricePerKg: 2200,
      fieldsToReview: const {VoiceCropField.quantity},
      warnings: const [
        'La cantidad se convirtió a 5.000 kg. Confírmala antes de publicar.',
      ],
    );
  }

  String fieldText(WidgetTester tester, int index) {
    return tester
            .widget<TextFormField>(find.byType(TextFormField).at(index))
            .controller
            ?.text ??
        '';
  }

  testWidgets(
    '1. Precarga en PublishCropScreen los datos reconocidos y marca lo pendiente',
    (tester) async {
      final service = FakeCropServiceForVoicePrefill();

      await tester.pumpWidget(
        createTestWidget(
          PublishCropScreen(
            initialDraft: voiceDraft(),
            cropService: service,
            currentUserIdForTesting: 'farmer-voice-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fieldText(tester, 1), equals('Papa'));
      expect(fieldText(tester, 3), equals('2200'));
      expect(fieldText(tester, 4), equals('5000'));
      expect(fieldText(tester, 5), equals('1'));
      expect(fieldText(tester, 6), equals('Nariño'));
      expect(fieldText(tester, 0), isEmpty);
      expect(fieldText(tester, 2), isEmpty);

      expect(find.byKey(const Key('voice_draft_banner')), findsOneWidget);
      expect(find.textContaining('Borrador creado por voz'), findsOneWidget);
      expect(find.textContaining('Confirma: Cantidad'), findsOneWidget);
      expect(find.textContaining('Faltan o debes completar'), findsOneWidget);
      expect(service.lastSavedCrop, isNull);
    },
  );

  testWidgets(
    '2. El formulario precargado permite completar y publicar con el flujo existente',
    (tester) async {
      final service = FakeCropServiceForVoicePrefill();

      await tester.pumpWidget(
        createTestWidget(
          PublishCropScreen(
            initialDraft: voiceDraft(),
            cropService: service,
            currentUserIdForTesting: 'farmer-voice-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Papa Pastusa por voz',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Papa seleccionada para mercado mayorista.',
      );
      await tester.enterText(find.byType(TextFormField).at(7), 'Pasto');

      final publishButton = find.widgetWithText(ElevatedButton, 'Publicar');
      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(service.lastSavedCrop, isNotNull);
      final saved = service.lastSavedCrop!;
      expect(saved.title, equals('Papa Pastusa por voz'));
      expect(saved.cropType, equals('Papa'));
      expect(saved.pricePerKg, equals(2200));
      expect(saved.stockTotal, equals(5000));
      expect(saved.minOrderKg, equals(1));
      expect(saved.department, equals('Nariño'));
      expect(saved.municipality, equals('Pasto'));
      expect(saved.status, equals(CropStatus.activa));
    },
  );

  testWidgets(
    '3. La edición de un cultivo conserva prioridad sobre el borrador de voz',
    (tester) async {
      final cropToEdit = CropModel(
        id: 'crop-edit-1',
        farmerId: 'farmer-voice-1',
        title: 'Café existente',
        description: 'Descripción existente',
        cropType: 'Café',
        pricePerKg: 18000,
        stockTotal: 500,
        minOrderKg: 10,
        department: 'Nariño',
        municipality: 'La Unión',
        status: CropStatus.activa,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 2),
      );

      await tester.pumpWidget(
        createTestWidget(
          PublishCropScreen(
            cropToEdit: cropToEdit,
            initialDraft: voiceDraft(),
            cropService: FakeCropServiceForVoicePrefill(),
            currentUserIdForTesting: 'farmer-voice-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), equals('Café existente'));
      expect(fieldText(tester, 1), equals('Café'));
      expect(fieldText(tester, 3), equals('18000'));
      expect(fieldText(tester, 4), equals('500'));
      expect(find.byKey(const Key('voice_draft_banner')), findsNothing);
      expect(find.text('Editar Cosecha'), findsOneWidget);
    },
  );

  testWidgets(
    '4. La creación manual sin borrador conserva los valores iniciales',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PublishCropScreen(
            cropService: FakeCropServiceForVoicePrefill(),
            currentUserIdForTesting: 'farmer-voice-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), isEmpty);
      expect(fieldText(tester, 1), isEmpty);
      expect(fieldText(tester, 2), isEmpty);
      expect(fieldText(tester, 3), isEmpty);
      expect(fieldText(tester, 4), isEmpty);
      expect(fieldText(tester, 5), equals('1'));
      expect(fieldText(tester, 6), equals('Nariño'));
      expect(find.byKey(const Key('voice_draft_banner')), findsNothing);
    },
  );
}
