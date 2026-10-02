import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_form_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('back asks before discarding an edited document', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TemgundrapFormScreen())),
      child: const Text('AÇ'),
    )))));
    await tester.tap(find.text('AÇ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('document-unit-title')), 'DÜZENLENEN BİRLİK');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Değişikliklerden vazgeçilsin mi?'), findsOneWidget);
    expect(find.byType(TemgundrapFormScreen), findsOneWidget);
    await tester.tap(find.text('DÜZENLEMEYE DEVAM ET'));
    await tester.pumpAndSettle();
    expect(find.text('DÜZENLENEN BİRLİK'), findsOneWidget);
  });

  test('corrupt stored documents produce a recoverable error without overwrite', () async {
    SharedPreferences.setMockInitialValues({'temgundrap_documents_v1': '{broken'});
    await expectLater(TemgundrapRepository().getAll(), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('TEMGÜNDRAP'))));
    expect((await SharedPreferences.getInstance()).getString('temgundrap_documents_v1'), '{broken');
  });
  test('repeated TEMGUN Excel shares have immutable attachment names', () async {
    final directory = await Directory.systemTemp.createTemp('temgun_test_');
    addTearDown(() => directory.delete(recursive: true));
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    final attachments = <String>[];
    messenger.setMockMethodCallHandler(paths, (_) async => directory.path);
    messenger.setMockMethodCallHandler(share, (call) async {
      attachments.add(((call.arguments as Map)['paths'] as List).single as String);
      return 'dev.test.viewer';
    });
    addTearDown(() { messenger.setMockMethodCallHandler(paths, null); messenger.setMockMethodCallHandler(share, null); });
    final document = TemgundrapDocument(id: 'same', date: DateTime(2026, 10, 2), unitTitle: 'BİRLİK', approverName: '', approverRank: '', approverDuty: '', operations: const [], isDraft: true, updatedAt: DateTime(2026, 10, 2));
    await TemgundrapExcelExporter.share(document);
    final original = await File(attachments.single).readAsBytes();
    await TemgundrapExcelExporter.share(TemgundrapDocument.fromJson({...document.toJson(), 'approverName': 'YENİ KOMUTAN'}));
    expect(attachments.last.split(Platform.pathSeparator).last, isNot(attachments.first.split(Platform.pathSeparator).last));
    expect(await File(attachments.first).readAsBytes(), original);
  });
}
