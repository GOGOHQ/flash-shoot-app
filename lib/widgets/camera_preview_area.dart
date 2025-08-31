import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'grid_painter.dart';

class CameraPreviewArea extends StatefulWidget {
  final CameraController? controller;
  final GridType gridType;
  final List<double> zoomLevels; // 自动检测到的可选倍率 (min ~ max)

  const CameraPreviewArea({
    super.key,
    required this.controller,
    required this.gridType,
    required this.zoomLevels,
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
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),

          /// 辅助线
          if (widget.gridType != GridType.none)
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(gridType: widget.gridType),
            ),

          /// 浮动显示当前倍率
          Positioned(
            bottom: 50, // 距离底部的距离
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_currentZoom.toStringAsFixed(1)}x",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
