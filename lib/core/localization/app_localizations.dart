import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Base localization class for Agricultural Marketplace.
///
/// This class and delegate provide the infrastructure for localized translations.
/// When actual translation keys are added in [app_es.arb] and [app_en.arb],
/// corresponding getters or lookup mechanisms can be added here or via Flutter's gen-l10n tool.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// Retrieves the [AppLocalizations] instance from the given [BuildContext].
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Shorthand accessor that asserts [AppLocalizations] is present.
  static AppLocalizations current(BuildContext context) {
    final AppLocalizations? instance = of(context);
    assert(instance != null, 'No AppLocalizations found in context');
    return instance!;
  }

  /// The delegate to be included in `MaterialApp.localizationsDelegates`.
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => <String>['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
