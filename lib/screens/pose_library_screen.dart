import 'package:flutter/material.dart';
import 'camera_screen.dart';
import '../config/app_routes.dart';

class PoseLibraryScreen extends StatefulWidget {
  final void Function(String imagePath, String posePath)? onSelectPose;

  const PoseLibraryScreen({super.key, this.onSelectPose});

  @override
  State<PoseLibraryScreen> createState() => _PoseLibraryScreenState();
}

class _PoseLibraryScreenState extends State<PoseLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 定义分类数据
  final List<String> tabs = ['收藏', '热门', '单人', '双人', '多人', '情侣'];

  // 图片数据
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
      'assets/original_picture/单人/9.jpg',
      'assets/original_picture/单人/10.jpg',
      'assets/original_picture/单人/11.jpg',
      'assets/original_picture/单人/12.jpg',
      'assets/original_picture/单人/13.jpg',
      'assets/original_picture/单人/14.jpg',
      'assets/original_picture/单人/15.jpg',
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
      'assets/original_picture/双人/13.jpg',
      'assets/original_picture/双人/14.jpg',
      'assets/original_picture/双人/15.jpg',
      'assets/original_picture/双人/16.jpg',
      'assets/original_picture/双人/17.jpg',
      'assets/original_picture/双人/18.jpg',
      'assets/original_picture/双人/19.jpg',
      'assets/original_picture/双人/20.jpg',
      'assets/original_picture/双人/21.jpg',
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
      'assets/original_picture/多人/25.jpg',
      'assets/original_picture/多人/26.jpg',
      'assets/original_picture/多人/27.jpg',
      'assets/original_picture/多人/28.jpg',
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
      'assets/original_picture/情侣/20.jpg',
      'assets/original_picture/情侣/21.jpg',
      'assets/original_picture/情侣/22.jpg',
      'assets/original_picture/情侣/23.jpg',
      'assets/original_picture/情侣/24.jpg',
      'assets/original_picture/情侣/25.jpg',
      'assets/original_picture/情侣/26.jpg',
      'assets/original_picture/情侣/27.jpg',
      'assets/original_picture/情侣/28.jpg',
      'assets/original_picture/情侣/29.jpg',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildGridForCategory(String category) {
      final categoryImages = images[category] ?? [];
      bool isLoadingMore = false;
        // 从 arguments 获取回调函数
      return StatefulBuilder(
        builder: (context, setState) {
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo is ScrollUpdateNotification &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent * 0.8 &&
                  !isLoadingMore) {
                setState(() {
                  isLoadingMore = true;
                });
                // 模拟预加载（可替换为实际数据加载）
                Future.delayed(const Duration(seconds: 2), () {
                  setState(() {
                    isLoadingMore = false;
                  });
                });
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categoryImages.length + (isLoadingMore ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 两列
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 4, // 正方形
              ),
              itemBuilder: (context, index) {
                if (index == categoryImages.length && isLoadingMore) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final imagePath = categoryImages[index];
                String posePath = imagePath.replaceFirst('original_picture', 'poses');
                posePath = posePath.replaceAll(RegExp(r'\.\w+$'), '.png');

                // ⚡ 点击跳转到 CameraScreen 并传递叠加图片
                return GestureDetector(
                  onTap: () {
                    if (widget.onSelectPose != null) {
                      widget.onSelectPose!(imagePath!, posePath!);
                    }
                    Navigator.pop(context); // 返回 CameraScreen
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FadeInImage(
                      placeholder: const AssetImage('assets/placeholder.png'),
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
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
// import 'package:flutter/material.dart';

// class PoseLibraryScreen extends StatelessWidget {
//   const PoseLibraryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("姿势库")),
//       body: const Center(
//         child: Text("这里是姿势库页面（TODO）"),
//       ),
//     );
//   }
// }
