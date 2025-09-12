import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

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
              onPressed: uploading ? null : uploadSelectedAndClearBackground,
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
                      onTap: () => _toggleSelection(index),
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
