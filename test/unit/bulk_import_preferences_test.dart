import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/bulk_import_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const preferences = BulkImportPreferences();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('audit text preference is disabled until explicitly enabled', () async {
    expect(await preferences.loadKeepAuditText(), isFalse);
  });

  test('audit text preference survives later service instances', () async {
    await preferences.saveKeepAuditText(true);

    expect(
      await const BulkImportPreferences().loadKeepAuditText(),
      isTrue,
    );

    await preferences.saveKeepAuditText(false);
    expect(await preferences.loadKeepAuditText(), isFalse);
  });
}
