import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';

void main() {
  Widget buildTestHost({
    required void Function(ArchiveExportResult? result) onResult,
    String subtitle = 'Test Faaliyeti Alt Başlık',
    String? initialTimeRange,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final result = await showArchiveExportSheet(
                  context,
                  subtitle: subtitle,
                  initialTimeRange: initialTimeRange,
                );
                onResult(result);
              },
              child: const Text('Aç'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('returns export result without time range when no hour is typed', (tester) async {
    ArchiveExportResult? received;
    await tester.pumpWidget(
      buildTestHost(onResult: (res) => received = res),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(find.text('Dışa Aktar ve Yazdır'), findsOneWidget);
    expect(find.text('Saat Aralığı (İsteğe Bağlı)'), findsOneWidget);

    // Directly tap Excel without touching hour input
    await tester.tap(find.text('Excel Olarak Aktar (.xlsx)'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.type, equals(ArchiveExportType.excel));
    expect(received!.timeRange, isNull);
  });

  testWidgets('returns typed time range when user fills hour input and taps print', (tester) async {
    ArchiveExportResult? received;
    await tester.pumpWidget(
      buildTestHost(onResult: (res) => received = res),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '06.00-08.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Doğrudan Yazdır'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.type, equals(ArchiveExportType.print));
    expect(received!.timeRange, equals('06.00-08.00'));
  });

  testWidgets('preset chip populates time field and clear button resets it', (tester) async {
    ArchiveExportResult? received;
    await tester.pumpWidget(
      buildTestHost(onResult: (res) => received = res),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    // Tap preset chip
    await tester.tap(find.text('20.00-08.00'));
    await tester.pumpAndSettle();

    expect(find.text('Temizle'), findsOneWidget);

    // Tap Temizle
    await tester.tap(find.text('Temizle'));
    await tester.pumpAndSettle();

    // Now tap PDF
    await tester.tap(find.text('PDF Belgesi Paylaş'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.type, equals(ArchiveExportType.pdf));
    expect(received!.timeRange, isNull);
  });
}
