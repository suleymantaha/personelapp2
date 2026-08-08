import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_commander_picker.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_vehicle_editor.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_strength_editor.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

void main() {
  group('Temgundrap Widgets & Pickers Tests', () {
    testWidgets('TemgundrapCommanderPicker renders options and responds to selection', (WidgetTester tester) async {
      const options = [
        TemgundrapCommanderOption(id: 1, name: 'Ahmet Yılmaz', rank: 'Yüzbaşı'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemgundrapCommanderPicker(
              options: options,
              onChanged: (selected) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TemgundrapCommanderPicker), findsOneWidget);
    });

    testWidgets('TemgundrapVehicleEditor renders vehicle catalog and list buttons', (WidgetTester tester) async {
      const catalog = {
        'Kobra': ['23-01', '23-02'],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemgundrapVehicleEditor(
              catalog: catalog,
              vehicles: const [],
              onAdd: (assignment) {},
              onRemove: (index) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TemgundrapVehicleEditor), findsOneWidget);
    });

    testWidgets('TemgundrapStrengthEditor renders officer/NCO counts and inputs', (WidgetTester tester) async {
      const strength = TemgundrapStrength(
        officer: 2,
        nco: 5,
        specialistGendarmerie: 3,
        specialistSergeant: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemgundrapStrengthEditor(
              value: strength,
              onChanged: (updated) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TemgundrapStrengthEditor), findsOneWidget);
    });
  });
}
