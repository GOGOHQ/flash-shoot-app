import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../config/app_routes.dart';
import '../screens/pose_library_screen.dart';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';


class CameraBottomBar extends StatefulWidget {
  final VoidCallback? onTakePicture;
  final VoidCallback? onSwitchCamera;
  final void Function({
    required String imagePath,
    required String posePath,
  })? onSelectPose;

  const CameraBottomBar({
    super.key,
    this.onTakePicture,
    this.onSwitchCamera,
    this.onSelectPose,
  });

  @override
  State<CameraBottomBar> createState() => _CameraBottomBarState();
}

class _CameraBottomBarState extends State<CameraBottomBar> {
  AssetEntity? _firstAsset;
  Uint8List? _thumbData;
  
  // 自动获取的 user_id
  String? userId;

  @override
  void initState() {
    super.initState();
    _initUserId();
    _loadFirstAsset();
  }

    // 获取设备唯一标识作为 user_id
  Future<void> _initUserId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        userId = iosInfo.identifierForVendor ?? 'ios_guest';
      });
    } else {
      setState(() {
        userId = 'unknown';
      });
    }
  }

  Future<void> _loadFirstAsset() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isNotEmpty) {
      final recent = albums.first;
      final assets = await recent.getAssetListRange(start: 0, end: 1);
      if (assets.isNotEmpty) {
        final thumb = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize(200, 200), // 注意这里要传 ThumbnailSize
        );
        setState(() {
          _firstAsset = assets.first;
          _thumbData = thumb;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 左边：相册预览入口
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.gallery);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _thumbData == null
                      ? const Icon(Icons.photo, color: Colors.white)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _thumbData!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              Row(
                children: [
                  /// 姿势库预览入口
                  GestureDetector(
                    onTap: () {
                      if (widget.onSelectPose != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PoseLibraryScreen(
                              userId: userId ?? 'unknown',
                              onSelectPose: (imagePath, posePath) {
                                widget.onSelectPose!(
                                  imagePath: imagePath,
                                  posePath: posePath,
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, AppRoutes.poseLibrary);
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey,
                      child: const Icon(Icons.accessibility_new, color: Colors.white),
                    ),
                  ),

                  /// 前后相机切换按钮
                  IconButton(
                    onPressed: widget.onSwitchCamera,
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ],
          ),

          /// 中间：拍摄按钮
          GestureDetector(
            onTap: widget.onTakePicture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
