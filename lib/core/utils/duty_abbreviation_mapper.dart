import 'package:flutter/material.dart';

/// Görev isimlerinin kısa kodlarını (Badge text) ve görsel renk temasını yöneten utility sınıfı.
class DutyAbbreviationMapper {
  static const Map<String, Map<String, dynamic>> _dutyConfig = {
    'GÜLÜŞKÜR': {
      'code': 'Gş',
      'lightBg': Color(0xFFE3F2FD),
      'darkBg': Color(0xFF15283B),
      'lightText': Color(0xFF1565C0),
      'darkText': Color(0xFF90CAF9),
    },
    'HAZIR KITA': {
      'code': 'H.K',
      'lightBg': Color(0xFFFFF3E0),
      'darkBg': Color(0xFF3E2723),
      'lightText': Color(0xFFE65100),
      'darkText': Color(0xFFFFB74D),
    },
    'NÖBET': {
      'code': 'Nbt',
      'lightBg': Color(0xFFFFEBEE),
      'darkBg': Color(0xFF3E1C1C),
      'lightText': Color(0xFFC62828),
      'darkText': Color(0xFFEF9A9A),
    },
    'İZİNLİ': {
      'code': 'İzn',
      'lightBg': Color(0xFFECEFF1),
      'darkBg': Color(0xFF263238),
      'lightText': Color(0xFF37474F),
      'darkText': Color(0xFFECEFF1),
    },
    'İSTİRAHATLİ': {
      'code': 'İst',
      'lightBg': Color(0xFFE8F5E9),
      'darkBg': Color(0xFF1B3820),
      'lightText': Color(0xFF2E7D32),
      'darkText': Color(0xFFA5D6A7),
    },
    'RAPORLU': {
      'code': 'Rpr',
      'lightBg': Color(0xFFFFF8E1),
      'darkBg': Color(0xFF3E3215),
      'lightText': Color(0xFFE65100),
      'darkText': Color(0xFFFFD54F),
    },
    'SEVK': {
      'code': 'Svk',
      'lightBg': Color(0xFFEDE7F6),
      'darkBg': Color(0xFF2C1A3E),
      'lightText': Color(0xFF6A1B9A),
      'darkText': Color(0xFFCE93D8),
    },
  };

  /// Verilen görev adına göre kısa kodu getirir (Örn: "Gülüşkür" -> "Gş").
  static String getAbbreviation(String fullName) {
    if (fullName.isEmpty) return '';
    final upper = fullName.toUpperCase().trim();
    if (_dutyConfig.containsKey(upper)) {
      return _dutyConfig[upper]!['code'] as String;
    }
    // Tanımsız görev ise ilk 3 harfini al
    return fullName.length > 3 ? fullName.substring(0, 3) : fullName;
  }

  /// Görev etiketinin arka plan rengini getirir.
  static Color getBadgeBgColor(String fullName, {bool isDark = false}) {
    final upper = fullName.toUpperCase().trim();
    if (_dutyConfig.containsKey(upper)) {
      return isDark
          ? _dutyConfig[upper]!['darkBg'] as Color
          : _dutyConfig[upper]!['lightBg'] as Color;
    }
    return isDark ? const Color(0xFF263238) : const Color(0xFFECEFF1);
  }

  /// Görev etiketinin metin rengini getirir.
  static Color getTextColor(String fullName, {bool isDark = false}) {
    final upper = fullName.toUpperCase().trim();
    if (_dutyConfig.containsKey(upper)) {
      return isDark
          ? _dutyConfig[upper]!['darkText'] as Color
          : _dutyConfig[upper]!['lightText'] as Color;
    }
    return isDark ? const Color(0xFFECEFF1) : const Color(0xFF37474F);
  }
}

