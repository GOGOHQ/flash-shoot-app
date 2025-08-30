import 'package:flutter/material.dart';

class CameraTopBar extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onToggleFlash;
  final VoidCallback? onToggleGrid;

  const CameraTopBar({
    super.key,
    this.onClose,
    this.onToggleFlash,
    this.onToggleGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 左边关闭按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),

          /// 右边操作按钮：闪光灯、构图线
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: onToggleFlash,
              ),
              IconButton(
                icon: const Icon(Icons.grid_on, color: Colors.white),
                onPressed: onToggleGrid,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
