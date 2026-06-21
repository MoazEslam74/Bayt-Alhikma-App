import 'package:flutter/material.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

class LanguageProvider with ChangeNotifier {
  // 1. Initialize directly from Storage
  // Since LocalStorageService.init() is called in main(), this is safe.
  Locale _appLocale = Locale(LocalStorageService.getLanguage());

  Locale get locale => _appLocale;

  // Helper to check if current locale is Arabic
  bool get isArabic => _appLocale.languageCode == 'ar';

  void changeLanguage(Locale type) {
    if (_appLocale == type) {
      return;
    }

    // 2. Update State
    _appLocale = type;

    // 3. Save to Local Storage immediately
    LocalStorageService.saveLanguage(type.languageCode);

    notifyListeners();
  }
}
