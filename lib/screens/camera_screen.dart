import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
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
  String? _overlayImagePath; // ✅ 在这里定义
  String? _overlayPosePath; // ✅ 在这里定义

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      // 只保留前置和后置摄像头

      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.max,
          enableAudio: false,
        );
        camerasfb = _cameras!.where((c) =>
            c.lensDirection == CameraLensDirection.back ||
            c.lensDirection == CameraLensDirection.front
        ).toList();
        await _cameraController!.initialize();

        // 读取相机支持的倍率范围
        final minZoom = await _cameraController!.getMinZoomLevel();
        final maxZoom = await _cameraController!.getMaxZoomLevel();
        // 自动生成倍率列表（例如 1x, 2x, 3x ... 到最大值）
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
      // 拍照
      final XFile file = await _cameraController!.takePicture();
      debugPrint("拍摄完成: ${file.path}");

      // 请求相册权限
      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        debugPrint("相册权限未授权，无法保存照片");
        return;
      }

      // 保存到相册
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

      // 只在两个摄像头之间切换
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
            /// 相机预览区 + 浮动窗口
            Expanded(
              child: Stack(
                children: [
                  /// 相机预览
                  CameraPreviewArea(
                    controller: _cameraController,
                    gridType: _gridType,
                    zoomLevels: _zoomLevels,
                    overlayPosePath: _overlayPosePath, // ✅ 姿势叠加
                  ),

                  /// 浮动小窗口（左下角缩略图）
                  if (_overlayImagePath != null)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: GestureDetector(
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
                            maxWidth: 150, // 限制最大宽
                            maxHeight: 150, // 限制最大高
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
            ),


            /// 底部栏
            CameraBottomBar(
              onTakePicture: _takePicture,
              onSwitchCamera: _switchCamera,
              onSelectPose: ({required String imagePath, required String posePath}) {
                setState(() {
                  _overlayImagePath = imagePath;
                  _overlayPosePath = posePath;
                  // print("Overlay Image Path: $imagePath");
                  // print("Overlay Pose Path: $posePath");
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
