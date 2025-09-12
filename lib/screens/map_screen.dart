import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:map_launcher/map_launcher.dart';
import '../config/baidu_map_config.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../widgets/recommendation_bubble.dart';
import 'poi_detail_screen.dart';
import 'weather_detail_screen.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BMFMapController? _mapController;
  bool _isMapReady = false;
  BMFMapType _mapType = BMFMapType.Standard;
  
  // 定位相关
  LocationFlutterPlugin? _locationPlugin;
  BMFCoordinate? _currentLocation;
  bool _isLocating = false;
  
  // 天气相关
  bool _isLoadingWeather = false;
  
  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  // POI 标记相关
  List<BMFMarker> _poiMarkers = [];
  bool _isLoadingPois = false;
  List<Place> _nearbyPois = [];
  
  // POI 气泡相关
  Place? _selectedPoi;
  Offset? _bubblePosition;
  
  // 预加载相关
  bool _isPreloading = false;
  bool _hasPreloadedData = false;
  
  
  // 推荐项目
  final List<Map<String, dynamic>> _recommendItems = [
    {'name': '美食', 'icon': Icons.restaurant, 'keyword': '美食'},
    {'name': '景点', 'icon': Icons.attractions, 'keyword': '景点'},
    {'name': '娱乐', 'icon': Icons.sports_esports, 'keyword': '娱乐'},
  ];

  @override
  void initState() {
    super.initState();
    _initBaiduMap();
    // 开始预加载POI数据
    _startPreloading();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationPlugin?.stopLocation();
    super.dispose();
  }

  Future<void> _initBaiduMap() async {
    try {
      // 设置用户是否同意SDK隐私协议
      BMFMapSDK.setAgreePrivacy(true);
      
      // 初始化定位插件
      _locationPlugin = LocationFlutterPlugin();
      _locationPlugin!.setAgreePrivacy(true);

      // 百度地图sdk初始化鉴权
      if (Platform.isIOS) {
        _locationPlugin!.authAK(BaiduMapConfig.ak);
        BMFMapSDK.setApiKeyAndCoordType(
            BaiduMapConfig.ak, BMF_COORD_TYPE.BD09LL);
      } else if (Platform.isAndroid) {
        BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
      }

      setState(() {
        _isMapReady = true;
      });
      
      // 获取定位权限并设置默认位置（不显示气泡）
      await _requestLocationPermission();
      await _setDefaultLocation();
    } catch (e) {
      debugPrint('百度地图初始化失败: $e');
    }
  }

  // 请求定位权限
  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.location.request();
      if (status != PermissionStatus.granted) {
        debugPrint('定位权限被拒绝');
      }
    }
  }

  // 设置默认位置（不显示气泡）
  Future<void> _setDefaultLocation() async {
    debugPrint('=== 设置默认位置 ===');
    if (_locationPlugin == null) {
      debugPrint('定位插件未初始化');
      return;
    }

    try {
      debugPrint('设置默认位置: ${BaiduMapConfig.defaultLatitude}, ${BaiduMapConfig.defaultLongitude}');
      // 使用默认位置（北京天安门）
      setState(() {
        _currentLocation = BMFCoordinate(
          BaiduMapConfig.defaultLatitude,
          BaiduMapConfig.defaultLongitude,
        );
      });
      
      // 更新地图到当前位置
      _updateMapToCurrentLocation();
      
      // 调用测试输出指定POI
      try {
        await _apiService.debugPrintSpecifiedPois(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
        );
      } catch (e) {
        debugPrint('调试输出指定POI失败: $e');
      }
      
      debugPrint('=== 默认位置设置完成 ===');
    } catch (e) {
      debugPrint('设置默认位置失败: $e');
    }
  }

  // 开始定位
  Future<void> _startLocation() async {
    debugPrint('=== 开始定位流程 ===');
    if (_locationPlugin == null) {
      debugPrint('定位插件未初始化');
      return;
    }
    
    setState(() {
      _isLocating = true;
    });

    try {
      debugPrint('设置默认位置: ${BaiduMapConfig.defaultLatitude}, ${BaiduMapConfig.defaultLongitude}');
      // 使用默认位置（北京天安门）
      setState(() {
        _currentLocation = BMFCoordinate(
          BaiduMapConfig.defaultLatitude,
          BaiduMapConfig.defaultLongitude,
        );
        _isLocating = false;
      });
      
      // 更新地图到当前位置
      _updateMapToCurrentLocation();
      
      // 调用测试输出指定POI
      try {
        await _apiService.debugPrintSpecifiedPois(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
        );
      } catch (e) {
        debugPrint('调试输出指定POI失败: $e');
      }
      
      debugPrint('准备显示推荐气泡...');
      // 显示推荐气泡
      _showRecommendationBubble();
      
      debugPrint('开始加载周围 POI...');
      // 加载周围 POI 并在地图上标记
      _loadNearbyPois();
      
      debugPrint('=== 定位流程完成 ===');
    } catch (e) {
      debugPrint('开始定位失败: $e');
      setState(() {
        _isLocating = false;
      });
    }
  }

  // 显示推荐气泡
  void _showRecommendationBubble() {
    debugPrint('=== 显示推荐气泡 ===');
    debugPrint('当前位置: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}');
    
    if (_currentLocation == null) {
      debugPrint('当前位置为空，无法显示推荐气泡');
      _showSnackBar('请先获取当前位置');
      return;
    }

    debugPrint('创建推荐气泡组件...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecommendationBubble(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        onClose: () {
          debugPrint('关闭推荐气泡');
          Navigator.pop(context);
        },
      ),
    );
    debugPrint('推荐气泡已显示');
  }

  // 获取周围 POI 列表
  Future<void> _loadNearbyPois() async {
    if (_currentLocation == null || _mapController == null) {
      debugPrint('当前位置或地图控制器为空，无法加载 POI');
      return;
    }

    // 如果已有预加载数据，直接使用
    if (_hasPreloadedData && _nearbyPois.isNotEmpty) {
      debugPrint('使用预加载的POI数据，共 ${_nearbyPois.length} 个');
      _addPoiMarkers();
      return;
    }

    setState(() {
      _isLoadingPois = true;
    });

    try {
      debugPrint('=== 开始加载周围 POI ===');
      debugPrint('当前位置: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');

      final List<Place> allPois = [];

      final locationStr = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
      final radius = 15000;

      final hasSpecifiedKeywords = BaiduMapConfig.specifiedPoiKeywords.isNotEmpty;
      final hasSpecifiedUids = BaiduMapConfig.specifiedPoiUids.isNotEmpty;

      if (hasSpecifiedKeywords) {
        debugPrint('启用指定关键词检索: ${BaiduMapConfig.specifiedPoiKeywords}');
        
        // 第一步：通过 geocode 获取白名单关键词的精确坐标
        final Map<String, Location> keywordLocations = {};
        for (final keyword in BaiduMapConfig.specifiedPoiKeywords) {
          try {
            debugPrint('正在地理编码: "$keyword"');
            final geocodeResp = await _apiService.geocode(address: keyword);
            debugPrint('"$keyword" 地理编码响应: status=${geocodeResp.status}');
            if (geocodeResp.status == 0) {
              keywordLocations[keyword] = geocodeResp.result.location;
              debugPrint('关键词 "$keyword" 坐标: (${geocodeResp.result.location.lat}, ${geocodeResp.result.location.lng})');
            } else {
              debugPrint('关键词 "$keyword" 地理编码失败: status=${geocodeResp.status}');
              // 尝试添加城市信息重新编码
              try {
                final retryResp = await _apiService.geocode(address: '北京$keyword');
                if (retryResp.status == 0) {
                  keywordLocations[keyword] = retryResp.result.location;
                  debugPrint('关键词 "$keyword" 重试成功，坐标: (${retryResp.result.location.lat}, ${retryResp.result.location.lng})');
                } else {
                  debugPrint('关键词 "$keyword" 重试也失败: status=${retryResp.status}');
                }
              } catch (retryE) {
                debugPrint('关键词 "$keyword" 重试异常: $retryE');
              }
            }
          } catch (e) {
            debugPrint('关键词 "$keyword" 地理编码异常: $e');
          }
          // 控制请求节奏
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // 第二步：基于获取到的坐标，使用 searchPlaces 获取具体POI信息
        for (final entry in keywordLocations.entries) {
          final keyword = entry.key;
          final location = entry.value;
          try {
            debugPrint('基于坐标检索 "$keyword" 在 (${location.lat}, ${location.lng})');
            final resp = await _apiService.searchPlaces(
              q: keyword,
              location: '${location.lat},${location.lng}',
              radius: 5000, // 增大搜索半径，环球影城面积大
              limit: 10, // 增加数量，提高找到的概率
            );
            debugPrint('"$keyword" 搜索结果: ${resp.results.length} 条');
            for (final result in resp.results) {
              debugPrint('  - ${result.name} (${result.location.lat}, ${result.location.lng})');
            }
            allPois.addAll(resp.results);
            
            // 如果没找到结果，尝试更宽泛的搜索
            if (resp.results.isEmpty && keyword == '环球影城') {
              debugPrint('"$keyword" 未找到，尝试更宽泛搜索...');
              final broadResp = await _apiService.searchPlaces(
                q: '环球影城',
                location: '${location.lat},${location.lng}',
                radius: 10000, // 更大的搜索半径
                limit: 20,
              );
              debugPrint('"$keyword" 宽泛搜索结果: ${broadResp.results.length} 条');
              for (final result in broadResp.results) {
                debugPrint('  - ${result.name} (${result.location.lat}, ${result.location.lng})');
              }
              allPois.addAll(broadResp.results);
            }
          } catch (e) {
            debugPrint('基于坐标检索 "$keyword" 失败: $e');
          }
          // 控制请求节奏
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        // 保持原逻辑：景点、公园、博物馆、历史建筑
        try {
          final attractionResponse = await _apiService.searchPlaces(
            q: '景点',
            location: locationStr,
            radius: radius,
            limit: 20,
          );
          allPois.addAll(attractionResponse.results);
          debugPrint('获取到 ${attractionResponse.results.length} 个景点 POI');
        } catch (e) {
          debugPrint('获取景点 POI 失败: $e');
        }

        await Future.delayed(const Duration(milliseconds: 800));

        try {
          final parkResponse = await _apiService.searchPlaces(
            q: '公园',
            location: locationStr,
            radius: radius,
            limit: 15,
          );
          allPois.addAll(parkResponse.results);
          debugPrint('获取到 ${parkResponse.results.length} 个公园 POI');
        } catch (e) {
          debugPrint('获取公园 POI 失败: $e');
        }

        await Future.delayed(const Duration(milliseconds: 800));

        try {
          final museumResponse = await _apiService.searchPlaces(
            q: '博物馆',
            location: locationStr,
            radius: radius,
            limit: 10,
          );
          allPois.addAll(museumResponse.results);
          debugPrint('获取到 ${museumResponse.results.length} 个博物馆 POI');
        } catch (e) {
          debugPrint('获取博物馆 POI 失败: $e');
        }

        await Future.delayed(const Duration(milliseconds: 800));

        try {
          final historicResponse = await _apiService.searchPlaces(
            q: '历史建筑',
            location: locationStr,
            radius: radius,
            limit: 10,
          );
          allPois.addAll(historicResponse.results);
          debugPrint('获取到 ${historicResponse.results.length} 个历史建筑 POI');
        } catch (e) {
          debugPrint('获取历史建筑 POI 失败: $e');
        }
      }
      
      // 去重（基于 uid）+ 可选 UID 白名单过滤 + 关键词/别名过滤 + 地理距离容错（3km）
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
            // 由于此处 keywordLocations 在本作用域外，简化用当前地图中心位置做近邻判断兜底
            final dKm = _haversineKm(_currentLocation!.latitude, _currentLocation!.longitude, poi.location.lat, poi.location.lng);
            match = dKm <= 3.0;
          }
          if (!match) continue;
        }

        if (!uniquePois.containsKey(poi.uid)) {
          uniquePois[poi.uid] = poi;
        }
      }
      
      // 严格精确匹配：按关键词挑选1个最匹配的结果，仅保留白名单数量
      List<Place> finalPois = uniquePois.values.toList();
      if (hasSpecifiedKeywords) {
        final List<Place> selected = [];
        for (final k in BaiduMapConfig.specifiedPoiKeywords) {
          // 精确名称列表
          final exactList = BaiduMapConfig.specifiedPoiExactNames[k] ?? const [];
          final candidates = finalPois.where((p) {
            if (exactList.isNotEmpty) {
              return exactList.contains(p.name);
            }
            return p.name.contains(k);
          }).toList();
          if (candidates.isEmpty) continue;
          // 选取距离当前关键词 geocode 位置最近的一个（此处退化为距离地图中心最近）
          candidates.sort((a, b) {
            final da = _haversineKm(_currentLocation!.latitude, _currentLocation!.longitude, a.location.lat, a.location.lng);
            final db = _haversineKm(_currentLocation!.latitude, _currentLocation!.longitude, b.location.lat, b.location.lng);
            return da.compareTo(db);
          });
          selected.add(candidates.first);
        }
        finalPois = selected;
      }

      setState(() {
        _nearbyPois = finalPois;
        _isLoadingPois = false;
      });
      
      debugPrint('获取到 ${_nearbyPois.length} 个景点 POI');
      debugPrint('POI 详情: ${_nearbyPois.map((p) => '${p.name} (${p.location.lat}, ${p.location.lng})').toList()}');
      
      // 在地图上添加标记
      _addPoiMarkers();
      
    } catch (e) {
      debugPrint('获取周围 POI 失败: $e');
      setState(() {
        _isLoadingPois = false;
      });
      _showSnackBar('获取周围地点失败: $e');
    }
  }

  // 在地图上添加 POI 标记
  void _addPoiMarkers() {
    if (_mapController == null) {
      debugPrint('地图控制器为空，无法添加 POI 标记');
      return;
    }

    if (_nearbyPois.isEmpty) {
      debugPrint('POI 列表为空，无法添加标记');
      return;
    }

    debugPrint('开始添加 POI 标记，共 ${_nearbyPois.length} 个 POI');

    // 清除现有标记
    _clearPoiMarkers();

    _poiMarkers.clear();
    
    for (int i = 0; i < _nearbyPois.length; i++) {
      final poi = _nearbyPois[i];
      final iconType = _getPoiIcon(poi);
      
      debugPrint('添加标记 $i: ${poi.name} 位置: (${poi.location.lat}, ${poi.location.lng}) 类型: $iconType');
      
      // 使用 BMFMarker 的默认构造函数，使用系统默认图标
      final marker = BMFMarker(
        position: BMFCoordinate(
          poi.location.lat,
          poi.location.lng,
        ),
        title: poi.name,
        subtitle: poi.address,
        identifier: poi.uid.isNotEmpty ? poi.uid : 'poi_$i', // 添加唯一标识符
      );
      
      _poiMarkers.add(marker);
      _mapController!.addMarker(marker);
      
      debugPrint('标记 $i 已添加到地图');
    }
    
    debugPrint('已添加 ${_poiMarkers.length} 个 POI 标记到地图');
  }

  // 根据 POI 类型获取图标
  String _getPoiIcon(Place poi) {
    // 使用 Flutter 自带的图标，通过图标名称返回
    final category = poi.detailInfo.classifiedPoiTag.toLowerCase();
    final name = poi.name.toLowerCase();
    
    if (category.contains('餐饮') || name.contains('餐厅') || name.contains('美食') || name.contains('饭店')) {
      return 'restaurant'; // 美食图标
    } else if (category.contains('旅游') || name.contains('景点') || name.contains('公园') || name.contains('博物馆')) {
      return 'attractions'; // 景点图标
    } else if (category.contains('娱乐') || name.contains('KTV') || name.contains('电影院') || name.contains('游戏')) {
      return 'sports_esports'; // 娱乐图标
    } else if (category.contains('购物') || name.contains('商场') || name.contains('超市') || name.contains('商店')) {
      return 'shopping_cart'; // 购物图标
    } else {
      return 'location_on'; // 默认位置图标
    }
  }

  // 根据 POI 类型获取图标数据
  IconData _getPoiIconData(Place poi) {
    final category = poi.detailInfo.classifiedPoiTag.toLowerCase();
    final name = poi.name.toLowerCase();
    
    if (category.contains('餐饮') || name.contains('餐厅') || name.contains('美食') || name.contains('饭店')) {
      return Icons.restaurant;
    } else if (category.contains('旅游') || name.contains('景点') || name.contains('公园') || name.contains('博物馆')) {
      return Icons.attractions;
    } else if (category.contains('娱乐') || name.contains('KTV') || name.contains('电影院') || name.contains('游戏')) {
      return Icons.sports_esports;
    } else if (category.contains('购物') || name.contains('商场') || name.contains('超市') || name.contains('商店')) {
      return Icons.shopping_cart;
    } else {
      return Icons.location_on;
    }
  }

  // 根据 POI 类型获取图标颜色
  Color _getPoiIconColor(Place poi) {
    final category = poi.detailInfo.classifiedPoiTag.toLowerCase();
    final name = poi.name.toLowerCase();
    
    if (category.contains('餐饮') || name.contains('餐厅') || name.contains('美食') || name.contains('饭店')) {
      return Colors.red;
    } else if (category.contains('旅游') || name.contains('景点') || name.contains('公园') || name.contains('博物馆')) {
      return Colors.green;
    } else if (category.contains('娱乐') || name.contains('KTV') || name.contains('电影院') || name.contains('游戏')) {
      return Colors.purple;
    } else if (category.contains('购物') || name.contains('商场') || name.contains('超市') || name.contains('商店')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
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

  // 开始预加载POI数据
  Future<void> _startPreloading() async {
    if (_isPreloading || _hasPreloadedData) return;
    
    setState(() {
      _isPreloading = true;
    });
    
    try {
      debugPrint('=== 开始预加载POI数据 ===');
      
      // 使用默认位置进行预加载
      final defaultLat = BaiduMapConfig.defaultLatitude;
      final defaultLng = BaiduMapConfig.defaultLongitude;
      
      final preloadedPois = await _apiService.preloadPoiData(
        lat: defaultLat,
        lng: defaultLng,
      );
      
      setState(() {
        _nearbyPois = preloadedPois;
        _hasPreloadedData = true;
        _isPreloading = false;
      });
      
      debugPrint('预加载完成，获取到 ${preloadedPois.length} 个POI');
      
      // 如果地图已经准备好，立即显示POI标记
      if (_mapController != null) {
        _addPoiMarkers();
      }
      
    } catch (e) {
      debugPrint('预加载POI数据失败: $e');
      setState(() {
        _isPreloading = false;
      });
    }
  }

  // 清除 POI 标记
  void _clearPoiMarkers() {
    if (_mapController == null) return;
    
    for (final marker in _poiMarkers) {
      _mapController!.removeMarker(marker);
    }
    _poiMarkers.clear();
  }

  // 更新地图到当前位置
  void _updateMapToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.updateMapOptions(
        BMFMapOptions(
          center: _currentLocation!,
          zoomLevel: 12, // 降低缩放级别，从15改为12，确保能看到更多POI
        ),
      );
    }
  }

  // 搜索附近地点
  Future<void> _searchNearbyPlaces(String keyword) async {
    if (_currentLocation == null) {
      _showSnackBar('正在获取位置信息，请稍后再试');
      return;
    }

    try {
      setState(() {
        _isLoadingPois = true;
      });

      debugPrint('搜索附近 $keyword: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      
      // 使用当前位置搜索附近的地点
      final places = await _apiService.searchPlaces(
        q: keyword,
        location: '${_currentLocation!.latitude},${_currentLocation!.longitude}',
        radius: 3000, // 3公里范围内搜索
        limit: 20,
      );

      if (places.results.isEmpty) {
        _showSnackBar('附近暂无$keyword');
        return;
      }

      // 清空现有标记
      _clearPoiMarkers();
      
      // 更新POI列表
      setState(() {
        _nearbyPois = places.results;
        _isLoadingPois = false;
      });

      // 在地图上添加标记
      _addPoiMarkers();

      _showSnackBar('找到 ${places.results.length} 个附近$keyword');
      
    } catch (e) {
      debugPrint('搜索附近$keyword失败: $e');
      _showSnackBar('搜索失败，请重试');
      setState(() {
        _isLoadingPois = false;
      });
    }
  }

  // 搜索地点
  Future<void> _searchPlaces(String keyword) async {
    if (keyword.trim().isEmpty) {
      _showSnackBar('请输入搜索关键词');
      return;
    }

    try {
      debugPrint('=== 开始搜索流程 ===');
      debugPrint('搜索关键词: $keyword');
      
      // 第一步：根据关键词获取经纬度
      debugPrint('第一步：地理编码获取经纬度');
      final location = await _apiService.getLocationByAddress(keyword);
      
      if (location == null) {
        debugPrint('地理编码失败，尝试直接搜索');
        // 如果地理编码失败，尝试直接搜索
        await _searchPlacesDirectly(keyword);
        return;
      }
      
      debugPrint('获取到经纬度: ${location.lat}, ${location.lng}');
      
      // 第二步：根据经纬度获取地点详情
      debugPrint('第二步：根据经纬度获取地点详情');
      final places = await _getPlacesByLocation(location, keyword);
      
      if (places.isEmpty) {
        debugPrint('根据经纬度未找到地点，尝试直接搜索');
        // 如果根据经纬度未找到地点，尝试直接搜索
        await _searchPlacesDirectly(keyword);
        return;
      }
      
      debugPrint('找到 ${places.length} 个地点');
      
      // 导航到搜索结果页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultPage(
            keyword: keyword,
            places: places,
            centerLocation: location,
          ),
        ),
      );
      
      debugPrint('=== 搜索流程完成 ===');
    } catch (e) {
      debugPrint('搜索失败: $e');
      _showSnackBar('搜索失败: 请检查网络连接或稍后重试');
      
      // 显示模拟数据用于测试
      _showMockSearchResults(keyword);
    }
  }

  // 根据经纬度获取地点详情
  Future<List<Place>> _getPlacesByLocation(Location location, String keyword) async {
    try {
      debugPrint('根据经纬度搜索地点: ${location.lat}, ${location.lng}');
      
      // 使用经纬度作为中心点搜索附近的地点
      final places = await _apiService.searchPlaces(
        q: keyword,
        location: '${location.lat},${location.lng}',
        radius: 5000, // 5公里范围内搜索
        limit: 20,
      );
      
      debugPrint('根据经纬度搜索到 ${places.results.length} 个地点');
      return places.results;
    } catch (e) {
      debugPrint('根据经纬度搜索失败: $e');
      return [];
    }
  }

  // 直接搜索地点（备用方案）
  Future<void> _searchPlacesDirectly(String keyword) async {
    try {
      debugPrint('直接搜索地点: $keyword');
      
      String? city;
      if (_currentLocation != null) {
        // 尝试根据当前位置获取城市信息
        try {
          final address = await _apiService.getAddressByLocation(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          );
          if (address != null && address.contains('市')) {
            // 提取城市名称
            final cityMatch = RegExp(r'([^省]+市)').firstMatch(address);
            if (cityMatch != null) {
              city = cityMatch.group(1);
              debugPrint('提取到城市: $city');
            }
          }
        } catch (e) {
          debugPrint('获取城市信息失败: $e');
        }
      }
      
      final places = await _apiService.searchPlaces(
        q: keyword,
        city: city,
        limit: 20,
      );
      
      debugPrint('直接搜索到 ${places.results.length} 个地点');
      
      // 导航到搜索结果页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultPage(
            keyword: keyword,
            places: places.results,
            centerLocation: _currentLocation != null 
                ? Location(lat: _currentLocation!.latitude, lng: _currentLocation!.longitude)
                : null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('直接搜索失败: $e');
      _showSnackBar('搜索失败: 请检查网络连接或稍后重试');
      
      // 显示模拟数据用于测试
      _showMockSearchResults(keyword);
    }
  }

  // 获取天气信息
  Future<void> _getWeatherInfo() async {
    if (_currentLocation == null) {
      _showSnackBar('请先获取当前位置');
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      debugPrint('开始获取天气信息');
      debugPrint('当前位置: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      
      final weatherResponse = await _apiService.getWeatherByLocation(
        location: Location(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
        ),
      );
      
      setState(() {
        _isLoadingWeather = false;
      });
      
          debugPrint('天气数据获取成功: ${weatherResponse.result.now.text}');
    debugPrint('天气数据获取成功 - 温度: ${weatherResponse.result.now.temp}°C');
    debugPrint('天气数据获取成功 - 位置: ${weatherResponse.result.location.city}');
      
      // 导航到天气详情页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherDetailScreen(
            weatherData: weatherResponse,
            location: Location(
              lat: _currentLocation!.latitude,
              lng: _currentLocation!.longitude,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('获取天气信息失败: $e');
      setState(() {
        _isLoadingWeather = false;
      });
      _showSnackBar('获取天气信息失败: 请检查网络连接或稍后重试');
    }
  }

  // 显示模拟搜索结果（用于测试）
  void _showMockSearchResults(String keyword) {
    final mockPlaces = [
      Place(
        name: '示例${keyword}店1',
        location: Location(lat: 39.9042, lng: 116.4074),
        address: '北京市东城区示例地址1',
        province: '北京市',
        city: '北京市',
        area: '东城区',
        town: '示例街道',
        townCode: 110101,
        streetId: 'mock_street_1',
        detail: 1,
        uid: 'mock_uid_1',
        detailInfo: PlaceDetailInfo(
          classifiedPoiTag: '示例分类',
          distance: 100,
          tag: '示例标签',
          type: '示例类型',
          detailUrl: 'https://example.com',
          price: '50.0',
          overallRating: '4.5',
          commentNum: '100',
          shopHours: '09:00-22:00',
          label: '示例标签',
          children: [],
        ),
      ),
      Place(
        name: '示例${keyword}店2',
        location: Location(lat: 39.9043, lng: 116.4075),
        address: '北京市东城区示例地址2',
        province: '北京市',
        city: '北京市',
        area: '东城区',
        town: '示例街道',
        townCode: 110101,
        streetId: 'mock_street_2',
        detail: 1,
        uid: 'mock_uid_2',
        detailInfo: PlaceDetailInfo(
          classifiedPoiTag: '示例分类',
          distance: 200,
          tag: '示例标签',
          type: '示例类型',
          detailUrl: 'https://example.com',
          price: '80.0',
          overallRating: '4.2',
          commentNum: '80',
          shopHours: '10:00-21:00',
          label: '示例标签',
          children: [],
        ),
      ),
    ];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultPage(
          keyword: keyword,
          places: mockPlaces,
        ),
      ),
    );
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required bool isLoading,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '魔拍地图',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
        actions: [
          _buildActionButton(
            onPressed: _getWeatherInfo,
            icon: Icons.wb_sunny_outlined,
            isLoading: _isLoadingWeather,
            tooltip: '天气预报',
          ),
          _buildActionButton(
            onPressed: _loadNearbyPois,
            icon: Icons.location_on_outlined,
            isLoading: _isLoadingPois,
            tooltip: '显示周围地点',
          ),
          _buildActionButton(
            onPressed: _startLocation,
            icon: Icons.my_location_outlined,
            isLoading: _isLocating,
            tooltip: '定位',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // 搜索框
            _buildSearchBar(),
            
            // 地图区域
            Expanded(
              child: _buildMapView(),
            ),
            
            // 推荐项目
            _buildRecommendItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16), // 增加顶部padding为AppBar留空间
      child: Column(
        children: [
          // 搜索输入框
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索地点、地址或关键词...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.all(8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchPlaces(value.trim());
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_searchController.text.trim().isNotEmpty) {
                        _searchPlaces(_searchController.text.trim());
                      }
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '搜索',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 搜索建议
          if (_searchController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '搜索建议',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildSuggestionChip('${_searchController.text}附近'),
                      _buildSuggestionChip('${_searchController.text}美食'),
                      _buildSuggestionChip('${_searchController.text}景点'),
                      _buildSuggestionChip('${_searchController.text}酒店'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = suggestion;
          _searchPlaces(suggestion);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 14,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Text(
                suggestion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (!_isMapReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在初始化百度地图...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        BMFMapWidget(
          onBMFMapCreated: (BMFMapController controller) {
            _mapController = controller;
            debugPrint('百度地图创建成功');
            _setupMapCallbacks();
            
            // 如果已有预加载数据，立即显示POI标记
            if (_hasPreloadedData && _nearbyPois.isNotEmpty) {
              debugPrint('地图创建完成，显示预加载的POI标记');
              _addPoiMarkers();
            }
          },
          mapOptions: _getMapOptions(),
        ),
        
        // POI 气泡显示
        if (_selectedPoi != null && _bubblePosition != null)
          Positioned(
            left: _bubblePosition!.dx.clamp(10.0, MediaQuery.of(context).size.width - 210),
            top: _bubblePosition!.dy.clamp(10.0, MediaQuery.of(context).size.height - 100),
            child: GestureDetector(
              onTap: () {
                // 点击气泡可以关闭
                setState(() {
                  _selectedPoi = null;
                  _bubblePosition = null;
                });
              },
              child: _buildPoiBubble(_selectedPoi!),
            ),
          ),
        // 定位状态指示器
        if (_isLocating)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '定位中...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        
        // POI 加载状态指示器
        if (_isLoadingPois || _isPreloading)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPreloading ? '加载地点数据...' : '加载周围地点...',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        
        // POI 统计信息和列表
        if (_nearbyPois.isNotEmpty && !_isLoadingPois)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 统计信息行
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '周围发现 ${_nearbyPois.length} 个地点',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _clearPoiMarkers,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.clear_rounded,
                                    size: 14,
                                    color: Colors.red[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '清除',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // POI 列表
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyPois.length,
                      itemBuilder: (context, index) {
                        final poi = _nearbyPois[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // 显示POI气泡
                              _showPoiBubbleFromList(poi);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12, bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey[50]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _getPoiIconColor(poi).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getPoiIconData(poi),
                                          size: 16,
                                          color: _getPoiIconColor(poi),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          poi.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    poi.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      if (poi.detailInfo.overallRating != '0') ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                poi.detailInfo.overallRating,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.amber[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.directions_walk_rounded, size: 12, color: Colors.blue),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${poi.detailInfo.distance}m',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendItems() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _recommendItems.map((item) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _searchNearbyPlaces(item['keyword']),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        item['icon'],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _setupMapCallbacks() {
    if (_mapController == null) return;

    // 地图渲染每一帧画面过程中，以及每次需要重绘地图时都会调用此接口
    _mapController!.setMapOnDrawMapFrameCallback(
        callback: (BMFMapStatus mapStatus) {
      // debugPrint('地图渲染每一帧: ${mapStatus.toMap()}');
    });

    // 地图区域即将改变时会调用此接口
    _mapController!.setMapRegionWillChangeCallback(
        callback: (BMFMapStatus mapStatus) {
      debugPrint('地图区域即将改变: ${mapStatus.toMap()}');
    });

    // 地图区域改变完成后会调用此接口
    _mapController!.setMapRegionDidChangeCallback(
        callback: (BMFMapStatus mapStatus) {
      debugPrint('地图区域改变完成: ${mapStatus.toMap()}');
    });

    // 设置地图点击回调 - 暂时注释，使用备用方案
    // _mapController!.setMapOnTapCallback(
    //     (BMFCoordinate coordinate) {
    //   debugPrint('地图被点击: ${coordinate.latitude}, ${coordinate.longitude}');
    //   _handleMapClick(coordinate);
    // });

    debugPrint('地图回调设置完成');
  }

  
  

  
  
  
  // 显示POI名字气泡
  void _showPoiName(Place poi, Offset screenPosition) {
    setState(() {
      _selectedPoi = poi;
      // 计算气泡位置（在标记位置上方，并考虑气泡大小）
      _bubblePosition = Offset(
        screenPosition.dx - 100, // 气泡宽度的一半，使其居中
        screenPosition.dy - 60,  // 在标记上方60像素
      );
    });
    
    // 8秒后自动隐藏气泡，给用户更多时间查看详情
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _selectedPoi = null;
          _bubblePosition = null;
        });
      }
    });
  }

  // 从POI列表显示气泡
  void _showPoiBubbleFromList(Place poi) {
    if (_mapController == null) return;
    
    // 将POI的地图坐标转换为屏幕坐标
    _mapController!.convertCoordinateToScreenPoint(
      BMFCoordinate(poi.location.lat, poi.location.lng),
    ).then((BMFPoint? screenPoint) {
      if (screenPoint != null) {
        debugPrint('POI列表点击 - 屏幕坐标: $screenPoint');
        _showPoiName(poi, Offset(screenPoint.x, screenPoint.y));
      }
    });
  }

  // 构建POI气泡
  Widget _buildPoiBubble(Place poi) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 点击气泡跳转到详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoiDetailScreen(poi: poi),
            ),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.blue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 气泡内容
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPoiIconData(poi),
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 12,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '点击查看详情',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 小三角形指示器
              Container(
                width: 0,
                height: 0,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.transparent, width: 10),
                    right: BorderSide(color: Colors.transparent, width: 10),
                    top: BorderSide(color: Colors.white, width: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BMFMapOptions _getMapOptions() {
    BMFCoordinate center = _currentLocation ?? 
      BMFCoordinate(
        BaiduMapConfig.defaultLatitude,
        BaiduMapConfig.defaultLongitude,
      );
    
    return BMFMapOptions(
      mapType: _mapType,
      zoomLevel: 12, // 降低缩放级别，从15改为12，确保能看到更多POI
      maxZoomLevel: 21,
      minZoomLevel: 4,
      backgroundColor: Colors.blue,
      logoPosition: BMFLogoPosition.LeftBottom,
      center: center,
      showDEMLayer: true,
    );
  }
}

// 地图搜索结果视图
class MapSearchResultView extends StatefulWidget {
  final String keyword;
  final List<Place> places;
  final Location centerLocation;

  const MapSearchResultView({
    super.key,
    required this.keyword,
    required this.places,
    required this.centerLocation,
  });

  @override
  State<MapSearchResultView> createState() => _MapSearchResultViewState();
}

class _MapSearchResultViewState extends State<MapSearchResultView> {
  BMFMapController? _mapController;
  bool _isMapReady = false;
  List<BMFMarker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initBaiduMap();
  }

  Future<void> _initBaiduMap() async {
    try {
      // 设置用户是否同意SDK隐私协议
      BMFMapSDK.setAgreePrivacy(true);

      // 百度地图sdk初始化鉴权
      if (Platform.isIOS) {
        BMFMapSDK.setApiKeyAndCoordType(
            BaiduMapConfig.ak, BMF_COORD_TYPE.BD09LL);
      } else if (Platform.isAndroid) {
        BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
      }

      setState(() {
        _isMapReady = true;
      });
      
      // 添加标记点
      _addMarkers();
    } catch (e) {
      debugPrint('百度地图初始化失败: $e');
    }
  }

  void _addMarkers() {
    if (_mapController == null) return;

    _markers.clear();
    
    // 添加中心点标记
    final centerMarker = BMFMarker.icon(
      position: BMFCoordinate(
        widget.centerLocation.lat,
        widget.centerLocation.lng,
      ),
      title: '搜索中心',
      icon: 'assets/logo.jpeg',
    );
    _markers.add(centerMarker);

    // 添加搜索结果标记
    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      final marker = BMFMarker.icon(
        position: BMFCoordinate(
          place.location.lat,
          place.location.lng,
        ),
        title: place.name,
        subtitle: place.address,
        icon: 'assets/logo.jpeg',
      );
      _markers.add(marker);
    }

    // 添加标记到地图
    for (final marker in _markers) {
      _mapController!.addMarker(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.keyword} 地图'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isMapReady
          ? Stack(
              children: [
                BMFMapWidget(
                  onBMFMapCreated: (BMFMapController controller) {
                    _mapController = controller;
                    _addMarkers();
                  },
                  mapOptions: BMFMapOptions(
                    center: BMFCoordinate(
                      widget.centerLocation.lat,
                      widget.centerLocation.lng,
                    ),
                    zoomLevel: 14,
                    maxZoomLevel: 21,
                    minZoomLevel: 4,
                  ),
                ),
                // 搜索结果统计
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '找到 ${widget.places.length} 个${widget.keyword}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载地图...'),
                ],
              ),
            ),
    );
  }
}


