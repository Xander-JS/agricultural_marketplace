import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import 'counter_offer_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/utils/app_formatters.dart';

class DealDetailScreen extends StatefulWidget {
  final String negotiationId;
  final String? role;
  final NegotiationModel? initialNegotiation;
  final NegotiationService? service;

  const DealDetailScreen({
    super.key,
    required this.negotiationId,
    this.role,
    this.initialNegotiation,
    this.service,
  });

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  late final NegotiationService _service;
  bool _isLoading = true;
  String? _errorMessage;
  NegotiationModel? _negotiation;

  bool get _isBuyer {
    if (widget.role != null) {
      return UserRole.isBuyerRole(widget.role);
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _negotiation != null) {
      return _negotiation!.buyerId == user.id;
    }
    return false;
  }

  bool get _isMyTurn {
    if (_negotiation == null) return false;
    return _negotiation!.isMyTurn(isBuyer: _isBuyer);
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NegotiationService();

    if (widget.initialNegotiation != null) {
      _negotiation = widget.initialNegotiation;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialNegotiation != null && _negotiation != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final negotiation = await _service.getNegotiationById(widget.negotiationId);
      if (mounted) {
        setState(() {
          _negotiation = negotiation;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n?.deal_detail_title ?? 'Detalle del trato'),
      ),
      body: _buildBody(isDark, l10n),
    );
  }

  Widget _buildBody(bool isDark, AppLocalizations? l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Ocurrió un error: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                ),
                child: Text(l10n?.market_retry ?? 'Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_negotiation == null) {
      return Center(
        child: Text(
          'No se encontró el trato.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    final n = _negotiation!;

    final offers = n.offers != null ? List<NegotiationOfferModel>.from(n.offers!) : <NegotiationOfferModel>[];
    offers.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final latestOffer = offers.isNotEmpty ? offers.last : null;

    final counterpartLabel = _isBuyer
        ? (l10n?.deal_counterpart_farmer ?? 'Productor')
        : (l10n?.deal_counterpart_buyer ?? 'Comprador');

    final counterpartName = _isBuyer
        ? (n.farmerProfile?['full_name'] ?? 'Productor (${n.crop?.municipality ?? ""})')
        : (n.buyerProfile?['full_name'] ?? 'Comprador');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.crop?.title ?? 'Cosecha desconocida',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              counterpartLabel,
              style: TextStyle(
                color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              counterpartName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),

            Divider(height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),

            if (latestOffer != null) ...[
              _buildInfoRow('Cantidad', UnitFormatters.formatKg(latestOffer.quantityKg), isDark),
              const SizedBox(height: 10),
              _buildInfoRow(
                'Precio por kg',
                CurrencyFormatters.formatCop(latestOffer.proposedPricePerKg),
                isDark,
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Método de entrega', latestOffer.deliveryMethod, isDark),
              Divider(height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ],

            _buildInfoRow(
              'Estado',
              n.status.toDisplayName(),
              isDark,
              isStatus: true,
              status: n.status,
            ),

            Divider(height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),

            Text(
              l10n?.deal_history_title ?? 'Historial de ofertas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...offers.map((offer) => _buildOfferBubble(offer, n, isDark, l10n)),

            const SizedBox(height: 24),

            _buildActionButtons(n, latestOffer, isDark, l10n),

            if (n.status == NegotiationStatus.completada) ...[
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La calificación de tratos estará disponible pronto.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: Text(_isBuyer ? 'Calificar productor' : 'Calificar comprador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                    foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool isStatus = false,
    NegotiationStatus? status,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 15,
          ),
        ),
        if (isStatus && status != null)
          _buildStatusBadge(status, isDark)
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(NegotiationStatus status, bool isDark) {
    Color color;
    switch (status) {
      case NegotiationStatus.propuesta:
        color = isDark ? const Color(0xFF64B5F6) : AppColors.info;
        break;
      case NegotiationStatus.contraofertada:
        color = isDark ? const Color(0xFFFFB74D) : AppColors.warning;
        break;
      case NegotiationStatus.acordada:
        color = isDark ? AppColors.darkTertiary : AppColors.success;
        break;
      case NegotiationStatus.completada:
        color = isDark ? const Color(0xFF80CBC4) : const Color(0xFF00897B);
        break;
      case NegotiationStatus.rechazada:
      case NegotiationStatus.cancelada:
        color = isDark ? const Color(0xFFEF9A9A) : AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toDisplayName(),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOfferBubble(
    NegotiationOfferModel offer,
    NegotiationModel negotiation,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    final isMe = offer.senderId == user?.id;

    final senderLabel = isMe
        ? 'Tú'
        : (_isBuyer
            ? (l10n?.deal_counterpart_farmer ?? 'Productor')
            : (l10n?.deal_counterpart_buyer ?? 'Comprador'));

    final primaryThemeColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSecondary.withValues(alpha: 0.6))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
          ),
          border: Border.all(
            color: isMe
                ? primaryThemeColor.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        width: MediaQuery.of(context).size.width * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  senderLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMe ? primaryThemeColor : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                Text(
                  DateFormatters.formatOfferDateTime(offer.createdAt),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatters.formatPricePerKg(offer.proposedPricePerKg),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              UnitFormatters.formatKg(offer.quantityKg),
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              'Entrega: ${offer.deliveryMethod}',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${offer.message}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    NegotiationModel n,
    NegotiationOfferModel? latestOffer,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    if (n.status == NegotiationStatus.acordada) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.successLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.handshake_outlined, color: AppColors.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n?.deal_agreed_desc ?? 'Trato acordado. Coordina la entrega física para completar la operación.',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _completeNegotiation(n),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n?.deal_complete_btn ?? 'Confirmar entrega y completar trato'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _rejectOffer(n),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n?.deal_cancel_agreed ?? 'Cancelar acuerdo'),
            ),
          ),
        ],
      );
    }

    if (n.status == NegotiationStatus.completada ||
        n.status == NegotiationStatus.rechazada ||
        n.status == NegotiationStatus.cancelada) {
      return const SizedBox.shrink();
    }

    // Si NO es mi turno, mostramos el aviso de espera
    if (!_isMyTurn) {
      final waitingMessage = _isBuyer
          ? (l10n?.deal_waiting_farmer ?? 'Esperando respuesta del productor')
          : (l10n?.deal_waiting_buyer ?? 'Esperando respuesta del comprador');

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, color: isDark ? const Color(0xFFFFB74D) : AppColors.warning),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    waitingMessage,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFFB25E00),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Si el comprador apenas envió propuesta y desea cancelar:
          if (_isBuyer && n.status == NegotiationStatus.propuesta) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _cancelOffer(n),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n?.deal_cancel_deal ?? 'Cancelar propuesta'),
            ),
          ],
        ],
      );
    }

    // SÍ es mi turno: Aceptar, Contraofertar o Rechazar
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _acceptOffer(n),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n?.deal_accept_offer ?? 'Aceptar oferta',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: latestOffer == null ? null : () => _navigateToCounterOffer(n, latestOffer),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n?.deal_counter_offer ?? 'Contraofertar',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _rejectOffer(n),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n?.deal_reject_deal ?? 'Rechazar trato',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCounterOffer(NegotiationModel n, NegotiationOfferModel latestOffer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterOfferScreen(
          negotiation: n,
          latestOffer: latestOffer,
          role: widget.role,
          service: _service,
        ),
      ),
    );
    if (result == true) {
      _loadData();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _acceptOffer(NegotiationModel n) async {
    final l10n = AppLocalizations.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _service.acceptOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.deal_accept_success ?? 'Trato acordado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOffer(NegotiationModel n) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deal_reject_confirm_title ?? '¿Rechazar este trato?'),
        content: Text(
          l10n?.deal_reject_confirm_desc ??
              'Esta acción no se puede deshacer y el trato se cerrará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.profile_cancel ?? 'Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.deal_reject_deal ?? 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _service.rejectOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.deal_reject_success ?? 'El trato ha sido rechazado'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelOffer(NegotiationModel n) async {
    try {
      await _service.cancelOffer(n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta cancelada')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeNegotiation(NegotiationModel n) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deal_complete_confirm_title ?? '¿Completar este trato?'),
        content: Text(
          l10n?.deal_complete_confirm_desc ??
              'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.profile_cancel ?? 'Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.deal_complete_confirm_btn ?? 'Completar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _service.completeNegotiation(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.deal_completed_success ?? 'Trato completado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
