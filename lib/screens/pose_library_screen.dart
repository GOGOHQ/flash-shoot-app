import 'package:flutter/material.dart';

class PoseLibraryScreen extends StatefulWidget {
  const PoseLibraryScreen({super.key});

  @override
  State<PoseLibraryScreen> createState() => _PoseLibraryScreenState();
}

class _PoseLibraryScreenState extends State<PoseLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 定义分类数据
  final List<String> tabs = ['收藏', '热门', '生活旅拍', '形象照'];

  // 图片数据
  final Map<String, List<String>> images = {
    '收藏': [
      'assets/original_picture/single_pose/1.jpg',
      'assets/original_picture/single_pose/2.jpg',
      'assets/original_picture/single_pose/3.jpg',
    ],
    '热门': [
      'assets/original_picture/double_pose/1.jpg',
      'assets/original_picture/double_pose/2.jpg',
      'assets/original_picture/double_pose/3.jpg',
    ],
    '生活旅拍': [
      'assets/original_picture/multi_pose/1.jpg',
      'assets/original_picture/multi_pose/2.jpg',
      'assets/original_picture/multi_pose/3.jpg',
    ],
    '形象照': [
      'assets/original_picture/triple_pose/1.jpg',
      'assets/original_picture/triple_pose/2.jpg',
      'assets/original_picture/triple_pose/3.jpg',
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
              // Simulate preloading (replace with actual data fetch if needed)
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
              crossAxisCount: 2, // Two columns
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1, // Square aspect ratio
            ),
            itemBuilder: (context, index) {
              if (index == categoryImages.length && isLoadingMore) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final imagePath = categoryImages[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage(
                  placeholder: const AssetImage('assets/placeholder.png'), // Add a placeholder image in assets
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
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
