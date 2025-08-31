import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'grid_painter.dart';

class CameraPreviewArea extends StatefulWidget {
  final CameraController? controller;
  final GridType gridType;
  final List<double> zoomLevels; // 自动检测到的可选倍率 (min ~ max)
  final String? overlayImagePath; // 新增

  const CameraPreviewArea({
    super.key,
    required this.controller,
    required this.gridType,
    required this.zoomLevels,
    this.overlayImagePath, // 新增
  });

  @override
  State<CameraPreviewArea> createState() => _CameraPreviewAreaState();
}

class _CameraPreviewAreaState extends State<CameraPreviewArea> {
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  double get _minZoom =>
      widget.zoomLevels.isNotEmpty ? widget.zoomLevels.first : 1.0;
  double get _maxZoom =>
      widget.zoomLevels.isNotEmpty ? widget.zoomLevels.last : 5.0;

  @override
  void initState() {
    super.initState();
    _currentZoom = _minZoom;
  }

  Future<void> _setZoom(double zoom) async {
    if (widget.controller != null && widget.controller!.value.isInitialized) {
      final clamped = zoom.clamp(_minZoom, _maxZoom);
      await widget.controller!.setZoomLevel(clamped);
      setState(() {
        _currentZoom = clamped;
      });
    }
  }
  
  Widget _buildZoomButton(double value) {
    return GestureDetector(
      onTap: () => _setZoom(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          "${value.toStringAsFixed(1)}x",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onScaleStart: (details) {
        _baseZoom = _currentZoom;
      },
      onScaleUpdate: (details) {
        final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
        _setZoom(newZoom);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// 相机预览
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),

          /// 辅助线
          if (widget.gridType != GridType.none)
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(gridType: widget.gridType),
            ),
          
          // 姿势叠加图
          if (widget.overlayImagePath != null)
            Opacity(
              opacity: 0.5, // 半透明
              child: Image.asset(
                widget.overlayImagePath!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          /// 浮动显示当前倍率 + 固定倍率按钮
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 左侧固定倍率按钮
                _buildZoomButton(1.0),
                const SizedBox(width: 8),
                _buildZoomButton(2.0),
                const SizedBox(width: 8),
                /// 当前倍率显示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_currentZoom.toStringAsFixed(1)}x",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                const SizedBox(width: 8),
                /// 右侧固定倍率按钮
                _buildZoomButton(3.0),
                const SizedBox(width: 8),
                _buildZoomButton(5.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
