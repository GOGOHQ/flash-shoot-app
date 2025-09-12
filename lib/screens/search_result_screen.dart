import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;

  const SearchResultScreen({super.key, required this.keyword});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  List<String> allImages = [];
  List<String> displayedImages = [];
  int pageSize = 10;
  int currentPage = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImagesFromManifest(widget.keyword);
  }

  Future<void> _loadImagesFromManifest(String folderName) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final List<String> images = manifestMap.keys
        .where((String key) => key.startsWith('assets/数据库/$folderName/'))
        .toList();

    setState(() {
      allImages = images;
      displayedImages.clear();
      currentPage = 0;
    });

    _loadMore();
  }

  void _loadMore() {
    if (isLoading) return;
    if (currentPage * pageSize >= allImages.length) return;

    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      final nextPage = currentPage + 1;
      final nextItems = allImages.skip(currentPage * pageSize).take(pageSize);

      setState(() {
        displayedImages.addAll(nextItems);
        currentPage = nextPage;
        isLoading = false;
      });
    });
  }

  /// 保存到相册
  Future<void> _saveImage(String assetPath) async {
    // 权限检查
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("没有相册权限，无法保存")),
      );
      return;
    }

    try {
      final byteData = await rootBundle.load(assetPath);
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(byteData.buffer.asUint8List()),
        quality: 100,
        name: assetPath.split('/').last,
      );
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("已保存到相册")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("保存失败")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("错误: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.keyword} - 搜索结果")),
      body: allImages.isEmpty
          ? const Center(child: Text("没有找到相关图片"))
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 100) {
                  _loadMore();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 双列
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8, // 图片比例
                ),
                itemCount: displayedImages.length +
                    (currentPage * pageSize < allImages.length ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedImages.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final imgPath = displayedImages[index];
                  return GestureDetector(
                    onLongPress: () => _saveImage(imgPath),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              imgPath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              imgPath.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
