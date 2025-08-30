import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'grid_painter.dart';

class CameraPreviewArea extends StatelessWidget {
  final CameraController? controller;
  final GridType gridType;

  const CameraPreviewArea({
    super.key,
    required this.controller,
    required this.gridType,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: CameraPreview(controller!),
        ),
        if (gridType != GridType.none)
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(gridType: gridType),
          ),
      ],
    );
  }
}
