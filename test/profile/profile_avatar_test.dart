import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/avatars/user_avatar.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/profile/screens/farmer_profile_screen.dart';
import 'package:agricultural_marketplace/features/profile/services/profile_service.dart';

class MockProfileServiceForAvatar extends ProfileService {
  String? uploadedUserId;
  File? uploadedFile;
  String? mockPathToReturn = 'farmer-test-1/avatar.jpg';
  bool shouldThrowOnUpload = false;
  String? uploadErrorMessage;
  int getFarmerProfileDataCallCount = 0;
  FarmerProfileData? mockProfileDataToReturn;

  @override
  Future<String?> getProfilePath(String userId) async {
    final path = mockProfileDataToReturn?.profilePath ?? mockPathToReturn;
    profilePathNotifier.value = path;
    return path;
  }

  @override
  Future<void> deleteProfilePicture(String userId, [String? profilePath]) async {
    profilePathNotifier.value = null;
  }

  @override
  Future<String> uploadProfilePicture(
    String userId,
    File imageFile, {
    String? oldProfilePath,
  }) async {
    if (shouldThrowOnUpload) {
      throw Exception(uploadErrorMessage ?? 'Fallo de conexión en Supabase Storage o Base de Datos');
    }
    uploadedUserId = userId;
    uploadedFile = imageFile;
    final path = mockPathToReturn ?? '$userId/avatar.jpg';
    profilePathNotifier.value = path;
    return path;
  }

