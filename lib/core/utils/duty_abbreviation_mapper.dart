import 'package:flutter/material.dart';

/// Görev isimlerinin kısa kodlarını (Badge text) ve görsel renk temasını yöneten utility sınıfı.
class DutyAbbreviationMapper {
  static const Map<String, Map<String, dynamic>> _dutyConfig = {
    'GÜLÜŞKÜR': {
      'code': 'Gş',
      'lightBg': Color(0xFFE3F2FD),
      'darkBg': Color(0xFF0D47A1),
      'lightText': Color(0xFF1565C0),
      'darkText': Color(0xFF90CAF9),
    },
    'HAZIR KITA': {
      'code': 'H.K',
      'lightBg': Color(0xFFFFF3E0),
      'darkBg': Color(0xFFE65100),
      'lightText': Color(0xFFE65100),
      'darkText': Color(0xFFFFCC80),
    },
    'NÖBET': {
      'code': 'Nbt',
      'lightBg': Color(0xFFFFEBEE),
      'darkBg': Color(0xFFB71C1C),
      'lightText': Color(0xFFC62828),
      'darkText': Color(0xFFEF9A9A),
    },
    'İZİNLİ': {
      'code': 'İzn',
      'lightBg': Color(0xFFF5F5F5),
      'darkBg': Color(0xFF424242),
      'lightText': Color(0xFF616161),
      'darkText': Color(0xFFE0E0E0),
    },
    'İSTİRAHATLİ': {
      'code': 'İst',
      'lightBg': Color(0xFFE8F5E9),
      'darkBg': Color(0xFF1B5E20),
      'lightText': Color(0xFF2E7D32),
      'darkText': Color(0xFFA5D6A7),
    },
    'RAPORLU': {
      'code': 'Rpr',
      'lightBg': Color(0xFFFFF8E1),
      'darkBg': Color(0xFFF57F17),
      'lightText': Color(0xFFF57F17),
      'darkText': Color(0xFFFFE082),
    },
    'SEVK': {
      'code': 'Svk',
      'lightBg': Color(0xFFEDE7F6),
      'darkBg': Color(0xFF4A148C),
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
    return isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100;
  }

  /// Görev etiketinin metin rengini getirir.
  static Color getTextColor(String fullName, {bool isDark = false}) {
    final upper = fullName.toUpperCase().trim();
    if (_dutyConfig.containsKey(upper)) {
      return isDark
          ? _dutyConfig[upper]!['darkText'] as Color
          : _dutyConfig[upper]!['lightText'] as Color;
    }
    return isDark ? Colors.white70 : Colors.blueGrey.shade900;
  }
}
