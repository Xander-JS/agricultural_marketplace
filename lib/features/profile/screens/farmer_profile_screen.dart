import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_preferences_service.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../../core/widgets/badges/status_badge.dart';
import '../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/cards/inset_group_section.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../core/widgets/feedback/status_banner.dart';
import '../../../core/widgets/inputs/app_segmented_control.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../models/farmer_profile_data.dart';
import '../services/profile_service.dart';
import '../../review/models/review_model.dart';
import '../../review/services/review_service.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/loading/section_skeletons.dart';

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
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();
  late final ReviewService _reviewService =
      widget.reviewService ?? ReviewService();
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
  String? _savingField;

  /// Anchor of the settings groups, reached from the navigation bar.
  final GlobalKey _settingsKey = GlobalKey();

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
      }
      if (mounted) setState(() {});
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkAndSaveField('phone', _phoneController.text.trim());
      } else {
        _phoneSaved = false;
      }
      if (mounted) setState(() {});
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
        throw Exception(
          'No hay usuario autenticado. (Modo prueba activo sin sesión)',
        );
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
        showAppSnackBar(
          context,
          '${l10n.profile_load_error}: $e',
          tone: StatusTone.error,
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

    setState(() {
      _isSaving = true;
      _savingField = field;
    });

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
        setState(() {
          _isSaving = false;
          _savingField = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingField = null;
        });
        final l10n = AppLocalizations.of(context)!;
        showAppSnackBar(
          context,
          l10n.profile_update_error(e.toString()),
          tone: StatusTone.error,
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
        showAppSnackBar(
          context,
          '${l10n.profile_save_settings_error}: $e',
          tone: StatusTone.error,
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
        showAppSnackBar(
          context,
          l10n.profile_updated_photo,
          tone: StatusTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showAppSnackBar(
          context,
          l10n.profile_photo_error(e.toString()),
          tone: StatusTone.error,
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
        // Two equal-width actions: the destructive one carries the color,
        // cancel stays quiet but just as easy to reach.
        const buttonSize = Size(0, AppDimensions.buttonHeightMedium);
        return AlertDialog(
          title: Text(
            l10n.profile_logout_confirm_title,
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n.profile_logout_confirm_desc,
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    child: Text(l10n.profile_cancel),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: buttonSize,
                      backgroundColor: dialogContext.appError,
                      foregroundColor: dialogContext.appOverlayText,
                    ),
                    child: Text(l10n.profile_logout),
                  ),
                ),
              ],
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
            await Supabase.instance.client.auth.signOut(
              scope: SignOutScope.local,
            );
          } catch (_) {}
        }
      }
    }
  }

  void _scrollToSettings() {
    final target = _settingsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: AppMotion.of(context, AppMotion.entrance),
      curve: AppMotion.easeInOut,
    );
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
        centerTitle: false,
        titleSpacing: AppDimensions.space16,
        title: const KusBrandLogo.compact(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space12),
            child: IconButton(
              icon: const Icon(
                LucideIcons.settings,
                size: AppDimensions.iconSM,
              ),
              onPressed: _profileData == null ? null : _scrollToSettings,
              tooltip: l10n.profile_settings_title,
              style: IconButton.styleFrom(
                foregroundColor: context.appTextPrimary,
                backgroundColor: context.appSurface,
                fixedSize: const Size.square(AppDimensions.minTouchTarget),
                shape: CircleBorder(side: BorderSide(color: context.appBorder)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const SectionSkeleton(
              kind: SectionSkeletonKind.profile,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: context.appPrimary,
              backgroundColor: context.appSurface,
              strokeWidth: 2.5,
              child: _profileData == null
                  ? ListView(
                      physics: AppMotion.scrollPhysics,
                      children: [
                        const SizedBox(height: AppDimensions.space48),
                        AppEmptyState(
                          icon: LucideIcons.cloudOff,
                          title: l10n.profile_no_data,
                          action: ElevatedButton.icon(
                            onPressed: _loadProfileData,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: Text(l10n.common_retry),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: AppMotion.scrollPhysics,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        40 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              screenTitle,
                              style: AppTextStyles.displayMedium.copyWith(
                                fontSize: 30,
                                color: context.appTextPrimary,
                              ),
                            ),
                          ),
                          _buildProfileHeader(l10n),
                          const SizedBox(height: AppDimensions.space32),
                          _buildStatisticsSection(l10n),
                          const SizedBox(height: AppDimensions.space32),
                          KeyedSubtree(
                            key: _settingsKey,
                            child: _buildContactSection(l10n),
                          ),
                          if (!_isBuyer) ...[
                            const SizedBox(height: AppDimensions.space24),
                            _buildNegotiationSections(l10n),
                          ],
                          const SizedBox(height: AppDimensions.space24),
                          _buildPreferencesSection(l10n),
                          const SizedBox(height: AppDimensions.space32),
                          InsetGroupSection(
                            children: [
                              InsetGroupRow(
                                title: l10n.profile_logout,
                                destructive: true,
                                destructiveIcon: LucideIcons.logOut,
                                onTap: _handleLogout,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  /// Apple ID-style identity card: avatar inside the verified ring, name,
  /// role and verification, then the user's reputation.
  Widget _buildProfileHeader(AppLocalizations l10n) {
    String? imageUrl;
    if (_profileData!.profilePath != null &&
        _profileData!.profilePath!.isNotEmpty) {
      imageUrl = _profileService.getPublicProfileImageUrl(
        _profileData!.profilePath!,
      );
    }

    final roleTriad = _isBuyer ? context.appInfoTriad : context.appBrandTriad;

    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Verified ring: brand hairline, a gap of surface, then
                      // the photo.
                      Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.appPrimary,
                            width: AppDimensions.borderWidthThick,
                          ),
                        ),
                        child: ValueListenableBuilder<String?>(
                          valueListenable: _profileService.profilePathNotifier,
                          builder: (context, livePath, _) {
                            final currentPath =
                                livePath ?? _profileData?.profilePath;
                            final resolvedImageUrl =
                                (currentPath != null && currentPath.isNotEmpty)
                                ? _profileService.getPublicProfileImageUrl(
                                    currentPath,
                                  )
                                : imageUrl;
                            return UserAvatar(
                              imageUrl: resolvedImageUrl,
                              radius: 50,
                              backgroundColor: context.appSurfaceVariant,
                              borderColor: AppColors.transparent,
                              borderWidth: 0,
                              iconColor: context.appTextMuted,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Semantics(
                          button: true,
                          label: l10n.profile_change_photo,
                          child: PressableScale(
                            enabled: !_isSaving,
                            child: GestureDetector(
                              key: const Key('change_avatar_button'),
                              onTap: _isSaving ? null : _pickAndUploadImage,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: context.appPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.appSurface,
                                    width: 3,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _isSaving && _savingField == null
                                    ? CupertinoActivityIndicator(
                                        radius: 7,
                                        color: context.appOnPrimary,
                                      )
                                    : Icon(
                                        LucideIcons.camera,
                                        size: 16,
                                        color: context.appOnPrimary,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  _profileData!.fullName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppDimensions.space8,
                  runSpacing: AppDimensions.space8,
                  children: [
                    StatusBadge(
                      text: _profileData!.role.toUpperCase(),
                      icon: _isBuyer
                          ? LucideIcons.briefcaseBusiness
                          : LucideIcons.sprout,
                      backgroundColor: roleTriad.background,
                      textColor: roleTriad.text,
                      borderColor: roleTriad.border,
                    ),
                    StatusBadge(
                      text: l10n.profile_verified_badge,
                      icon: LucideIcons.badgeCheck,
                      backgroundColor: AppColors.successBgLight,
                      textColor: AppColors.successFgLight,
                      tone: StatusBadgeTone.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.appDivider),
          _buildReputationSection(l10n),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(AppLocalizations l10n) {
    final stats = _profileData!.stats;

    final tiles = <Widget>[
      // Para el Agricultor: 3 estadísticas (Publicados, Negociando, Cerradas);
      // para el Comerciante ÚNICAMENTE 2 (Negociando, Cerrados).
      if (!_isBuyer)
        _StatTile(
          icon: LucideIcons.sprout,
          label: l10n.profile_stat_published,
          value: stats.published.toString(),
        ),
      _StatTile(
        icon: LucideIcons.arrowLeftRight,
        label: l10n.profile_stat_negotiating,
        value: stats.negotiating.toString(),
      ),
      _StatTile(
        icon: LucideIcons.handshake,
        label: _isBuyer
            ? l10n.profile_stat_closed_buyer
            : l10n.profile_stat_closed_farmer,
        value: stats.closed.toString(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            l10n.profile_stats_title,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppDimensions.space8),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReputationSection(AppLocalizations l10n) {
    final summary = _reputation;
    final isLoading =
        _isLoadingReputation || (summary == null && !_reputationLoadFailed);

    final Widget content;
    if (isLoading) {
      content = Row(
        children: [
          const CupertinoActivityIndicator(radius: 8),
          const SizedBox(width: 10),
          Text(
            l10n.reputation_loading,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      );
    } else if (_reputationLoadFailed) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                color: context.appError,
                size: AppDimensions.iconSM,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  l10n.reputation_load_error,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appErrorText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          SecondaryActionButton(
            key: const ValueKey('profile_reputation_retry'),
            onPressed: () => _loadReputation(_profileData!.id),
            text: l10n.market_retry,
            icon: LucideIcons.refreshCw,
            height: AppDimensions.minTouchTarget,
          ),
        ],
      );
    } else if (summary == null || summary.isNew) {
      content = Row(
        children: [
          Icon(
            CupertinoIcons.star,
            color: context.appTextMuted,
            size: AppDimensions.iconMD,
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              l10n.reputation_no_ratings,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appTextSecondary,
              ),
            ),
          ),
        ],
      );
    } else {
      Widget figure(String value, String label, {bool rated = false}) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (rated)
                    TextSpan(
                      text: '★ ',
                      style: TextStyle(color: context.appRatingGold),
                    ),
                  TextSpan(text: value),
                ],
              ),
              style: AppTextStyles.figureLarge.copyWith(
                fontSize: 26,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ],
        );
      }

      content = IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: figure(
                summary.averageRating.toStringAsFixed(1),
                l10n.reputation_average_label,
                rated: true,
              ),
            ),
            VerticalDivider(width: 32, color: context.appDivider),
            Expanded(
              child: figure(
                '${summary.totalReviews}',
                l10n.reputation_reviews_received,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reputation_title,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations l10n) {
    return InsetGroupSection(
      header: l10n.profile_contact_info,
      footer: l10n.profile_contact_autosave,
      children: [
        _EditableContactRow(
          icon: LucideIcons.mail,
          triad: context.appIconTriad,
          label: l10n.profile_email,
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          isSaving: _savingField == 'email',
          isSaved: _emailSaved,
        ),
        _EditableContactRow(
          icon: LucideIcons.phone,
          triad: context.appIconTriad,
          label: l10n.profile_phone,
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          keyboardType: TextInputType.phone,
          isSaving: _savingField == 'phone',
          isSaved: _phoneSaved,
        ),
      ],
    );
  }

  /// Preferencias comerciales: EXCLUSIVAS DEL AGRICULTOR.
  Widget _buildNegotiationSections(AppLocalizations l10n) {
    final settings = _profileData!.settings;

    Widget toggle(bool value, ValueChanged<bool> onChanged) => CupertinoSwitch(
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeTrackColor: context.appPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetGroupSection(
          header: l10n.profile_negotiation_options,
          children: [
            InsetGroupRow(
              leading: IconSquircle(
                icon: LucideIcons.calendarClock,
                triad: context.appIconTriad,
                size: 30,
              ),
              title: l10n.profile_enable_early_sale,
              trailing: toggle(settings.enableEarlySale, (val) {
                _updateSettings(
                  FarmerSettingsData(
                    enableEarlySale: val,
                    sharePhone: settings.sharePhone,
                    shareLocation: settings.shareLocation,
                    shareWhatsapp: settings.shareWhatsapp,
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space24),
        InsetGroupSection(
          header: l10n.profile_visibility_negotiation,
          children: [
            InsetGroupRow(
              leading: IconSquircle(
                icon: LucideIcons.phone,
                triad: context.appIconTriad,
                size: 30,
              ),
              title: l10n.profile_visibility_phone,
              trailing: toggle(settings.sharePhone, (val) {
                _updateSettings(
                  FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: val,
                    shareLocation: settings.shareLocation,
                    shareWhatsapp: settings.shareWhatsapp,
                  ),
                );
              }),
            ),
            InsetGroupRow(
              leading: IconSquircle(
                icon: LucideIcons.messageCircle,
                triad: context.appIconTriad,
                size: 30,
              ),
              title: l10n.profile_visibility_whatsapp,
              trailing: toggle(settings.shareWhatsapp, (val) {
                _updateSettings(
                  FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: settings.sharePhone,
                    shareLocation: settings.shareLocation,
                    shareWhatsapp: val,
                  ),
                );
              }),
            ),
            InsetGroupRow(
              leading: IconSquircle(
                icon: LucideIcons.mapPin,
                triad: context.appIconTriad,
                size: 30,
              ),
              title: l10n.profile_visibility_location,
              trailing: toggle(settings.shareLocation, (val) {
                _updateSettings(
                  FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: settings.sharePhone,
                    shareLocation: val,
                    shareWhatsapp: settings.shareWhatsapp,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  /// Apariencia e idioma: común para ambos roles. Cada control aplica el
  /// cambio al instante en toda la app.
  Widget _buildPreferencesSection(AppLocalizations l10n) {
    return InsetGroupSection(
      header: l10n.profile_accessibility,
      children: [
        InsetGroupRow(
          leading: IconSquircle(
            icon: _isDarkMode ? LucideIcons.moon : LucideIcons.sun,
            triad: context.appIconTriad,
            size: 30,
          ),
          title: l10n.profile_appearance,
          trailing: AppSegmentedControl<bool>(
            compact: true,
            value: _isDarkMode,
            onChanged: (val) async {
              setState(() {
                _isDarkMode = val;
              });
              await AppPreferencesService.instance.toggleDarkMode(val);
            },
            segments: {
              false: AppSegment(label: l10n.profile_theme_light),
              true: AppSegment(label: l10n.profile_theme_dark),
            },
          ),
        ),
        InsetGroupRow(
          leading: IconSquircle(
            icon: LucideIcons.globe,
            triad: context.appIconTriad,
            size: 30,
          ),
          title: l10n.profile_language,
          trailing: AppSegmentedControl<bool>(
            compact: true,
            value: _isEnglish,
            onChanged: (val) async {
              setState(() {
                _isEnglish = val;
              });
              await AppPreferencesService.instance.toggleEnglish(val);
            },
            segments: {
              false: AppSegment(label: l10n.profile_language_es),
              true: AppSegment(label: l10n.profile_language_en),
            },
          ),
        ),
      ],
    );
  }
}

/// One commercial counter: a small mark and label over the figure.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.appTextSecondary),
          const SizedBox(height: AppDimensions.space12),
          Text(
            value,
            style: AppTextStyles.figureLarge.copyWith(
              fontSize: 26,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contact detail edited in place, the way iOS edits a contact field. The
/// value saves when the field loses focus; the trailing mark reports it.
class _EditableContactRow extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad triad;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final bool isSaving;
  final bool isSaved;

  const _EditableContactRow({
    required this.icon,
    required this.triad,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.keyboardType,
    required this.isSaving,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (isSaving) {
      trailing = const CupertinoActivityIndicator(
        key: ValueKey('saving'),
        radius: 8,
      );
    } else if (isSaved) {
      trailing = Icon(
        LucideIcons.circleCheck,
        key: const ValueKey('saved'),
        size: 18,
        color: context.appSuccess,
      );
    } else if (!focusNode.hasFocus) {
      trailing = Icon(
        LucideIcons.squarePen,
        key: const ValueKey('editable'),
        size: 16,
        color: context.appTextMuted,
      );
    } else {
      trailing = const SizedBox(key: ValueKey('editing'), width: 18);
    }

    return InkWell(
      onTap: focusNode.requestFocus,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            IconSquircle(icon: icon, triad: triad, size: 30),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.only(top: 2, bottom: 2),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
