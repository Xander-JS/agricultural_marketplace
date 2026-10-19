import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_preferences_service.dart';
import '../models/farmer_profile_data.dart';
import '../services/profile_service.dart';

/// Pantalla de Perfil compartida entre los roles Agricultor y Comerciante/Comprador.
///
/// Conserva intacta la experiencia y opciones de negociación del agricultor,
/// y adapta dinámicamente las estadísticas (solo Negociando y Cerrados para el comerciante)
/// y las opciones de configuración, respetando temas claro y oscuro y localización.
class FarmerProfileScreen extends StatefulWidget {
  final FarmerProfileData? initialProfileData;

  const FarmerProfileScreen({
    super.key,
    this.initialProfileData,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  FarmerProfileData? _profileData;

  // Preferencias de Accesibilidad (conectadas globalmente a AppPreferencesService)
  late bool _isDarkMode;
  late bool _isEnglish;

  // Controladores para la edición de campos de contacto
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  bool _emailSaved = false;
  bool _phoneSaved = false;
  StateSetter? _modalSetState;

  bool get _isBuyer {
    final role = _profileData?.role.trim().toLowerCase() ?? '';
    return role == 'comprador' || role == 'comerciante';
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = AppPreferencesService.instance.isDarkMode;
    _isEnglish = AppPreferencesService.instance.isEnglish;

    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _checkAndSaveField('email', _emailController.text.trim());
      } else {
        _emailSaved = false;
        _modalSetState?.call(() {});
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkAndSaveField('phone', _phoneController.text.trim());
      } else {
        _phoneSaved = false;
        _modalSetState?.call(() {});
      }
    });

