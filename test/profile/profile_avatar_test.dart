import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/avatars/user_avatar.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/profile/screens/farmer_profile_screen.dart';
import 'package:agricultural_marketplace/features/profile/services/profile_service.dart';

class MockProfileServiceForAvatar extends ProfileService {
  String? uploadedUserId;
  File? uploadedFile;
  String? mockPathToReturn = 'farmer-test-1/avatar.jpg';

  @override
  Future<String> uploadProfilePicture(
    String userId,
    File imageFile, {
    String? oldProfilePath,
  }) async {
    uploadedUserId = userId;
    uploadedFile = imageFile;
    return mockPathToReturn ?? '$userId/avatar.jpg';
  }

  @override
  String getPublicProfileImageUrl(String profilePath) {
    if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
      return profilePath;
    }
    return 'https://placeholder.supabase.co/storage/v1/object/public/profiles/$profilePath';
  }
}

class MockImagePickerForAvatar extends ImagePicker {
  XFile? pickedFile;
  bool pickImageCalled = false;

  MockImagePickerForAvatar({this.pickedFile});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    pickImageCalled = true;
    return pickedFile;
  }
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

  Widget createTestWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  final baseProfileData = FarmerProfileData(
    id: 'farmer-test-1',
    fullName: 'Roberto Doncel',
    role: 'agricultor',
    email: 'roberto@finca.co',
    phone: '+57 312 345 6789',
    profilePath: null,
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: true,
      shareLocation: true,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(
      published: 5,
      negotiating: 2,
      closed: 4,
    ),
  );

  group('Fase 2 — Widget UserAvatar (visualización, errores y fallback)', () {
    testWidgets('1. UserAvatar sin imagen muestra avatar predeterminado (Icons.person)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: Center(
              child: UserAvatar(imageUrl: null, radius: 24),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el icono predeterminado
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('2. UserAvatar con URL vacía o de espacios muestra avatar predeterminado', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: Center(
              child: UserAvatar(imageUrl: '   ', radius: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('3. UserAvatar con error de carga no rompe la interfaz y recurre al icono predeterminado', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: Center(
              child: UserAvatar(
                imageUrl: 'https://placeholder.supabase.co/storage/v1/object/public/profiles/inexistente.jpg',
                radius: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Al fallar la red o no encontrar la imagen, errorBuilder muestra el icono
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('4. UserAvatar con onTap reacciona al toque', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: Center(
              child: UserAvatar(
                imageUrl: null,
                radius: 20,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('Fase 2 — FarmerProfileScreen (foto de perfil y actualización)', () {
    testWidgets('5. Pantalla de perfil sin foto muestra UserAvatar con icono predeterminado', (tester) async {
      final mockService = MockProfileServiceForAvatar();

      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(
            initialProfileData: baseProfileData,
            profileService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // La cabecera del perfil debe mostrar UserAvatar
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byKey(const Key('change_avatar_button')), findsOneWidget);
    });

    testWidgets('6. Actualizar foto de perfil invoca pickImage y uploadProfilePicture reflejando el cambio', (tester) async {
      final mockService = MockProfileServiceForAvatar();
      final mockPicker = MockImagePickerForAvatar(
        pickedFile: XFile('/tmp/test_avatar.jpg'),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(
            initialProfileData: baseProfileData,
            profileService: mockService,
            imagePicker: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pulsar el botón flotante de la cámara para cambiar el avatar
      final changeAvatarButton = find.byKey(const Key('change_avatar_button'));
      expect(changeAvatarButton, findsOneWidget);

      await tester.tap(changeAvatarButton);
      await tester.pumpAndSettle();

      // Verificar que se invocó el ImagePicker
      expect(mockPicker.pickImageCalled, isTrue);

      // Verificar que el servicio subió la imagen para el usuario
      expect(mockService.uploadedUserId, equals(baseProfileData.id));
      expect(mockService.uploadedFile, isNotNull);

      // Debe mostrar el SnackBar de éxito
      expect(find.text('Foto de perfil actualizada'), findsOneWidget);
    });

    testWidgets('7. Cancelar la selección de foto no sube archivos ni altera el perfil', (tester) async {
      final mockService = MockProfileServiceForAvatar();
      final mockPicker = MockImagePickerForAvatar(pickedFile: null);

      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(
            initialProfileData: baseProfileData,
            profileService: mockService,
            imagePicker: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final changeAvatarButton = find.byKey(const Key('change_avatar_button'));
      await tester.tap(changeAvatarButton);
      await tester.pumpAndSettle();

      expect(mockPicker.pickImageCalled, isTrue);
      expect(mockService.uploadedUserId, isNull);
      expect(find.text('Foto de perfil actualizada'), findsNothing);
    });
  });

  group('Fase 2 — Reutilización en CropDetailScreen y Modelo FarmerProfileData', () {
    testWidgets('8. CropDetailScreen reutiliza UserAvatar en la tarjeta del productor', (tester) async {
      final sampleCrop = CropModel(
        id: 'crop-avatar-1',
        farmerId: 'farmer-test-1',
        title: 'Cacao Fino de Aroma',
        description: 'Cacao seleccionado',
        cropType: 'Cacao',
        pricePerKg: 12000,
        stockTotal: 100,
        stockCommitted: 0,
        stockSold: 0,
        minOrderKg: 10,
        department: 'Huila',
        municipality: 'Garzón',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: const [],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: baseProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe existir UserAvatar en la tarjeta del productor
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    test('9. ProfileService.getPublicProfileImageUrl resuelve URLs directas y relativas', () {
      final service = ProfileService();

      // URL absoluta no es modificada ni duplicada
      const absoluteUrl = 'https://images.unsplash.com/profile-sample.jpg';
      expect(service.getPublicProfileImageUrl(absoluteUrl), equals(absoluteUrl));

      // Ruta relativa genera URL con timestamp
      const relativePath = 'farmer-999/avatar.png';
      final generatedUrl = service.getPublicProfileImageUrl(relativePath);
      expect(generatedUrl, contains('profiles'));
      expect(generatedUrl, contains('farmer-999/avatar.png'));
      expect(generatedUrl, contains('?t='));
    });

    test('10. FarmerProfileData.copyWith preserva o actualiza profilePath adecuadamente', () {
      final profile = baseProfileData.copyWith(profilePath: 'user-1/foto.jpg');
      expect(profile.profilePath, equals('user-1/foto.jpg'));
      expect(profile.fullName, equals(baseProfileData.fullName));

      final clearedProfile = profile.copyWith(clearProfilePath: true);
      expect(clearedProfile.profilePath, isNull);
    });
  });
}
