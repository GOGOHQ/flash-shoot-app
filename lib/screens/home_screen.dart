import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/app_routes.dart';
import '../services/unsplash_service.dart';
import '../models/recommendation_item.dart';
import '../screens/card_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _subTabIndex = 0;
  final UnsplashService _unsplashService = UnsplashService();
  int _currentPage = 1; // 用于分页
  final List<String> _mainTabs = ["关注", "推荐", "热门"];
  final List<String> _recommendSubTabs = [
    "全部",
    "找同伴",
    "找摄影师",
    "找模特",
    "吃喝玩乐",
  ];
  

  int _selectedIndex = 0;

  final List<_NavItem> _items = [
    _NavItem("机位", Icons.map, AppRoutes.map),
    _NavItem("相机", Icons.camera_alt, AppRoutes.camera),
    _NavItem("消息", Icons.message, AppRoutes.message),
    _NavItem("我", Icons.people, AppRoutes.info),
  ];

  // 主 Tab：关注、推荐、热门
final List<RecommendationItem> _followingList = []; // 关注页数据
final List<RecommendationItem> _hotList = [];   // 热门页数据

// 推荐页二级 Tab
final List<RecommendationItem> _recommendationsPose = [];
final List<RecommendationItem> _recommendationsEdit = [];
final List<RecommendationItem> _recommendationsPhoto = [];
final List<RecommendationItem> _recommendationsLocation = [];

  // Manually specified data for the recommendations
  final List<RecommendationItem> _recommendationsAll = [
    RecommendationItem(
      title: "🪄跟着百变小樱知世学拍照👀包出片的！",
      username: "一颗米栗",
      avatarUrl: "assets/home/1/头像.webp",
      imageUrl: "assets/home/1/1.jpg",
      likes: 12345,
    ),
    RecommendationItem(
      title: "晒到的阳光分你一半",
      username: "蓝色水母",
      avatarUrl: "assets/home/2/头像.webp",
      imageUrl: "assets/home/2/2.jpg",
      likes: 67890,
    ),
    RecommendationItem(
      title: "520情侣拍照姿势合集来啦！！📸",
      username: "张张呐",
      avatarUrl: "assets/home/3/头像.webp",
      imageUrl: "assets/home/3/3.jpg",
      likes: 34567,
    ),
    RecommendationItem(
      title: "ˏ🎂ˎˊ˗「🥂🎂存一些生日拍照姿势吧！",
      username: "陪拍周包子（全能型",
      avatarUrl: "assets/home/4/头像.webp",
      imageUrl: "assets/home/4/4.jpg",
      likes: 89012,
    ),
    RecommendationItem(
      title: "青甘环线万能合影模版｜大学生速存💥",
      username: "不定式方程🌻",
      avatarUrl: "assets/home/5/头像.webp",
      imageUrl: "assets/home/5/5.jpg",
      likes: 23456,
    ),
    RecommendationItem(
      title: "花少14张合照！北斗七行真的无法超越",
      username: "喵星",
      avatarUrl: "assets/home/6/头像.webp",
      imageUrl: "assets/home/6/6.jpg",
      likes: 4567,
    ),
    RecommendationItem(
      title: "情侣这样拍也太有感觉了👩‍❤️‍👨！！",
      username: "休想断我财璐",
      avatarUrl: "assets/home/7/头像.webp",
      imageUrl: "assets/home/7/7.jpg",
      likes: 5678,
    ),
    RecommendationItem(
      title: "独属我们的海边胶片回忆💕",
      username: "钱小峰",
      avatarUrl: "assets/home/8/头像.webp",
      imageUrl: "assets/home/8/8.jpg",
      likes: 6789,
    ),
    RecommendationItem(
      title: "💙",
      username: "照桥心美",
      avatarUrl: "assets/home/9/头像.webp",
      imageUrl: "assets/home/9/9.jpg",
      likes: 7890,
    ),
    RecommendationItem(
      title: "普通人拍也好看的万能拍照姿势📸",
      username: "小酷爱拍照",
      avatarUrl: "assets/home/10/头像.webp",
      imageUrl: "assets/home/10/10.jpg",
      likes: 8901,
    ),
    // Add more items here
  ];

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  List<RecommendationItem> _getCurrentList() {
    switch (_mainTabController.index) {
      case 0:
        return _followingList;
      case 1:
        switch (_subTabIndex) {
          case 0:
            return _recommendationsAll;
          case 1:
            return _recommendationsPose;
          case 2:
            return _recommendationsEdit;
          case 3:
            return _recommendationsPhoto;
          case 4:
            return _recommendationsLocation;
          default:
            return _recommendationsAll;
        }
      case 2:
        return _hotList;
      default:
        return _recommendationsAll;
    }
  }

  
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 180,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('AI姿势生成'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.gallery);
              },
            ),
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
     _initData();
    _scrollController.addListener(_onScroll);
  // 默认落在 推荐 (index = 1)
    _mainTabController = TabController(length: _mainTabs.length, vsync: this, initialIndex: 1);
    _mainTabController.addListener(() {
      setState(() {});
    });
  }
  Future<void> _initData() async {
    try {
      // 获取第一页数据
      final photos = await _unsplashService.fetchPosePhotos(page: 1, perPage: 25); // 假设每个列表 10 条

      // 转换成 RecommendationItem
      final List<RecommendationItem> items = photos.map((photo) {
        return RecommendationItem(
          title: photo['description'] ?? 'No description',
          username: photo['author']['name'] ?? 'Anonymous',
          avatarUrl: photo['author']['avatar'] ?? '',
          imageUrl: photo['small'] ?? '',
          likes: photo['likes'] ?? 0,
        );
      }).toList();

      // 每个列表取 10 条数据
      setState(() {
        _hotList.addAll(items.getRange(0, min(4, items.length)));
        _followingList.addAll(items.getRange(4, min(8, items.length)));
        _recommendationsPose.addAll(items.getRange(8, min(12, items.length)));
        _recommendationsEdit.addAll(items.getRange(12, min(16, items.length)));
        _recommendationsPhoto.addAll(items.getRange(16, min(20, items.length)));
        _recommendationsLocation.addAll(items.getRange(20, min(24, items.length)));
      });
      _currentPage = 2; // 下一页
    } catch (e) {
      print("❌ 初始化数据失败: $e");
    }
  }

  void _onScroll() {
    List<RecommendationItem> currentList = _getCurrentList();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreList(currentList);
    }
  }

  Future<void> _loadMoreList(List<RecommendationItem> currentList) async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final photos = await _unsplashService.fetchPosePhotos(
        page: _currentPage,
        perPage: 10,
      );

      final newItems = photos.map((photo) {
        return RecommendationItem(
          title: photo['description'] ?? '无描述',
          username: photo['author']['name'] ?? '匿名',
          avatarUrl: photo['author']['avatar'] ?? '',
          imageUrl: photo['small'] ?? '',
          likes: photo['likes'] ?? 0,
        );
      }).toList();

      setState(() {
        currentList.addAll(newItems);
      });

      _currentPage++;
    } catch (e) {
      print("❌ 加载 Unsplash 图片失败: $e");
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshList(List<RecommendationItem> currentList) async {
    setState(() {
      currentList.clear();
    });

    try {
      final results = await _unsplashService.fetchPosePhotos(
        page: _currentPage,
        perPage: 10,
      );

      final fetchedItems = results.map((item) {
        return RecommendationItem(
          title: item['description'] ?? '无描述',
          username: item['author']['name'] ?? '匿名',
          avatarUrl: item['author']['avatar'] ?? '',
          imageUrl: item['small'] ?? '',
          likes: item['likes'] ?? 0,
        );
      }).toList();

      setState(() {
        currentList.addAll(fetchedItems);
      });

      _currentPage++;
    } catch (e) {
      print("❌ 获取 Unsplash 图片失败: $e");
    }
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

  Widget _buildCard(RecommendationItem item) {
    bool isNetworkImage = item.imageUrl.startsWith('http');
    bool isNetworkAvatar = item.avatarUrl.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardDetailScreen(item: item),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isNetworkImage
                ? Image.network(item.imageUrl, fit: BoxFit.cover, width: double.infinity)
                : Image.asset(item.imageUrl, fit: BoxFit.cover, width: double.infinity),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  isNetworkAvatar
                      ? CircleAvatar(radius: 12, backgroundImage: NetworkImage(item.avatarUrl))
                      : CircleAvatar(radius: 12, backgroundImage: AssetImage(item.avatarUrl)),
                  const SizedBox(width: 8),
                  Text(item.username, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('${item.likes}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<RecommendationItem> currentList = _getCurrentList();

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
              onRefresh: () => _refreshList(currentList),
              child: MasonryGridView.count(
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                padding: const EdgeInsets.all(8),
                itemCount: currentList.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < currentList.length) {
                    return _buildCard(currentList[index]);
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