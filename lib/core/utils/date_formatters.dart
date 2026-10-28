import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Utilidad centralizada para formateo consistente de fechas en español (`es_CO`).
/// Evita desfases por conversión UTC a zona horaria local en fechas de calendario (como cosechas).
abstract final class DateFormatters {
  static const String defaultLocale = 'es_CO';
  static bool _initialized = false;

  /// Idioma de la app; lo fija la raíz de la app al cambiar de idioma.
  static String languageCode = 'es';

  static bool get _isEnglish => languageCode == 'en';

  /// Asegura que los símbolos de fecha para `es_CO` y `es` estén inicializados.
  static void ensureInitialized() {
    if (!_initialized) {
      initializeDateFormatting(defaultLocale, null);
      initializeDateFormatting('es', null);
      initializeDateFormatting('en', null);
      _initialized = true;
    }
  }

  static DateFormat _getFormatter(String pattern) {
    ensureInitialized();
    return DateFormat(pattern, _isEnglish ? 'en' : defaultLocale);
  }

  /// Parsea una fecha de tipo calendario (como `estimated_harvest_date`) de manera segura,
  /// evitando que conversiones horarias UTC desplacen el día hacia atrás o adelante.
  ///
  /// Soporta:
  /// - `String`: "2026-11-15", "2026-11-15T00:00:00.000Z"
  /// - `DateTime`: extrae año, mes y día exactos.
  static DateTime? parseCalendarDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) {
      return DateTime(date.year, date.month, date.day);
    }
    final str = date.toString().trim();
    if (str.isEmpty) return null;

    final dateOnly = str.split('T')[0];
    final parts = dateOnly.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.tryParse(str);
  }

  /// Formatea una fecha de cosecha estimada en formato `dd/MM/yyyy` (ej: "15/11/2026").
  /// Garantiza que no exista desfase de zona horaria.
  static String formatHarvestDate(dynamic date, {String fallback = '--'}) {
    final parsed = parseCalendarDate(date);
    if (parsed == null) return fallback;
    final formatter = _getFormatter('dd/MM/yyyy');
    return formatter.format(parsed);
  }

  /// Formatea una fecha de cosecha estimada en formato extendido español (ej: "15 de noviembre, 2026").
  static String formatHarvestDateLong(dynamic date, {String fallback = '--'}) {
    final parsed = parseCalendarDate(date);
    if (parsed == null) return fallback;
    final formatter = _isEnglish
        ? _getFormatter('MMMM d, yyyy')
        : _getFormatter("d 'de' MMMM, yyyy");
    return formatter.format(parsed);
  }

  /// Formato estándar de fecha: `dd/MM/yyyy`
  static String formatDate(DateTime? date, {String fallback = '--'}) {
    if (date == null) return fallback;
    final formatter = _getFormatter('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Formato medio en español: `dd MMM yyyy` (ej: "15 nov 2026")
  static String formatMediumDate(DateTime? date, {String fallback = '--'}) {
    if (date == null) return fallback;
    final formatter = _getFormatter('dd MMM yyyy');
    return formatter.format(date);
  }

  /// Formato para ofertas y mensajes con hora corta: `dd/MM hh:mm a` (ej: "15/11 03:30 p. m.")
  static String formatOfferDateTime(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    final formatter = _getFormatter('dd/MM hh:mm a');
    return formatter.format(dateTime.toLocal());
  }

  /// Formato completo de fecha y hora: `dd MMM yyyy, hh:mm a` (ej: "15 nov 2026, 03:30 p. m.")
  static String formatFullDateTime(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    final formatter = _getFormatter('dd MMM yyyy, hh:mm a');
    return formatter.format(dateTime.toLocal());
  }
}
