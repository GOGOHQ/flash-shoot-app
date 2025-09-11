import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import '../config/api_config.dart';
import '../config/baidu_map_config.dart';
import 'dart:math' as math;

class ApiService {
  
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP 客户端
  final http.Client _client = http.Client();
  
  // 缓存机制
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10); // 缓存10分钟

  // 缓存相关方法
  String _generateCacheKey(String endpoint, Map<String, String>? queryParameters) {
    final params = queryParameters?.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&') ?? '';
    return '$endpoint?$params';
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  dynamic _getCache(String key) {
    if (_isCacheValid(key)) {
      return _cache[key];
    }
    return null;
  }

  // 通用 GET 请求方法
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParameters, bool useCache = true}) async {
    // 检查缓存
    if (useCache) {
      final cacheKey = _generateCacheKey(endpoint, queryParameters);
      final cachedData = _getCache(cacheKey);
      if (cachedData != null) {
        debugPrint('使用缓存数据: $cacheKey');
        return cachedData;
      }
    }
    
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
        
        // 缓存成功响应
        if (useCache) {
          final cacheKey = _generateCacheKey(endpoint, queryParameters);
          _setCache(cacheKey, data);
        }
        
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
  }) async {
    debugPrint('=== 小红书API调用开始 ===');
    
    final queryParams = <String, String>{};
    
    if (limit != null) queryParams['limit'] = limit.toString();
    if (q != null) queryParams['q'] = q;

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

  /// 测试函数：根据当前白名单配置检索并将 POI 列表输出到终端
  ///
  /// 使用 `BaiduMapConfig.specifiedPoiKeywords` 和 `specifiedPoiUids`。
  /// 若关键词白名单为空，将输出提示并不执行检索。
  Future<void> debugPrintSpecifiedPois({
    required double lat,
    required double lng,
  }) async {
    final keywords = BaiduMapConfig.specifiedPoiKeywords;
    final uidWhitelist = BaiduMapConfig.specifiedPoiUids;
    final exactNames = BaiduMapConfig.specifiedPoiExactNames;

    if (keywords.isEmpty) {
      debugPrint('[POI TEST] 关键词白名单为空，未执行检索。请在 BaiduMapConfig.specifiedPoiKeywords 中配置关键词。');
      return;
    }

    debugPrint('=== [POI TEST] 开始检索（lat=$lat, lng=$lng） ===');
    final List<Place> aggregated = [];

    // 第一步：通过 geocode 获取白名单关键词的精确坐标
    final Map<String, Location> keywordLocations = {};
    for (final keyword in keywords) {
      try {
        debugPrint('[POI TEST] 正在地理编码: "$keyword"');
        final geocodeResp = await geocode(address: keyword);
        debugPrint('[POI TEST] "$keyword" 地理编码响应: status=${geocodeResp.status}');
        if (geocodeResp.status == 0) {
          keywordLocations[keyword] = geocodeResp.result.location;
          debugPrint('[POI TEST] "$keyword" 坐标: (${geocodeResp.result.location.lat}, ${geocodeResp.result.location.lng})');
        } else {
          debugPrint('[POI TEST] "$keyword" 地理编码失败: status=${geocodeResp.status}');
          // 尝试添加城市信息重新编码
          try {
            final retryResp = await geocode(address: '北京$keyword');
            if (retryResp.status == 0) {
              keywordLocations[keyword] = retryResp.result.location;
              debugPrint('[POI TEST] "$keyword" 重试成功，坐标: (${retryResp.result.location.lat}, ${retryResp.result.location.lng})');
            } else {
              debugPrint('[POI TEST] "$keyword" 重试也失败: status=${retryResp.status}');
            }
          } catch (retryE) {
            debugPrint('[POI TEST] "$keyword" 重试异常: $retryE');
          }
        }
      } catch (e) {
        debugPrint('[POI TEST] "$keyword" 地理编码异常: $e');
      }
      // 控制请求节奏
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 第二步：基于获取到的坐标，使用 searchPlaces 获取具体POI信息
    for (final entry in keywordLocations.entries) {
      final keyword = entry.key;
      final location = entry.value;
      try {
        debugPrint('[POI TEST] 基于坐标检索 "$keyword" 在 (${location.lat}, ${location.lng})');
        final resp = await searchPlaces(
          q: keyword,
          location: '${location.lat},${location.lng}',
          radius: 5000, // 增大搜索半径，环球影城面积大
          limit: 10, // 增加数量，提高找到的概率
        );
        debugPrint('[POI TEST] "$keyword" 搜索结果: ${resp.results.length} 条');
        for (final result in resp.results) {
          debugPrint('[POI TEST]   - ${result.name} (${result.location.lat}, ${result.location.lng})');
        }
        aggregated.addAll(resp.results);
        
        // 如果没找到结果，尝试更宽泛的搜索
        if (resp.results.isEmpty && keyword == '环球影城') {
          debugPrint('[POI TEST] "$keyword" 未找到，尝试更宽泛搜索...');
          final broadResp = await searchPlaces(
            q: '环球影城',
            location: '${location.lat},${location.lng}',
            radius: 10000, // 更大的搜索半径
            limit: 20,
          );
          debugPrint('[POI TEST] "$keyword" 宽泛搜索结果: ${broadResp.results.length} 条');
          for (final result in broadResp.results) {
            debugPrint('[POI TEST]   - ${result.name} (${result.location.lat}, ${result.location.lng})');
          }
          aggregated.addAll(broadResp.results);
        }
      } catch (e) {
        debugPrint('[POI TEST] 基于坐标检索 "$keyword" 失败: $e');
      }
      // 控制请求节奏
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 去重与可选 UID 白名单过滤（支持别名与地理距离容错）
    final Map<String, Place> uniqueByUid = {};
    for (final p in aggregated) {
      if (p.uid.isEmpty) continue;
      if (uidWhitelist.isNotEmpty && !uidWhitelist.contains(p.uid)) continue;
      final String name = p.name;
      bool match = keywords.any((k) => name.contains(k));
      if (!match) {
        for (final k in keywords) {
          final List<String> aliasList = (BaiduMapConfig.specifiedPoiAliases[k] ?? const []);
          if (aliasList.any((a) => name.contains(a))) {
            match = true;
            break;
          }
        }
      }
      bool nearEnough = false;
      if (!match) {
        // 使用每个关键词的 geocode 坐标做近邻判断（3km）
        for (final loc in keywordLocations.values) {
          final dKm = _haversineKm(loc.lat, loc.lng, p.location.lat, p.location.lng);
          if (dKm <= 3.0) {
            nearEnough = true;
            break;
          }
        }
      }
      if (!match && !nearEnough) continue;
      uniqueByUid.putIfAbsent(p.uid, () => p);
    }

    // 严格精确匹配：按关键词挑选1个最匹配的结果，仅保留白名单数量
    final List<Place> results = [];
    for (final k in keywords) {
      final candidates = uniqueByUid.values.where((p) {
        final name = p.name;
        final exactList = exactNames[k] ?? const [];
        // 若有 exact 名称，必须精确等于其一；否则使用包含匹配
        if (exactList.isNotEmpty) {
          return exactList.contains(name);
        }
        return name.contains(k);
      }).toList();
      if (candidates.isEmpty) continue;
      // 选取距离该关键词 geocode 坐标最近的一个
      Location? loc = keywordLocations[k];
      candidates.sort((a, b) {
        final da = loc == null ? 0.0 : _haversineKm(loc.lat, loc.lng, a.location.lat, a.location.lng);
        final db = loc == null ? 0.0 : _haversineKm(loc.lat, loc.lng, b.location.lat, b.location.lng);
        return da.compareTo(db);
      });
      results.add(candidates.first);
    }
    debugPrint('=== [POI TEST] 最终 POI 数量: ${results.length} ===');
    for (int i = 0; i < results.length; i++) {
      final p = results[i];
      debugPrint('[POI TEST] #${i + 1} ${p.name} | uid=${p.uid} | (${p.location.lat}, ${p.location.lng}) | address=${p.address}');
    }

    debugPrint('=== [POI TEST] 检索完成 ===');
  }

  // 计算两点间球面距离（公里）
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0;
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  /// 预加载POI数据
  /// 
  /// [lat] 纬度
  /// [lng] 经度
  /// 返回预加载的POI列表
  Future<List<Place>> preloadPoiData({
    required double lat,
    required double lng,
  }) async {
    debugPrint('=== 开始预加载POI数据 ===');
    debugPrint('位置: $lat, $lng');
    
    try {
      final List<Place> allPois = [];
      final locationStr = '$lat,$lng';
      final radius = 15000;

      final hasSpecifiedKeywords = BaiduMapConfig.specifiedPoiKeywords.isNotEmpty;
      final hasSpecifiedUids = BaiduMapConfig.specifiedPoiUids.isNotEmpty;

      if (hasSpecifiedKeywords) {
        debugPrint('预加载指定关键词POI: ${BaiduMapConfig.specifiedPoiKeywords}');
        
        // 第一步：通过 geocode 获取白名单关键词的精确坐标
        final Map<String, Location> keywordLocations = {};
        for (final keyword in BaiduMapConfig.specifiedPoiKeywords) {
          try {
            debugPrint('预加载地理编码: "$keyword"');
            final geocodeResp = await geocode(address: keyword);
            if (geocodeResp.status == 0) {
              keywordLocations[keyword] = geocodeResp.result.location;
              debugPrint('预加载关键词 "$keyword" 坐标: (${geocodeResp.result.location.lat}, ${geocodeResp.result.location.lng})');
            } else {
              // 尝试添加城市信息重新编码
              try {
                final retryResp = await geocode(address: '北京$keyword');
                if (retryResp.status == 0) {
                  keywordLocations[keyword] = retryResp.result.location;
                  debugPrint('预加载关键词 "$keyword" 重试成功，坐标: (${retryResp.result.location.lat}, ${retryResp.result.location.lng})');
                }
              } catch (retryE) {
                debugPrint('预加载关键词 "$keyword" 重试异常: $retryE');
              }
            }
          } catch (e) {
            debugPrint('预加载关键词 "$keyword" 地理编码异常: $e');
          }
          // 控制请求节奏
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // 第二步：基于获取到的坐标，使用 searchPlaces 获取具体POI信息
        for (final entry in keywordLocations.entries) {
          final keyword = entry.key;
          final location = entry.value;
          try {
            debugPrint('预加载基于坐标检索 "$keyword" 在 (${location.lat}, ${location.lng})');
            final resp = await searchPlaces(
              q: keyword,
              location: '${location.lat},${location.lng}',
              radius: 5000,
              limit: 10,
            );
            debugPrint('预加载 "$keyword" 搜索结果: ${resp.results.length} 条');
            allPois.addAll(resp.results);
            
            // 如果没找到结果，尝试更宽泛的搜索
            if (resp.results.isEmpty && keyword == '环球影城') {
              debugPrint('预加载 "$keyword" 未找到，尝试更宽泛搜索...');
              final broadResp = await searchPlaces(
                q: '环球影城',
                location: '${location.lat},${location.lng}',
                radius: 10000,
                limit: 20,
              );
              debugPrint('预加载 "$keyword" 宽泛搜索结果: ${broadResp.results.length} 条');
              allPois.addAll(broadResp.results);
            }
          } catch (e) {
            debugPrint('预加载基于坐标检索 "$keyword" 失败: $e');
          }
          // 控制请求节奏
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } else {
        // 保持原逻辑：景点、公园、博物馆、历史建筑
        final categories = [
          {'q': '景点', 'limit': 20},
          {'q': '公园', 'limit': 15},
          {'q': '博物馆', 'limit': 10},
          {'q': '历史建筑', 'limit': 10},
        ];
        
        for (final category in categories) {
          try {
            final response = await searchPlaces(
              q: category['q'] as String,
              location: locationStr,
              radius: radius,
              limit: int.parse(category['limit'] as String),
            );
            allPois.addAll(response.results);
            debugPrint('预加载获取到 ${response.results.length} 个${category['q']} POI');
          } catch (e) {
            debugPrint('预加载获取${category['q']} POI 失败: $e');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // 去重和过滤
      final Map<String, Place> uniquePois = {};
      for (final poi in allPois) {
        if (poi.uid.isEmpty) continue;
        if (hasSpecifiedUids && !BaiduMapConfig.specifiedPoiUids.contains(poi.uid)) continue;

        bool match = true;
        if (BaiduMapConfig.specifiedPoiKeywords.isNotEmpty) {
          final name = poi.name;
          match = BaiduMapConfig.specifiedPoiKeywords.any((k) => name.contains(k));
          if (!match) {
            // 别名匹配
            for (final k in BaiduMapConfig.specifiedPoiKeywords) {
              final aliasList = BaiduMapConfig.specifiedPoiAliases[k] ?? const [];
              if (aliasList.any((a) => name.contains(a))) {
                match = true;
                break;
              }
            }
          }
          if (!match) {
            // 地理距离容错：若与任一关键词的 geocode 坐标距离 < 3km 放行
            final dKm = _haversineKm(lat, lng, poi.location.lat, poi.location.lng);
            match = dKm <= 3.0;
          }
          if (!match) continue;
        }

        if (!uniquePois.containsKey(poi.uid)) {
          uniquePois[poi.uid] = poi;
        }
      }
      
      // 严格精确匹配：按关键词挑选1个最匹配的结果
      List<Place> finalPois = uniquePois.values.toList();
      if (hasSpecifiedKeywords) {
        final List<Place> selected = [];
        for (final k in BaiduMapConfig.specifiedPoiKeywords) {
          final exactList = BaiduMapConfig.specifiedPoiExactNames[k] ?? const [];
          final candidates = finalPois.where((p) {
            if (exactList.isNotEmpty) {
              return exactList.contains(p.name);
            }
            return p.name.contains(k);
          }).toList();
          if (candidates.isEmpty) continue;
          // 选取距离当前关键词 geocode 位置最近的一个
          candidates.sort((a, b) {
            final da = _haversineKm(lat, lng, a.location.lat, a.location.lng);
            final db = _haversineKm(lat, lng, b.location.lat, b.location.lng);
            return da.compareTo(db);
          });
          selected.add(candidates.first);
        }
        finalPois = selected;
      }

      debugPrint('预加载完成，获取到 ${finalPois.length} 个POI');
      debugPrint('=== 预加载POI数据完成 ===');
      
      return finalPois;
    } catch (e) {
      debugPrint('预加载POI数据失败: $e');
      return [];
    }
  }

  // 释放资源
  void dispose() {
    _client.close();
  }
}
