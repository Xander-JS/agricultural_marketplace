import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_indicator.dart';
import '../login/screens/login_screen.dart';
import '../recovery/screens/reset_password_screen.dart';
import '../recovery/services/recovery_service.dart';
import '../verificacion/screens/verification_status_screen.dart';
import '../verificacion/services/verification_service.dart';
import '../../dashboard/screens/main_dashboard_screen.dart';
import '../../moderation/screens/moderation_queue_screen.dart';
import '../../moderation/services/moderation_service.dart';

enum _AuthGateStatus {
  initialLoading,
  loading,
  unauthenticated,
  authenticatedApproved,
  authenticatedPendingVerification,
  passwordRecovery,
  profileNotFound,
  networkError,
  recoverableError,
}

/// Guardián central de autenticación y navegación reactiva.
///
/// Coordina la sesión persistida (`currentSession`) y el stream (`onAuthStateChange`),
/// resolviendo de forma atómica el rol y estado de verificación del usuario.
///
/// Protegido contra condiciones de carrera mediante epoch token y con soporte
/// para inyección de dependencias para pruebas deterministas.
class AuthGate extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final Stream<AuthState>? authStateStream;
  final Future<Map<String, dynamic>?> Function(String userId)? profileFetcher;
  final Session? initialSession;
  final bool enableAutoPolling;
  final RecoveryService? recoveryService;
  final ModerationService? moderationService;
  final Future<AuthResponse> Function()? sessionRefresher;

  const AuthGate({
    super.key,
    this.supabaseClient,
    this.authStateStream,
    this.profileFetcher,
    this.initialSession,
    this.enableAutoPolling = true,
    this.recoveryService,
    this.moderationService,
    this.sessionRefresher,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _AuthGateStatus _status = _AuthGateStatus.initialLoading;
  String? _activeUserId;
  String? _role;
  VerificationStatusData? _verificationData;
  String? _errorMessage;

  int _resolutionEpoch = 0;
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient? get _client {
    if (widget.supabaseClient != null) return widget.supabaseClient;
    if (Supabase.instance.isInitialized) return Supabase.instance.client;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _evaluateInitialSession();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    final stream = widget.authStateStream ?? _client?.auth.onAuthStateChange;
    if (stream != null) {
      _authSubscription = stream.listen(_handleAuthStateChange);
    }
  }

  void _evaluateInitialSession() {
    final session = widget.initialSession ?? _client?.auth.currentSession;
    if (session != null) {
      _activeUserId = session.user.id;
      _status = _AuthGateStatus.loading;
      _resolveProfile(session.user.id, ++_resolutionEpoch);
    } else {
      _status = _AuthGateStatus.initialLoading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _status == _AuthGateStatus.initialLoading) {
          final lateSession =
              widget.initialSession ?? _client?.auth.currentSession;
          if (lateSession == null) {
            setState(() {
              _status = _AuthGateStatus.unauthenticated;
            });
          } else {
            _activeUserId = lateSession.user.id;
            _resolveProfile(lateSession.user.id, ++_resolutionEpoch);
          }
        }
      });
    }
  }

  void _handleAuthStateChange(AuthState data) {
    final event = data.event;
    final session = data.session;

    switch (event) {
      case AuthChangeEvent.initialSession:
        if (session != null) {
          if (_activeUserId != session.user.id ||
              _status != _AuthGateStatus.authenticatedApproved) {
            _activeUserId = session.user.id;
            _resolveProfile(session.user.id, ++_resolutionEpoch);
          }
        } else {
          if (_activeUserId == null && widget.initialSession == null) {
            if (mounted) {
              setState(() {
                _status = _AuthGateStatus.unauthenticated;
                _activeUserId = null;
              });
            }
          }
        }
        break;

      case AuthChangeEvent.signedIn:
        if (session != null) {
          if (_activeUserId != session.user.id ||
              _status != _AuthGateStatus.authenticatedApproved) {
            _activeUserId = session.user.id;
            _resolveProfile(session.user.id, ++_resolutionEpoch);
          }
        }
        break;

      case AuthChangeEvent.signedOut:
      // ignore: deprecated_member_use
      case AuthChangeEvent.userDeleted:
        _resolutionEpoch++;
        _activeUserId = null;
        if (mounted) {
          setState(() {
            _status = _AuthGateStatus.unauthenticated;
            _role = null;
            _verificationData = null;
            _errorMessage = null;
          });
        }
        break;

      case AuthChangeEvent.tokenRefreshed:
        // Operación pasiva: el token fue renovado en memoria/storage.
        // NO se re-consulta la base de datos ni se reconstruye la navegación.
        break;

      case AuthChangeEvent.userUpdated:
        if (_status != _AuthGateStatus.passwordRecovery && session != null) {
          _activeUserId = session.user.id;
          _resolveProfile(session.user.id, ++_resolutionEpoch);
        }
        break;

      case AuthChangeEvent.passwordRecovery:
        if (session != null) {
          _activeUserId = session.user.id;
          if (mounted) {
            setState(() {
              _status = _AuthGateStatus.passwordRecovery;
            });
          }
        }
        break;

      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
  }

  Future<Map<String, dynamic>?> _defaultProfileFetcher(String userId) async {
    final client = _client;
    if (client == null) return null;

    final res = await client
        .from('profiles')
        .select('role, verification_status')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return null;

    try {
      final attempt = await client
          .from('verification_attempts')
          .select(
            'status, rejection_reason, document_front_path, document_back_path, selfie_path',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (attempt != null) {
        res['has_verification_attempt'] = true;
        res['has_all_documents'] = [
          attempt['document_front_path'],
          attempt['document_back_path'],
          attempt['selfie_path'],
        ].every((path) => path is String && path.trim().isNotEmpty);
        if (attempt['rejection_reason'] != null) {
          res['rejection_reason'] = attempt['rejection_reason'];
        }
      }
    } catch (_) {
      // La pantalla de verificación puede reintentar la consulta sin bloquear
      // la resolución del perfil.
    }

    return res;
  }

  Future<AuthResponse> _refreshSession() async {
    if (widget.sessionRefresher != null) {
      return await widget.sessionRefresher!();
    }
    final client = _client;
    if (client != null) {
      return await client.auth.refreshSession();
    }
    throw const AuthException('No active SupabaseClient for refreshSession');
  }

  Future<bool> _handleAuthOrExpiredError(String userId, int epoch) async {
    try {
      final refreshRes = await _refreshSession();
      if (!mounted || epoch != _resolutionEpoch) return true;

      if (refreshRes.session != null) {
        await _resolveProfile(userId, epoch);
        return true;
      } else {
        await _handleSignOut();
        return true;
      }
    } on AuthException catch (_) {
      if (!mounted || epoch != _resolutionEpoch) return true;
      await _handleSignOut();
      return true;
    } catch (refreshErr) {
      if (!mounted || epoch != _resolutionEpoch) return true;

      final refreshErrStr = refreshErr.toString();
      final isNetwork =
          refreshErr is SocketException ||
          refreshErrStr.contains('SocketException') ||
          refreshErrStr.contains('ClientException') ||
          refreshErrStr.contains('Network') ||
          refreshErrStr.contains('TimeoutException') ||
          refreshErrStr.contains('Failed host lookup');

      if (isNetwork) {
        setState(() {
          _status = _AuthGateStatus.networkError;
          _errorMessage = refreshErrStr;
        });
        return true;
      } else {
        await _handleSignOut();
        return true;
      }
    }
  }

  Future<void> _resolveProfile(String userId, int epoch) async {
    if (mounted) {
      setState(() {
        _status = _AuthGateStatus.loading;
        _errorMessage = null;
        _role = null;
        _verificationData = null;
      });
    }

    try {
      final fetcher = widget.profileFetcher ?? _defaultProfileFetcher;
      final profile = await fetcher(userId);

      // Verificación de concurrencia: si el epoch cambió durante la consulta, descartar
      if (!mounted || epoch != _resolutionEpoch) return;

      if (profile == null) {
        setState(() {
          _status = _AuthGateStatus.profileNotFound;
        });
        return;
      }

      final rawStatus = profile['verification_status'] as String?;
      final rawRole = profile['role'] as String?;

      final parsedRole = UserRole.tryParse(rawRole);
      if (parsedRole == null) {
        setState(() {
          _status = _AuthGateStatus.recoverableError;
          _errorMessage = 'El rol del perfil no es válido o no está definido.';
        });
        return;
      }

      final verificationStatus = UserVerificationStatus.fromString(rawStatus);
      final role = parsedRole.toDbValue();

      if (verificationStatus.isApproved) {
        setState(() {
          _status = _AuthGateStatus.authenticatedApproved;
          _role = role;
        });
      } else {
        setState(() {
          _status = _AuthGateStatus.authenticatedPendingVerification;
          _role = role;
          _verificationData = VerificationStatusData(
            status: verificationStatus.toDbValue(),
            role: role,
            rejectionReason: profile['rejection_reason'] as String?,
            hasVerificationAttempt: profile['has_verification_attempt'] == true,
            hasAllDocuments: profile['has_all_documents'] == true,
          );
        });
      }
    } on PostgrestException catch (e) {
      if (!mounted || epoch != _resolutionEpoch) return;

      final isAuthOrExpired =
          e.code == '28000' ||
          e.code == 'PGRST301' ||
          e.code == '401' ||
          e.message.toLowerCase().contains('jwt') ||
          e.message.toLowerCase().contains('token') ||
          e.message.toLowerCase().contains('unauthorized');

      if (isAuthOrExpired) {
        final handled = await _handleAuthOrExpiredError(userId, epoch);
        if (handled) return;
      }

      if (!mounted || epoch != _resolutionEpoch) return;
      setState(() {
        _status = _AuthGateStatus.recoverableError;
        _errorMessage = e.message;
      });
    } on AuthException catch (e) {
      if (!mounted || epoch != _resolutionEpoch) return;

      final errStr = e.toString().toLowerCase();
      final isAuthOrExpired =
          e.statusCode == '401' ||
          errStr.contains('jwt') ||
          errStr.contains('token') ||
          errStr.contains('unauthorized') ||
          errStr.contains('invalid_grant') ||
          errStr.contains('session');

      if (isAuthOrExpired) {
        final handled = await _handleAuthOrExpiredError(userId, epoch);
        if (handled) return;
      }

      if (!mounted || epoch != _resolutionEpoch) return;
      setState(() {
        _status = _AuthGateStatus.recoverableError;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted || epoch != _resolutionEpoch) return;

      final errStr = e.toString();
      final errLower = errStr.toLowerCase();

      final isNetwork =
          e is SocketException ||
          errStr.contains('SocketException') ||
          errStr.contains('ClientException') ||
          errStr.contains('Network') ||
          errStr.contains('TimeoutException') ||
          errStr.contains('Failed host lookup');

      if (isNetwork) {
        setState(() {
          _status = _AuthGateStatus.networkError;
          _errorMessage = errStr;
        });
        return;
      }

      final isAuthOrExpired =
          errLower.contains('jwt expired') ||
          errLower.contains('token is expired') ||
          errLower.contains('pgrst301') ||
          errLower.contains('28000');

      if (isAuthOrExpired) {
        final handled = await _handleAuthOrExpiredError(userId, epoch);
        if (handled) return;
      }

      if (!mounted || epoch != _resolutionEpoch) return;
      setState(() {
        _status = _AuthGateStatus.recoverableError;
        _errorMessage = errStr;
      });
    }
  }

  void _retryResolution() {
    if (_activeUserId != null) {
      _resolveProfile(_activeUserId!, ++_resolutionEpoch);
    } else {
      final session = widget.initialSession ?? _client?.auth.currentSession;
      if (session != null) {
        _activeUserId = session.user.id;
        _resolveProfile(session.user.id, ++_resolutionEpoch);
      } else {
        if (mounted) {
          setState(() {
            _status = _AuthGateStatus.unauthenticated;
          });
        }
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (mounted) {
      setState(() {
        _status = _AuthGateStatus.unauthenticated;
        _activeUserId = null;
        _role = null;
        _verificationData = null;
        _errorMessage = null;
      });
    }
    try {
      final client = _client;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (_) {
      try {
        final client = _client;
        if (client != null) {
          await client.auth.signOut(scope: SignOutScope.local);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _AuthGateStatus.initialLoading:
      case _AuthGateStatus.loading:
        return _buildLoadingView(context);

      case _AuthGateStatus.unauthenticated:
        return LoginScreen(recoveryService: widget.recoveryService);

      case _AuthGateStatus.passwordRecovery:
        return ResetPasswordScreen(
          recoveryService: widget.recoveryService,
          onPasswordUpdated: () async {
            await _handleSignOut();
          },
          onCancel: () async {
            await _handleSignOut();
          },
        );

      case _AuthGateStatus.authenticatedApproved:
        if (UserRole.fromString(_role) == UserRole.moderador) {
          return ModerationQueueScreen(
            moderationService: widget.moderationService,
            onSignOut: _handleSignOut,
          );
        }
        return MainDashboardScreen(
          role: _role ?? 'agricultor',
          onSignOut: _handleSignOut,
        );

      case _AuthGateStatus.authenticatedPendingVerification:
        return VerificationStatusScreen(
          initialData: _verificationData,
          onVerificationApproved: (data) {
            if (mounted) {
              setState(() {
                _status = _AuthGateStatus.authenticatedApproved;
                _role = data.role ?? _role ?? 'agricultor';
              });
            }
          },
          onSignOut: _handleSignOut,
          enableAutoPolling: widget.enableAutoPolling,
        );

      case _AuthGateStatus.networkError:
        return _buildNetworkErrorView(context);

      case _AuthGateStatus.profileNotFound:
        return _buildProfileNotFoundView(context);

      case _AuthGateStatus.recoverableError:
        return _buildRecoverableErrorView(context);
    }
  }

  Widget _buildLoadingView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppLoading(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicator(isSpinning: true),
          const SizedBox(height: 32),
          Text(
            l10n?.verification_status_checking ?? 'Consultando estado...',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkErrorView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppLoading(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.error, size: 80),
          const SizedBox(height: 24),
          Text(
            l10n?.verification_status_error_title ?? 'Ha ocurrido un error',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.verification_status_unknown_desc ?? 'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _retryResolution,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n?.verification_status_retry ?? 'Reintentar'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              l10n?.profile_logout ?? 'Cerrar sesión',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNotFoundView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppLoading(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_outlined, color: Colors.orange, size: 80),
          const SizedBox(height: 24),
          Text(
            l10n?.verification_status_unknown_title ?? 'Estado Desconocido',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.verification_status_unknown_desc ?? 'No pudimos determinar el estado de verificación. Por favor, contacta a soporte.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _retryResolution,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n?.verification_status_retry ?? 'Reintentar'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              l10n?.profile_logout ?? 'Cerrar sesión',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverableErrorView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppLoading(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 80),
          const SizedBox(height: 24),
          Text(
            l10n?.verification_status_error_title ?? 'Ha ocurrido un error',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? (l10n?.verification_status_unknown_desc ?? ''),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _retryResolution,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n?.verification_status_retry ?? 'Reintentar'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              l10n?.profile_logout ?? 'Cerrar sesión',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
