
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appNameAr = 'مجوهراتي';
  static const String appNameEn = 'Mojawharati';

  // ── Server Configuration ──────────────────────────────────
  // للتشغيل على الشبكة المحلية (Local Wi-Fi): اجعل isLocalMode = true واضبط localServerIp على IP اللابتوب
  static const bool isLocalMode = false;
  static const String localServerIp = '172.19.66.19';
  static const String liveServerUrl = 'mojowhrati-api.onrender.com';

  static String get apiBaseUrl {
    if (isLocalMode) {
      if (kIsWeb) {
        final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
        return 'http://$host:8000';
      }
      return 'http://$localServerIp:8000';
    }
    return 'https://$liveServerUrl';
  }

  // الرابط العام للمشاركة (QR codes, deep links)
  static String get publicBaseUrl => apiBaseUrl;

  // الروابط النهائية للـ API والملفات
  static String get baseUrl => '$apiBaseUrl/api/v1';
  static String get storageUrl => '$apiBaseUrl/storage';

  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;

  // Localization
  static const String currency = 'ر.ي';
  static const String countryCode = '+967';

  static const String placeholderImage = 'assets/images/logo.jpg';
  static const String logoPlaceholder = 'assets/images/logo.jpg';

  // Animations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // ── Laravel Reverb WebSocket ─────────────────────────────────
  // يجب أن يتطابق مع REVERB_APP_KEY في ملف .env الخاص بالـ Backend
  static const String reverbAppKey = 'z2weyntpqmksubfi6enb';

  static String get reverbPort => isLocalMode ? '8080' : '443';
  static String get reverbHost {
    if (isLocalMode) {
      if (kIsWeb) {
        return Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      }
      return localServerIp;
    }
    return liveServerUrl;
  }
}