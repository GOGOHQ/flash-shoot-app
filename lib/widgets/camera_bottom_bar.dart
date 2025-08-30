import 'package:flutter/material.dart';
import '../config/app_routes.dart';

class CameraBottomBar extends StatelessWidget {
  final VoidCallback? onTakePicture;
  final VoidCallback? onSwitchCamera;

  const CameraBottomBar({
    super.key,
    this.onTakePicture,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          /// 相册预览入口
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.gallery); // 先定义路由接口
            },
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey, // 先用灰色占位，后续换成缩略图
              child: const Icon(Icons.photo, color: Colors.white),
            ),
          ),

          /// 拍摄按钮
          GestureDetector(
            onTap: onTakePicture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
          ),

          /// 姿势库预览入口
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.poseLibrary); // 先定义路由接口
            },
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey, // 先用灰色占位，后续换成姿势库缩略图
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
    );
  }
}
