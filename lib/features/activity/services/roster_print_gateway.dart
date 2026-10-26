import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Sends an already generated PDF to the platform print dialog.
class RosterPrintGateway {
  const RosterPrintGateway({
    MethodChannel channel = const MethodChannel('nizam/roster_print'),
    Future<bool> Function(String, Uint8List)? standardPrint,
    bool? android,
  })  : _channel = channel,
        _standardPrint = standardPrint,
        _android = android;

  final MethodChannel _channel;
  final Future<bool> Function(String, Uint8List)? _standardPrint;
  final bool? _android;

  Future<void> printDocument({
    required String name,
    required pw.Document document,
  }) async {
    final bytes = await document.save();
    final pageCount = document.document.pdfPageList.pages.length;
    if (pageCount < 1) {
      throw StateError('Cannot print a PDF without pages.');
    }

    if (_android ?? defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('printPdf', {
          'name': name,
          'bytes': bytes,
          'pageCount': pageCount,
        });
        return;
      } on MissingPluginException {
        // Older Android builds do not have the native print channel.
      } on PlatformException catch (error) {
        if (error.code != 'UNSUPPORTED') rethrow;
      }
    }

    if (_standardPrint != null) {
      await _standardPrint(name, bytes);
    } else {
      await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
    }
  }
}