    if (widget.initialProfileData != null) {
      _profileData = widget.initialProfileData;
      _emailController.text = _profileData!.email;
      _phoneController.text = _profileData!.phone;
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProfileData();
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado. (Modo prueba activo sin sesión)');
      }
      final userId = currentUser.id;
      final data = await _profileService.getFarmerProfileData(userId);
      if (mounted) {
        setState(() {
          _profileData = data;
          _emailController.text = data.email;
          _phoneController.text = data.phone;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.profile_load_error ?? "Error al cargar el perfil"}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _checkAndSaveField(String field, String value) async {
    if (_profileData == null) return;

    if (field == 'email' && value == _profileData!.email) return;
    if (field == 'phone' && value == _profileData!.phone) return;

    setState(() => _isSaving = true);
    _modalSetState?.call(() {});

    try {
      if (field == 'email') {
        await _profileService.updateProfileData(_profileData!.id, email: value);
        _profileData = FarmerProfileData(
          id: _profileData!.id,
          fullName: _profileData!.fullName,
          role: _profileData!.role,
          email: value,
          phone: _profileData!.phone,
          profilePath: _profileData!.profilePath,
          stats: _profileData!.stats,
          settings: _profileData!.settings,
        );
        _emailSaved = true;
      } else if (field == 'phone') {
        await _profileService.updateProfileData(_profileData!.id, phone: value);
        _profileData = FarmerProfileData(
          id: _profileData!.id,
          fullName: _profileData!.fullName,
          role: _profileData!.role,
          email: _profileData!.email,
          phone: value,
          profilePath: _profileData!.profilePath,
          stats: _profileData!.stats,
          settings: _profileData!.settings,
        );
        _phoneSaved = true;
      }

      if (mounted) {
        setState(() => _isSaving = false);
        _modalSetState?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _modalSetState?.call(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar dato: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateSettings(FarmerSettingsData newSettings) async {
    if (_profileData == null) return;

    setState(() {
      _profileData = FarmerProfileData(
        id: _profileData!.id,
        fullName: _profileData!.fullName,
        role: _profileData!.role,
        email: _profileData!.email,
        phone: _profileData!.phone,
        profilePath: _profileData!.profilePath,
        stats: _profileData!.stats,
        settings: newSettings,
      );
    });

    try {
      await _profileService.updateFarmerSettings(_profileData!.id, newSettings);
    } catch (e) {
      await _loadProfileData();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.profile_save_settings_error ?? "Error al guardar configuración"}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_profileData == null) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final file = File(image.path);
      await _profileService.uploadProfilePicture(_profileData!.id, file);
      await _loadProfileData();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.profile_updated_photo ?? 'Foto de perfil actualizada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            l10n?.profile_logout_confirm_title ?? '¿Cerrar sesión?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            l10n?.profile_logout_confirm_desc ?? '¿Estás seguro de que deseas salir de tu cuenta?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                l10n?.profile_cancel ?? 'Cancelar',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.profile_logout ?? 'Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Sign out error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    final screenTitle = _isBuyer
        ? (l10n?.profile_title_buyer ?? 'Mi Perfil')
        : (l10n?.profile_title_farmer ?? 'Mi Finca');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: AppTextStyles.displaySmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _isSaving || _profileData == null ? null : _showSettingsBottomSheet,
            tooltip: l10n?.profile_settings_title ?? 'Configuración',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tertiaryColor))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: tertiaryColor,
              child: _profileData == null
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Text(
                            l10n?.profile_no_data ?? 'No se pudieron cargar los datos.',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(isDark, textPrimary, tertiaryColor),
                          const SizedBox(height: 32),
                          _buildStatisticsSection(isDark, textPrimary),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
    );
  }

  void _showSettingsBottomSheet() {
    _emailSaved = false;
    _phoneSaved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _modalSetState = setModalState;
          final l10n = AppLocalizations.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final sheetBackground = isDark ? AppColors.darkBackground : AppColors.lightBackground;
          final sheetSurface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
          final settings = _profileData!.settings;

          return Container(
            decoration: BoxDecoration(
              color: sheetBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n?.profile_contact_info ?? 'Información de contacto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: l10n?.profile_email ?? 'Correo electrónico',
                    controller: _emailController,
                    originalValue: _profileData!.email,
                    icon: Icons.email_outlined,
                    focusNode: _emailFocusNode,
                    isSaved: _emailSaved,
                    keyboardType: TextInputType.emailAddress,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: l10n?.profile_phone ?? 'Número de teléfono',
                    controller: _phoneController,
                    originalValue: _profileData!.phone,
                    icon: Icons.phone_outlined,
                    focusNode: _phoneFocusNode,
                    isSaved: _phoneSaved,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Opciones de negociación: EXCLUSIVAS DEL AGRICULTOR
                  if (!_isBuyer) ...[
                    Text(
                      l10n?.profile_negotiation_options ?? 'Opciones de negociación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      title: l10n?.profile_enable_early_sale ?? 'Habilitar precompra',
                      value: settings.enableEarlySale,
                      icon: Icons.calendar_month_outlined,
                      isDark: isDark,
                      onChanged: (val) {
                        setModalState(() {
                          _updateSettings(FarmerSettingsData(
                            enableEarlySale: val,
                            sharePhone: settings.sharePhone,
                            shareLocation: settings.shareLocation,
                            shareWhatsapp: settings.shareWhatsapp,
                          ));
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.profile_visibility_negotiation ?? 'Visibilidad durante una negociación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: sheetSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchListTileInside(
                            title: l10n?.profile_visibility_phone ?? 'Teléfono',
                            value: settings.sharePhone,
                            isDark: isDark,
                            onChanged: (val) {
                              setModalState(() {
                                _updateSettings(FarmerSettingsData(
                                  enableEarlySale: settings.enableEarlySale,
                                  sharePhone: val,
                                  shareLocation: settings.shareLocation,
                                  shareWhatsapp: settings.shareWhatsapp,
                                ));
                              });
                            },
                          ),
                          Divider(height: 1, color: borderColor),
                          _buildSwitchListTileInside(
                            title: l10n?.profile_visibility_location ?? 'Ubicación',
                            value: settings.shareLocation,
                            isDark: isDark,
                            onChanged: (val) {
                              setModalState(() {
                                _updateSettings(FarmerSettingsData(
                                  enableEarlySale: settings.enableEarlySale,
                                  sharePhone: settings.sharePhone,
                                  shareLocation: val,
                                  shareWhatsapp: settings.shareWhatsapp,
                                ));
                              });
                            },
                          ),
                          Divider(height: 1, color: borderColor),
                          _buildSwitchListTileInside(
                            title: l10n?.profile_visibility_whatsapp ?? 'WhatsApp',
                            value: settings.shareWhatsapp,
                            isDark: isDark,
                            onChanged: (val) {
                              setModalState(() {
                                _updateSettings(FarmerSettingsData(
                                  enableEarlySale: settings.enableEarlySale,
                                  sharePhone: settings.sharePhone,
                                  shareLocation: settings.shareLocation,
                                  shareWhatsapp: val,
                                ));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Accesibilidad: Común para ambos roles
                  Text(
                    l10n?.profile_accessibility ?? 'Accesibilidad',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: sheetSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchListTileInside(
                          title: l10n?.profile_dark_mode ?? 'Modo oscuro',
                          value: _isDarkMode,
                          isDark: isDark,
                          onChanged: (val) async {
                            setModalState(() {
                              _isDarkMode = val;
                            });
                            setState(() {
                              _isDarkMode = val;
                            });
                            await AppPreferencesService.instance.toggleDarkMode(val);
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        _buildSwitchListTileInside(
                          title: l10n?.profile_english_language ?? 'Idioma inglés',
                          value: _isEnglish,
                          isDark: isDark,
                          onChanged: (val) async {
                            setModalState(() {
                              _isEnglish = val;
                            });
                            setState(() {
                              _isEnglish = val;
                            });
                            await AppPreferencesService.instance.toggleEnglish(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cierre de sesión: Común para ambos roles
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: Text(
                        l10n?.profile_logout ?? 'Cerrar sesión',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color textPrimary, Color tertiaryColor) {
    String? imageUrl;
    if (_profileData!.profilePath != null && _profileData!.profilePath!.isNotEmpty) {
      imageUrl = _profileService.getPublicProfileImageUrl(_profileData!.profilePath!);
    }

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final badgeBgColor = isDark
        ? AppColors.darkSecondary
        : AppColors.lightSecondary;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: borderColor,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.lightTextDisabled)
                  : null,
            ),
            GestureDetector(
              onTap: _isSaving ? null : _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tertiaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            (_profileData!.role).toUpperCase(),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _profileData!.fullName,
          textAlign: TextAlign.center,
          style: AppTextStyles.displaySmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String originalValue,
    required IconData icon,
    required FocusNode focusNode,
    required bool isSaved,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fieldBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          focusNode: focusNode,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.lightTextDisabled),
            suffixIcon: isSaved
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : null,
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tertiaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(bool isDark, Color textPrimary) {
    final l10n = AppLocalizations.of(context);
    final stats = _profileData!.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.profile_stats_title ?? 'Estadísticas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (!_isBuyer) ...[
          // Para el Agricultor: 3 estadísticas (Publicados, Negociando, Cerradas)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n?.profile_stat_published ?? 'Publicados',
                  stats.published.toString(),
                  Icons.grass_outlined,
                  AppColors.info,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n?.profile_stat_negotiating ?? 'Negociando',
                  stats.negotiating.toString(),
                  Icons.handshake_outlined,
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n?.profile_stat_closed_farmer ?? 'Cerradas',
                  stats.closed.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),
        ] else ...[
          // Para el Comerciante: ÚNICAMENTE 2 estadísticas (Negociando, Cerrados)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n?.profile_stat_negotiating ?? 'Negociando',
                  stats.negotiating.toString(),
                  Icons.handshake_outlined,
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  l10n?.profile_stat_closed_buyer ?? 'Cerrados',
                  stats.closed.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryBg = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    return Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: secondaryBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: tertiaryColor),
        ),
        value: value,
        onChanged: _isSaving ? null : onChanged,
        activeThumbColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        activeTrackColor: tertiaryColor,
        inactiveThumbColor: AppColors.lightTextDisabled,
        inactiveTrackColor: borderColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSwitchListTileInside({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary),
      ),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeThumbColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      activeTrackColor: tertiaryColor,
      inactiveThumbColor: AppColors.lightTextDisabled,
      inactiveTrackColor: borderColor,
    );
  }
}
