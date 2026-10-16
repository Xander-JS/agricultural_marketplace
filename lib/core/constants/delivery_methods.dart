/// Mapeo centralizado del enum PostgreSQL `delivery_method`:
/// - `en_finca`
/// - `punto_acordado`
/// - `transportadora`
enum DeliveryMethod {
  enFinca('en_finca', 'En finca'),
  puntoAcordado('punto_acordado', 'Punto de acopio / acordado'),
  transportadora('transportadora', 'Transportadora / Bodega');

  final String dbValue;
  final String defaultLabel;

  const DeliveryMethod(this.dbValue, this.defaultLabel);

  /// Convierte cualquier representación de texto a la instancia correspondiente
  static DeliveryMethod fromString(String? val) {
    final v = (val ?? '').trim().toLowerCase();
    if (v.contains('finca')) return DeliveryMethod.enFinca;
    if (v.contains('transpor') || v.contains('bodega') || v.contains('destino')) {
      return DeliveryMethod.transportadora;
    }
    return DeliveryMethod.puntoAcordado;
  }

  /// Retorna el valor admitido por PostgreSQL
  static String toDb(String? val) => fromString(val).dbValue;

  /// Retorna una etiqueta legible
  static String toLabel(String? val) => fromString(val).defaultLabel;

  /// Lista de opciones para selectores en UI
  static List<String> get uiOptions => [
    'En finca',
    'Punto de acopio / acordado',
    'Transportadora / Bodega',
  ];
}
