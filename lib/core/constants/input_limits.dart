import 'package:flutter/services.dart';

/// Límites de longitud y de dígitos para todos los campos de entrada.
///
/// Textos: número máximo de caracteres. Números: dígitos enteros máximos
/// (ninguno admite negativos). Ajusta aquí y se aplica en toda la app.
abstract final class InputLimits {
  // Identidad y acceso (sin contador visible)
  static const int personName = 60;
  static const int email = 100;
  static const int password = 64;
  static const int phone = 15;

  // Contenido clave (con contador visible)
  static const int cropTitle = 60;
  static const int cropType = 40;
  static const int place = 40;
  static const int description = 500;
  static const int message = 300;
  static const int review = 500;
  static const int voiceTranscript = 500;
  static const int costConcept = 60;

  // Otros campos de texto
  static const int search = 60;
  static const int shortNote = 120;

  // Numéricos: dígitos enteros máximos
  static const int kgDigits = 7; // hasta 9.999.999 kg
  static const int pricePerKgDigits = 7; // hasta $9.999.999 por kg
  static const int amountDigits = 10; // costos y totales en COP
  static const int decimals = 2;
  static const int percentChars = 6; // p. ej. 100,00

  /// Número positivo con hasta [digits] enteros y [decimals] decimales
  /// (punto como separador). Rechaza la tecla en lugar de recortar.
  static List<TextInputFormatter> decimal(int digits) {
    final pattern = RegExp('^\\d{0,$digits}(\\.\\d{0,$decimals})?\$');
    return [
      TextInputFormatter.withFunction(
        (oldValue, newValue) =>
            pattern.hasMatch(newValue.text) ? newValue : oldValue,
      ),
    ];
  }

  /// Entero positivo con hasta [digits] dígitos.
  static List<TextInputFormatter> integer(int digits) => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(digits),
  ];
}
