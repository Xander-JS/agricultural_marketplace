import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/avatars/user_avatar.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../../core/widgets/loading/app_skeleton.dart';
import '../../../../core/widgets/misc/pressable_scale.dart';
import '../models/moderation_request.dart';
import '../services/moderation_service.dart';
import '../widgets/verification_status_badge.dart';
import 'moderation_detail_screen.dart';

/// Pantalla que presenta la cola de solicitudes de verificación pendientes
/// para moderadores autorizados.
class ModerationQueueScreen extends StatefulWidget {
  final ModerationService? moderationService;
  final VoidCallback? onSignOut;
  final bool? isModeratorOverride;

  const ModerationQueueScreen({
    super.key,
    this.moderationService,
    this.onSignOut,
    this.isModeratorOverride,
  });

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  late ModerationService _service;
  bool _isLoading = true;
  bool _isAuthorized = true;
  String? _errorMessage;
  List<ModerationRequest> _requests = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _service = widget.moderationService ?? ModerationService();
    _checkAuthorizationAndLoad();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.isModeratorOverride != null) {
      _isAuthorized = widget.isModeratorOverride!;
    } else {
      _isAuthorized = await _service.isCurrentUserModerator();
    }

    if (!_isAuthorized) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    await _loadRequests();
  }

  Future<void> _loadRequests({String? filter}) async {
    final statusFilter = filter ?? _statusFilter;
    try {
      final items = await _service.fetchPendingRequests(
        statusFilter: statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _requests = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _handleRequestUpdated(ModerationRequest updated) {
    setState(() {
      final index = _requests.indexWhere((r) => r.id == updated.id);
      if (index >= 0) {
        if (!updated.isPending) {
          // Si ya no es pendiente, remover de la cola activa
          _requests.removeAt(index);
        } else {
          // Si hay filtro activo y el nuevo estado no coincide con el filtro, remover
          if (_statusFilter != null &&
              updated.status.toDbValue() != _statusFilter) {
            _requests.removeAt(index);
          } else {
            _requests[index] = updated;
          }
        }
      }
    });
  }

  Future<void> _openRequest(ModerationRequest req) async {
    final updated = await Navigator.of(context).push<ModerationRequest?>(
      MaterialPageRoute(
        builder: (ctx) => ModerationDetailScreen(
          request: req,
          moderationService: _service,
          onRequestUpdated: _handleRequestUpdated,
        ),
      ),
    );
    if (updated != null) {
      _handleRequestUpdated(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showList = _isAuthorized && !_isLoading && _errorMessage == null;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QueueHeader(
              title: l10n.moderation_queue_title,
              subtitle: showList
                  ? l10n.moderation_queue_count(_requests.length)
                  : null,
              actions: [
                if (_isAuthorized)
                  _HeaderAction(
                    tooltip: l10n.moderation_queue_refresh,
                    icon: LucideIcons.refreshCw,
                    onPressed: _isLoading ? null : () => _loadRequests(),
                  ),
                if (widget.onSignOut != null)
                  _HeaderAction(
                    tooltip: l10n.profile_logout,
                    icon: LucideIcons.logOut,
                    onPressed: widget.onSignOut,
                  ),
              ],
            ),
            if (_isAuthorized && _errorMessage == null)
              _buildFilterBar(context, l10n),
            // States swap instantly: moderators open this screen many
            // times a day, so a crossfade would only slow them down.
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 1. Caso de rol no autorizado
    if (!_isAuthorized) {
      return _QueueMessage(
        icon: Icons.gpp_bad_outlined,
        triad: context.appErrorTriad,
        title: l10n.moderation_unauthorized_title,
        description: l10n.moderation_unauthorized_desc,
        action: widget.onSignOut == null
            ? null
            : SecondaryActionButton(
                onPressed: widget.onSignOut,
                text: l10n.profile_logout,
                icon: LucideIcons.logOut,
              ),
      );
    }

    // 2. Estado de carga: esqueletos con la forma real de las tarjetas
    if (_isLoading) {
      return const _QueueSkeleton();
    }

    // 3. Estado de error
    if (_errorMessage != null) {
      return _QueueMessage(
        icon: Icons.error_outline,
        triad: context.appErrorTriad,
        title: l10n.verification_status_error_title,
        description: _errorMessage!,
        action: SecondaryActionButton(
          onPressed: _checkAuthorizationAndLoad,
          text: l10n.common_retry,
          icon: LucideIcons.refreshCw,
        ),
      );
    }

    // 4. Cola vacía (sigue permitiendo deslizar para actualizar)
    if (_requests.isEmpty) {
      return RefreshIndicator(
        color: context.appPrimary,
        backgroundColor: context.appSurface,
        onRefresh: () => _loadRequests(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _QueueMessage(
                icon: Icons.inbox_outlined,
                triad: context.appNeutralTriad,
                title: l10n.moderation_queue_empty_title,
                description: l10n.moderation_queue_empty_desc,
              ),
            ),
          ),
        ),
      );
    }

    // 5. Lista de solicitudes
    return RefreshIndicator(
      color: context.appPrimary,
      backgroundColor: context.appSurface,
      onRefresh: () => _loadRequests(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.space16,
          AppDimensions.space8,
          AppDimensions.space16,
          AppDimensions.space24 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: _requests.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppDimensions.space12),
        itemBuilder: (ctx, index) {
          final req = _requests[index];
          return _RequestCard(
            key: ValueKey('moderation_queue_card_${req.id}'),
            request: req,
            statusBadge: _buildStatusChip(req.status, req.id),
            onTap: () => _openRequest(req),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppLocalizations l10n) {
    Widget segment(String key, String label) => Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelMedium.copyWith(
          color: context.appTextPrimary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        0,
        AppDimensions.space16,
        AppDimensions.space8,
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _statusFilter ?? _filterAll,
        backgroundColor: context.appSurfaceVariant,
        thumbColor: context.appSurface,
        padding: const EdgeInsets.all(3),
        onValueChanged: (value) {
          final newFilter = value == null || value == _filterAll ? null : value;
          if (newFilter == _statusFilter) return;
          setState(() => _statusFilter = newFilter);
          _loadRequests(filter: newFilter);
        },
        children: {
          _filterAll: segment(
            'moderation_filter_all',
            l10n.moderation_filter_all,
          ),
          'pendiente': segment(
            'moderation_filter_pending',
            l10n.moderation_filter_pending,
          ),
          'en_revision_ia': segment(
            'moderation_filter_in_review',
            l10n.moderation_filter_in_review,
          ),
        },
      ),
    );
  }

  static const String _filterAll = 'all';

  Widget _buildStatusChip(UserVerificationStatus status, String id) {
    return verificationStatusBadge(
      context,
      status,
      key: ValueKey('moderation_queue_item_status_$id'),
    );
  }
}

/// Large-title header with the queue size and the screen's two actions.
class _QueueHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const _QueueHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        AppDimensions.space12,
        AppDimensions.space12,
        AppDimensions.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KusBrandLogo.compact(),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  title,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.standard),
                  child: subtitle == null
                      ? const SizedBox(height: 20)
                      : Text(
                          subtitle!,
                          key: ValueKey(subtitle),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.appTextSecondary,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                ),
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: AppDimensions.space8),
            action,
          ],
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppDimensions.iconSM),
      style: IconButton.styleFrom(
        foregroundColor: context.appTextPrimary,
        backgroundColor: context.appSurface,
        fixedSize: const Size.square(AppDimensions.minTouchTarget),
        shape: CircleBorder(side: BorderSide(color: context.appBorder)),
      ),
    );
  }
}

