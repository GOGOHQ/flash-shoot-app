import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("地图/天气规划")),
      body: const Center(
        child: Text("这里是地图/天气规划页面（TODO）"),
      ),
    );
  }
}
