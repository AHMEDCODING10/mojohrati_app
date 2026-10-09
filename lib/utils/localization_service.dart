
import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static Map<String, String>? _localizedStrings;

  static Future<void> load(String localeCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/translations/$localeCode.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    } catch (e) {
      // ignore: avoid_print
      print('Localization Error: Failed to load $localeCode.json - $e');
      _localizedStrings = {};
    }
  }

  static String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }
}

extension TranslateExtension on String {
  String tr() {
    return LocalizationService.translate(this);
  }
}
