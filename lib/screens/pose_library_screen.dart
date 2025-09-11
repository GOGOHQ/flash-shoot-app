import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PoseLibraryScreen extends StatefulWidget {
  final void Function(String imagePath, String posePath)? onSelectPose;

  const PoseLibraryScreen({super.key, this.onSelectPose});

  @override
  State<PoseLibraryScreen> createState() => _PoseLibraryScreenState();
}

class _PoseLibraryScreenState extends State<PoseLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['收藏', '热门', '单人', '双人', '多人', '情侣', '用户上传'];

  final Map<String, List<String>> images = {
    '收藏': ['assets/original_picture/收藏/1.jpg'],
    '热门': ['assets/original_picture/热门/1.jpg'],
    '单人': ['assets/original_picture/单人/1.jpg'],
    '双人': ['assets/original_picture/双人/1.jpg'],
    '多人': ['assets/original_picture/多人/1.jpg'],
    '情侣': ['assets/original_picture/情侣/1.jpg'],
  };

  // 你的后端地址
  final String baseUrl = 'https://50b82cf769ca.ngrok-free.app';
  final String wsUrl = 'wss://50b82cf769ca.ngrok-free.app/socket.io/?EIO=4&transport=websocket';

  List<String> localMovedImages = [];
  WebSocketChannel? _channel;
  Timer? _pollingTimer;
  int cacheSize = 0; // MB

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadLocalCache();
    _fetchInitialMovedImages(); // ✅ 初始加载已有 moved 图片
    _connectWebSocket();        // ✅ 监听新增图片
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channel?.sink.close();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<Directory> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory("${dir.path}/pose_cache");
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<void> _loadLocalCache() async {
    final cacheDir = await _getCacheDir();
    final files = cacheDir.listSync();
    localMovedImages = files.map((f) => f.path).toList();
    await _updateCacheSize();
    setState(() {});
  }

  Future<void> _updateCacheSize() async {
    final cacheDir = await _getCacheDir();
    int totalSize = 0;
    for (var f in cacheDir.listSync()) {
      if (f is File) totalSize += await f.length();
    }
    setState(() {
      cacheSize = (totalSize / (1024 * 1024)).ceil(); // MB
    });
  }

  Future<String> _downloadAndCache(String url) async {
    final cacheDir = await _getCacheDir();
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

  /// ✅ 初次进入时加载后端已有的 moved 图片
  Future<void> _fetchInitialMovedImages() async {
    try {
      final resp = await Dio().get("$baseUrl/moved");
      if (resp.statusCode == 200 && resp.data is List) {
        for (String urlPath in resp.data) {
          final imageUrl = "$baseUrl$urlPath";
          final filePath = await _downloadAndCache(imageUrl);
          if (!localMovedImages.contains(filePath)) {
            localMovedImages.add(filePath);
          }
        }
        setState(() {});
      }
    } catch (e) {
      print("初始获取 moved 图片失败: $e");
    }
  }

  /// ✅ 监听 WebSocket，新增图片实时更新
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel?.stream.listen((message) async {
        if (message.toString().contains("/moved/")) {
          final imageUrl = "$baseUrl${message.toString()}";
          final filePath = await _downloadAndCache(imageUrl);
          if (!localMovedImages.contains(filePath)) {
            setState(() {
              localMovedImages.add(filePath);
            });
          }
        }
      }, onError: (error) {
        print("WebSocket error: $error");
      }, onDone: () {
        print("WebSocket closed, retrying...");
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      });
    } catch (e) {
      print("WebSocket 连接失败: $e");
    }
  }

  Widget buildGridForCategory(String category) {
    if (category == '用户上传') {
      if (localMovedImages.isEmpty) {
        return const Center(child: Text("暂无上传图片"));
      }
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
          final filePath = localMovedImages[index];
          return GestureDetector(
            onTap: () {
              if (widget.onSelectPose != null) {
                widget.onSelectPose!(filePath, filePath);
              }
              Navigator.pop(context);
            },
            onLongPress: () async {
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
              setState(() {
                localMovedImages.removeAt(index);
              });
              await _updateCacheSize();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image));
                },
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
        String posePath = imagePath.replaceFirst('original_picture', 'poses');
        posePath = posePath.replaceAll(RegExp(r'\.\w+$'), '.png');

        return GestureDetector(
          onTap: () {
            if (widget.onSelectPose != null) {
              widget.onSelectPose!(imagePath, posePath);
            }
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error, color: Colors.red));
              },
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
