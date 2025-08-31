import 'package:flutter/foundation.dart';

// API 响应的基础模型
class ApiResponse<T> {
  final T? data;
  final String? message;
  final int? status;

  ApiResponse({
    this.data,
    this.message,
    this.status,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiResponse<T>(
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'],
      status: json['status'],
    );
  }
}

// 小红书相关模型
class XhsPost {
  final String id;
  final String title;
  final String author;
  final int likes;
  final String excerpt;
  final String postUrl;

  XhsPost({
    required this.id,
    required this.title,
    required this.author,
    required this.likes,
    required this.excerpt,
    required this.postUrl,
  });

  factory XhsPost.fromJson(Map<String, dynamic> json) {
    return XhsPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      likes: json['likes'] ?? 0,
      excerpt: json['excerpt'] ?? '',
      postUrl: json['post_url'] ?? '',
    );
  }
}

class XhsHotResponse {
  final List<XhsPost> data;

  XhsHotResponse({required this.data});

  factory XhsHotResponse.fromJson(Map<String, dynamic> json) {
    return XhsHotResponse(
      data: (json['data'] as List?)
          ?.map((item) => XhsPost.fromJson(item))
          .toList() ?? [],
    );
  }
}

class XhsSearchResponse {
  final List<String> links;

  XhsSearchResponse({required this.links});

  factory XhsSearchResponse.fromJson(Map<String, dynamic> json) {
    return XhsSearchResponse(
      links: (json['links'] as List?)?.cast<String>() ?? [],
    );
  }
}

// 百度地图相关模型
class Location {
  final double lng;
  final double lat;

  Location({required this.lng, required this.lat});

  factory Location.fromJson(Map<String, dynamic> json) {
    debugPrint('Location.fromJson 输入: $json');
    
    // 尝试不同的字段名
    final lng = (json['lng'] ?? json['longitude'] ?? json['x']) as num?;
    final lat = (json['lat'] ?? json['latitude'] ?? json['y']) as num?;
    
    final location = Location(
      lng: lng?.toDouble() ?? 0.0,
      lat: lat?.toDouble() ?? 0.0,
    );
    
    debugPrint('Location 解析结果: lng=${location.lng}, lat=${location.lat}');
    return location;
  }

  Map<String, dynamic> toJson() => {
    'lng': lng,
    'lat': lat,
  };
}

class GeocodeResult {
  final Location location;
  final int precise;
  final int confidence;
  final int comprehension;
  final String level;

  GeocodeResult({
    required this.location,
    required this.precise,
    required this.confidence,
    required this.comprehension,
    required this.level,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    return GeocodeResult(
      location: Location.fromJson(json['location'] ?? {}),
      precise: json['precise'] ?? 0,
      confidence: json['confidence'] ?? 0,
      comprehension: json['comprehension'] ?? 0,
      level: json['level'] ?? '',
    );
  }
}

class GeocodeResponse {
  final int status;
  final GeocodeResult result;

  GeocodeResponse({required this.status, required this.result});

  factory GeocodeResponse.fromJson(Map<String, dynamic> json) {
    return GeocodeResponse(
      status: json['status'] ?? 0,
      result: GeocodeResult.fromJson(json['result'] ?? {}),
    );
  }
}

class AddressComponent {
  final String country;
  final String province;
  final String city;
  final String district;
  final String town;
  final String street;
  final String streetNumber;
  final String adcode;

  AddressComponent({
    required this.country,
    required this.province,
    required this.city,
    required this.district,
    required this.town,
    required this.street,
    required this.streetNumber,
    required this.adcode,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      town: json['town'] ?? '',
      street: json['street'] ?? '',
      streetNumber: json['street_number'] ?? '',
      adcode: json['adcode'] ?? '',
    );
  }
}

class ReverseGeocodeResult {
  final Location location;
  final String formattedAddress;
  final AddressComponent addressComponent;
  final String business;

  ReverseGeocodeResult({
    required this.location,
    required this.formattedAddress,
    required this.addressComponent,
    required this.business,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      location: Location.fromJson(json['location'] ?? {}),
      formattedAddress: json['formatted_address'] ?? '',
      addressComponent: AddressComponent.fromJson(json['addressComponent'] ?? {}),
      business: json['business'] ?? '',
    );
  }
}

class ReverseGeocodeResponse {
  final int status;
  final ReverseGeocodeResult result;

  ReverseGeocodeResponse({required this.status, required this.result});

  factory ReverseGeocodeResponse.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResponse(
      status: json['status'] ?? 0,
      result: ReverseGeocodeResult.fromJson(json['result'] ?? {}),
    );
  }
}

