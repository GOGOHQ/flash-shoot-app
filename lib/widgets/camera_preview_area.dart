import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'grid_painter.dart';

class CameraPreviewArea extends StatefulWidget {
  final CameraController? controller;
  final GridType gridType;

  const CameraPreviewArea({
    super.key,
    required this.controller,
    required this.gridType,
  });

  @override
  State<CameraPreviewArea> createState() => _CameraPreviewAreaState();
}

class _CameraPreviewAreaState extends State<CameraPreviewArea> {
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 5.0;
  List<double> _availableZoomLevels = [1.0, 2.0, 5.0];

  Offset? _dragStartOffset;
  double _dragStartZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initZoomLevels();
  }

  Future<void> _initZoomLevels() async {
    if (widget.controller == null) return;
    try {
      _minZoom = await widget.controller!.getMinZoomLevel();
      _maxZoom = await widget.controller!.getMaxZoomLevel();

      final levels = [1.0, 2.0, 3.0, 5.0];
      _availableZoomLevels = levels
          .where((z) => z >= _minZoom && z <= _maxZoom)
          .toList();

      if (_availableZoomLevels.isEmpty) {
        _availableZoomLevels = [_minZoom];
      }

      setState(() {});
    } catch (e) {
      debugPrint("获取相机缩放信息失败: $e");
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (widget.controller == null) return;
    try {
      final clamped = zoom.clamp(_minZoom, _maxZoom);
      await widget.controller!.setZoomLevel(clamped);
      setState(() {
        _currentZoom = clamped;
      });
    } catch (e) {
      debugPrint("设置缩放失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: widget.controller!.value.aspectRatio,
          child: CameraPreview(widget.controller!),
        ),
        if (widget.gridType != GridType.none)
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(gridType: widget.gridType),
          ),

        /// 底部倍率按钮
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _availableZoomLevels.map((zoom) {
              final isSelected = zoom == _currentZoom;
              return GestureDetector(
                onTap: () => _setZoom(zoom),
                onLongPressStart: (details) {
                  _dragStartOffset = details.globalPosition;
                  _dragStartZoom = _currentZoom;
                },
                onLongPressMoveUpdate: (details) {
                  if (_dragStartOffset != null) {
                    final dy = _dragStartOffset!.dy - details.globalPosition.dy;
                    final deltaZoom = dy * 0.01; // 灵敏度
                    _setZoom(_dragStartZoom + deltaZoom);
                  }
                },
                onLongPressEnd: (_) {
                  _dragStartOffset = null;
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    zoom.toStringAsFixed(1).replaceAll('.0', ''),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
