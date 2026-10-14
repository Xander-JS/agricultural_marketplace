import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import 'deal_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class DealsScreen extends StatefulWidget {
  final String? role;
  final List<NegotiationModel>? initialNegotiations;
  final NegotiationService? service;

  const DealsScreen({
    super.key,
    this.role,
    this.initialNegotiations,
    this.service,
  });

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  late final NegotiationService _service;
  bool _isLoading = true;
  String? _errorMessage;
  List<NegotiationModel> _negotiations = [];
  String? _userRole;
  late TabController _tabController;

  bool get _isBuyer {
    if (widget.role != null) {
      final r = widget.role!.trim().toLowerCase();
      return r == 'comprador' || r == 'comerciante';
    }
    if (_userRole != null) {
      final r = _userRole!.trim().toLowerCase();
      return r == 'comprador' || r == 'comerciante';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NegotiationService();
    _tabController = TabController(length: 5, vsync: this);

    if (widget.initialNegotiations != null) {
      _negotiations = widget.initialNegotiations!;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.initialNegotiations != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Si el rol no fue inyectado, consultarlo en profiles
      if (widget.role == null) {
        try {
          final profileRes = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          if (profileRes != null && profileRes['role'] != null) {
            _userRole = profileRes['role'] as String;
          }
        } catch (_) {}
      }

      List<NegotiationModel> negotiations;
      if (_isBuyer) {
        negotiations = await _service.getBuyerNegotiations(user.id);
      } else {
        negotiations = await _service.getFarmerNegotiations(user.id);
      }

      if (mounted) {
        setState(() {
          _negotiations = negotiations;
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

  List<NegotiationModel> _getFilteredNegotiations(int index) {
    if (index == 0) return _negotiations;
    switch (index) {
      case 1: // Pendientes
        return _negotiations.where((n) => n.status == NegotiationStatus.propuesta).toList();
      case 2: // En negociación
        return _negotiations.where((n) => n.status == NegotiationStatus.contraofertada).toList();
      case 3: // Acordados
        return _negotiations.where((n) => n.status == NegotiationStatus.acordada).toList();
      case 4: // Historial (completados, rechazados, cancelados)
        return _negotiations.where((n) =>
          n.status == NegotiationStatus.completada ||
          n.status == NegotiationStatus.rechazada ||
          n.status == NegotiationStatus.cancelada
        ).toList();
      default:
        return _negotiations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n?.deals_title ?? 'Tratos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n?.deals_tab_all ?? 'Todos'),
            Tab(text: l10n?.deals_tab_pending ?? 'Pendientes'),
            Tab(text: l10n?.deals_tab_in_negotiation ?? 'En negociación'),
            Tab(text: l10n?.deals_tab_agreed ?? 'Acordados'),
            Tab(text: l10n?.deals_tab_history ?? 'Historial'),
          ],
        ),
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

    return TabBarView(
      controller: _tabController,
      children: List.generate(
        5,
        (index) => _buildList(_getFilteredNegotiations(index), isDark, l10n),
      ),
    );
  }

  Widget _buildList(List<NegotiationModel> list, bool isDark, AppLocalizations? l10n) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: _buildEmptyState(isDark, l10n),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildDealCard(list[index], isDark, l10n);
        },
      ),
    );
  }

  Widget _buildDealCard(NegotiationModel negotiation, bool isDark, AppLocalizations? l10n) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final latestOffer = (negotiation.offers != null && negotiation.offers!.isNotEmpty)
        ? negotiation.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final quantity = latestOffer?.quantityKg ?? 0;
    final price = latestOffer?.proposedPricePerKg ?? 0;

    final counterpartLabel = _isBuyer
        ? (l10n?.deal_counterpart_farmer ?? 'Productor')
        : (l10n?.deal_counterpart_buyer ?? 'Comprador');

    final counterpartName = _isBuyer
        ? (negotiation.farmerProfile?['full_name'] ??
            (negotiation.crop?.municipality != null
                ? 'Productor (${negotiation.crop!.municipality})'
                : 'Productor'))
        : (negotiation.buyerProfile?['full_name'] ?? 'Comprador');

    final formatter = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO');
    final formattedDate = formatter.format(negotiation.updatedAt);

    // Determinar si es el turno del usuario autenticado
    final isPendingOrNegotiating =
        negotiation.status == NegotiationStatus.propuesta ||
        negotiation.status == NegotiationStatus.contraofertada;

    final isMyTurn = isPendingOrNegotiating &&
        ((_isBuyer && negotiation.currentResponder == 'buyer') ||
         (!_isBuyer && negotiation.currentResponder == 'farmer'));

    final isWaiting = isPendingOrNegotiating && !isMyTurn;

    final primaryThemeColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    negotiation.crop?.title ?? 'Cosecha desconocida',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(negotiation.status, isDark),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$counterpartLabel: $counterpartName',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (latestOffer != null) ...[
              Row(
                children: [
                  Text(
                    '${quantity.toStringAsFixed(0)} kg',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${currencyFormatter.format(price)} / kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isMyTurn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n?.deals_your_turn ?? 'Tu turno',
                      style: TextStyle(
                        color: primaryThemeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isWaiting)
                  Text(
                    l10n?.deals_waiting_response ?? 'Esperando respuesta',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFFB74D) : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(negotiation),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l10n?.deals_see_deal ?? 'Ver trato →'),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toDisplayName(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations? l10n) {
    final title = _isBuyer
        ? (l10n?.deals_empty_buyer_title ?? 'Aún no tienes tratos')
        : (l10n?.deals_empty_farmer_title ?? 'Aún no tienes tratos');

    final desc = _isBuyer
        ? (l10n?.deals_empty_buyer_desc ??
            'Cuando realices una oferta en el mercado sobre una cosecha, podrás seguirla y negociar aquí.')
        : (l10n?.deals_empty_farmer_desc ??
            'Cuando un comprador realice una oferta sobre una de tus cosechas, aparecerá aquí.');

    final buttonLabel = _isBuyer
        ? (l10n?.deals_explore_market ?? 'Explorar mercado')
        : (l10n?.deals_view_crops ?? 'Ver mis cosechas');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 80,
            color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: Icon(_isBuyer ? Icons.storefront : Icons.grass),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(NegotiationModel negotiation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealDetailScreen(
          negotiationId: negotiation.id,
          role: widget.role,
          service: _service,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }
}
