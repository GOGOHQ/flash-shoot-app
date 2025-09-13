import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'photo_detail_screen.dart';
import 'package:flutter/services.dart';
import '../screens/show_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> assets = [];
  int crossAxisCount = 3; // 默认列数
  double scaleFactor = 1.0;

  // 多选相关
  bool selectionMode = false;
  final Set<int> selectedIndices = {};

  // 上传相关
  bool uploading = false;
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier(0.0);

  // 本地后端地址
  final String baseUrl = 'https://dfa701042fd7.ngrok-free.app';
  String? userId;

  // 缩略图缓存
  final Map<int, Uint8List> thumbCache = {};

  @override
  void initState() {
    super.initState();
    _initUserId();
    _fetchAssets();
  }

  Future<void> _initUserId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        userId = iosInfo.identifierForVendor ?? 'ios_guest';
      });
    } else {
      setState(() {
        userId = 'unknown';
      });
    }
  }

  Future<void> _fetchAssets() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return;

    final albums = await PhotoManager.getAssetPathList();
    List<AssetEntity> allAssets = [];

    for (var album in albums) {
      final photos = await album.getAssetListPaged(page: 0, size: 1000);
      allAssets.addAll(photos);
    }

    setState(() {
      assets = allAssets;
    });
  }

  Future<Uint8List?> _loadThumb(int index) async {
    if (thumbCache.containsKey(index)) return thumbCache[index];
    final data =
        await assets[index].thumbnailDataWithSize(const ThumbnailSize(200, 200));
    if (data != null) thumbCache[index] = data;
    return data;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scaleFactor *= details.scale;
      if (scaleFactor > 1.5) crossAxisCount = 2;
      else if (scaleFactor < 0.8) crossAxisCount = 5;
      else crossAxisCount = 3;
      scaleFactor = scaleFactor.clamp(0.5, 2.0);
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      selectionMode = true;
      selectedIndices.add(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) selectedIndices.remove(index);
      else selectedIndices.add(index);

      if (selectedIndices.isEmpty) selectionMode = false;
    });
  }

  /// 上传选中的图片（线稿生成）
  Future<void> _uploadSelected() async {
    if (selectedIndices.isEmpty || userId == null) return;

    setState(() {
      uploading = true;
    });
    uploadProgressNotifier.value = 0.0;

    final dio = Dio();
    final formData = FormData();
    formData.fields.add(MapEntry('user_id', userId!));
    formData.fields.add(MapEntry('type', 'sketch')); // 标记线稿生成类型

    try {
      for (var i in selectedIndices) {
        final asset = assets[i];
        final file = await asset.file;
        if (file == null) continue;
        final name = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: name),
        ));
      }

      final response = await dio.post(
        "$baseUrl/upload",
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
        onSendProgress: (sent, total) {
          if (total != 0) uploadProgressNotifier.value = sent / total;
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('上传成功')));
        setState(() {
          selectedIndices.clear();
          selectionMode = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('上传出错: $e')));
    } finally {
      setState(() {
        uploading = false;
      });
      uploadProgressNotifier.value = 0.0;
    }
  }

/// 姿势指导逻辑
  Future<void> _poseGuidance() async {
    if (userId == null || selectedIndices.isEmpty) return;

    setState(() {
      uploading = true;
    });
    uploadProgressNotifier.value = 0.0;

    final dio = Dio();
    final formData = FormData();
    formData.fields.add(MapEntry('user_id', userId!));

    try {
      // 将选中的图片加入 formData
      for (var i in selectedIndices) {
        final asset = assets[i];
        final file = await asset.file;
        if (file == null) continue;
        final name = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: name),
        ));
      }

      // 上传到 /background 接口
      final response = await dio.post(
        '$baseUrl/background',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
        onSendProgress: (sent, total) {
          if (total != 0) uploadProgressNotifier.value = sent / total;
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('上传到 background 成功')));

        // 上传完成后清空选中状态
        setState(() {
          selectedIndices.clear();
          selectionMode = false;
        });

        // 上传成功后延迟 2 秒跳转到 ShowScreen
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowScreen(
                baseUrl: baseUrl, // 确保传入 baseUrl
                userId: userId!,
              ),
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('上传出错: $e')));
    } finally {
      setState(() {
        uploading = false;
      });
      uploadProgressNotifier.value = 0.0;
    }
  }


  /// 弹出选择对话框
  void _showUploadOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('请选择操作'),
        content: const Text('请选择你要进行的操作'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadSelected(); // 点击线稿生成
            },
            child: const Text('线稿生成'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _poseGuidance(); // 点击姿势指导
            },
            child: const Text('姿势指导'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    uploadProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('${selectedIndices.length} selected')
            : const Text('Gallery'),
        actions: [
              // 👁️ 眼睛按钮：无论是否多选模式都显示
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowScreen(
                      baseUrl: baseUrl,
                      userId: userId!,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('用户信息未初始化')),
                );
              }
            },
          ),
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: uploading ? null : _showUploadOptions, // 点击弹出对话框
            ),
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedIndices.clear();
                  selectionMode = false;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: _onScaleUpdate,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: _loadThumb(index),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Container(color: Colors.grey[300]);
                    final selected = selectedIndices.contains(index);

                    return GestureDetector(
                      onLongPress: () => _enterSelectionMode(index),
                      onTap: () {
                        if (selectionMode) {
                          _toggleSelection(index);
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoDetailScreen(
                              asset: assets[index],
                              allAssets: assets,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snapshot.data!, fit: BoxFit.cover),
                          if (selectionMode)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? Colors.blue : Colors.black26,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  selected ? Icons.check : Icons.circle,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (uploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: uploadProgressNotifier,
                builder: (context, value, _) {
                  return LinearProgressIndicator(value: value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
