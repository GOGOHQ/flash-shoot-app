import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/app_routes.dart';

// Class to hold a single item's data
class _RecommendationItem {
  final String title;
  final String username;
  final String avatarUrl;
  final String imageUrl;

  _RecommendationItem({
    required this.title,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _subTabIndex = 0;
  final List<String> _mainTabs = ["关注", "推荐", "热门"];
  final List<String> _recommendSubTabs = [
    "全部",
    "姿势",
    "修图",
    "摄影",
    "打卡地",
    "风格",
  ];

  int _selectedIndex = 0;

  final List<_NavItem> _items = [
    _NavItem("机位", Icons.map, AppRoutes.map),
    _NavItem("相机", Icons.camera_alt, AppRoutes.camera),
    _NavItem("消息", Icons.message, AppRoutes.message),
    _NavItem("我", Icons.people, AppRoutes.info),
  ];

  // Manually specified data for the recommendations
  final List<_RecommendationItem> _recommendations = [
    _RecommendationItem(
      title: "🪄跟着百变小樱知世学拍照👀包出片的！",
      username: "一颗米栗",
      avatarUrl: "assets/home/1/头像.webp",
      imageUrl: "assets/home/1/1.jpg",
    ),
    _RecommendationItem(
      title: "晒到的阳光分你一半",
      username: "蓝色水母",
      avatarUrl: "assets/home/2/头像.webp",
      imageUrl: "assets/home/2/2.jpg",
    ),
    _RecommendationItem(
      title: "520情侣拍照姿势合集来啦！！📸",
      username: "张张呐",
      avatarUrl: "assets/home/3/头像.webp",
      imageUrl: "assets/home/3/3.jpg",
    ),
    _RecommendationItem(
      title: "ˏ🎂ˎˊ˗「🥂🎂存一些生日拍照姿势吧！",
      username: "陪拍周包子（全能型",
      avatarUrl: "assets/home/4/头像.webp",
      imageUrl: "assets/home/4/4.jpg",
    ),
    _RecommendationItem(
      title: "青甘环线万能合影模版｜大学生速存💥",
      username: "不定式方程🌻",
      avatarUrl: "assets/home/5/头像.webp",
      imageUrl: "assets/home/5/5.jpg",
    ),
    _RecommendationItem(
      title: "花少14张合照！北斗七行真的无法超越",
      username: "喵星",
      avatarUrl: "assets/home/6/头像.webp",
      imageUrl: "assets/home/6/6.jpg",
    ),
    _RecommendationItem(
      title: "情侣这样拍也太有感觉了👩‍❤️‍👨！！",
      username: "休想断我财璐",
      avatarUrl: "assets/home/7/头像.webp",
      imageUrl: "assets/home/7/7.jpg",
    ),
    _RecommendationItem(
      title: "独属我们的海边胶片回忆💕",
      username: "钱小峰",
      avatarUrl: "assets/home/8/头像.webp",
      imageUrl: "assets/home/8/8.jpg",
    ),
    _RecommendationItem(
      title: "💙",
      username: "照桥心美",
      avatarUrl: "assets/home/9/头像.webp",
      imageUrl: "assets/home/9/9.jpg",
    ),
    _RecommendationItem(
      title: "普通人拍也好看的万能拍照姿势📸",
      username: "小酷爱拍照",
      avatarUrl: "assets/home/10/头像.webp",
      imageUrl: "assets/home/10/10.jpg",
    ),
    // Add more items here
  ];

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 180,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('上传照片'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/upload');
              },
            ),
            ListTile(
              leading: Icon(Icons.text_fields),
              title: Text('写笔记'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/note');
              },
            ),
            ListTile(
              leading: Icon(Icons.text_fields),
              title: Text('取消'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/note');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _mainTabController = TabController(length: _mainTabs.length, vsync: this);
    _mainTabController.addListener(() {
      setState(() {});
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 2));

    // Custom data for new items to load
    final List<_RecommendationItem> newItems = [
      _RecommendationItem(
        title: "又一张自定义照片",
        username: "新的用户",
        avatarUrl: "https://example.com/avatars/new_user.jpg",
imageUrl: "https://example.com/images/new_photo.jpg",
      ),
      // Add more new items here
    ];

    _recommendations.addAll(newItems);

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _recommendations.clear();
    // Add your initial custom data back here
    _recommendations.addAll([
      _RecommendationItem(
        title: "我的第一张自定义照片",
        username: "摄影小能手",
        avatarUrl: "https://example.com/avatars/user1.jpg",
imageUrl: "https://example.com/images/photo1.jpg",
),
_RecommendationItem(
title: "美丽的日落",
        username: "旅行达人",
        avatarUrl: "https://example.com/avatars/user2.jpg",
imageUrl: "https://example.com/images/photo2.jpg",
),
_RecommendationItem(
title: "城市夜景",
        username: "夜拍爱好者",
        avatarUrl: "https://example.com/avatars/user3.jpg",
imageUrl: "https://example.com/images/photo3.jpg",
      ),
    ]);
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index < _items.length) {
      Navigator.pushNamed(context, _items[index].route);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  Widget _buildSubTabBar() {
    if (_mainTabController.index != 1) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendSubTabs.length,
        itemBuilder: (context, index) {
          final isSelected = _subTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _subTabIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _recommendSubTabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(_RecommendationItem item) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  height: 100, // Placeholder height on error
                  color: Colors.grey,
                  child: const Center(child: Icon(Icons.error)),
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: AssetImage(item.avatarUrl),
                  onBackgroundImageError: (exception, stackTrace) =>
                      const Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Text(
                  item.username,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_mainTabs.length, (index) {
            final isSelected = _mainTabController.index == index;
            return GestureDetector(
              onTap: () {
                _mainTabController.animateTo(index);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      _mainTabs[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/logo.jpeg"),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.search);
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.apiTest);
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'API 测试',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.networkTest);
            },
            icon: const Icon(Icons.wifi),
            tooltip: '网络测试',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSubTabBar(),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: Colors.white,
              onRefresh: _refresh,
              child: MasonryGridView.count(
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                padding: const EdgeInsets.all(8),
                itemCount: _recommendations.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _recommendations.length) {
                    return _buildCard(_recommendations[index]);
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: _items
            .map((item) =>
                BottomNavigationBarItem(icon: Icon(item.icon), label: item.label))
            .toList(),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: Offset(0, 25),
        child: FloatingActionButton.small(
          onPressed: _showAddOptions,
          child: Icon(Icons.add),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  _NavItem(this.label, this.icon, this.route);
}