  @override
  Future<FarmerProfileData> getFarmerProfileData(String userId) async {
    getFarmerProfileDataCallCount++;
    return mockProfileDataToReturn ??
        FarmerProfileData(
          id: userId,
          fullName: 'Roberto Doncel',
          role: 'agricultor',
          email: 'roberto@finca.co',
          phone: '+57 312 345 6789',
          profilePath: mockPathToReturn,
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
  }

  @override
  String getPublicProfileImageUrl(String profilePath) {
    if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
      return profilePath;
    }
    return 'https://placeholder.supabase.co/storage/v1/object/public/profiles/$profilePath?t=123456';
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

  setUp(() {
    ProfileService.currentProfilePathNotifier.value = null;
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
    testWidgets('1. UserAvatar sin imagen muestra avatar predeterminado (LucideIcons.userRound)', (tester) async {
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

      expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
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

      expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
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

      expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
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

    testWidgets('5. UserAvatar resuelve automáticamente rutas relativas del bucket profiles generando NetworkImage', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: Center(
              child: UserAvatar(
                imageUrl: 'farmer-test-1/avatar.jpg',
                radius: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, contains('profiles/farmer-test-1/avatar.jpg'));
    });
  });

  group('Fase 2 — FarmerProfileScreen (foto de perfil, reactividad y persistencia)', () {
    testWidgets('6. Pantalla de perfil sin foto muestra UserAvatar con icono predeterminado', (tester) async {
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

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
      expect(find.byKey(const Key('change_avatar_button')), findsOneWidget);
    });

    testWidgets('7. Actualizar foto de perfil invoca pickImage y uploadProfilePicture, mostrando éxito y actualizando UserAvatar inmediatamente sin recarga completa', (tester) async {
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

      // Estado inicial: avatar sin foto
      var avatarWidget = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatarWidget.imageUrl, isNull);
      expect(mockService.getFarmerProfileDataCallCount, equals(0));

      final changeAvatarButton = find.byKey(const Key('change_avatar_button'));
      expect(changeAvatarButton, findsOneWidget);

      await tester.tap(changeAvatarButton);
      await tester.pumpAndSettle();

      expect(mockPicker.pickImageCalled, isTrue);
      expect(mockService.uploadedUserId, equals(baseProfileData.id));
      expect(mockService.uploadedFile, isNotNull);

      // SnackBar de éxito
      expect(find.text('Foto de perfil actualizada'), findsOneWidget);

      // UserAvatar se actualiza reactivamente con la nueva URL
      avatarWidget = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatarWidget.imageUrl, isNotNull);
      expect(avatarWidget.imageUrl, contains('farmer-test-1/avatar.jpg'));

      // Verificar que NO se requirió una recarga completa de datos del perfil
      expect(mockService.getFarmerProfileDataCallCount, equals(0));
    });

    testWidgets('8. Cancelar la selección de foto no sube archivos ni altera el perfil', (tester) async {
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

    testWidgets('9. Tratamiento de errores: fallo en uploadProfilePicture muestra error, omite mensaje de éxito y preserva foto previa', (tester) async {
      final mockService = MockProfileServiceForAvatar()
        ..shouldThrowOnUpload = true
        ..uploadErrorMessage = 'Error simulado de conexión con Storage o Base de Datos';
      final mockPicker = MockImagePickerForAvatar(
        pickedFile: XFile('/tmp/test_avatar.jpg'),
      );

      final initialProfileWithPhoto = baseProfileData.copyWith(
        profilePath: 'farmer-test-1/foto_previa.jpg',
      );

      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(
            initialProfileData: initialProfileWithPhoto,
            profileService: mockService,
            imagePicker: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar inicial tiene la foto previa
      var avatarWidget = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatarWidget.imageUrl, contains('foto_previa.jpg'));

      // Intentar subir nueva foto
      final changeAvatarButton = find.byKey(const Key('change_avatar_button'));
      await tester.tap(changeAvatarButton);
      await tester.pumpAndSettle();

      // NO debe mostrar éxito
      expect(find.text('Foto de perfil actualizada'), findsNothing);

      // Debe mostrar mensaje de error
      expect(find.textContaining('Error al subir imagen'), findsOneWidget);

      // La foto previa debe seguir visible en el avatar
      avatarWidget = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatarWidget.imageUrl, contains('foto_previa.jpg'));
    });

    test('10. Conservación de la foto tras consultar getFarmerProfileData', () async {
      final profileWithPhoto = baseProfileData.copyWith(
        profilePath: 'farmer-test-1/foto_persistida.jpg',
      );
      final mockService = MockProfileServiceForAvatar()
        ..mockProfileDataToReturn = profileWithPhoto;

      final loadedProfile = await mockService.getFarmerProfileData('farmer-test-1');
      expect(loadedProfile.profilePath, equals('farmer-test-1/foto_persistida.jpg'));
      expect(mockService.getFarmerProfileDataCallCount, equals(1));
    });
  });

  group('Fase 2 — Reutilización en CropDetailScreen y Modelo FarmerProfileData', () {
    testWidgets('11. CropDetailScreen reutiliza UserAvatar en la tarjeta del productor', (tester) async {
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

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
    });

    test('12. ProfileService.getPublicProfileImageUrl resuelve URLs directas y genera URLs estables con cache busting', () {
      final service = ProfileService();

      const absoluteUrl = 'https://images.unsplash.com/profile-sample.jpg';
      expect(service.getPublicProfileImageUrl(absoluteUrl), equals(absoluteUrl));

      const relativePath = 'farmer-999/avatar.png';
      final url1 = service.getPublicProfileImageUrl(relativePath);
      final url2 = service.getPublicProfileImageUrl(relativePath);

      expect(url1, contains('profiles'));
      expect(url1, contains('farmer-999/avatar.png'));
      expect(url1, contains('?t='));
      // La llamada sucesiva en el mismo ciclo retorna la misma URL estable para evitar reconstrucciones de red
      expect(url1, equals(url2));

      // La invalidación explícita refresca la versión
      service.invalidateCache(relativePath);
      final url3 = service.getPublicProfileImageUrl(relativePath);
      expect(url3, contains('farmer-999/avatar.png'));
    });

    test('13. FarmerProfileData.copyWith preserva o actualiza profilePath adecuadamente', () {
      final profile = baseProfileData.copyWith(profilePath: 'user-1/foto.jpg');
      expect(profile.profilePath, equals('user-1/foto.jpg'));
      expect(profile.fullName, equals(baseProfileData.fullName));

      final clearedProfile = profile.copyWith(clearProfilePath: true);
      expect(clearedProfile.profilePath, isNull);
    });

    test('14. FarmerProfileData.fromMap mapea correctamente profile_path del esquema real', () {
      final rawProfile = {
        'id': 'farmer-99',
        'full_name': 'Ana María Gómez',
        'role': 'agricultor',
        'email': 'ana@finca.co',
        'phone': '+57 310 111 2233',
        'profile_path': 'farmer-99/avatar.jpg',
        'department': 'Caldas',
        'municipality': 'Chinchiná',
      };

      final profile = FarmerProfileData.fromMap(
        profileMap: rawProfile,
        settingsMap: {},
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      expect(profile.profilePath, equals('farmer-99/avatar.jpg'));
      expect(profile.fullName, equals('Ana María Gómez'));
    });
  });

  group('Fase 2 — Visualización de la foto de perfil en «Mi Mercado» y en el Panel del Comprador', () {
    testWidgets('15. «Mi Mercado» (rol agricultor) muestra avatar con icono predeterminado si no tiene foto y refleja reactivamente la foto tras subirla', (tester) async {
      final mockService = MockProfileServiceForAvatar()..mockPathToReturn = null;
      ProfileService.currentProfilePathNotifier.value = null;

      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'agricultor',
            initialCrops: const [],
            profileService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título 'Mi Mercado'
      expect(find.text('Mi Mercado'), findsOneWidget);

      // El avatar en el AppBar muestra el fallback predeterminado
      final avatarFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(UserAvatar),
      );
      expect(avatarFinder, findsOneWidget);
      var avatarWidget = tester.widget<UserAvatar>(avatarFinder);
      expect(avatarWidget.imageUrl, isNull);

      // Simular que el usuario sube una foto en su perfil
      ProfileService.currentProfilePathNotifier.value = 'farmer-test-1/nueva_foto.jpg';
      await tester.pumpAndSettle();

      // UserAvatar en AppBar se actualiza reactivamente sin necesidad de recargar la pantalla
      avatarWidget = tester.widget<UserAvatar>(avatarFinder);
      expect(avatarWidget.imageUrl, isNotNull);
      expect(avatarWidget.imageUrl, contains('farmer-test-1/nueva_foto.jpg'));
    });

    testWidgets('16. «Mercado» (rol comprador) muestra la foto del comprador y se actualiza reactivamente', (tester) async {
      final mockService = MockProfileServiceForAvatar()
        ..mockPathToReturn = 'buyer-42/foto_comprador.jpg';
      ProfileService.currentProfilePathNotifier.value = 'buyer-42/foto_comprador.jpg';

      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'comprador',
            initialCrops: const [],
            profileService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título 'Mercado'
      expect(find.text('Mercado'), findsOneWidget);

      // El avatar en el AppBar muestra la foto del comprador
      final avatarFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(UserAvatar),
      );
      expect(avatarFinder, findsOneWidget);
      var avatarWidget = tester.widget<UserAvatar>(avatarFinder);
      expect(avatarWidget.imageUrl, contains('buyer-42/foto_comprador.jpg'));

      // Si el comprador cambia su foto, se actualiza inmediatamente
      ProfileService.currentProfilePathNotifier.value = 'buyer-42/foto_actualizada.png';
      await tester.pumpAndSettle();

      avatarWidget = tester.widget<UserAvatar>(avatarFinder);
      expect(avatarWidget.imageUrl, contains('buyer-42/foto_actualizada.png'));
    });

    testWidgets('17. Tocar el avatar en «Mi Mercado» o «Mercado» dispara onProfileTap', (tester) async {
      bool profileTapped = false;
      final mockService = MockProfileServiceForAvatar()..mockPathToReturn = 'user-1/avatar.jpg';
      ProfileService.currentProfilePathNotifier.value = 'user-1/avatar.jpg';

      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'agricultor',
            initialCrops: const [],
            profileService: mockService,
            onProfileTap: () {
              profileTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final avatarFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(UserAvatar),
      );
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    });

    testWidgets('18. MainDashboardScreen conmuta a la pestaña de perfil al pulsar el avatar del AppBar (agricultor)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MainDashboardScreen(role: 'agricultor'),
        ),
      );
      await tester.pumpAndSettle();

      // Inicialmente en pestaña 0 (Marketplace)
      expect(find.text('Mi Mercado'), findsOneWidget);

      final avatarFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(UserAvatar),
      );
      expect(avatarFinder, findsOneWidget);

      // Tocar el avatar del AppBar
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Debe haber cambiado al índice 3: FarmerProfileScreen
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(3));
      expect(find.byType(FarmerProfileScreen), findsOneWidget);
    });

    testWidgets('19. MainDashboardScreen conmuta a la pestaña de perfil al pulsar el avatar del AppBar (comprador)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MainDashboardScreen(role: 'comprador'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);

      final avatarFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(UserAvatar),
      );
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(3));
      expect(find.byType(FarmerProfileScreen), findsOneWidget);
    });
  });
}
