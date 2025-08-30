import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("社区")),
      body: const Center(
        child: Text("这里是社区页面（TODO）"),
      ),
    );
  }
}
