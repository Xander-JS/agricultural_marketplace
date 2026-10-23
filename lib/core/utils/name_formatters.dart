/// Short display names for people, built from the single `full_name`
/// column of `profiles`.
abstract final class NameFormatters {
  /// Lowercase connectors that belong to the surname or name after them
  /// ("de la Cruz", "del Castillo", "San Juan").
  static const Set<String> _particles = {
    'de',
    'del',
    'la',
    'las',
    'los',
    'y',
    'e',
    'san',
    'santa',
  };

  /// Courtesy titles that stay attached to the given name after them, as
  /// rural Nariño users often register themselves ("Don Jaime").
  static const Set<String> _honorifics = {'don', 'doña', 'dona', 'sr.', 'sra.'};

  /// First given name and first surname of [fullName], following the
  /// Colombian order of given names first, then paternal and maternal
  /// surnames:
  ///
  /// - "Juan Carlos Pérez Gómez" → "Juan Pérez"
  /// - "María de los Ángeles Rosero Pantoja" → "María Rosero"
  /// - "Jaime Pérez Gómez" → "Jaime Pérez"
  /// - "Don Jaime Cafetero" → "Don Jaime Cafetero"
  ///
  /// Names of one or two parts are returned whole. Returns an empty string
  /// when [fullName] is null or blank.
  static String firstNameAndSurname(String? fullName) {
    final units = _nameUnits(fullName);
    if (units.length <= 2) return units.join(' ');
    // Three parts are read as one given name plus two surnames; four or
    // more as two given names plus the surnames.
    final surname = units.length == 3 ? units[1] : units[2];
    return '${units.first} $surname';
  }

  /// Splits [fullName] into words, gluing particles and honorifics to the
  /// word that follows them.
  static List<String> _nameUnits(String? fullName) {
    final words = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);

    final units = <String>[];
    final pending = <String>[];
    for (final word in words) {
      final lower = word.toLowerCase();
      if (_particles.contains(lower) || _honorifics.contains(lower)) {
        pending.add(word);
        continue;
      }
      units.add([...pending, word].join(' '));
      pending.clear();
    }
    // A trailing connector has nothing to attach to: keep it on the last
    // unit rather than dropping part of the name.
    if (pending.isNotEmpty) {
      if (units.isEmpty) {
        units.add(pending.join(' '));
      } else {
        units[units.length - 1] = [units.last, ...pending].join(' ');
      }
    }
    return units;
  }
}
