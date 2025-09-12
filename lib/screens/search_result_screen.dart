import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

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

  /// 弹出确认提示
  Future<bool> _confirmSave(String imgName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("保存到相册"),
            content: Text("是否要保存图片 [$imgName] 到相册？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("取消"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("保存"),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 长按保存到相册
  Future<void> _saveToGallery(String assetPath) async {
    final fileName = assetPath.split('/').last;
    final confirm = await _confirmSave(fileName);
    if (!confirm) return;

    try {
      final byteData = await rootBundle.load(assetPath);
      final result = await ImageGallerySaver.saveImage(
        Uint8List.view(byteData.buffer),
        quality: 100,
        name: fileName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['isSuccess'] ? "保存成功 ✅" : "保存失败 ❌")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("保存失败 ❌")),
      );
    }
  }

  /// 只展示图片
  Widget _buildCard(String imgPath) {
    return GestureDetector(
      onLongPress: () => _saveToGallery(imgPath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imgPath,
          fit: BoxFit.cover,
        ),
      ),
    );
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
              child: MasonryGridView.count(
                padding: const EdgeInsets.all(8),
                crossAxisCount: 2, // 双列
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: displayedImages.length +
                    (currentPage * pageSize < allImages.length ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedImages.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildCard(displayedImages[index]);
                },
              ),
            ),
    );
  }
}
