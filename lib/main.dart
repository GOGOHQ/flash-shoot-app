import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:photo_manager/photo_manager.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const FlashShootApp());
}

class FlashShootApp extends StatelessWidget {
  const FlashShootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraWithOverlay(),
    );
  }
}

class CameraWithOverlay extends StatefulWidget {
  const CameraWithOverlay({super.key});

  @override
  _CameraWithOverlayState createState() => _CameraWithOverlayState();
}

class _CameraWithOverlayState extends State<CameraWithOverlay> {
  late CameraController _controller;
  bool _initialized = false;
  bool _showGrid = false;

  // 当前选择的姿势图
  String? _currentPose;

  // 最近一张保存的照片路径
  String? _lastSavedPhoto;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller.initialize();
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  Future<void> _takePicture() async {
    try {
      final XFile file = await _controller.takePicture();
      // 直接保存到相册
      await GallerySaver.saveImage(file.path, albumName: "FlashShoot");
      setState(() => _lastSavedPhoto = file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('照片已保存到相册')),
      );
    } catch (e) {
      debugPrint('拍照失败: $e');
    }
  }

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller),

          // 九宫格参考线
          if (_showGrid)
            CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),

          // 叠加 SVG 线稿姿势图
          if (_currentPose != null)
            Center(
              child: SvgPicture.asset(
                _currentPose!,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.6),
                  BlendMode.srcIn,
                ),
              ),
            ),

          // 右上角按钮
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(_showGrid ? Icons.grid_off : Icons.grid_on,
                      color: Colors.white),
                  onPressed: () => setState(() => _showGrid = !_showGrid),
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.white),
                  onPressed: () async {
                    final pose = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PoseLibrary(),
                      ),
                    );
                    if (pose != null && mounted) {
                      setState(() => _currentPose = pose);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: _openGallery,
                ),
              ],
            ),
          ),

          // 拍照按钮
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _takePicture,
                child: const Icon(Icons.camera, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1;

    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(thirdWidth * i, 0), Offset(thirdWidth * i, size.height), paint);
      canvas.drawLine(Offset(0, thirdHeight * i), Offset(size.width, thirdHeight * i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PoseLibrary extends StatelessWidget {
  const PoseLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final poses = [
      "assets/poses/pose1.svg",
      "assets/poses/pose2.svg",
      "assets/poses/pose3.svg",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("姿势库")),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: poses.length,
        itemBuilder: (context, index) {
          final pose = poses[index];
          return GestureDetector(
            onTap: () => Navigator.pop(context, pose),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                pose,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _media = [];

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);
      final List<AssetEntity> media =
          await albums.first.getAssetListPaged(page: 0, size: 100);
      setState(() => _media = media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("相册预览")),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _media.length,
        itemBuilder: (context, index) {
          final asset = _media[index];
          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return Container(color: Colors.grey);
            },
          );
        },
      ),
    );
  }
}
