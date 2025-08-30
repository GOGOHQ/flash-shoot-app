import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/baidu_map_config.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

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
  
  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
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
      
      // 获取定位权限并开始定位
      await _requestLocationPermission();
      await _startLocation();
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

  // 开始定位
  Future<void> _startLocation() async {
    if (_locationPlugin == null) return;
    
    setState(() {
      _isLocating = true;
    });

    try {
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
    } catch (e) {
      debugPrint('开始定位失败: $e');
      setState(() {
        _isLocating = false;
      });
    }
  }

  // 更新地图到当前位置
  void _updateMapToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.updateMapOptions(
        BMFMapOptions(
          center: _currentLocation!,
          zoomLevel: 15,
        ),
      );
    }
  }

  // 搜索地点
  Future<void> _searchPlaces(String keyword) async {
    if (_currentLocation == null) {
      _showSnackBar('请先获取当前位置');
      return;
    }

    try {
      debugPrint('开始搜索: $keyword');
      debugPrint('当前位置: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      
      final places = await _apiService.searchPlaces(
        q: keyword,
        location: '${_currentLocation!.latitude},${_currentLocation!.longitude}',
        radius: 2000,
        limit: 20,
      );
      
      debugPrint('搜索成功，找到 ${places.results.length} 个结果');
      
      // 导航到搜索结果页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultPage(
            keyword: keyword,
            places: places.results,
          ),
        ),
      );
    } catch (e) {
      debugPrint('搜索失败: $e');
      _showSnackBar('搜索失败: 请检查网络连接或稍后重试');
      
      // 显示模拟数据用于测试
      _showMockSearchResults(keyword);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _startLocation,
            icon: _isLocating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
            tooltip: '定位',
          ),
        ],
      ),
      body: Column(
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索地点...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchPlaces(value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _searchPlaces(_searchController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('搜索'),
          ),
        ],
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
          },
          mapOptions: _getMapOptions(),
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
      ],
    );
  }

  Widget _buildRecommendItems() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendItems.length,
        itemBuilder: (context, index) {
          final item = _recommendItems[index];
          return GestureDetector(
            onTap: () => _searchPlaces(item['keyword']),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'],
                    size: 32,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  }

  BMFMapOptions _getMapOptions() {
    BMFCoordinate center = _currentLocation ?? 
      BMFCoordinate(
        BaiduMapConfig.defaultLatitude,
        BaiduMapConfig.defaultLongitude,
      );
    
    return BMFMapOptions(
      mapType: _mapType,
      zoomLevel: 15,
      maxZoomLevel: 21,
      minZoomLevel: 4,
      backgroundColor: Colors.blue,
      logoPosition: BMFLogoPosition.LeftBottom,
      center: center,
      showDEMLayer: true,
    );
  }
}

// 搜索结果页面
class SearchResultPage extends StatelessWidget {
  final String keyword;
  final List<Place> places;

  const SearchResultPage({
    super.key,
    required this.keyword,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$keyword 搜索结果'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: places.isEmpty
          ? const Center(
              child: Text('暂无搜索结果'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(place.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.address),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(' ${place.detailInfo.overallRating}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                            Text(' ${place.detailInfo.distance}m'),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showPlaceDetails(context, place);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('地址: ${place.address}'),
            Text('评分: ${place.detailInfo.overallRating}'),
            Text('距离: ${place.detailInfo.distance}m'),
            if (place.detailInfo.price.isNotEmpty)
              Text('人均: ¥${place.detailInfo.price}'),
            if (place.detailInfo.shopHours.isNotEmpty)
              Text('营业时间: ${place.detailInfo.shopHours}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // 这里可以添加导航功能
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('导航'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // 这里可以添加分享功能
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('分享'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
