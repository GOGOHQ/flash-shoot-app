import 'dart:convert';
import 'package:flutter/services.dart';

/// POI内容数据模型
class PoiContentModel {
  final Map<String, PoiCanonicalName> canonicalNames;
  final Map<String, List<PoiImageItem>> content;

  PoiContentModel({
    required this.canonicalNames,
    required this.content,
  });

  factory PoiContentModel.fromJson(Map<String, dynamic> json) {
    final canonicalNamesData = json['canonical_names'] as Map<String, dynamic>;
    final contentData = json['content'] as Map<String, dynamic>;

    final canonicalNames = canonicalNamesData.map(
      (key, value) => MapEntry(key, PoiCanonicalName.fromJson(value)),
    );

    final content = contentData.map(
      (key, value) => MapEntry(
        key,
        (value as List).map((item) => PoiImageItem.fromJson(item)).toList(),
      ),
    );

    return PoiContentModel(
      canonicalNames: canonicalNames,
      content: content,
    );
  }

  /// 根据POI名称获取对应的图片列表
  List<PoiImageItem>? getImagesForPoi(String poiName) {
    // 先尝试直接匹配
    if (content.containsKey(poiName)) {
      return content[poiName];
    }

    // 通过别名匹配
    for (final entry in canonicalNames.entries) {
      final canonicalName = entry.key;
      final aliases = entry.value.aliases;
      
      if (aliases.contains(poiName)) {
        return content[canonicalName];
      }
    }

    return null;
  }

  /// 获取所有可用的POI名称
  List<String> getAllPoiNames() {
    return content.keys.toList();
  }
}

/// POI规范名称和别名
class PoiCanonicalName {
  final List<String> aliases;

  PoiCanonicalName({required this.aliases});

  factory PoiCanonicalName.fromJson(Map<String, dynamic> json) {
    return PoiCanonicalName(
      aliases: List<String>.from(json['aliases'] ?? []),
    );
  }
}

/// POI图片项目
class PoiImageItem {
  final String image;
  final List<String> text;

  PoiImageItem({
    required this.image,
    required this.text,
  });

  factory PoiImageItem.fromJson(Map<String, dynamic> json) {
    return PoiImageItem(
      image: json['image'] ?? '',
      text: List<String>.from(json['text'] ?? []),
    );
  }
}

/// POI内容服务
class PoiContentService {
  static PoiContentModel? _cachedModel;
  
  /// 加载POI内容数据
  static Future<PoiContentModel> loadPoiContent() async {
    if (_cachedModel != null) {
      return _cachedModel!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/poi/poi_content.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedModel = PoiContentModel.fromJson(jsonData);
      return _cachedModel!;
    } catch (e) {
      throw Exception('加载POI内容失败: $e');
    }
  }

  /// 根据POI名称获取图片列表
  static Future<List<PoiImageItem>?> getImagesForPoi(String poiName) async {
    final model = await loadPoiContent();
    return model.getImagesForPoi(poiName);
  }

  /// 清除缓存
  static void clearCache() {
    _cachedModel = null;
  }
}
