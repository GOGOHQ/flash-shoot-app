import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> assets = [];
  int crossAxisCount = 3; // 默认列数
  double scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return;

    final albums = await PhotoManager.getAssetPathList();
    List<AssetEntity> allAssets = [];

    for (var album in albums) {
      final photos = await album.getAssetListPaged(page: 0, size: 1000); // 每个相册最多1000张
      allAssets.addAll(photos);
    }

    setState(() {
      assets = allAssets;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scaleFactor *= details.scale;
      if (scaleFactor > 1.5) crossAxisCount = 2;
      else if (scaleFactor < 0.8) crossAxisCount = 5;
      else crossAxisCount = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gallery')),
      body: GestureDetector(
        onScaleUpdate: _onScaleUpdate,
        child: GridView.builder(
          padding: EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Widget>(
              future: assets[index].thumbnailDataWithSize(ThumbnailSize(200, 200)).then((data) {
                return Image.memory(data!, fit: BoxFit.cover);
              }),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container(color: Colors.grey[300]);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailScreen(
                          asset: assets[index],
                          allAssets: assets,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: snapshot.data,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
