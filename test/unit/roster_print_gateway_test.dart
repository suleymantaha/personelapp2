import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/features/activity/services/roster_print_gateway.dart';

const _channel = MethodChannel('nizam/roster_print');

pw.Document _document(int pages) {
  final document = pw.Document();
  for (var index = 0; index < pages; index++) {
    document.addPage(pw.Page(build: (_) => pw.Text('Page ${index + 1}')));
  }
  return document;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final pages in [1, 2, 3]) {
    test('Android gets the actual $pages-page PDF and page count', () async {
      Map<Object?, Object?>? arguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        expect(call.method, 'printPdf');
        arguments = call.arguments as Map<Object?, Object?>;
        return null;
      });
      final document = _document(pages);
      var fallbackCalled = false;
      await RosterPrintGateway(
        android: true,
        standardPrint: (_, __) async {
          fallbackCalled = true;
          return true;
        },
      ).printDocument(name: 'Roster', document: document);

      expect(arguments?['name'], 'Roster');
      expect(arguments?['pageCount'], pages);
      expect(arguments?['bytes'], isA<Uint8List>());
      expect((arguments?['bytes'] as Uint8List).sublist(0, 5),
          [37, 80, 68, 70, 45]);
      expect(fallbackCalled, isFalse);
    });
  }

  test('non-Android uses the existing printing path', () async {
    var nativeCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async {
      nativeCalled = true;
      return null;
    });
    Uint8List? fallbackBytes;
    await RosterPrintGateway(
      android: false,
      standardPrint: (_, bytes) async {
        fallbackBytes = bytes;
        return true;
      },
    ).printDocument(name: 'Roster', document: _document(1));
    expect(nativeCalled, isFalse);
    expect(fallbackBytes, isNotEmpty);
  });

  for (final failure in ['missing', 'unsupported']) {
    test('$failure native channel falls back to printing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (_) async {
        if (failure == 'missing') throw MissingPluginException();
        throw PlatformException(code: 'UNSUPPORTED');
      });
      var fallbackCalled = false;
      await RosterPrintGateway(
        android: true,
        standardPrint: (_, __) async {
          fallbackCalled = true;
          return true;
        },
      ).printDocument(name: 'Roster', document: _document(1));
      expect(fallbackCalled, isTrue);
    });
  }

  test('native print failure propagates without opening a second dialog',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async {
      throw PlatformException(code: 'PRINT_FAILED');
    });
    var fallbackCalled = false;
    await expectLater(
      RosterPrintGateway(
        android: true,
        standardPrint: (_, __) async {
          fallbackCalled = true;
          return true;
        },
      ).printDocument(name: 'Roster', document: _document(1)),
      throwsA(isA<PlatformException>()),
    );
    expect(fallbackCalled, isFalse);
  });
}
