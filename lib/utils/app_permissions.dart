import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppPermissions {
  /// 请求相机和存储/相册权限
  static Future<bool> requestCameraAndStorage() async {
    if (kIsWeb) {
      // Web 环境下不需要手动申请权限
      return true;
    }

    // final cameraStatus = await Permission.camera.request();
    final cameraStatus = PermissionStatus.granted;
    print("Camera status: $cameraStatus");

    PermissionStatus storageStatus = PermissionStatus.granted;
    PermissionStatus photosStatus = PermissionStatus.granted;

    // if (Platform.isAndroid) {
    //   storageStatus = await Permission.storage.request();
    // } else if (Platform.isIOS) {
    //   photosStatus = await Permission.photos.request();
    //   print("photosStatus status: $photosStatus");
    // }

    return cameraStatus.isGranted &&
        (storageStatus.isGranted || photosStatus.isGranted);
  }

  /// 检查是否有相机权限
  static Future<bool> hasCameraPermission() async {
    if (kIsWeb) return true;
    return await Permission.camera.isGranted;
  }

  /// 检查是否有相册权限
  static Future<bool> hasGalleryPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      return await Permission.storage.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    return true;
  }

  /// 打开系统设置，让用户手动开启权限
  static Future<void> openAppSettingsPage() async {
    if (!kIsWeb) {
      await openAppSettings();
    }
  }
}