class PlaceDetailInfo {
  final String classifiedPoiTag;
  final int distance;
  final String tag;
  final Location? naviLocation;
  final String type;
  final String detailUrl;
  final String price;
  final String overallRating;
  final String commentNum;
  final String shopHours;
  final String label;
  final List<dynamic> children;

  PlaceDetailInfo({
    required this.classifiedPoiTag,
    required this.distance,
    required this.tag,
    this.naviLocation,
    required this.type,
    required this.detailUrl,
    required this.price,
    required this.overallRating,
    required this.commentNum,
    required this.shopHours,
    required this.label,
    required this.children,
  });

  factory PlaceDetailInfo.fromJson(Map<String, dynamic> json) {
    debugPrint('PlaceDetailInfo.fromJson 输入: $json');
    
    try {
      final detailInfo = PlaceDetailInfo(
        classifiedPoiTag: json['classified_poi_tag'] ?? json['category'] ?? '',
        distance: json['distance'] ?? 0,
        tag: json['tag'] ?? '',
        naviLocation: json['navi_location'] != null 
            ? Location.fromJson(json['navi_location']) 
            : null,
        type: json['type'] ?? '',
        detailUrl: json['detail_url'] ?? '',
        price: json['price'] ?? '',
        overallRating: json['overall_rating'] ?? json['rating'] ?? '0',
        commentNum: json['comment_num'] ?? json['comments'] ?? '0',
        shopHours: json['shop_hours'] ?? json['hours'] ?? '',
        label: json['label'] ?? '',
        children: json['children'] ?? [],
      );
      debugPrint('PlaceDetailInfo 解析成功');
      return detailInfo;
    } catch (e) {
      debugPrint('PlaceDetailInfo 解析失败: $e');
      // 返回默认的 PlaceDetailInfo 对象，但尝试保留navi_location
      return PlaceDetailInfo(
        classifiedPoiTag: '',
        distance: 0,
        tag: '',
        naviLocation: json['navi_location'] != null 
            ? Location.fromJson(json['navi_location']) 
            : null,
        type: '',
        detailUrl: '',
        price: '',
        overallRating: '0',
        commentNum: '0',
        shopHours: '',
        label: '',
        children: [],
      );
    }
  }
}

class Place {
  final String name;
  final Location location;
  final String address;
  final String province;
  final String city;
  final String area;
  final String town;
  final int townCode;
  final String streetId;
  final int detail;
  final String uid;
  final PlaceDetailInfo detailInfo;

  Place({
    required this.name,
    required this.location,
    required this.address,
    required this.province,
    required this.city,
    required this.area,
    required this.town,
    required this.townCode,
    required this.streetId,
    required this.detail,
    required this.uid,
    required this.detailInfo,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    debugPrint('Place.fromJson 输入: $json');
    
    try {
      final place = Place(
        name: json['name'] ?? json['title'] ?? '',
        location: Location.fromJson(json['location'] ?? json['point'] ?? {}),
        address: json['address'] ?? json['addr'] ?? '',
        province: json['province'] ?? '',
        city: json['city'] ?? '',
        area: json['area'] ?? json['district'] ?? '',
        town: json['town'] ?? '',
        townCode: json['town_code'] ?? 0,
        streetId: json['street_id'] ?? '',
        detail: json['detail'] ?? 0,
        uid: json['uid'] ?? json['id'] ?? '',
        detailInfo: PlaceDetailInfo.fromJson(json['detail_info'] ?? json['detail'] ?? {}),
      );
      debugPrint('Place 解析成功: ${place.name}');
      return place;
    } catch (e) {
      debugPrint('Place 解析失败: $e');
      // 返回一个默认的 Place 对象，但保留基本信息
      return Place(
        name: json['name'] ?? '未知地点',
        location: Location.fromJson(json['location'] ?? {}),
        address: json['address'] ?? '',
        province: '',
        city: '',
        area: '',
        town: '',
        townCode: 0,
        streetId: '',
        detail: 0,
        uid: json['uid'] ?? '',
        detailInfo: PlaceDetailInfo.fromJson(json['detail_info'] ?? {}),
      );
    }
  }
}

class SearchPlacesResponse {
  final int status;
  final String message;
  final String resultType;
  final String queryType;
  final List<Place> results;

  SearchPlacesResponse({
    required this.status,
    required this.message,
    required this.resultType,
    required this.queryType,
    required this.results,
  });

  factory SearchPlacesResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('SearchPlacesResponse.fromJson 输入: $json');
    
    final resultsData = json['results'] as List? ?? [];
    debugPrint('搜索结果数据: $resultsData');
    
    final results = resultsData.map((item) {
      debugPrint('处理单个地点: $item');
      return Place.fromJson(item);
    }).toList();
    
    debugPrint('解析后的结果数量: ${results.length}');
    
