import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DeviceInstallationService {
  static const _fileName = 'device_installation_id.txt';
  final _uuid = const Uuid();

  Future<String> getOrCreateDeviceId() async {
    final file = await _getFile();
    if (await file.exists()) {
      final value = (await file.readAsString()).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    final newId = _uuid.v4();
    await file.writeAsString(newId);
    return newId;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
