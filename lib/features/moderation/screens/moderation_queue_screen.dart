import 'package:flutter/material.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/moderation_request.dart';
import '../services/moderation_service.dart';
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

  Future<void> _loadRequests() async {
    try {
      final items = await _service.fetchPendingRequests();
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
          _requests[index] = updated;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.moderation_queue_title ?? 'Cola de Moderación'),
        actions: [
          IconButton(
            tooltip: l10n?.verification_status_update_status ?? 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRequests,
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: l10n?.profile_logout ?? 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: widget.onSignOut,
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 1. Caso de rol no autorizado
    if (!_isAuthorized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_outlined, size: 72, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                l10n?.moderation_unauthorized_title ?? 'Acceso No Autorizado',
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.moderation_unauthorized_desc ??
                    'Tu cuenta no posee privilegios de moderación para acceder a esta consola.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (widget.onSignOut != null)
                ElevatedButton(
                  onPressed: widget.onSignOut,
                  child: Text(l10n?.profile_logout ?? 'Cerrar sesión'),
                ),
            ],
          ),
        ),
      );
    }

    // 2. Estado de Carga
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. Estado de Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                l10n?.verification_status_error_title ?? 'Error al cargar solicitudes',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkAuthorizationAndLoad,
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.verification_status_retry ?? 'Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Estado de Cola Vacía
    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 72, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.moderation_queue_empty_title ?? 'No hay solicitudes pendientes',
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.moderation_queue_empty_desc ??
                            'Todas las solicitudes de verificación han sido resueltas o no hay envíos pendientes.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 5. Lista de Solicitudes
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (ctx, index) {
          final req = _requests[index];
          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: req.userRole == UserRole.comprador
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                child: Icon(
                  req.userRole == UserRole.comprador ? Icons.shopping_bag_outlined : Icons.spa_outlined,
                  color: req.userRole == UserRole.comprador ? Colors.blue[800] : Colors.green[800],
                ),
              ),
              title: Text(
                req.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          req.userRole.displayName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(req.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    req.createdAt.toLocal().toString().split('.')[0],
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
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
              },
            ),
          );
        },
      ),
    );
  }
}