    return SearchPlacesResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      resultType: json['result_type'] ?? '',
      queryType: json['query_type'] ?? '',
      results: results,
    );
  }
}

class WeatherResponse {
  final int status;
  final String message;
  final WeatherResult result;

  WeatherResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    // 处理嵌套的data结构
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    return WeatherResponse(
      status: data['status'] ?? 0,
      message: data['message'] ?? '',
      result: WeatherResult.fromJson(data['result'] ?? {}),
    );
  }
}

class WeatherResult {
  final WeatherLocation location;
  final WeatherNow now;
  final List<WeatherIndex> indexes;
  final List<dynamic> alerts;
  final List<WeatherForecast> forecasts;

  WeatherResult({
    required this.location,
    required this.now,
    required this.indexes,
    required this.alerts,
    required this.forecasts,
  });

  factory WeatherResult.fromJson(Map<String, dynamic> json) {
    return WeatherResult(
      location: WeatherLocation.fromJson(json['location'] ?? {}),
      now: WeatherNow.fromJson(json['now'] ?? {}),
      indexes: (json['indexes'] as List?)
          ?.map((item) => WeatherIndex.fromJson(item))
          .toList() ?? [],
      alerts: json['alerts'] as List? ?? [],
      forecasts: (json['forecasts'] as List?)
          ?.map((item) => WeatherForecast.fromJson(item))
          .toList() ?? [],
    );
  }
}

class WeatherLocation {
  final String country;
  final String province;
  final String city;
  final String name;
  final String id;

  WeatherLocation({
    required this.country,
    required this.province,
    required this.city,
    required this.name,
    required this.id,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      name: json['name'] ?? '',
      id: json['id'] ?? '',
    );
  }
}

class WeatherNow {
  final String text;
  final int temp;
  final int feelsLike;
  final int rh;
  final String windClass;
  final String windDir;
  final int prec1h;
  final int clouds;
  final int vis;
  final int aqi;
  final int pm25;
  final int pm10;
  final int no2;
  final int so2;
  final int o3;
  final double co;
  final int windAngle;
  final int uvi;
  final int pressure;
  final int dpt;
  final String uptime;

  WeatherNow({
    required this.text,
    required this.temp,
    required this.feelsLike,
    required this.rh,
    required this.windClass,
    required this.windDir,
    required this.prec1h,
    required this.clouds,
    required this.vis,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.so2,
    required this.o3,
    required this.co,
    required this.windAngle,
    required this.uvi,
    required this.pressure,
    required this.dpt,
    required this.uptime,
  });

  factory WeatherNow.fromJson(Map<String, dynamic> json) {
    return WeatherNow(
      text: json['text'] ?? '',
      temp: json['temp'] ?? 0,
      feelsLike: json['feels_like'] ?? 0,
      rh: json['rh'] ?? 0,
      windClass: json['wind_class'] ?? '',
      windDir: json['wind_dir'] ?? '',
      prec1h: json['prec_1h'] ?? 0,
      clouds: json['clouds'] ?? 0,
      vis: json['vis'] ?? 0,
      aqi: json['aqi'] ?? 0,
      pm25: json['pm25'] ?? 0,
      pm10: json['pm10'] ?? 0,
      no2: json['no2'] ?? 0,
      so2: json['so2'] ?? 0,
      o3: json['o3'] ?? 0,
      co: (json['co'] as num?)?.toDouble() ?? 0.0,
      windAngle: json['wind_angle'] ?? 0,
      uvi: json['uvi'] ?? 0,
      pressure: json['pressure'] ?? 0,
      dpt: json['dpt'] ?? 0,
      uptime: json['uptime'] ?? '',
    );
  }
}

class WeatherIndex {
  final String name;
  final String brief;
  final String detail;

  WeatherIndex({
    required this.name,
    required this.brief,
    required this.detail,
  });

  factory WeatherIndex.fromJson(Map<String, dynamic> json) {
    return WeatherIndex(
      name: json['name'] ?? '',
      brief: json['brief'] ?? '',
      detail: json['detail'] ?? '',
    );
  }
}

class WeatherForecast {
  final String date;
  final String text;
  final int high;
  final int low;
  final String windDir;
  final String windClass;
  final int rh;
  final int prec;

  WeatherForecast({
    required this.date,
    required this.text,
    required this.high,
    required this.low,
    required this.windDir,
    required this.windClass,
    required this.rh,
    required this.prec,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['date'] ?? '',
      text: json['text'] ?? '',
      high: json['high'] ?? 0,
      low: json['low'] ?? 0,
      windDir: json['wind_dir'] ?? '',
      windClass: json['wind_class'] ?? '',
      rh: json['rh'] ?? 0,
      prec: json['prec'] ?? 0,
    );
  }
}