/// One verification request: who, which role, when, and where it stands.
class _RequestCard extends StatelessWidget {
  final ModerationRequest request;
  final Widget statusBadge;
  final VoidCallback onTap;

  const _RequestCard({
    super.key,
    required this.request,
    required this.statusBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = request.userRole == UserRole.comprador;
    final roleTriad = isBuyer ? context.appInfoTriad : context.appBrandTriad;

    return PressableScale(
      child: Material(
        color: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          side: BorderSide(color: context.appBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space16,
            ),
            child: Row(
              children: [
                UserAvatar(radius: 22),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          statusBadge,
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleTriad.background,
                              borderRadius: AppDimensions.borderRadiusSM,
                              border: Border.all(color: roleTriad.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBuyer
                                      ? LucideIcons.briefcaseBusiness
                                      : LucideIcons.sprout,
                                  size: 12,
                                  color: roleTriad.foreground,
                                ),
                                const SizedBox(width: AppDimensions.space4),
                                Text(
                                  request.userRole.displayName,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: roleTriad.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Flexible(
                            child: Text(
                              request.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.appTextSecondary,
                                fontFeatures: AppTextStyles.tabularFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        formatModerationDate(context, request.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: context.appTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered state message (unauthorized, error, empty).
class _QueueMessage extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad triad;
  final String title;
  final String description;
  final Widget? action;

  const _QueueMessage({
    required this.icon,
    required this.triad,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: triad.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: triad.border),
                ),
                child: Icon(icon, size: 34, color: triad.foreground),
              ),
              const SizedBox(height: AppDimensions.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AppDimensions.space24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmering stand-ins at the real size of request cards.
class _QueueSkeleton extends StatelessWidget {
  const _QueueSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget card() => Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: context.appBorder),
      ),
      child: const Row(
        children: [
          AppSkeletonBlock.circle(size: 44),
          SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppSkeletonBlock(width: 140, height: 14),
                    Spacer(),
                    AppSkeletonBlock(
                      width: 72,
                      height: 22,
                      radius: AppDimensions.radiusFull,
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.space12),
                AppSkeletonBlock(width: 168, height: 10),
                SizedBox(height: AppDimensions.space8),
                AppSkeletonBlock(width: 96, height: 10),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: l10n?.loading_skeleton_semantics,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space16,
          AppDimensions.space8,
          AppDimensions.space16,
          AppDimensions.space24,
        ),
        itemCount: 4,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.space12),
        itemBuilder: (_, _) => AppShimmer(child: card()),
      ),
    );
  }
}
