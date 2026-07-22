import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();
  static const String _storageKey = 'investigo_system_language_v1';

  Locale _locale = const Locale('bn', 'BD');

  Locale get locale => _locale;
  bool get isBangla => _locale.languageCode == 'bn';
  String get languageCode => _locale.languageCode;

  String text(String bangla, String english) => isBangla ? bangla : english;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_storageKey) ?? 'bn';
    _locale = code == 'en'
        ? const Locale('en', 'US')
        : const Locale('bn', 'BD');
  }

  Future<void> setLanguage(String code) async {
    final normalized = code == 'en' ? 'en' : 'bn';
    final next = normalized == 'en'
        ? const Locale('en', 'US')
        : const Locale('bn', 'BD');
    if (_locale == next) return;

    _locale = next;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, normalized);
  }
}
