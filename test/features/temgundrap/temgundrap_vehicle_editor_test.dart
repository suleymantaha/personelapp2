import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_vehicle_editor.dart';

void main() {
  test('istenen araç türleri varsayılan katalogda yer alır', () {
    expect(
      defaultTemgundrapVehicleCatalog.keys,
      containsAll(['KOBRA', 'KİRPİ', 'KAMYON', 'HILUX', 'TOURNUE']),
    );
  });

  testWidgets('model seçilip plaka elle girilince aracı ekler', (tester) async {
    TemgundrapVehicleAssignment? added;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TemgundrapVehicleEditor(
      catalog: const {
        'TRANSİT': ['23 JAA 240']
      },
      vehicles: const [],
      onAdd: (value) => added = value,
      onRemove: (_) {},
    ))));
    await tester.tap(find.byKey(const Key('vehicle-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANSİT').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('vehicle-plate')), '23 abc 123');
    await tester.pump();
    await tester.tap(find.byKey(const Key('vehicle-add')));
    expect(added?.model, 'TRANSİT');
    expect(added?.plate, '23 ABC 123');
  });

  testWidgets('kayıtlı plaka hızlı seçimle kullanılabilir', (tester) async {
    TemgundrapVehicleAssignment? added;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TemgundrapVehicleEditor(
      catalog: const {
        'TRANSİT': ['23 JAA 240']
      },
      vehicles: const [],
      onAdd: (value) => added = value,
      onRemove: (_) {},
    ))));

    await tester.tap(find.byKey(const Key('vehicle-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANSİT').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-plate-23 JAA 240')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('vehicle-add')));

    expect(added?.plate, '23 JAA 240');
  });

  testWidgets('dar ekranda taşma üretmeden dikey yerleşir', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TemgundrapVehicleEditor(
      catalog: const {
        'TRANSİT': ['23 JAA 240']
      },
      vehicles: const [],
      onAdd: (_) {},
      onRemove: (_) {},
    ))));
    expect(tester.takeException(), isNull);
  });
}
