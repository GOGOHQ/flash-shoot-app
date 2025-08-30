# Photo Backend API 库使用说明

## 概述

这个 API 库封装了 Photo Backend 提供的所有 API 接口，包括小红书 MCP 服务和百度地图 MCP 服务。

## 文件结构

```
lib/
├── models/
│   └── api_models.dart          # API 响应数据模型
├── services/
│   └── api_service.dart         # API 服务类
└── config/
    └── api_config.dart          # API 配置
```

## 快速使用

### 1. 获取 API 服务实例

```dart
import 'package:your_app/services/api_service.dart';
import 'package:your_app/models/api_models.dart';

final apiService = ApiService();
```

### 2. 小红书 API

```dart
// 获取热门帖子
final xhsResponse = await apiService.getXhsHot(limit: 10);
print('热门帖子数量: ${xhsResponse.data.length}');

// 搜索帖子链接
final searchResponse = await apiService.searchXhsPosts(q: '美食', limit: 5);
print('搜索到 ${searchResponse.links.length} 个链接');
```

### 3. 百度地图 API

```dart
// 地理编码（地址转坐标）
final geocodeResponse = await apiService.geocode(address: '北京市朝阳区');
if (geocodeResponse.status == 0) {
  final location = geocodeResponse.result.location;
  print('坐标: ${location.lat}, ${location.lng}');
}

// 逆地理编码（坐标转地址）
final reverseResponse = await apiService.reverseGeocode(
  lat: 39.9042, 
  lng: 116.4074,
);
if (reverseResponse.status == 0) {
  print('地址: ${reverseResponse.result.formattedAddress}');
}

// 搜索地点
final placesResponse = await apiService.searchPlaces(
  q: '美食',
  city: '北京',
  location: '39.9042,116.4074',
  radius: 2000,
  limit: 10,
);
print('找到 ${placesResponse.results.length} 个地点');

// 天气查询
final weatherResponse = await apiService.getWeather(
  location: '116.391275,39.906217',
);
print('天气数据: ${weatherResponse.data}');
```

### 4. 便捷方法

```dart
// 根据地址获取坐标
final location = await apiService.getLocationByAddress('北京市朝阳区');

// 根据坐标获取地址
final address = await apiService.getAddressByLocation(39.9042, 116.4074);

// 搜索附近美食
final foodPlaces = await apiService.searchNearbyFood(
  lat: 39.9042,
  lng: 116.4074,
  radius: 2000,
  limit: 5,
);

// 搜索附近景点
final attractions = await apiService.searchNearbyAttractions(
  lat: 39.9042,
  lng: 116.4074,
  radius: 5000,
  limit: 10,
);
```

## 错误处理

```dart
try {
  final response = await apiService.getXhsHot(limit: 5);
  // 处理成功响应
} catch (e) {
  // 处理错误
  print('API 调用失败: $e');
}
```

## 配置

在 `lib/config/api_config.dart` 中可以修改基础 URL：

```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.22:8080';
}
```

## 注意事项

1. 确保应用有网络访问权限
2. 始终使用 try-catch 处理 API 调用
3. 在应用退出时调用 `apiService.dispose()` 释放资源
