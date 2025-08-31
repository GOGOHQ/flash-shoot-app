import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import '../config/api_config.dart';

class ApiService {
  
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP 客户端
  final http.Client _client = http.Client();

  // 通用 GET 请求方法
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParameters}) async {
    // 尝试主 URL
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(queryParameters: queryParameters);
      debugPrint('API 请求 (主): $uri');
      
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15), // 增加超时时间到15秒
        onTimeout: () {
          throw Exception('请求超时');
        },
      );
      
      debugPrint('API 响应状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API 响应数据: $data');
        return data;
      } else {
        debugPrint('API 错误响应: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('主 URL 请求失败: $e');
      
      // 尝试备用 URL
      try {
        final backupUri = Uri.parse('${ApiConfig.backupBaseUrl}$endpoint').replace(queryParameters: queryParameters);
        debugPrint('API 请求 (备用): $backupUri');
        
        final response = await _client.get(backupUri).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('备用请求超时');
          },
        );
        
        debugPrint('备用 API 响应状态码: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint('备用 API 响应数据: $data');
          return data;
        } else {
          debugPrint('备用 API 错误响应: ${response.body}');
          throw Exception('备用 HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (backupError) {
        debugPrint('备用 URL 请求也失败: $backupError');
        throw Exception('网络请求失败: $e (备用: $backupError)');
      }
    }
  }

  // 小红书 API 方法

  /// 搜索热门帖子
  /// 
  /// [limit] 返回结果数量，默认 10
  /// [q] 搜索关键词，如果不提供则返回热门帖子
  /// [skipLogin] 是否跳过登录，默认 false
  Future<XhsHotResponse> getXhsHot({
    int? limit,
    String? q,
    bool? skipLogin,
  }) async {
    debugPrint('=== 小红书API调用开始 ===');
    debugPrint('参数: limit=$limit, q=$q, skipLogin=$skipLogin');
    
    final queryParams = <String, String>{};
    
    if (limit != null) queryParams['limit'] = limit.toString();
    if (q != null) queryParams['q'] = q;
    if (skipLogin != null) queryParams['skip_login'] = skipLogin.toString();

    debugPrint('查询参数: $queryParams');
    final response = await _get('/api/xhs/hot', queryParameters: queryParams);
    debugPrint('小红书API原始响应: $response');
    
    final result = XhsHotResponse.fromJson(response);
    debugPrint('小红书API解析结果: ${result.data.length} 条数据');
    debugPrint('=== 小红书API调用完成 ===');
    
    return result;
  }

  /// 搜索帖子链接
  /// 
  /// [q] 搜索关键词（必需）
  /// [limit] 返回结果数量，默认 5
  /// [skipLogin] 是否跳过登录，默认 false
  Future<XhsSearchResponse> searchXhsPosts({
    required String q,
    int? limit,
    bool? skipLogin,
  }) async {
    final queryParams = <String, String>{
      'q': q,
    };
    
    if (limit != null) queryParams['limit'] = limit.toString();
    if (skipLogin != null) queryParams['skip_login'] = skipLogin.toString();

    final response = await _get('/api/xhs/search', queryParameters: queryParams);
    return XhsSearchResponse.fromJson(response);
  }

  // 百度地图 API 方法

  /// 地理编码
  /// 
  /// [address] 地址字符串（必需）
  Future<GeocodeResponse> geocode({
    required String address,
  }) async {
    final queryParams = <String, String>{
      'address': address,
    };

    final response = await _get('/api/baidu-maps/geocode', queryParameters: queryParams);
    return GeocodeResponse.fromJson(response['data']);
  }

  /// 逆地理编码
  /// 
  /// [lat] 纬度（必需）
  /// [lng] 经度（必需）
  Future<ReverseGeocodeResponse> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
    };

    final response = await _get('/api/baidu-maps/reverse-geocode', queryParameters: queryParams);
    return ReverseGeocodeResponse.fromJson(response['data']);
  }

  /// 搜索地点
  /// 
  /// [q] 搜索关键词（必需）
  /// [city] 城市名称（可选）
  /// [limit] 返回结果数量，默认 10
  /// [tag] 标签（可选）
  /// [region] 地区（可选）
  /// [location] 位置坐标（可选）
  /// [radius] 搜索半径（可选）
  Future<SearchPlacesResponse> searchPlaces({
    required String q,
    String? city,
    int? limit,
    String? tag,
    String? region,
    String? location,
    int? radius,
  }) async {
    final queryParams = <String, String>{
      'q': q,
    };
    
    if (city != null) queryParams['city'] = city;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (tag != null) queryParams['tag'] = tag;
    if (region != null) queryParams['region'] = region;
    if (location != null) queryParams['location'] = location;
    if (radius != null) queryParams['radius'] = radius.toString();

    final response = await _get('/api/baidu-maps/search-places', queryParameters: queryParams);
    debugPrint('搜索地点 API 原始响应: $response');
    
    // API 返回的是 {data: [地点数组]}，我们需要构造正确的格式
    final placesList = response['data'] as List? ?? [];
    debugPrint('搜索地点 API 地点数组: $placesList');
    
    // 构造 SearchPlacesResponse 期望的格式
    final formattedResponse = {
      'status': 0,
      'message': 'success',
      'result_type': 'place',
      'query_type': 'search',
      'results': placesList,
    };
    
    debugPrint('搜索地点 API 格式化后数据: $formattedResponse');
    
    return SearchPlacesResponse.fromJson(formattedResponse);
  }

  /// 天气查询
  /// 
  /// [location] 经纬度坐标，格式：经度,纬度（必需）
  Future<WeatherResponse> getWeather({
    required String location,
  }) async {
    final queryParams = <String, String>{
      'location': location,
    };

    debugPrint('天气查询 API 请求参数: $queryParams');
    final response = await _get('/api/baidu-maps/weather', queryParameters: queryParams);
    debugPrint('天气查询 API 原始响应: $response');
    return WeatherResponse.fromJson(response);
  }

  /// 天气查询（使用 Location 对象）
  /// 
  /// [location] Location 对象（必需）
  Future<WeatherResponse> getWeatherByLocation({
    required Location location,
  }) async {
    final locationString = '${location.lng},${location.lat}';
    return getWeather(location: locationString);
  }

  // 便捷方法

  /// 根据地址获取坐标
  Future<Location?> getLocationByAddress(String address) async {
    try {
      final response = await geocode(address: address);
      if (response.status == 0) {
        return response.result.location;
      }
      return null;
    } catch (e) {
      debugPrint('获取地址坐标失败: $e');
      return null;
    }
  }

  /// 根据坐标获取地址
  Future<String?> getAddressByLocation(double lat, double lng) async {
    try {
      final response = await reverseGeocode(lat: lat, lng: lng);
      if (response.status == 0) {
        return response.result.formattedAddress;
      }
      return null;
    } catch (e) {
      debugPrint('获取坐标地址失败: $e');
      return null;
    }
  }

  /// 搜索附近的美食
  Future<List<Place>> searchNearbyFood({
    required double lat,
    required double lng,
    int radius = 2000,
    int limit = 10,
  }) async {
    try {
      final location = '$lat,$lng';
      final response = await searchPlaces(
        q: '美食',
        tag: '餐饮服务',
        location: location,
        radius: radius,
        limit: limit,
      );
      return response.results;
    } catch (e) {
      debugPrint('搜索附近美食失败: $e');
      return [];
    }
  }

  /// 搜索附近的景点
  Future<List<Place>> searchNearbyAttractions({
    required double lat,
    required double lng,
    int radius = 5000,
    int limit = 10,
  }) async {
    try {
      final location = '$lat,$lng';
      final response = await searchPlaces(
        q: '景点',
        tag: '旅游景点',
        location: location,
        radius: radius,
        limit: limit,
      );
      return response.results;
    } catch (e) {
      debugPrint('搜索附近景点失败: $e');
      return [];
    }
  }

  // 释放资源
  void dispose() {
    _client.close();
  }
}
