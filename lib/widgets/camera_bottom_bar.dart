import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import '../screens/pose_library_screen.dart';

class CameraBottomBar extends StatelessWidget {
  final VoidCallback? onTakePicture;
  final VoidCallback? onSwitchCamera;
  final void Function(String)? onSelectPose; // 新增


  const CameraBottomBar({
    super.key,
    this.onTakePicture,
    this.onSwitchCamera,
    this.onSelectPose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// 左右功能按钮
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
                  color: Colors.grey,
                  child: const Icon(Icons.photo, color: Colors.white),
                ),
              ),

              Row(
                children: [
                  /// 姿势库预览入口
                  GestureDetector(
                    onTap: () {
                      if (onSelectPose != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PoseLibraryScreen(onSelectPose: onSelectPose),
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
                    onPressed: onSwitchCamera,
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ],
          ),

          /// 中间：拍摄按钮（始终居中）
          /// 中间：拍摄按钮（始终居中）
          GestureDetector(
            onTap: onTakePicture,
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
