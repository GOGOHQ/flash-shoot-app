import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:dio/dio.dart';
import 'photo_detail_screen.dart';

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
  double uploadProgress = 0.0; // 0.0 - 1.0

  // 本地后端地址（把 <YOUR_COMPUTER_IP> 替换为你电脑在同一 Wi-Fi 的 IP）
  final String uploadUrl = 'https://50b82cf769ca.ngrok-free.app/upload';

  @override
  void initState() {
    super.initState();
    _fetchAssets();
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

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scaleFactor *= details.scale;
      if (scaleFactor > 1.5) crossAxisCount = 2;
      else if (scaleFactor < 0.8) crossAxisCount = 5;
      else crossAxisCount = 3;

      // 将 scaleFactor 归一化一下，避免快速累积
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

  Future<void> _uploadSelected() async {
    if (selectedIndices.isEmpty) return;
    setState(() {
      uploading = true;
      uploadProgress = 0.0;
    });

    final dio = Dio();

    try {
      final formData = FormData();
      int idx = 0;
      final indices = selectedIndices.toList();

      for (var i in indices) {
        final asset = assets[i];
        final file = await asset.file; // AssetEntity.file 返回 File?（iOS/Android）
        if (file == null) continue; // 跳过无法获取到的

        final name = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: name),
        ));
        idx++;
      }

      // 上传并监听进度
      final response = await dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          // 需要的其他配置
        ),
        onSendProgress: (sent, total) {
          if (total != 0) {
            setState(() {
              uploadProgress = sent / total;
            });
          }
        },
      );

      if (response.statusCode == 200) {
        // 上传成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传成功')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传出错: $e')),
      );
    } finally {
      setState(() {
        uploading = false;
        uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('${selectedIndices.length} selected')
            : Text('Gallery'),
        actions: [
          if (selectionMode)
            IconButton(
              icon: Icon(Icons.upload_file),
              onPressed: uploading ? null : _uploadSelected,
            ),
          if (selectionMode)
            IconButton(
              icon: Icon(Icons.clear),
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
              padding: EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Widget>(
                  future: assets[index]
                      .thumbnailDataWithSize(ThumbnailSize(200, 200))
                      .then((data) => Image.memory(data!, fit: BoxFit.cover)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container(color: Colors.grey[300]);

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
                          snapshot.data!,
                          if (selectionMode)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? Colors.blue : Colors.black26,
                                ),
                                padding: EdgeInsets.all(4),
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
              child: LinearProgressIndicator(value: uploadProgress),
            ),
        ],
      ),
    );
  }
}
