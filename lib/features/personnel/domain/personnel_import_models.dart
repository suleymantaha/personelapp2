class PersonnelImportEntry {
  const PersonnelImportEntry({
    required this.adSoyad,
    required this.rutbe,
    required this.birlik,
    this.timId,
  });

  final String adSoyad;
  final String rutbe;
  final String birlik;
  final int? timId;
}

class PersonnelImportResult {
  const PersonnelImportResult({
    required this.addedCount,
    required this.skippedCount,
  });

  final int addedCount;
  final int skippedCount;
}
