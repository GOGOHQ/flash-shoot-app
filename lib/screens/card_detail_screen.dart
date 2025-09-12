import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:faker/faker.dart' hide Image;
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/recommendation_item.dart';
import 'package:flutter/services.dart' show rootBundle;


class CardDetailScreen extends StatefulWidget {
  final RecommendationItem item;

  const CardDetailScreen({super.key, required this.item});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final Faker faker = Faker();
  final List<Map<String, dynamic>> _comments = [];

  late int _likes;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.item.likes;
    _comments.addAll(_generateFakeComments(8));
  }

  List<Map<String, dynamic>> _generateFakeComments(int count) {
    return List.generate(count, (index) {
      final avatarId = 1011 + index; // 自增 ID
      return {
        "username": faker.internet.userName(),
        "avatar": "https://picsum.photos/id/$avatarId/150/150",
        "comment": faker.lorem.sentence(),
        "likes": faker.randomGenerator.integer(500, min: 1),
        "isLiked": false,
      };
    });
  }

  void _showCommentInput() {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      setState(() {
                        _comments.insert(0, {
                          "username": "You",
                          "avatar": "https://i.pravatar.cc/150?img=1",
                          "comment": controller.text.trim(),
                          "likes": 0,
                          "isLiked": false,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _likes -= 1;
      } else {
        _likes += 1;
      }
      _isLiked = !_isLiked;
    });
  }

  void _toggleCommentLike(int index) {
    setState(() {
      final c = _comments[index];
      if (c["isLiked"]) {
        c["likes"] -= 1;
      } else {
        c["likes"] += 1;
      }
      c["isLiked"] = !c["isLiked"];
    });
  }

  Future<void> _saveImageToGallery() async {
    final imageUrl = widget.item.imageUrl;
    try {
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List imageBytes = Uint8List.fromList(response.data);

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "flutter_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("保存成功！")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("保存失败")),
        );
      }
    } catch (e) {
      print("❌ 保存图片失败: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("保存出错")),
      );
    }
  }

  Future<void> _saveAssetImageToGallery(String assetPath) async {
    try {
      // 从 assets 加载图片
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List imageBytes = byteData.buffer.asUint8List();

      // 保存到相册
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "flutter_asset_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("保存成功！")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("保存失败")),
        );
      }
    } catch (e) {
      print("❌ 保存 asset 图片失败: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("保存出错")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = widget.item.imageUrl.startsWith('http');
    bool isNetworkAvatar = widget.item.avatarUrl.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            isNetworkAvatar
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(widget.item.avatarUrl),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(widget.item.avatarUrl),
                  ),
            const SizedBox(width: 8),
            Text(
              widget.item.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片 + 长按弹窗
            GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return SizedBox(
                      height: 140,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.download),
                            title: const Text("保存到相册"),
                            onTap: () async {
                              Navigator.pop(context);
                              if (widget.item.imageUrl.startsWith('http')) {
                                _saveImageToGallery(); // 网络图片
                              } else {
                                _saveAssetImageToGallery(widget.item.imageUrl); // 本地资源图片
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.close),
                            title: const Text("取消"),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: isNetworkImage
                  ? Image.network(widget.item.imageUrl,
                      width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(widget.item.imageUrl,
                      width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.item.title,
                  style: const TextStyle(fontSize: 16)),
            ),
            const Divider(height: 24),

            // 评论区
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text("Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(c["avatar"]),
                  ),
                  title: Text(c["username"],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c["comment"]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          c["isLiked"]
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: c["isLiked"] ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => _toggleCommentLike(index),
                      ),
                      Text('${c["likes"]}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 56,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleLike,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 4),
            Text('$_likes', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _showCommentInput,
              child: const Icon(Icons.comment, color: Colors.grey, size: 32),
            ),
            const SizedBox(width: 4),
            Text('${_comments.length}', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _showCommentInput,
              child: const Icon(Icons.edit, color: Colors.blue, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
