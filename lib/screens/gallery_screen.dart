import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("相册")),
      body: const Center(
        child: Text("这里是相册页面（TODO）"),
      ),
    );
  }
}
