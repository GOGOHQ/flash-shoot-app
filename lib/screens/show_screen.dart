import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class ShowScreen extends StatefulWidget {
  final String baseUrl;
  final String userId;

  const ShowScreen({Key? key, required this.baseUrl, required this.userId})
      : super(key: key);

  @override
  _ShowScreenState createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  List<String> imageUrls = [];
  bool loading = true;
  final Set<int> selectedIndices = {};
  bool selectionMode = false;
  bool uploading = false;
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier(0.0);

  String style = "";
  String flag = "";

  @override
  void initState() {
    super.initState();
    fetchBackgroundPersonImages();
  }

  Future<void> fetchBackgroundPersonImages() async {
    setState(() {
      loading = true;
      if (!selectionMode) selectedIndices.clear();
    });

    try {
      final response = await Dio().get(
        '${widget.baseUrl}/background_person',
        queryParameters: {'user_id': widget.userId},
      );

      if (response.statusCode == 200 && response.data is List) {
        List<String> urls = List<String>.from(response.data);
        setState(() {
          imageUrls = urls;
        });
      } else {
        setState(() {
          imageUrls = [];
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
      setState(() {
        imageUrls = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
      selectionMode = selectedIndices.isNotEmpty;
    });
  }

  Future<void> uploadSelectedAndClearBackground() async {
    if (selectedIndices.isEmpty) return;

    setState(() {
      uploading = true;
    });

    try {
      final dio = Dio();
      final formData = FormData();
      formData.fields.add(MapEntry('user_id', widget.userId));

      for (var index in selectedIndices) {
        final filename = imageUrls[index].split('/').last;
        formData.fields.add(MapEntry('filenames', filename));
      }

      final resp = await dio.post(
        '${widget.baseUrl}/transfer_background',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已上传并删除 background_person')),
        );
        fetchBackgroundPersonImages();
      } else {
        throw Exception('操作失败，状态码: ${resp.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() {
        uploading = false;
        selectedIndices.clear();
        selectionMode = false;
      });
    }
  }

  // 姿势指导
  Future<void> _poseGuidance() async {
    if (widget.userId == null || selectedIndices.isEmpty) return;

    setState(() {
      uploading = true;
    });
    uploadProgressNotifier.value = 0.0;

    final dio = Dio();
    final formData = FormData();

    // ===== 1. 用户信息和定制参数打包成 JSON =====
    final metadata = {
      "user_id": widget.userId,
      "style": style,  // 风格
      "flag": flag,   // 判断是姿势指导还是姿势推荐
    };

    // // 注意这里把 JSON 转成字符串放到 formData 里
    // formData.fields.add(MapEntry("metadata", metadata.toString())); 
    // 如果后端需要标准 JSON，建议用：
    // import 'dart:convert';
    formData.fields.add(MapEntry("metadata", jsonEncode(metadata)));

    try {
      // ===== 2. 将选中的图片加入 formData =====
      for (var index in selectedIndices) {
        final filename = imageUrls[index].split('/').last;
        formData.fields.add(MapEntry('filenames', filename));
      }
      // ===== 3. 上传 =====
      final response = await dio.post(
        "${widget.baseUrl}/background",
        data: formData,
        options: Options(headers: {"Accept": "application/json"}),
        onSendProgress: (sent, total) {
          if (total != 0) uploadProgressNotifier.value = sent / total;
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("上传到 background 成功")));

        setState(() {
          selectedIndices.clear();
          selectionMode = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("上传失败: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("上传出错: $e")));
    } finally {
      setState(() {
        uploading = false;
      });
      uploadProgressNotifier.value = 0.0;
    }
  }


  void _showUploadOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Center(
          child: Text(
            '请选择操作',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== 上传类 =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.draw),
                label: const Text('用户调整'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    flag = "weitiao";
                  });
                  _showCustomizationDialog();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.accessibility_new),
                label: const Text('线稿生成'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  uploadSelectedAndClearBackground();
                },
              ),
            ),         
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }

  /// 用户调整对话框
  void _showCustomizationDialog() {
    final TextEditingController styleController =
        TextEditingController(text: style);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Center(
          child: Text(
            "用户调整",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: styleController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "微调描述",
                  prefixIcon: const Icon(Icons.brush),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
            },
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                style = styleController.text.trim();
              });
              Navigator.pop(context); // 关闭对话框
              _poseGuidance();
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  /// 打开全屏预览（支持左右滑动）
  void _openImagePreview(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final imgUrl = imageUrls[index];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    '${widget.baseUrl}$imgUrl',
                    fit: BoxFit.contain, // 居中显示
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('${selectedIndices.length} selected')
            : const Text('Background Person'),
        actions: [
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: uploading ? null : () {
                setState(() {
                  style = "";
                  flag = "";
                });
                _showUploadOptions();
              }, 
            ),
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedIndices.clear();
                  selectionMode = false;
                });
              },
            ),
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchBackgroundPersonImages,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : imageUrls.isEmpty
              ? const Center(child: Text('No images found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final relativeUrl = imageUrls[index];
                    final selected = selectedIndices.contains(index);

                    return GestureDetector(
                      onTap: () => _openImagePreview(index), // 👉 点击预览（可左右滑）
                      onLongPress: () => _toggleSelection(index), // 👉 长按选择
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              '${widget.baseUrl}$relativeUrl',
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (selectionMode)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    selected ? Colors.blue : Colors.black26,
                                child: Icon(
                                  selected ? Icons.check : Icons.circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),  
    );
  }
}
