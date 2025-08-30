import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/camera_top_bar.dart';
import '../widgets/camera_preview_area.dart';
import '../widgets/camera_bottom_bar.dart';
import '../widgets/grid_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  GridType _gridType = GridType.none;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  void _toggleGrid() {
    setState(() {
      switch (_gridType) {
        case GridType.none:
          _gridType = GridType.ruleOfThirds;
          break;
        case GridType.ruleOfThirds:
          _gridType = GridType.diagonals;
          break;
        case GridType.diagonals:
          _gridType = GridType.cross;
          break;
        case GridType.cross:
          _gridType = GridType.goldenRatio;
          break;
        case GridType.goldenRatio:
          _gridType = GridType.none;
          break;
      }
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final file = await _cameraController!.takePicture();
    debugPrint("拍摄完成: ${file.path}");
    // TODO: 保存或跳转到预览页
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentIndex = _cameras!.indexOf(_cameraController!.description);
    final newIndex = (currentIndex + 1) % _cameras!.length;

    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// 顶部栏
            CameraTopBar(
              onClose: () => Navigator.pop(context),
              onToggleFlash: _toggleFlash,
              onToggleGrid: _toggleGrid,
            ),

            /// 相机预览区
            Expanded(
              child: CameraPreviewArea(
                controller: _cameraController,
                gridType: _gridType,
              ),
            ),

            /// 底部栏
            CameraBottomBar(
              onTakePicture: _takePicture,
              onSwitchCamera: _switchCamera,
            ),
          ],
        ),
      ),
    );
  }
}
