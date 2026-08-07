import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class BackupFileGateway {
  Future<bool> saveBackup(String contents, {Rect? shareOrigin});

  Future<String?> openBackup();
}

class DeviceBackupFileGateway implements BackupFileGateway {
  static const MethodChannel _androidFiles = MethodChannel(
    'nizam/backup_files',
  );
  static const XTypeGroup _backupType = XTypeGroup(
    label: 'Nizam yedek dosyası',
    extensions: <String>['nizam', 'json'],
    mimeTypes: <String>['application/json'],
  );
  static const XTypeGroup _androidBackupType = XTypeGroup(
    label: 'Nizam yedek dosyası',
  );

  @override
  Future<bool> saveBackup(String contents, {Rect? shareOrigin}) async {
    final filename = _filename();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _androidFiles.invokeMethod<bool>('saveBackup', {
            'name': filename,
            'mimeType': 'application/json',
            'bytes': Uint8List.fromList(utf8.encode(contents)),
          }) ??
          false;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final directory = await getTemporaryDirectory();
      final file = XFile.fromData(
        utf8.encode(contents),
        mimeType: 'application/json',
        name: filename,
        path: '${directory.path}/$filename',
      );
      await file.saveTo(file.path);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[file],
          subject: 'Nizam uygulama yedeği',
          text:
              'Bu dosyayı cihazın yerel depolamasında güvenli bir klasöre kaydedin.',
          sharePositionOrigin: shareOrigin,
        ),
      );
      return result.status != ShareResultStatus.dismissed;
    }

    final location = await getSaveLocation(
      suggestedName: filename,
      acceptedTypeGroups: const <XTypeGroup>[_backupType],
      confirmButtonText: 'Yedeği kaydet',
    );
    if (location == null) return false;
    final file = XFile.fromData(
      utf8.encode(contents),
      mimeType: 'application/json',
      name: filename,
    );
    await file.saveTo(location.path);
    return true;
  }

  @override
  Future<String?> openBackup() async {
    final file = await openFile(
      acceptedTypeGroups:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? const <XTypeGroup>[_androidBackupType]
              : const <XTypeGroup>[_backupType],
      confirmButtonText: 'Yedeği seç',
    );
    return file?.readAsString();
  }

  String _filename() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Nizam_Yedek_${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}-${two(now.minute)}.nizam';
  }
}
