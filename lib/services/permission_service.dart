import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool _isRequesting = false;

  static Future<bool> requestStoragePermission() async {
    if (_isRequesting) return false;
    _isRequesting = true;

    try {
      if (Platform.isAndroid) {
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

        Permission permission;

        if (sdk >= 33) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }

        final status = await permission.request();
        return status.isGranted;
      }

      return true;
    } finally {
      _isRequesting = false;
    }
  }
}