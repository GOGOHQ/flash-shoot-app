import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'photo_detail_screen.dart';
import 'package:flutter/services.dart';
import '../screens/show_screen.dart';
import 'dart:convert';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> assets = [];
  int crossAxisCount = 3; // 默认列数
  double scaleFactor = 1.0;

  // 多选相关
  bool selectionMode = false;
  final Set<int> selectedIndices = {};

  // 上传相关
  bool uploading = false;
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier(0.0);

  // 本地后端地址
  final String baseUrl = 'https://88866280c441.ngrok-free.app';
  String? userId;
  // 用户属性（全部字符串）
  String gender = "";
  String age = "";
  String height = "";
  String weight = "";

  // 个性化定制
  String peopleCount = "";
  String style = "";
  String flag = "";

  // 缩略图缓存
  final Map<int, Uint8List> thumbCache = {};

  @override
  void initState() {
    super.initState();
    _initUserId();
    _fetchAssets();
  }

  Future<void> _initUserId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        userId = iosInfo.identifierForVendor ?? 'ios_guest';
      });
    } else {
      setState(() {
        userId = 'unknown';
      });
    }
  }

  Future<void> _fetchAssets() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return;

    final albums = await PhotoManager.getAssetPathList();
    List<AssetEntity> allAssets = [];

    for (var album in albums) {
      final photos = await album.getAssetListPaged(page: 0, size: 1000);
      allAssets.addAll(photos);
    }

    setState(() {
      assets = allAssets;
    });
  }

  Future<Uint8List?> _loadThumb(int index) async {
    if (thumbCache.containsKey(index)) return thumbCache[index];
    final data =
        await assets[index].thumbnailDataWithSize(const ThumbnailSize(200, 200));
    if (data != null) thumbCache[index] = data;
    return data;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scaleFactor *= details.scale;
      if (scaleFactor > 1.5) crossAxisCount = 2;
      else if (scaleFactor < 0.8) crossAxisCount = 5;
      else crossAxisCount = 3;
      scaleFactor = scaleFactor.clamp(0.5, 2.0);
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      selectionMode = true;
      selectedIndices.add(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) selectedIndices.remove(index);
      else selectedIndices.add(index);

      if (selectedIndices.isEmpty) selectionMode = false;
    });
  }

  // 上传选中的图片（线稿生成）
  Future<void> _uploadSelected() async {
    if (selectedIndices.isEmpty || userId == null) return;

    setState(() {
      uploading = true;
    });
    uploadProgressNotifier.value = 0.0;

    final dio = Dio();
    final formData = FormData();
    formData.fields.add(MapEntry('user_id', userId!));
    formData.fields.add(MapEntry('type', 'sketch')); // 标记线稿生成类型

    try {
      for (var i in selectedIndices) {
        final asset = assets[i];
        final file = await asset.file;
        if (file == null) continue;
        final name = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: name),
        ));
      }

      final response = await dio.post(
        "$baseUrl/upload",
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
        onSendProgress: (sent, total) {
          if (total != 0) uploadProgressNotifier.value = sent / total;
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('上传成功')));
        setState(() {
          selectedIndices.clear();
          selectionMode = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('上传出错: $e')));
    } finally {
      setState(() {
        uploading = false;
      });
      uploadProgressNotifier.value = 0.0;
    }
  }
  // 姿势指导
  Future<void> _poseGuidance() async {
    if (userId == null || selectedIndices.isEmpty) return;

    setState(() {
      uploading = true;
    });
    uploadProgressNotifier.value = 0.0;

    final dio = Dio();
    final formData = FormData();

    // ===== 1. 用户信息和定制参数打包成 JSON =====
    final metadata = {
      "user_id": userId,
      "gender": gender,
      "age": age,
      "height": height,
      "weight": weight,
      "peopleCount": peopleCount, // 人数
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
      for (var i in selectedIndices) {
        final asset = assets[i];
        final file = await asset.file;
        if (file == null) continue;
        final name = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          "files",
          await MultipartFile.fromFile(file.path, filename: name),
        ));
      }

      // ===== 3. 上传 =====
      final response = await dio.post(
        "$baseUrl/background",
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

        // 跳转到 ShowScreen
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowScreen(
                baseUrl: baseUrl,
                userId: userId!,
              ),
            ),
          );
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
            // ===== 功能类 =====
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('用户属性'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showUserAttributesDialog();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('个性化定制'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomizationDialog();
                  // TODO: 打开个性化定制对话框
                },
              ),
            ),

            // ===== 分隔线 =====
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(thickness: 1.2),
            ),

            // ===== 上传类 =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.draw),
                label: const Text('线稿生成'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _uploadSelected();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.accessibility_new),
                label: const Text('姿势指导'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    flag = "zhidao";
                  });
                  Navigator.pop(context);
                  _poseGuidance();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.accessibility_new),
                label: const Text('姿势推荐'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    flag = "tuijian";
                  });
                  Navigator.pop(context);
                  _poseGuidance();
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

  /// 输入用户属性的对话框
  void _showUserAttributesDialog() {
    final genderOptions = ["男", "女", "其他"];
    String tempGender = gender.isNotEmpty ? gender : genderOptions[0];

    final ageController = TextEditingController(text: age);
    final heightController = TextEditingController(text: height);
    final weightController = TextEditingController(text: weight);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "填写用户属性",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 性别选择
              DropdownButtonFormField<String>(
                value: tempGender,
                items: genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) tempGender = value;
                },
                decoration: InputDecoration(
                  labelText: "性别",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 年龄
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "年龄",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 身高
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "身高 (cm)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 体重
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "体重 (kg)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭用户属性对话框
              _showUploadOptions();   // 回到上传选项对话框
            },
            child: const Text("取消"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                gender = tempGender;
                age = ageController.text.trim();
                height = heightController.text.trim();
                weight = weightController.text.trim();
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("用户属性已保存")),
              );
              _showUploadOptions();   // 回到上传选项对话框
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

/// 个性化定制对话框
  void _showCustomizationDialog() {
    final TextEditingController peopleController =
        TextEditingController(text: peopleCount);
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
            "个性化定制",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "人数",
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: null,
              controller: styleController,
              decoration: InputDecoration(
                labelText: "风格",
                prefixIcon: const Icon(Icons.brush),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              _showUploadOptions();
            },
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                peopleCount = peopleController.text.trim();
                style = styleController.text.trim();
              });
              Navigator.pop(context); // 关闭对话框
              _showUploadOptions();
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    uploadProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('${selectedIndices.length} selected')
            : const Text('Gallery'),
        actions: [
              // 👁️ 眼睛按钮：无论是否多选模式都显示
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowScreen(
                      baseUrl: baseUrl,
                      userId: userId!,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('用户信息未初始化')),
                );
              }
            },
          ),
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: uploading ? null : () {
                setState(() {
                  peopleCount = "";
                  style = "";
                  flag = "";
                });
                _showUploadOptions();
              }, // 点击弹出对话框
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
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: _onScaleUpdate,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: _loadThumb(index),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Container(color: Colors.grey[300]);
                    final selected = selectedIndices.contains(index);

                    return GestureDetector(
                      onLongPress: () => _enterSelectionMode(index),
                      onTap: () {
                        if (selectionMode) {
                          _toggleSelection(index);
                          return;
                        }

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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snapshot.data!, fit: BoxFit.cover),
                          if (selectionMode)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? Colors.blue : Colors.black26,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  selected ? Icons.check : Icons.circle,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (uploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: uploadProgressNotifier,
                builder: (context, value, _) {
                  return LinearProgressIndicator(value: value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
