import 'package:flutter/material.dart';

class PoseLibraryScreen extends StatelessWidget {
  const PoseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("姿势库")),
      body: const Center(
        child: Text("这里是姿势库页面（TODO）"),
      ),
    );
  }
}
