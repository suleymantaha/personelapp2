import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_header_banner.dart';

void main() {
  Future<void> render(WidgetTester tester, {required bool imageImport}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BulkImportHeaderBanner(
            isKeyboardVisible: false,
            isImageImport: imageImport,
            onBack: () {},
            onClose: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('OCR uses image-specific title in shared import header',
      (tester) async {
    await render(tester, imageImport: true);
    expect(find.text('Görselden Toplu Aktar'), findsOneWidget);
    expect(find.text('Metinden Toplu Aktarım'), findsNothing);
  });

  testWidgets('normal paste mode keeps text-specific title', (tester) async {
    await render(tester, imageImport: false);
    expect(find.text('Metinden Toplu Aktarım'), findsOneWidget);
    expect(find.text('Görselden Toplu Aktar'), findsNothing);
  });
}
