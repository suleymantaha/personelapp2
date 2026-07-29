import 'package:shared_preferences/shared_preferences.dart';

class BulkImportPreferences {
  const BulkImportPreferences();

  static const String _keepAuditTextKey = 'bulk_import_keep_audit_text_enabled';

  Future<bool> loadKeepAuditText() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_keepAuditTextKey) ?? false;
  }

  Future<void> saveKeepAuditText(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keepAuditTextKey, value);
  }
}
