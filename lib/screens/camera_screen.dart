import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart'; // 导入系统设置

import '../config/app_routes.dart';
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
  List<CameraDescription>? camerasfb;
  List<double> _zoomLevels = [];
  bool _isFlashOn = false;
  GridType _gridType = GridType.none;
  String? _overlayImagePath;
  String? _overlayPosePath;

  // 对焦相关
  Offset? _focusPoint;
  bool _showFocusRect = false;

  // 浮动窗口拖动相关
  Offset _overlayImageOffset = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    // 禁止屏幕旋转
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 只允许竖屏
    ]);
    _initCamera();
  }

  @override
  void dispose() {
    // 恢复系统默认方向设置（如果你需要允许其他页面旋转的话）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.max,
          enableAudio: false,
        );

        camerasfb = _cameras!.where((c) =>
            c.lensDirection == CameraLensDirection.back ||
            c.lensDirection == CameraLensDirection.front).toList();

        await _cameraController!.initialize();

        final minZoom = await _cameraController!.getMinZoomLevel();
        final maxZoom = await _cameraController!.getMaxZoomLevel();

        final List<double> zoomLevels = [];
        for (double z = minZoom; z <= maxZoom; z += 1.0) {
          zoomLevels.add(double.parse(z.toStringAsFixed(1)));
        }

        if (mounted) {
          setState(() {
            _zoomLevels = zoomLevels;
          });
        }
      }
    } catch (e) {
      debugPrint("初始化相机失败: $e");
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

    try {
      final XFile file = await _cameraController!.takePicture();
      debugPrint("拍摄完成: ${file.path}");

      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        debugPrint("相册权限未授权，无法保存照片");
        return;
      }

      final result = await PhotoManager.editor.saveImageWithPath(file.path);
      if (result != null) {
        debugPrint("照片已保存到系统相册: $result");
      } else {
        debugPrint("照片保存失败");
      }
    } catch (e) {
      debugPrint("拍照或保存失败: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (camerasfb == null || camerasfb!.length < 2) return;

    try {
      final currentIndex = camerasfb!.indexOf(_cameraController!.description);
      final newIndex = (currentIndex == 0) ? 1 : 0;

      await _cameraController?.dispose();

      _cameraController = CameraController(
        camerasfb![newIndex],
        ResolutionPreset.max,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("切换前后摄像头失败: $e");
    }
  }

  void _onFocusTap(TapUpDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final dx = details.localPosition.dx / constraints.maxWidth;
    final dy = details.localPosition.dy / constraints.maxHeight;
    final offset = Offset(dx, dy);

    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);

      setState(() {
        _focusPoint = details.localPosition;
        _showFocusRect = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFocusRect = false;
          });
        }
      });
    } catch (e) {
      debugPrint("对焦失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            CameraTopBar(
              onClose: () => Navigator.pop(context),
              onToggleFlash: _toggleFlash,
              onToggleGrid: _toggleGrid,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _onFocusTap(details, constraints),
                    child: Stack(
                      children: [
                        CameraPreviewArea(
                          controller: _cameraController,
                          gridType: _gridType,
                          zoomLevels: _zoomLevels,
                          overlayPosePath: _overlayPosePath,
                        ),
                        if (_showFocusRect && _focusPoint != null)
                          Positioned(
                            left: _focusPoint!.dx - 30,
                            top: _focusPoint!.dy - 150,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        if (_overlayImagePath != null)
                          Positioned(
                            left: _overlayImageOffset.dx,
                            top: _overlayImageOffset.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _overlayImageOffset += details.delta;
                                  _overlayImageOffset = Offset(
                                    _overlayImageOffset.dx.clamp(0, constraints.maxWidth - 125),
                                    _overlayImageOffset.dy.clamp(0, constraints.maxHeight - 150),
                                  );
                                });
                              },
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.asset(
                                      _overlayImagePath!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                  maxHeight: 150,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black54,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _overlayImagePath!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            CameraBottomBar(
              onTakePicture: _takePicture,
              onSwitchCamera: _switchCamera,
              onSelectPose: ({required String imagePath, required String posePath}) {
                setState(() {
                  _overlayImagePath = imagePath;
                  _overlayPosePath = posePath;
                  _overlayImageOffset = const Offset(16, 16);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
