import 'package:dio/dio.dart';

class UnsplashService {
  final String accessKey = "Sgw_B-2Ko-7eqZa0DcTVjtHoj5Ur-MJfjb2HmiC2BU4"; // ⚠️ 替换成你的 Unsplash Access Key
  final String baseUrl = "https://api.unsplash.com";

  final Dio _dio = Dio();

  /// 搜索“拍照姿势”相关图片
  Future<List<Map<String, dynamic>>> fetchPosePhotos({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dio.get(
        "$baseUrl/search/photos",
        queryParameters: {
          "query": "pose",
          "page": page,
          "per_page": perPage,
          "client_id": accessKey,
          "order_by": "relevant", // 可选：relevant / latest
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data["results"];

        // 先转换成 Map 列表
        final photos = results.map((item) {
          return {
            "id": item["id"],
            "description": item["description"] ?? item["alt_description"] ?? "无描述",
            "small": item["urls"]["small"],
            "regular": item["urls"]["regular"],
            "likes": item["likes"],
            "author": {
              "name": item["user"]["name"],
              "avatar": item["user"]["profile_image"]["medium"],
            },
          };
        }).toList();

        // 按点赞数降序排序
        photos.sort((a, b) => (b["likes"] as int).compareTo(a["likes"] as int));

        return photos;
      } else {
        throw Exception("Failed to fetch photos");
      }
    } catch (e) {
      print("❌ Unsplash API Error: $e");
      return [];
    }
  }

}
