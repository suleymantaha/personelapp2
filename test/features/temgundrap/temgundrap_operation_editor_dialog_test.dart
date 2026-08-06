import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_operation_editor_dialog.dart';

void main() {
  testWidgets('operasyon formunu bağımsız bölümlerle gösterir', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allPersonnelProvider
            .overrideWith((ref) => Stream.value(<PersonelTableData>[]))
      ],
      child: const MaterialApp(home: TemgundrapOperationEditorDialog()),
    ));
    await tester.pump();
    expect(find.byKey(const Key('issuing-unit')), findsOneWidget);
    expect(find.byKey(const Key('operation-area-picker')), findsOneWidget);
    expect(find.byKey(const Key('operation-purpose')), findsOneWidget);
    expect(find.byKey(const Key('strength-total')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('vehicle-model')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('vehicle-model')), findsOneWidget);
  });
}
