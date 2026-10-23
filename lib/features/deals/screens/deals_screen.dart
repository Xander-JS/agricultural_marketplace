import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import 'deal_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/loading/section_skeletons.dart';

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

  bool get _isBuyer => UserRole.isBuyerRole(widget.role ?? _userRole);

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(l10n.deals_title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.deals_tab_all),
            Tab(text: l10n.deals_tab_pending),
            Tab(text: l10n.deals_tab_in_negotiation),
            Tab(text: l10n.deals_tab_agreed),
            Tab(text: l10n.deals_tab_history),
          ],
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const SectionSkeleton(kind: SectionSkeletonKind.rowCards);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.appError),
              const SizedBox(height: 16),
              Text(
                l10n.deals_error_prefix(_errorMessage!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: context.appOnPrimary,
                ),
                child: Text(l10n.common_retry),
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
        (index) => _buildList(_getFilteredNegotiations(index), l10n),
      ),
    );
  }

  Widget _buildList(List<NegotiationModel> list, AppLocalizations l10n) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: context.appPrimary,
        backgroundColor: context.appSurface,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: AppMotion.scrollPhysics,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: _buildEmptyState(l10n),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: context.appPrimary,
      backgroundColor: context.appSurface,
      strokeWidth: 2.5,
      child: ListView.builder(
        physics: AppMotion.scrollPhysics,
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildDealCard(list[index], l10n);
        },
      ),
    );
  }

  Widget _buildDealCard(NegotiationModel negotiation, AppLocalizations l10n) {
    final latestOffer = (negotiation.offers != null && negotiation.offers!.isNotEmpty)
        ? negotiation.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final quantity = latestOffer?.quantityKg ?? 0;
    final price = latestOffer?.proposedPricePerKg ?? 0;

    final counterpartLabel = _isBuyer
        ? l10n.deal_counterpart_farmer
        : l10n.deal_counterpart_buyer;

    final counterpartName = _isBuyer
        ? (negotiation.farmerProfile?['full_name'] ??
            (negotiation.crop?.municipality != null
                ? l10n.deals_producer_with_location(
                    negotiation.crop!.municipality,
                  )
                : l10n.deals_producer))
        : (negotiation.buyerProfile?['full_name'] ?? l10n.deals_buyer);

    final formattedDate = DateFormatters.formatFullDateTime(negotiation.updatedAt);

    // Determinar si es el turno del usuario autenticado
    final isPendingOrNegotiating =
        negotiation.status == NegotiationStatus.propuesta ||
        negotiation.status == NegotiationStatus.contraofertada;

    final isMyTurn = isPendingOrNegotiating &&
        negotiation.isMyTurn(isBuyer: _isBuyer);

    final isWaiting = isPendingOrNegotiating && !isMyTurn;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
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
                    negotiation.crop?.title ?? l10n.deals_unknown_crop,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(negotiation.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.deals_counterpart_name(counterpartLabel, counterpartName),
              style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (latestOffer != null) ...[
              Row(
                children: [
                  Text(
                    UnitFormatters.formatKg(quantity),
                    style: TextStyle(
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatters.formatPricePerKg(price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.appTextPrimary,
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
                  color: context.appTextDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: context.appTextDisabled,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isMyTurn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.deals_your_turn,
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isWaiting)
                  Text(
                    l10n.deals_waiting_response,
                    style: TextStyle(
                      color: context.appWarning,
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
                child: Text(l10n.deals_see_deal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NegotiationStatus status) {
    Color color;
    switch (status) {
      case NegotiationStatus.propuesta:
        color = context.appInfo;
        break;
      case NegotiationStatus.contraofertada:
        color = context.appWarning;
        break;
      case NegotiationStatus.acordada:
        color = context.appSuccess;
        break;
      case NegotiationStatus.completada:
        color = context.appPrimary;
        break;
      case NegotiationStatus.rechazada:
      case NegotiationStatus.cancelada:
        color = context.appError;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    final title = _isBuyer
        ? l10n.deals_empty_buyer_title
        : l10n.deals_empty_farmer_title;

    final desc = _isBuyer
        ? l10n.deals_empty_buyer_desc
        : l10n.deals_empty_farmer_desc;

    final buttonLabel = _isBuyer
        ? l10n.deals_explore_market
        : l10n.deals_view_crops;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 80,
            color: context.appTextDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: TextStyle(
              fontSize: 15,
              color: context.appTextSecondary,
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
              backgroundColor: context.appPrimary,
              foregroundColor: context.appOnPrimary,
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
