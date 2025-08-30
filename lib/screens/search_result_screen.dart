import 'package:flutter/material.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("搜索结果")),
      body: const Center(
        child: Text("这里是搜索结果页面（TODO）"),
      ),
    );
  }
}
