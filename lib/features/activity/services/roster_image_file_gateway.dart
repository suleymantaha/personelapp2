import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'roster_share_file.dart';

/// Use the existing Android document picker to avoid storage permissions.
Future<bool> saveRosterImageFile(String name, Uint8List bytes,
    {Rect? shareOrigin}) async {
  if (kIsWeb) {
    await XFile.fromData(bytes, name: name, mimeType: 'image/png').saveTo(name);
    return true;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return await const MethodChannel('nizam/backup_files').invokeMethod<bool>(
            'saveBackup',
            {'name': name, 'mimeType': 'image/png', 'bytes': bytes}) ??
        false;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final file = await createRosterShareFile(name, bytes);
    final result = await SharePlus.instance
        .share(ShareParams(files: [file], sharePositionOrigin: shareOrigin));
    return result.status == ShareResultStatus.success;
  }
  final location =
      await getSaveLocation(suggestedName: name, acceptedTypeGroups: const [
    XTypeGroup(label: 'PNG', extensions: ['png'])
  ]);
  if (location == null) return false;
  await XFile.fromData(bytes, mimeType: 'image/png').saveTo(location.path);
  return true;
}
