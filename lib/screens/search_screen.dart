import 'package:flutter/material.dart';
import '../config/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> hotSearches = const [
    "旅行拍照",
    "美食",
    "摄影技巧",
    "打卡地",
    "风格穿搭",
    "网红景点"
  ];

  List<String> searchHistory = []; // 搜索历史初始化为空

  List<String> searchResults = []; // 模拟搜索结果

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    // 添加到历史，如果已存在则移到前面
    setState(() {
      searchHistory.remove(keyword);
      searchHistory.insert(0, keyword);
    });
    // 跳转到搜索结果页面
    Navigator.pushNamed(context, AppRoutes.result);
  }

  void _onClearHistory() {
    setState(() {
      searchHistory.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSearchBox() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "搜索内容",
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearch,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.clear();
                  searchResults.clear();
                });
              },
              child: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildHotSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "热门搜索",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hotSearches
              .map((e) => GestureDetector(
                    onTap: () {
                      _controller.text = e;
                      _onSearch(e);
                    },
                    child: Chip(
                      label: Text(e),
                      backgroundColor: Colors.grey[200],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    if (searchHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "搜索历史",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _onClearHistory,
              child: const Text("清空"),
            ),
          ],
        ),
        Column(
          children: searchHistory
              .map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(e),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _onSearch(e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: _buildSearchBox(),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (searchResults.isEmpty) _buildHotSearches(),
              _buildSearchHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
