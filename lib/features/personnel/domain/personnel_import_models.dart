import 'dart:convert';

import 'package:personelapp2/core/utils/rank_helper.dart';

/// Shared by the preview and persistence so both detect the same repeated rows.
/// A name and rank alone do not identify a person across different teams/units.
String personnelImportKey({
  required String name,
  required String rank,
  required String unit,
  int? teamId,
}) {
  String fold(String value) => value
      .trim()
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ');
  final normalizedRank = normalizeRank(rank.trim());
  return jsonEncode([
    fold(name),
    fold(normalizedRank.isEmpty ? 'J.Er' : normalizedRank),
    teamId,
    if (teamId == null) fold(unit.trim().isEmpty ? 'Asayiş Timi' : unit),
  ]);
}

class PersonnelImportEntry {
  const PersonnelImportEntry({
    required this.adSoyad,
    required this.rutbe,
    required this.birlik,
    this.timId,
    this.existingPersonnelId,
    this.allowDuplicate = false,
    this.skip = false,
  });

  final String adSoyad;
  final String rutbe;
  final String birlik;
  final int? timId;
  final int? existingPersonnelId;
  final bool allowDuplicate;
  final bool skip;
}

class PersonnelImportResult {
  const PersonnelImportResult({
    required this.addedCount,
    required this.skippedCount,
    this.updatedCount = 0,
  });

  final int addedCount;
  final int skippedCount;
  final int updatedCount;
}
