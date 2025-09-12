import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PoseLibraryScreen extends StatefulWidget {
  final String userId; // 用户 ID
  final void Function(String imagePath, String posePath)? onSelectPose;

  const PoseLibraryScreen({
    super.key,
    required this.userId,
    this.onSelectPose,
  });

  @override
  State<PoseLibraryScreen> createState() => _PoseLibraryScreenState();
}

class _PoseLibraryScreenState extends State<PoseLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['用户上传','收藏', '热门', '单人', '双人', '多人', '情侣'];

  final Map<String, List<String>> images = {
    '收藏': [
      'assets/original_picture/收藏/1.jpg',
      'assets/original_picture/收藏/2.jpg',
      'assets/original_picture/收藏/3.jpg',
      'assets/original_picture/收藏/4.jpg',
      'assets/original_picture/收藏/5.jpg',
      'assets/original_picture/收藏/6.jpg',
      'assets/original_picture/收藏/7.jpg',
      'assets/original_picture/收藏/8.jpg',
    ],
    '热门': [
      'assets/original_picture/热门/1.jpg',
      'assets/original_picture/热门/2.jpg',
      'assets/original_picture/热门/3.jpg',
      'assets/original_picture/热门/4.jpg',
      'assets/original_picture/热门/5.jpg',
      'assets/original_picture/热门/6.jpg',
      'assets/original_picture/热门/7.jpg',
      'assets/original_picture/热门/8.jpg',
    ],
    '单人': [
      'assets/original_picture/单人/1.jpg',
      'assets/original_picture/单人/2.jpg',
      'assets/original_picture/单人/3.jpg',
      'assets/original_picture/单人/4.jpg',
      'assets/original_picture/单人/5.jpg',
      'assets/original_picture/单人/6.jpg',
      'assets/original_picture/单人/7.jpg',
      'assets/original_picture/单人/8.jpg',
    ],
    '双人': [
      'assets/original_picture/双人/1.jpg',
      'assets/original_picture/双人/2.jpg',
      'assets/original_picture/双人/3.jpg',
      'assets/original_picture/双人/4.jpg',
      'assets/original_picture/双人/5.jpg',
      'assets/original_picture/双人/6.jpg',
      'assets/original_picture/双人/7.jpg',
      'assets/original_picture/双人/8.jpg',
      'assets/original_picture/双人/9.jpg',
      'assets/original_picture/双人/10.jpg',
      'assets/original_picture/双人/11.jpg',
      'assets/original_picture/双人/12.jpg',
    ],
    '多人': [
     'assets/original_picture/多人/1.jpg',
      'assets/original_picture/多人/2.jpg',
      'assets/original_picture/多人/3.jpg',
      'assets/original_picture/多人/4.jpg',
      'assets/original_picture/多人/5.jpg',
      'assets/original_picture/多人/6.jpg',
      'assets/original_picture/多人/7.jpg',
      'assets/original_picture/多人/8.jpg',
      'assets/original_picture/多人/9.jpg',
      'assets/original_picture/多人/10.jpg',
      'assets/original_picture/多人/11.jpg',
      'assets/original_picture/多人/12.jpg',
      'assets/original_picture/多人/13.jpg',
      'assets/original_picture/多人/14.jpg',
      'assets/original_picture/多人/15.jpg',
      'assets/original_picture/多人/16.jpg',
      'assets/original_picture/多人/17.jpg',
      'assets/original_picture/多人/18.jpg',
      'assets/original_picture/多人/19.jpg',
      'assets/original_picture/多人/20.jpg',
      'assets/original_picture/多人/21.jpg',
      'assets/original_picture/多人/22.jpg',
      'assets/original_picture/多人/23.jpg',
      'assets/original_picture/多人/24.jpg',
    ],
    '情侣': [
      'assets/original_picture/情侣/1.jpg',
      'assets/original_picture/情侣/2.jpg',
      'assets/original_picture/情侣/3.jpg',
      'assets/original_picture/情侣/4.jpg',
      'assets/original_picture/情侣/5.jpg',
      'assets/original_picture/情侣/6.jpg',
      'assets/original_picture/情侣/7.jpg',
      'assets/original_picture/情侣/8.jpg',
      'assets/original_picture/情侣/9.jpg',
      'assets/original_picture/情侣/10.jpg',
      'assets/original_picture/情侣/11.jpg',
      'assets/original_picture/情侣/12.jpg',
      'assets/original_picture/情侣/13.jpg',
      'assets/original_picture/情侣/14.jpg',
      'assets/original_picture/情侣/15.jpg',
      'assets/original_picture/情侣/16.jpg',
      'assets/original_picture/情侣/17.jpg',
      'assets/original_picture/情侣/18.jpg',
      'assets/original_picture/情侣/19.jpg',
    ],
  };

  final String baseUrl = 'https://1b5de003978e.ngrok-free.app';

  List<String> localMovedImages = [];
  List<String> localXiangaoImages = [];
  Set<String> readFiles = {}; // 已读取文件集合
  int cacheSize = 0; // MB

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 获取缓存目录
  Future<Directory> _getCacheDir(String folderName) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory("${dir.path}/pose_cache/${widget.userId}/$folderName");
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return cacheDir;
  }

  /// 加载本地缓存
  Future<void> _loadLocalCache() async {
    // moved
    final movedDir = await _getCacheDir('moved');
    final movedFiles = movedDir.listSync().whereType<File>().toList();
    localMovedImages = movedFiles.map((f) => f.path).toList();
    readFiles.addAll(localMovedImages.map((e) => e.split('/').last));

    // xiangao
    final xiangaoDir = await _getCacheDir('xiangao');
    final xiangaoFiles = xiangaoDir.listSync().whereType<File>().toList();
    localXiangaoImages = xiangaoFiles.map((f) => f.path).toList();
    readFiles.addAll(localXiangaoImages.map((e) => e.split('/').last));

    await _updateCacheSize();
    setState(() {});
  }

  /// 更新缓存大小
  Future<void> _updateCacheSize() async {
    int totalSize = 0;
    for (var file in [...localMovedImages, ...localXiangaoImages].map((e) => File(e))) {
      if (await file.exists()) totalSize += await file.length();
    }
    setState(() {
      cacheSize = (totalSize / (1024 * 1024)).ceil();
    });
  }

  /// 下载文件到缓存
  Future<String> _downloadAndCache(String url, String folder) async {
    final cacheDir = await _getCacheDir(folder);
    final fileName = url.split('/').last;
    final filePath = "${cacheDir.path}/$fileName";
    final file = File(filePath);

    if (!await file.exists()) {
      try {
        final resp = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
        await file.writeAsBytes(resp.data);
        await _updateCacheSize();
      } catch (e) {
        print("下载失败: $e");
      }
    }
    return file.path;
  }

  /// 初始化加载后端 moved 和 xiangao 图片，只下载未读取的新文件
  Future<void> _initData() async {
    await _loadLocalCache();
    await _fetchNewFiles('moved');
    await _fetchNewFiles('xiangao');
  }

  Future<void> _fetchNewFiles(String folder) async {
    try {
      final resp = await Dio().get("$baseUrl/$folder", queryParameters: {"user_id": widget.userId});
      if (resp.statusCode == 200 && resp.data is List) {
        List<String> newFiles = [];
        for (String urlPath in resp.data) {
          final fileName = urlPath.split('/').last;
          if (readFiles.contains(fileName)) continue;
          final filePath = await _downloadAndCache("$baseUrl$urlPath", folder);
          newFiles.add(filePath);
          readFiles.add(fileName);
        }
        if (folder == 'moved') localMovedImages.addAll(newFiles);
        if (folder == 'xiangao') localXiangaoImages.addAll(newFiles);

        // 倒序排序
        if (folder == 'moved') {
          localMovedImages.sort((a, b) => b.split('/').last.compareTo(a.split('/').last));
        } else {
          localXiangaoImages.sort((a, b) => b.split('/').last.compareTo(a.split('/').last));
        }

        await _updateCacheSize();
        setState(() {});
      }
    } catch (e) {
      print("获取新 $folder 图片失败: $e");
    }
  }

  String _getFileNameWithoutExtension(String path) {
    final name = path.split('/').last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1) return name.substring(0, dotIndex);
    return name;
  }

  Widget buildGridForCategory(String category) {
    if (category == '用户上传') {
      if (localMovedImages.isEmpty) return const Center(child: Text("暂无上传图片"));

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: localMovedImages.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3 / 4,
        ),
        itemBuilder: (context, index) {
          final imagePath = localMovedImages[index];
          String posePath = imagePath; // 默认 posePath = imagePath

          // 判断是否在 localXiangaoImages 中存在同名文件
          final fileName = _getFileNameWithoutExtension(imagePath);
          final matchXiangao = localXiangaoImages.firstWhere(
            (e) => _getFileNameWithoutExtension(e) == fileName,
            orElse: () => '',
          );
          if (matchXiangao.isNotEmpty) {
            posePath = matchXiangao; // 如果存在就用 Xiangao 对应路径
          }
          return GestureDetector(
            onTap: () {
              widget.onSelectPose?.call(imagePath, posePath);
              Navigator.pop(context);
            },
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("确认删除"),
                    content: const Text("确定要删除这张图片吗？\n（会同时删除对应的效果图）"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("取消"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("删除", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) return; // 用户点取消，不执行删除

              final file = File(imagePath);
              final fileName = _getFileNameWithoutExtension(imagePath);

              // 删除 moved 文件
              if (await file.exists()) await file.delete();

              // 找到并删除对应的 xiangao 文件
              final matchXiangao = localXiangaoImages.firstWhere(
                (e) => _getFileNameWithoutExtension(e) == fileName,
                orElse: () => '',
              );
              if (matchXiangao.isNotEmpty) {
                final xiangaoFile = File(matchXiangao);
                if (await xiangaoFile.exists()) await xiangaoFile.delete();
                setState(() {
                  localXiangaoImages.remove(matchXiangao);
                  readFiles.remove(matchXiangao.split('/').last);
                });
              }

              // 更新 moved 列表
              setState(() {
                readFiles.remove(imagePath.split('/').last);
                localMovedImages.removeAt(index);
              });
              await _updateCacheSize();

              try {
                await Dio().post(
                  "$baseUrl/delete",
                  data: FormData.fromMap({
                    "user_id": widget.userId,
                    "filename": imagePath.split('/').last, // 原始文件名
                  }),
                );
              } catch (e) {
                print("远程删除失败: $e");
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          );
        },
      );
    }

    final categoryImages = images[category] ?? [];
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: categoryImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final imagePath = categoryImages[index];
        String posePath = imagePath.replaceFirst('original_picture', 'poses')
            .replaceAll(RegExp(r'\.\w+$'), '.png');

        return GestureDetector(
          onTap: () {
            widget.onSelectPose?.call(imagePath, posePath);
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error, color: Colors.red)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('姿势库'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text("缓存: ${cacheSize}MB")),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map(buildGridForCategory).toList(),
      ),
    );
  }
}




