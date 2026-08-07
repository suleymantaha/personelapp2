/// Helper utility for creating clean, readable export filenames across PDF and Excel.
/// Preserves Turkish characters (ç, ğ, ı, ö, ş, ü, Ç, Ğ, İ, Ö, Ş, Ü) while stripping
/// filesystem-forbidden characters (\ / : * ? " < > |).
String formatExportFileName({
  required String title,
  required String date,
  required String extension,
}) {
  // Replace OS invalid characters with '_'
  var cleanTitle = title
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_');

  // Strip leading/trailing underscores
  cleanTitle = cleanTitle.replaceAll(RegExp(r'^_+|_+$'), '');

  var cleanDate = date
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '-')
      .replaceAll(RegExp(r'\s+'), '_');

  final ext = extension.toLowerCase().replaceAll('.', '');

  if (cleanDate.isNotEmpty && !cleanTitle.contains(cleanDate)) {
    return '${cleanTitle}_$cleanDate.$ext';
  }
  return '$cleanTitle.$ext';
}
