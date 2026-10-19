import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';
import '../services/purchases_service.dart';
import '../widgets/purchase_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';

/// Pantalla principal del Módulo de Compras para el rol Comerciante/Comprador.
///
/// Permite consultar los acuerdos vigentes (`acordada`) y las compras cerradas
/// (`completada`) pactadas con productores agrícolas a partir de datos reales
/// de `negotiations`, `crops` y `negotiation_offers`.
class PurchasesScreen extends StatefulWidget {
  final List<NegotiationModel>? initialPurchases;
  final PurchasesService? service;
  final VoidCallback? onExploreMarket;

  const PurchasesScreen({
    super.key,
    this.initialPurchases,
    this.service,
    this.onExploreMarket,
  });

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late final PurchasesService _service;
  late final TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  List<NegotiationModel> _purchases = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PurchasesService();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialPurchases != null) {
      _purchases = widget.initialPurchases!;
      _isLoading = false;
    } else {
      _loadPurchases();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchases() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _purchases = [];
          });
        }
        return;
      }

      final data = await _service.getPurchases(userId);
      if (mounted) {
        setState(() {
          _purchases = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<NegotiationModel> _getFilteredPurchases(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _purchases
            .where((p) => p.status == NegotiationStatus.acordada)
            .toList();
      case 2:
        return _purchases
            .where((p) => p.status == NegotiationStatus.completada)
            .toList();
      case 0:
      default:
        return _purchases;
    }
  }

  int get _agreedCount =>
      _purchases.where((p) => p.status == NegotiationStatus.acordada).length;

  double get _totalInvested {
    double sum = 0.0;
    for (final p in _purchases) {
      final latestOffer = (p.offers != null && p.offers!.isNotEmpty)
          ? p.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;
      if (latestOffer != null) {
        sum += (latestOffer.quantityKg * latestOffer.proposedPricePerKg);
      }
    }
    return sum;
  }

  double get _totalVolumeKg {
    double sum = 0.0;
    for (final p in _purchases) {
      final latestOffer = (p.offers != null && p.offers!.isNotEmpty)
          ? p.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;
      if (latestOffer != null) {
        sum += latestOffer.quantityKg;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    final titleText = l10n?.purchases_title ?? 'Compras';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          titleText,
          style: AppTextStyles.displaySmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n?.purchases_tab_all ?? 'Todas'),
            Tab(text: l10n?.purchases_tab_agreed ?? 'Acordadas'),
            Tab(text: l10n?.purchases_tab_completed ?? 'Completadas'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadPurchases,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Banner resumen de métricas
                      _buildSummaryBanner(
                        isDark: isDark,
                        l10n: l10n,
                        agreedCount: _agreedCount,
                        totalInvested: _totalInvested,
                        totalVolumeKg: _totalVolumeKg,
                      ),
                      // Pestañas con lista de compras
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPurchasesList(
                              context: context,
                              items: _getFilteredPurchases(0),
                              isDark: isDark,
                              l10n: l10n,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              primaryColor: primaryColor,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                            _buildPurchasesList(
                              context: context,
                              items: _getFilteredPurchases(1),
                              isDark: isDark,
                              l10n: l10n,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              primaryColor: primaryColor,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                            _buildPurchasesList(
                              context: context,
                              items: _getFilteredPurchases(2),
                              isDark: isDark,
                              l10n: l10n,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              primaryColor: primaryColor,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryBanner({
    required bool isDark,
    required AppLocalizations? l10n,
    required int agreedCount,
    required double totalInvested,
    required double totalVolumeKg,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBannerItem(
              label: l10n?.purchases_total_agreed ?? 'Acuerdos vigentes',
              value: agreedCount.toString(),
              icon: Icons.handshake_outlined,
              isDark: isDark,
              color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(
            child: _buildBannerItem(
              label: l10n?.purchases_total_invested ?? 'Total pactado',
              value: CurrencyFormatters.formatCop(totalInvested),
              icon: Icons.payments_outlined,
              isDark: isDark,
              color: isDark ? const Color(0xFF81C784) : AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(
            child: _buildBannerItem(
              label: l10n?.purchases_total_volume ?? 'Volumen total',
              value: UnitFormatters.formatKg(totalVolumeKg),
              icon: Icons.scale_outlined,
              isDark: isDark,
              color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPurchasesList({
    required BuildContext context,
    required List<NegotiationModel> items,
    required bool isDark,
    required AppLocalizations? l10n,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPurchases,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.paddingScreen,
          child: _buildEmptyState(
            context: context,
            isDark: isDark,
            l10n: l10n,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primaryColor: primaryColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPurchases,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return PurchaseCard(
            purchase: item,
            onRefresh: _loadPurchases,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required bool isDark,
    required AppLocalizations? l10n,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space20,
        vertical: AppDimensions.space32,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: AppDimensions.iconXL,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            l10n?.purchases_placeholder_title ?? 'Módulo de Compras',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            l10n?.purchases_empty_title ?? 'No tienes compras aún',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            l10n?.purchases_empty_desc ??
                'Aquí aparecerán los acuerdos que hayas cerrado con los productores agrícolas y tus compras completadas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space8,
            ),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                  .withValues(alpha: 0.5),
              borderRadius: AppDimensions.borderRadiusFull,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: AppDimensions.iconXS,
                  color: primaryColor,
                ),
                const SizedBox(width: AppDimensions.space4),
                Text(
                  'Rol Comerciante',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onExploreMarket != null) ...[
            const SizedBox(height: AppDimensions.space20),
            ElevatedButton.icon(
              onPressed: widget.onExploreMarket,
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n?.purchases_empty_action ?? 'Explorar mercado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24,
                  vertical: AppDimensions.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