// 搜索结果页面
class SearchResultPage extends StatelessWidget {
  final String keyword;
  final List<Place> places;
  final Location? centerLocation; // 新增参数，用于传递中心位置

  const SearchResultPage({
    super.key,
    required this.keyword,
    required this.places,
    this.centerLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$keyword 搜索结果'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (centerLocation != null)
            IconButton(
              onPressed: () => _showMapView(context),
              icon: const Icon(Icons.map),
              tooltip: '在地图上查看',
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索统计信息
          if (centerLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '搜索中心: ${centerLocation!.lat.toStringAsFixed(4)}, ${centerLocation!.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // 搜索结果列表
          Expanded(
            child: places.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无搜索结果', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(Icons.location_on, color: Colors.blue[700]),
                          ),
                          title: Text(
                            place.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                place.address,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (place.detailInfo.overallRating != '0')
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        Text(' ${place.detailInfo.overallRating}'),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                  const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                                  Text(' ${place.detailInfo.distance}m'),
                                  if (place.detailInfo.price.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                    Text(' ¥${place.detailInfo.price}'),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showPlaceDetails(context, place);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 在地图上查看搜索结果
  void _showMapView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSearchResultView(
          keyword: keyword,
          places: places,
          centerLocation: centerLocation!,
        ),
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题和评分
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (place.detailInfo.overallRating != '0')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  place.detailInfo.overallRating,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 地址信息
                    _buildInfoRow(Icons.location_on, '地址', place.address, Colors.red),
                    
                    // 距离信息
                    _buildInfoRow(Icons.directions_walk, '距离', '${place.detailInfo.distance}m', Colors.blue),
                    
                    // 分类信息
                    if (place.detailInfo.classifiedPoiTag.isNotEmpty)
                      _buildInfoRow(Icons.category, '分类', place.detailInfo.classifiedPoiTag, Colors.green),
                    
                    // 价格信息
                    if (place.detailInfo.price.isNotEmpty)
                      _buildInfoRow(Icons.attach_money, '人均', '¥${place.detailInfo.price}', Colors.orange),
                    
                    // 营业时间
                    if (place.detailInfo.shopHours.isNotEmpty)
                      _buildInfoRow(Icons.access_time, '营业时间', place.detailInfo.shopHours, Colors.purple),
                    
                    // 评论数量
                    if (place.detailInfo.commentNum != '0')
                      _buildInfoRow(Icons.comment, '评论', '${place.detailInfo.commentNum}条', Colors.teal),
                    
                    // 标签信息
                    if (place.detailInfo.tag.isNotEmpty)
                      _buildInfoRow(Icons.label, '标签', place.detailInfo.tag, Colors.indigo),
                    
                    const SizedBox(height: 24),
                    
                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openNavigation(context, place);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.directions),
                            label: const Text('导航'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _sharePlace(context, place);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text('分享'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 查看详情按钮
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _viewPlaceDetails(context, place);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('查看详细信息'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openNavigation(BuildContext context, Place place) async {
    try {
      // 检查可用的地图应用
      final availableMaps = <MapType>[];
      
      // 检查各种地图应用是否可用
      if (await MapLauncher.isMapAvailable(MapType.google) == true) {
        availableMaps.add(MapType.google);
      }
      if (await MapLauncher.isMapAvailable(MapType.apple) == true) {
        availableMaps.add(MapType.apple);
      }
      if (await MapLauncher.isMapAvailable(MapType.amap) == true) {
        availableMaps.add(MapType.amap);
      }
      if (await MapLauncher.isMapAvailable(MapType.baidu) == true) {
        availableMaps.add(MapType.baidu);
      }
      if (await MapLauncher.isMapAvailable(MapType.tencent) == true) {
        availableMaps.add(MapType.tencent);
      }
      
      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到可用的地图应用')),
        );
        return;
      }

      // 显示地图选择弹窗
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择导航应用',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...availableMaps.map((mapType) {
                  return ListTile(
                    leading: Icon(_getMapIcon(mapType)),
                    title: Text(_getMapName(mapType)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _launchMap(mapType, place);
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动导航失败: $e')),
      );
    }
  }

  Future<void> _launchMap(MapType mapType, Place place) async {
    try {
      await MapLauncher.showDirections(
        mapType: mapType,
        destination: Coords(place.location.lat, place.location.lng),
        destinationTitle: place.name,
      );
    } catch (e) {
      // 如果导航失败，尝试显示标记
      try {
        await MapLauncher.showMarker(
          mapType: mapType,
          coords: Coords(place.location.lat, place.location.lng),
          title: place.name,
          description: place.address,
        );
      } catch (e2) {
        throw Exception('无法启动地图应用: $e2');
      }
    }
  }

  IconData _getMapIcon(MapType mapType) {
    switch (mapType) {
      case MapType.google:
        return Icons.map;
      case MapType.apple:
        return Icons.apple;
      case MapType.amap:
        return Icons.navigation;
      case MapType.baidu:
        return Icons.location_on;
      case MapType.tencent:
        return Icons.place;
      default:
        return Icons.map;
    }
  }

  String _getMapName(MapType mapType) {
    switch (mapType) {
      case MapType.google:
        return 'Google 地图';
      case MapType.apple:
        return '苹果地图';
      case MapType.amap:
        return '高德地图';
      case MapType.baidu:
        return '百度地图';
      case MapType.tencent:
        return '腾讯地图';
      default:
        return '地图应用';
    }
  }

  void _sharePlace(BuildContext context, Place place) {
    // 这里可以集成分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }

  void _viewPlaceDetails(BuildContext context, Place place) {
    // 这里可以跳转到详细页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('详细信息页面开发中...')),
    );
  }
}

// 地图搜索结果视图
