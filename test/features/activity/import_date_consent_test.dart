import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/import_date_consent.dart';

void main() {
  final now = DateTime(2026, 11, 3, 23, 59);
  Future<void> open(
    WidgetTester tester,
    List<String> dates, {
    String? targetDate,
    required ValueChanged<bool> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async => onResult(
                  await confirmImportDates(
                    context: context,
                    dates: dates,
                    targetDate: targetDate,
                    now: now,
                  ),
                ),
                child: const Text('Kaydet'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
  }

  testWidgets('today and next three calendar days need no extra consent', (
    tester,
  ) async {
    bool? result;
    await open(
        tester,
        [
          '2026-11-03',
          '2026-11-04',
          '2026-11-05',
          '2026-11-06',
        ],
        onResult: (value) => result = value);
    expect(result, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('past day asks before save and cancellation denies the write', (
    tester,
  ) async {
    bool? result;
    await open(tester, ['2026-11-02'], onResult: (value) => result = value);
    expect(result, isNull);
    expect(find.textContaining('02.11.2026'), findsOneWidget);
    expect(find.textContaining('Geçmiş tarih'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-date-cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('four days ahead requires explicit approval', (tester) async {
    bool? result;
    await open(tester, ['2026-11-07'], onResult: (value) => result = value);
    expect(result, isNull);
    expect(find.textContaining('3 günden fazla'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-date-approve')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('mixed dates are reviewed together and dismissal denies save', (
    tester,
  ) async {
    bool? result;
    await open(
        tester,
        [
          '2026-11-01',
          '2026-11-08',
          '2026-11-01',
        ],
        onResult: (value) => result = value);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('01.11.2026'), findsOneWidget);
    expect(find.textContaining('08.11.2026'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('source versus existing target date is never silently replaced', (
    tester,
  ) async {
    bool? result;
    await open(
      tester,
      ['2026-11-05'],
      targetDate: '2026-11-03',
      onResult: (value) => result = value,
    );
    expect(result, isNull);
    expect(find.textContaining('05.11.2026'), findsOneWidget);
    expect(find.textContaining('03.11.2026'), findsOneWidget);
    expect(find.textContaining('Yeni kart oluşturulmayacak'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-date-cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('invalid calendar date cannot be approved', (tester) async {
    bool? result;
    await open(tester, ['2026-02-31'], onResult: (value) => result = value);
    expect(find.byKey(const Key('import-date-approve')), findsNothing);
    await tester.tap(find.byKey(const Key('import-date-cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
