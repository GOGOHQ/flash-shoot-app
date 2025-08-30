import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
}

class _HomeScreenState extends State<HomeScreen>  with SingleTickerProviderStateMixin {
  
  late TabController _mainTabController; // 一级 Tab
  int _subTabIndex = 0; // 二级 Tab（推荐下的分类索引）
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

  //底部导航栏的item
  final List<_NavItem> _items = [
    _NavItem("机位", Icons.map, AppRoutes.map),
    _NavItem("相机", Icons.camera_alt, AppRoutes.camera),
    _NavItem("消息", Icons.message, AppRoutes.message),
    _NavItem("我", Icons.people, AppRoutes.info),
  ];

  // 推荐内容 展示初始化10条数据
  final List<Map<String, String>> _recommendations = List.generate(
    10,
    (i) => {
      "title": "推荐内容标题 $i",
      "avatar": "https://i.pravatar.cc/40?img=${i + 1}",
      "image": "https://picsum.photos/200/${200 + Random().nextInt(100)}?random=$i"
    },
  );

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
      setState(() {}); // 切换一级 Tab 时刷新
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }
  // 加载更多数据
  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 2));

    final nextIndex = _recommendations.length;
    _recommendations.addAll(List.generate(
      10,
      (i) => {
        "title": "推荐内容标题 ${nextIndex + i}",
        "avatar":
            "https://i.pravatar.cc/40?img=${(nextIndex + i) % 70 + 1}",
        "image":
            "https://picsum.photos/200/${200 + Random().nextInt(100)}?random=${nextIndex + i}"
      },
    ));

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _recommendations.clear();
    _recommendations.addAll(List.generate(
      10,
      (i) => {
        "title": "推荐内容标题 $i",
        "avatar": "https://i.pravatar.cc/40?img=${i + 1}",
        "image": "https://picsum.photos/200/${200 + Random().nextInt(100)}?random=$i"
      },
    ));
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pushNamed(context, _items[index].route);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  Widget _buildSubTabBar() {
    if (_mainTabController.index != 1) return const SizedBox.shrink();
    // 只在“推荐”页显示
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

  Widget _buildCard(Map<String, String> item) {
    return Card(
      color: Colors.white, // 设置背景为白色，确保图片和文字清晰可见
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          Image.network(
            item["image"]!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          const SizedBox(height: 8),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item["title"]!,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          // 用户头像
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(item["avatar"]!),
                ),
                const SizedBox(width: 8),
                const Text(
                  "用户名",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
      backgroundColor: Colors.white, // 整体背景白色
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar 背景白色
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min, // 只包裹内容
          children: List.generate(_mainTabs.length, (index) {
            final isSelected = _mainTabController.index == index;
            return GestureDetector(
              onTap: () {
                _mainTabController.animateTo(index); // 切换页面
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      _mainTabs[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  // 底部横线
                  Container(
                    height: 2,
                    width: 20, // 横线长度，可根据需要调整
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
          child: Image.asset("assets/logo.png"),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/search");
            },
            icon: const Icon(Icons.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1), // 高度 1
          child: Container(
            color: Colors.grey[300], // 线颜色
            height: 1,
          ),
        ),
      ),

      body:Column(
        
        children: [
          _buildSubTabBar(),
          Expanded(child: 
            RefreshIndicator(
              backgroundColor: Colors.white, // AppBar 背景白色
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
        backgroundColor: Colors.white, // AppBar 背景白色
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
        offset: Offset(0, 25), // 向下移动 10 像素
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
