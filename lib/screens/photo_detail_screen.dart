import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class PhotoDetailScreen extends StatefulWidget {
  final AssetEntity asset;
  final List<AssetEntity> allAssets;
  final int initialIndex;

  const PhotoDetailScreen({
    super.key,
    required this.asset,
    required this.allAssets,
    required this.initialIndex,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allAssets.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          return FutureBuilder<Uint8List?>(
            future: widget.allAssets[index].originBytes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              return GestureDetector(
                onTap: () => Navigator.pop(context), // 单击返回相册页
                child: InteractiveViewer(
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
