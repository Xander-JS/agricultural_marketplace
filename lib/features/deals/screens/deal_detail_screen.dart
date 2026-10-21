import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoadingContact = false;
  bool _isActionInProgress = false;
  String? _errorMessage;
  NegotiationModel? _negotiation;
  NegotiationContactInfo? _contactInfo;

  bool get _isBuyer {
    if (widget.role != null && widget.role!.trim().isNotEmpty) {
      return UserRole.isBuyerRole(widget.role);
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _negotiation != null) {
      return _negotiation!.buyerId == user.id;
    }
    if (user != null && widget.negotiationId.isNotEmpty) {
      // Fallback: try to infer from negotiation if loaded later; default to false if unknown
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
    }
    _loadData();
  }

  Future<void> _loadData({bool reload = false}) async {
    if (!reload && _negotiation != null) {
      // El detalle ya se puede pintar con la negociación disponible; los datos
      // de contacto son opcionales y nunca deben bloquear la pantalla.
      final status = _negotiation!.status;
      if (status == NegotiationStatus.acordada ||
          status == NegotiationStatus.completada) {
        unawaited(_loadContactInfo());
      }
      return;
    }

    setState(() {
      _isLoading = _negotiation == null;
      _errorMessage = null;
    });

    try {
      final negotiation = await _service.getNegotiationById(
        widget.negotiationId,
      );

      if (!mounted) return;
      setState(() {
        _negotiation = negotiation;
        _isLoading = false;
      });

      if (negotiation.status == NegotiationStatus.acordada ||
          negotiation.status == NegotiationStatus.completada) {
        unawaited(_loadContactInfo());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Si ya había datos visibles, se conserva el detalle y se evita
          // reemplazarlo por la pantalla de error.
          if (_negotiation == null) {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  /// Carga los datos de contacto autorizados de forma independiente.
  /// Un fallo o una demora de esta RPC no impide ver el trato.
  Future<void> _loadContactInfo() async {
    if (_isLoadingContact) return;
    _isLoadingContact = true;
    try {
      final contactInfo = await _service.getCounterpartContact(
        widget.negotiationId,
      );
      if (mounted) {
        setState(() {
          _contactInfo = contactInfo;
        });
      }
    } catch (e) {
      debugPrint('Aviso: no se pudo consultar contacto de contraparte: $e');
    } finally {
      _isLoadingContact = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadData(reload: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkTertiary
                      : AppColors.lightTertiary,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.white,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No se encontró el trato.',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(reload: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkTertiary
                    : AppColors.lightTertiary,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
              ),
              child: Text(l10n?.market_retry ?? 'Reintentar'),
            ),
          ],
        ),
      );
    }

    final n = _negotiation!;

    final offers = n.offers != null
        ? List<NegotiationOfferModel>.from(n.offers!)
        : <NegotiationOfferModel>[];
    offers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestOffer = offers.isNotEmpty ? offers.last : null;

    final counterpartLabel = _isBuyer
        ? (l10n?.deal_counterpart_farmer ?? 'Productor')
        : (l10n?.deal_counterpart_buyer ?? 'Comprador');

    final counterpartName = _isBuyer
        ? (n.farmerProfile?['full_name'] ??
              'Productor (${n.crop?.municipality ?? ""})')
        : (n.buyerProfile?['full_name'] ?? 'Comprador');

    return RefreshIndicator(
      onRefresh: () => _loadData(reload: true),
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
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              counterpartLabel,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              counterpartName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),

            Divider(
              height: 32,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),

            if (latestOffer != null) ...[
              _buildInfoRow(
                'Cantidad',
                UnitFormatters.formatKg(latestOffer.quantityKg),
                isDark,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                'Precio por kg',
                CurrencyFormatters.formatCop(latestOffer.proposedPricePerKg),
                isDark,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                'Método de entrega',
                latestOffer.deliveryMethod,
                isDark,
              ),
              Divider(
                height: 32,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ],

            _buildInfoRow(
              'Estado',
              n.status.toDisplayName(),
              isDark,
              isStatus: true,
              status: n.status,
            ),

            // SECCIÓN DE CONSENTIMIENTO Y CONTACTO CUANDO EL TRATO ESTÁ ACORDADO O COMPLETADO
            if (n.status == NegotiationStatus.acordada ||
                n.status == NegotiationStatus.completada) ...[
              const SizedBox(height: 20),
              _buildContactAndConsentSection(n, isDark, l10n),
            ],

            Divider(
              height: 32,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),

            Text(
              l10n?.deal_history_title ?? 'Historial de ofertas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...offers.map((offer) => _buildOfferBubble(offer, n, isDark, l10n)),

            const SizedBox(height: 24),

            _buildActionButtons(n, latestOffer, isDark, l10n),

            if (n.status == NegotiationStatus.completada) ...[
              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La calificación de tratos estará disponible pronto.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: Text(
                    _isBuyer ? 'Calificar productor' : 'Calificar comprador',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                    foregroundColor: isDark
                        ? AppColors.darkBackground
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  /// Construye la tarjeta integral de contacto de la contraparte y configuración
  /// de permisos propios para el trato acordado.
  Widget _buildContactAndConsentSection(
    NegotiationModel n,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final contact = _contactInfo;
    final counterpartTitle = _isBuyer
        ? 'Datos de contacto del Productor'
        : 'Datos de contacto del Comprador';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  counterpartTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. TELÉFONO / WHATSAPP
          if (contact != null && contact.hasCounterpartPhone) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Teléfono / WhatsApp autorizado:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    contact.counterpartPhone!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.call,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('Llamar'),
                        backgroundColor: AppColors.success,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        onPressed: () => _handleCall(contact.counterpartPhone!),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('WhatsApp'),
                        backgroundColor: const Color(0xFF25D366),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        onPressed: () =>
                            _handleWhatsApp(contact.counterpartPhone!),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar'),
                        onPressed: () => _copyToClipboard(
                          contact.counterpartPhone!,
                          'Teléfono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_locked_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_isBuyer ? "El productor" : "El comprador"} no ha autorizado compartir su teléfono ni WhatsApp.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 2. UBICACIÓN FÍSICA
          if (contact != null && contact.hasCounterpartLocation) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicación física autorizada:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${contact.counterpartMunicipality ?? ""}${contact.counterpartMunicipality != null && contact.counterpartDepartment != null ? ", " : ""}${contact.counterpartDepartment ?? ""}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (contact.counterpartLatitude != null &&
                      contact.counterpartLongitude != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Coordenadas: ${contact.counterpartLatitude!.toStringAsFixed(6)}, ${contact.counterpartLongitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ActionChip(
                    avatar: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Ver detalles de ubicación'),
                    onPressed: () => _showLocationDialog(contact),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_isBuyer ? "El productor" : "El comprador"} no ha autorizado compartir su ubicación física.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Divider(
            height: 24,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),

          // 3. MIS PERMISOS CONFIGURADOS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus permisos para este trato:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          'Teléfono: ${contact?.mySharePhone == true ? "Autorizado" : "Privado"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: contact?.mySharePhone == true
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextDisabled
                                : AppColors.lightTextDisabled,
                          ),
                        ),
                        Text(
                          'Ubicación: ${contact?.myShareLocation == true ? "Autorizada" : "Privada"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: contact?.myShareLocation == true
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showConsentBottomSheet(n),
                icon: const Icon(Icons.security, size: 16),
                label: const Text('Modificar'),
                style: OutlinedButton.styleFrom(
                  // El tema global define un ancho mínimo infinito para los
                  // botones; dentro de un Row eso produce constraints
                  // inválidas. Se limita el ancho para que el botón conviva
                  // con el texto expandido de la izquierda.
                  minimumSize: const Size(0, 40),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles: $text'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleCall(String phone) {
    _copyToClipboard(phone, 'Teléfono');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Teléfono $phone copiado. Listo para marcar desde tu teléfono.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleWhatsApp(String phone) {
    _copyToClipboard(phone, 'WhatsApp');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contacto de WhatsApp $phone copiado. Abre WhatsApp para iniciar conversación.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLocationDialog(NegotiationContactInfo contact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Ubicación física autorizada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.counterpartMunicipality != null ||
                contact.counterpartDepartment != null) ...[
              Text(
                'Municipio / Departamento:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${contact.counterpartMunicipality ?? ""}, ${contact.counterpartDepartment ?? ""}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
            ],
            if (contact.counterpartLatitude != null &&
                contact.counterpartLongitude != null) ...[
              Text(
                'Coordenadas geográficas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                'Lat: ${contact.counterpartLatitude!.toStringAsFixed(6)}\nLon: ${contact.counterpartLongitude!.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Text(
                'Ubicación verificada para la entrega de este lote.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.darkTextDisabled
                      : AppColors.lightTextDisabled,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (contact.counterpartLatitude != null &&
              contact.counterpartLongitude != null)
            TextButton.icon(
              onPressed: () {
                final coords =
                    '${contact.counterpartLatitude},${contact.counterpartLongitude}';
                _copyToClipboard(coords, 'Coordenadas');
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar coordenadas'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
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
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
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
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
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

    final primaryThemeColor = isDark
        ? AppColors.darkTertiary
        : AppColors.lightTertiary;

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
            bottomRight: isMe
                ? const Radius.circular(2)
                : const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(2),
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
                    color: isMe
                        ? primaryThemeColor
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                  ),
                ),
                Text(
                  DateFormatters.formatOfferDateTime(offer.createdAt),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextDisabled
                        : AppColors.lightTextDisabled,
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
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              UnitFormatters.formatKg(offer.quantityKg),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              'Entrega: ${offer.deliveryMethod}',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${offer.message}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
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
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.successLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.success.withValues(alpha: 0.3),
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.success,
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
              onPressed: _isActionInProgress
                  ? null
                  : () => _completeNegotiation(n),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                l10n?.deal_complete_btn ??
                    'Confirmar entrega y completar trato',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDark
                    ? AppColors.darkTertiary
                    : AppColors.lightTertiary,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isActionInProgress ? null : () => _cancelOffer(n),
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
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: isDark ? const Color(0xFFFFB74D) : AppColors.warning,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    waitingMessage,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFFB25E00),
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
              onPressed: _isActionInProgress ? null : () => _cancelOffer(n),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: _isActionInProgress
                ? null
                : () => _acceptOffer(n, latestOffer),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isDark
                  ? AppColors.darkTertiary
                  : AppColors.lightTertiary,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            onPressed: (_isActionInProgress || latestOffer == null)
                ? null
                : () => _navigateToCounterOffer(n, latestOffer),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            onPressed: _isActionInProgress ? null : () => _rejectOffer(n),
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

  void _navigateToCounterOffer(
    NegotiationModel n,
    NegotiationOfferModel latestOffer,
  ) async {
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
      _loadData(reload: true);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _acceptOffer(NegotiationModel n, NegotiationOfferModel? latestOffer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AcceptOfferConsentSheet(
        negotiation: n,
        latestOffer: latestOffer,
        isBuyer: _isBuyer,
        onConfirm: (sharePhone, shareLocation) async {
          Navigator.pop(ctx);
          await _executeAcceptWithConsent(n, sharePhone, shareLocation);
        },
      ),
    );
  }

  Future<void> _executeAcceptWithConsent(
    NegotiationModel n,
    bool sharePhone,
    bool shareLocation,
  ) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    final l10n = AppLocalizations.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Aceptar oferta formalmente (RPC existente accept_negotiation que reserva inventario)
      await _service.acceptOffer(n.id);

      // 2. Persistir consentimiento bidireccional seleccionado
      try {
        await _service.setNegotiationConsent(
          negotiationId: n.id,
          sharePhone: sharePhone,
          shareLocation: shareLocation,
        );
      } catch (consentError) {
        debugPrint(
          'Aviso: no se pudo guardar consentimiento inicial: $consentError',
        );
      }

      if (mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.deal_accept_success ?? 'Trato acordado correctamente',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(reload: true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  void _showConsentBottomSheet(NegotiationModel n) {
    final currentPhone = _contactInfo?.mySharePhone ?? false;
    final currentLocation = _contactInfo?.myShareLocation ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditConsentSheet(
        initialSharePhone: currentPhone,
        initialShareLocation: currentLocation,
        isBuyer: _isBuyer,
        onSave: (sharePhone, shareLocation) async {
          Navigator.pop(ctx);
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            await _service.setNegotiationConsent(
              negotiationId: n.id,
              sharePhone: sharePhone,
              shareLocation: shareLocation,
            );

            if (mounted) {
              Navigator.pop(context); // pop loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Permisos de contacto actualizados correctamente',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadData(reload: true);
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al actualizar permisos: ${e.toString().replaceFirst("Exception: ", "")}',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _rejectOffer(NegotiationModel n) async {
    if (_isActionInProgress) return;
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

    _isActionInProgress = true;
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _service.rejectOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.deal_reject_success ?? 'El trato ha sido rechazado',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        _loadData(reload: true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  Future<void> _cancelOffer(NegotiationModel n) async {
    if (_isActionInProgress) return;
    final l10n = AppLocalizations.of(context);
    final isAgreed = n.status == NegotiationStatus.acordada;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isAgreed
              ? '¿Cancelar este acuerdo?'
              : (l10n?.deal_cancel_deal ?? '¿Cancelar esta propuesta?'),
        ),
        content: Text(
          isAgreed
              ? 'Esta acción cancelará el trato acordado, liberará el stock reservado y cerrará la negociación.'
              : 'Esta acción cancelará la propuesta enviada, liberará el stock reservado y cerrará la negociación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.profile_cancel ?? 'Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isAgreed
                  ? (l10n?.deal_cancel_agreed ?? 'Cancelar acuerdo')
                  : (l10n?.deal_cancel_deal ?? 'Cancelar propuesta'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _isActionInProgress = true;
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _service.cancelOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAgreed
                  ? 'Acuerdo cancelado correctamente'
                  : 'Propuesta cancelada correctamente',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        _loadData(reload: true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  Future<void> _completeNegotiation(NegotiationModel n) async {
    if (_isActionInProgress) return;
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.deal_complete_confirm_title ?? '¿Completar este trato?',
        ),
        content: Text(
          l10n?.deal_complete_confirm_desc ?? 'Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario.',
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

    _isActionInProgress = true;
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _service.completeNegotiation(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.deal_completed_success ?? 'Trato completado exitosamente',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(reload: true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }
}

/// BottomSheet para confirmar la aceptación de una oferta y configurar el consentimiento inicial.
class _AcceptOfferConsentSheet extends StatefulWidget {
  final NegotiationModel negotiation;
  final NegotiationOfferModel? latestOffer;
  final bool isBuyer;
  final Function(bool sharePhone, bool shareLocation) onConfirm;

  const _AcceptOfferConsentSheet({
    required this.negotiation,
    required this.latestOffer,
    required this.isBuyer,
    required this.onConfirm,
  });

  @override
  State<_AcceptOfferConsentSheet> createState() =>
      _AcceptOfferConsentSheetState();
}

class _AcceptOfferConsentSheetState extends State<_AcceptOfferConsentSheet> {
  bool _sharePhone = false;
  bool _shareLocation = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aceptar oferta y acordar trato',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Al formalizar el acuerdo, el inventario pactado se reservará en el sistema. Selecciona qué datos de contacto autorizas compartir con la contraparte para coordinar la entrega física:',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _sharePhone,
                  onChanged: (val) => setState(() => _sharePhone = val),
                  title: const Text(
                    'Compartir mi teléfono y WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Permite a la contraparte llamarte o escribirte por WhatsApp para coordinar.',
                  ),
                  activeThumbColor: AppColors.success,
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                ),
                SwitchListTile.adaptive(
                  value: _shareLocation,
                  onChanged: (val) => setState(() => _shareLocation = val),
                  title: Text(
                    widget.isBuyer
                        ? 'Compartir mi ubicación de entrega'
                        : 'Compartir la ubicación de la finca',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Permite ver el municipio y coordenadas para planificar la ruta de entrega.',
                  ),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      widget.onConfirm(_sharePhone, _shareLocation),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                    foregroundColor: isDark
                        ? AppColors.darkBackground
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirmar acuerdo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// BottomSheet para consultar y modificar los permisos de consentimiento propios
/// durante una negociación en estado acordada.
class _EditConsentSheet extends StatefulWidget {
  final bool initialSharePhone;
  final bool initialShareLocation;
  final bool isBuyer;
  final Function(bool sharePhone, bool shareLocation) onSave;

  const _EditConsentSheet({
    required this.initialSharePhone,
    required this.initialShareLocation,
    required this.isBuyer,
    required this.onSave,
  });

  @override
  State<_EditConsentSheet> createState() => _EditConsentSheetState();
}

class _EditConsentSheetState extends State<_EditConsentSheet> {
  late bool _sharePhone;
  late bool _shareLocation;

  @override
  void initState() {
    super.initState();
    _sharePhone = widget.initialSharePhone;
    _shareLocation = widget.initialShareLocation;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.security, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mis permisos de contacto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Controla qué datos privados autorizas ver a la contraparte para coordinar este trato. Puedes revocar o conceder permisos en cualquier momento:',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _sharePhone,
                  onChanged: (val) => setState(() => _sharePhone = val),
                  title: const Text(
                    'Compartir mi teléfono y WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'La contraparte podrá ver tu número para llamadas o mensajes.',
                  ),
                  activeThumbColor: AppColors.success,
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                ),
                SwitchListTile.adaptive(
                  value: _shareLocation,
                  onChanged: (val) => setState(() => _shareLocation = val),
                  title: Text(
                    widget.isBuyer
                        ? 'Compartir mi ubicación de entrega'
                        : 'Compartir ubicación de la finca',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'La contraparte podrá ver municipio y coordenadas para la logística.',
                  ),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onSave(_sharePhone, _shareLocation),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                    foregroundColor: isDark
                        ? AppColors.darkBackground
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
