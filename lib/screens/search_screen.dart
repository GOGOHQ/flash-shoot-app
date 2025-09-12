import 'package:flutter/material.dart';
import 'search_result_screen.dart';

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
    "网红景点",
    "天坛",
    "故宫",
    "北京红墙",
    "环球影城",
    "天安门",
  ];

  List<String> searchHistory = [];

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    setState(() {
      searchHistory.remove(keyword);
      searchHistory.insert(0, keyword);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(keyword: keyword),
      ),
    );
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
                    onTap: () => _onSearch(e),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHotSearches(),
            _buildSearchHistory(),
          ],
        ),
      ),
    );
  }
}
