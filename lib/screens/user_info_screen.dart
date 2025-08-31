import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['笔记', '最近浏览', '收藏', '点赞'];
  int _selectedTabIndex = 0;

  // Mock user data
  final Map<String, String> _userData = {
    'username': 'Amon',
    'userId': '9347129304',
    'ipLocation': '中国 · 上海',
    'bio': '热爱摄影，分享生活点滴，欢迎交流！',
    'avatar': 'https://i.pravatar.cc/100?img=1',
  };

  // Mock stats
  final Map<String, String> _stats = {
    'following': '128',
    'followers': '345',
    'likes': '1024',
  };

  // Mock recent browsing history
  final List<Map<String, String>> _recentBrowsing = List.generate(
    5,
    (i) => {
      'title': '最近浏览 $i',
      'image': 'https://picsum.photos/150/${150 + Random().nextInt(50)}?random=$i',
      'avatar': 'https://i.pravatar.cc/40?img=${i + 1}',
    },
  );

  // Mock user posts, collected, and liked items
  final List<Map<String, String>> _userPosts = List.generate(
    8,
    (i) => {
      'title': '我的笔记 $i',
      'image': 'https://picsum.photos/200/${200 + Random().nextInt(100)}?random=$i',
      'avatar': 'https://i.pravatar.cc/40?img=1',
    },
  );

  final List<Map<String, String>> _collectedPosts = List.generate(
    6,
    (i) => {
      'title': '收藏内容 $i',
      'image': 'https://picsum.photos/200/${200 + Random().nextInt(100)}?random=${i + 10}',
      'avatar': 'https://i.pravatar.cc/40?img=${i + 2}',
    },
  );

  final List<Map<String, String>> _likedPosts = List.generate(
    4,
    (i) => {
      'title': '点赞内容 $i',
      'image': 'https://picsum.photos/200/${200 + Random().nextInt(100)}?random=${i + 20}',
      'avatar': 'https://i.pravatar.cc/40?img=${i + 3}',
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_userData['avatar']!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['username']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${_userData['userId']} | IP: ${_userData['ipLocation']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData['bio']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatColumn('关注', _stats['following']!),
                        const SizedBox(width: 16),
                        _buildStatColumn('粉丝', _stats['followers']!),
                        const SizedBox(width: 16),
                        _buildStatColumn('获赞', _stats['likes']!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement edit profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED4956),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('编辑资料'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement follow/unfollow
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFED4956)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '关注',
                    style: TextStyle(color: Color(0xFFED4956)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBrowsingTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentBrowsing.length,
        itemBuilder: (context, index) {
          final item = _recentBrowsing[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    item['image']!,
                    fit: BoxFit.cover,
                    height: 100,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(item['avatar']!),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _userData['username']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, String> item) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            item['image']!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(
              item['title']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(item['avatar']!),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _userData['username']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    List<Map<String, String>> content;
    Widget contentWidget;
    switch (_selectedTabIndex) {
      case 0:
        content = _userPosts;
        contentWidget = MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _buildCard(content[index]);
          },
        );
        break;
      case 1:
        contentWidget = _buildRecentBrowsingTab();
        break;
      case 2:
        content = _collectedPosts;
        contentWidget = MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _buildCard(content[index]);
          },
        );
        break;
      case 3:
        content = _likedPosts;
        contentWidget = MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _buildCard(content[index]);
          },
        );
        break;
      default:
        content = _userPosts;
        contentWidget = MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _buildCard(content[index]);
          },
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SizedBox(
        key: ValueKey<int>(_selectedTabIndex),
        height: _selectedTabIndex == 1 ? 180 : 600,
        child: contentWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _userData['username']!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildUserHeader()),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFED4956),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFFED4956),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: _tabs
                        .map((tab) => Tab(
                              child: Text(tab),
                            ))
                        .toList(),
                  ),
                ),
                Container(
                  color: Colors.grey[200],
                  height: 1,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }
}