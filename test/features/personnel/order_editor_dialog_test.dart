import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/order_editor_dialog.dart';

void main() {
  Future<void> open(
          WidgetTester tester, Future<void> Function(List<int>) save) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: OrderEditorDialog(
        title: 'Personel sırası',
        items: const [OrderEditorItem(1, 'Ali'), OrderEditorItem(2, 'Veli')],
        onSave: save,
      ))));
  testWidgets('move changes draft; only Save persists selected order',
      (tester) async {
    List<int>? saved;
    await open(tester, (ids) async {
      saved = ids;
    });
    await tester.tap(find.byKey(const ValueKey('move-down-1')));
    await tester.pump();
    expect(saved, isNull);
    expect(tester.getTopLeft(find.text('Veli')).dy,
        lessThan(tester.getTopLeft(find.text('Ali')).dy));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(saved, [2, 1]);
  });
  testWidgets('failed save keeps edited draft and shows actionable error',
      (tester) async {
    await open(tester, (_) async {
      throw StateError('Liste değişti');
    });
    await tester.tap(find.byKey(const ValueKey('move-down-1')));
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kaydedilemedi'), findsOneWidget);
    expect(find.text('Veli'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dragging a row persists the same order as arrow controls',
      (tester) async {
    List<int>? saved;
    await open(tester, (ids) async {
      saved = ids;
    });
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ReorderableDragStartListener).first));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(saved, [2, 1]);
  });
  testWidgets('cancel discards moved draft without writing', (tester) async {
    var saved = false;
    await open(tester, (_) async {
      saved = true;
    });
    await tester.tap(find.byKey(const ValueKey('move-down-1')));
    await tester.pump();
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
  });
  testWidgets('order editor works at phone width and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, (_) async {});
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('move-down-1')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
