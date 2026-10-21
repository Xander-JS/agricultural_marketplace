import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_preferences_service.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../models/farmer_profile_data.dart';
import '../services/profile_service.dart';
import '../../review/models/review_model.dart';
import '../../review/services/review_service.dart';

/// Pantalla de Perfil compartida entre los roles Agricultor y Comerciante/Comprador.
///
/// Conserva intacta la experiencia y opciones de negociación del agricultor,
/// y adapta dinámicamente las estadísticas (solo Negociando y Cerrados para el comerciante)
/// y las opciones de configuración, respetando temas claro y oscuro y localización.
class FarmerProfileScreen extends StatefulWidget {
  final FarmerProfileData? initialProfileData;
  final Future<void> Function()? onSignOut;
  final ProfileService? profileService;
  final ReviewService? reviewService;
  final ImagePicker? imagePicker;

  const FarmerProfileScreen({
    super.key,
    this.initialProfileData,
    this.onSignOut,
    this.profileService,
    this.reviewService,
    this.imagePicker,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  late final ProfileService _profileService = widget.profileService ?? ProfileService();
  late final ReviewService _reviewService = widget.reviewService ?? ReviewService();
  late final ImagePicker _imagePicker = widget.imagePicker ?? ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  FarmerProfileData? _profileData;

  // Reputación calculada por ReviewService para el usuario autenticado.
  ReviewSummary? _reputation;
  bool _isLoadingReputation = false;
  bool _reputationLoadFailed = false;

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
      _profileService.profilePathNotifier.value = _profileData!.profilePath;
      _emailController.text = _profileData!.email;
      _phoneController.text = _profileData!.phone;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadReputation(_profileData!.id);
        }
      });
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
        _profileService.invalidateCache(data.profilePath);
        _profileService.profilePathNotifier.value = data.profilePath;
        setState(() {
          _profileData = data;
          _emailController.text = data.email;
          _phoneController.text = data.phone;
          _isLoading = false;
        });
        await _loadReputation(userId);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.profile_load_error}: $e'),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }

  /// Carga la reputación del usuario desde `ReviewService`. Un fallo de esta
  /// consulta no afecta los datos del perfil y se muestra un estado de error
  /// con reintento, sin inventar un promedio.
  Future<void> _loadReputation(String userId) async {
    if (userId.trim().isEmpty || !mounted) return;

    setState(() {
      _isLoadingReputation = true;
      _reputationLoadFailed = false;
    });

    try {
      final summary = await _reviewService.getReputation(userId);
      if (!mounted) return;
      setState(() {
        _reputation = summary;
        _isLoadingReputation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reputation = null;
        _isLoadingReputation = false;
        _reputationLoadFailed = true;
      });
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_update_error(e.toString())),
            backgroundColor: context.appError,
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.profile_save_settings_error}: $e'),
            backgroundColor: context.appError,
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
      final newPath = await _profileService.uploadProfilePicture(
        _profileData!.id,
        file,
        oldProfilePath: _profileData?.profilePath,
      );
      if (mounted) {
        _profileService.profilePathNotifier.value = newPath;
        setState(() {
          _profileData = _profileData!.copyWith(profilePath: newPath);
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_updated_photo),
            backgroundColor: context.appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_photo_error(e.toString())),
            backgroundColor: context.appError,
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          title: Text(
            l10n.profile_logout_confirm_title,
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          content: Text(
            l10n.profile_logout_confirm_desc,
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                l10n.profile_cancel,
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appError,
                foregroundColor: context.appOnPrimary,
              ),
              child: Text(l10n.profile_logout),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _profileService.profilePathNotifier.value = null;
      if (widget.onSignOut != null) {
        await widget.onSignOut!();
      } else {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          debugPrint('Sign out remote error: $e');
          try {
            await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
          } catch (_) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screenTitle = _isBuyer
        ? (l10n.profile_title_buyer)
        : (l10n.profile_title_farmer);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: AppTextStyles.displaySmall.copyWith(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.appSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appTextPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _isSaving || _profileData == null ? null : _showSettingsBottomSheet,
            tooltip: l10n.profile_settings_title,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.appPrimary))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: context.appPrimary,
              child: _profileData == null
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Text(
                            l10n.profile_no_data,
                            style: TextStyle(color: context.appTextSecondary),
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
                          _buildProfileHeader(),
                          const SizedBox(height: 32),
                          _buildStatisticsSection(),
                          const SizedBox(height: 32),
                          _buildReputationSection(),
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
      backgroundColor: AppColors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _modalSetState = setModalState;
          final l10n = AppLocalizations.of(context)!;
          final settings = _profileData!.settings;

          return Container(
            decoration: BoxDecoration(
              color: context.appBackground,
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
                        color: context.appDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.profile_contact_info,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: l10n.profile_email,
                    controller: _emailController,
                    originalValue: _profileData!.email,
                    icon: Icons.email_outlined,
                    focusNode: _emailFocusNode,
                    isSaved: _emailSaved,
                    keyboardType: TextInputType.emailAddress,
                                      ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: l10n.profile_phone,
                    controller: _phoneController,
                    originalValue: _profileData!.phone,
                    icon: Icons.phone_outlined,
                    focusNode: _phoneFocusNode,
                    isSaved: _phoneSaved,
                    keyboardType: TextInputType.phone,
                                      ),
                  const SizedBox(height: 24),

                  // Opciones de negociación: EXCLUSIVAS DEL AGRICULTOR
                  if (!_isBuyer) ...[
                    Text(
                      l10n.profile_negotiation_options,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      title: l10n.profile_enable_early_sale,
                      value: settings.enableEarlySale,
                      icon: Icons.calendar_month_outlined,
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
                      l10n.profile_visibility_negotiation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: context.appSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: context.appBorder),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchListTileInside(
                            title: l10n.profile_visibility_phone,
                            value: settings.sharePhone,
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
                          Divider(height: 1, color: context.appDivider),
                          _buildSwitchListTileInside(
                            title: l10n.profile_visibility_location,
                            value: settings.shareLocation,
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
                          Divider(height: 1, color: context.appDivider),
                          _buildSwitchListTileInside(
                            title: l10n.profile_visibility_whatsapp,
                            value: settings.shareWhatsapp,
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
                    l10n.profile_accessibility,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: context.appSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.appBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchListTileInside(
                          title: l10n.profile_dark_mode,
                          value: _isDarkMode,
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
                        Divider(height: 1, color: context.appDivider),
                        _buildSwitchListTileInside(
                          title: l10n.profile_english_language,
                          value: _isEnglish,
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
                      icon: Icon(Icons.logout, color: context.appError),
                      label: Text(
                        l10n.profile_logout,
                        style: TextStyle(
                          color: context.appError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.appError),
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

  Widget _buildProfileHeader() {
    String? imageUrl;
    if (_profileData!.profilePath != null && _profileData!.profilePath!.isNotEmpty) {
      imageUrl = _profileService.getPublicProfileImageUrl(_profileData!.profilePath!);
    }


    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _profileService.profilePathNotifier,
              builder: (context, livePath, _) {
                final currentPath = livePath ?? _profileData?.profilePath;
                final resolvedImageUrl = (currentPath != null && currentPath.isNotEmpty)
                    ? _profileService.getPublicProfileImageUrl(currentPath)
                    : imageUrl;
                return UserAvatar(
                  imageUrl: resolvedImageUrl,
                  radius: 50,
                  backgroundColor: context.appSurfaceVariant,
                  borderColor: context.appBorder,
                  iconColor: context.appTextDisabled,
                );
              },
            ),
            GestureDetector(
              key: const Key('change_avatar_button'),
              onTap: _isSaving ? null : _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: context.appOverlayText, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.appPrimaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            (_profileData!.role).toUpperCase(),
            style: TextStyle(
              color: context.appOnPrimaryContainer,
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
            color: context.appTextPrimary,
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
    TextInputType? keyboardType,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          focusNode: focusNode,
          style: TextStyle(color: context.appTextPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: context.appTextDisabled),
            suffixIcon: isSaved
                ? Icon(Icons.check_circle, color: context.appSuccess)
                : null,
            filled: true,
            fillColor: context.appSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    final l10n = AppLocalizations.of(context)!;
    final stats = _profileData!.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_stats_title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (!_isBuyer) ...[
          // Para el Agricultor: 3 estadísticas (Publicados, Negociando, Cerradas)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.profile_stat_published,
                  stats.published.toString(),
                  Icons.grass_outlined,
                  context.appInfo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.profile_stat_negotiating,
                  stats.negotiating.toString(),
                  Icons.handshake_outlined,
                  context.appWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.profile_stat_closed_farmer,
                  stats.closed.toString(),
                  Icons.check_circle_outline,
                  context.appSuccess,
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
                  l10n.profile_stat_negotiating,
                  stats.negotiating.toString(),
                  Icons.handshake_outlined,
                  context.appWarning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  l10n.profile_stat_closed_buyer,
                  stats.closed.toString(),
                  Icons.check_circle_outline,
                  context.appSuccess,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReputationSection() {
    final l10n = AppLocalizations.of(context)!;
    final summary = _reputation;
    final isLoading =
        _isLoadingReputation || (summary == null && !_reputationLoadFailed);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reputation_title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: context.appShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.reputation_loading,
                      style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                    ),
                  ],
                )
              : _reputationLoadFailed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.appError,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.reputation_load_error,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('profile_reputation_retry'),
                      onPressed: () => _loadReputation(_profileData!.id),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.market_retry),
                    ),
                  ],
                )
              : summary == null || summary.isNew
              ? Row(
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      color: context.appTextDisabled,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.reputation_no_ratings,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '★ ${summary.averageRating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.appWarning,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.reputation_average_label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      color: context.appDivider,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${summary.totalReviews}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.reputation_reviews_received,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: context.appShadow,
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
              color: context.appTextSecondary,
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
  }) {

    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appPrimaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.appOnPrimaryContainer),
        ),
        value: value,
        onChanged: _isSaving ? null : onChanged,
        activeThumbColor: context.appSurface,
        activeTrackColor: context.appPrimary,
        inactiveThumbColor: context.appTextDisabled,
        inactiveTrackColor: context.appBorder,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSwitchListTileInside({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {

    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: context.appTextPrimary),
      ),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeThumbColor: context.appSurface,
      activeTrackColor: context.appPrimary,
      inactiveThumbColor: context.appTextDisabled,
      inactiveTrackColor: context.appBorder,
    );
  }
}
