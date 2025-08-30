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
    return Location(
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    );
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
    return PlaceDetailInfo(
      classifiedPoiTag: json['classified_poi_tag'] ?? '',
      distance: json['distance'] ?? 0,
      tag: json['tag'] ?? '',
      naviLocation: json['navi_location'] != null 
          ? Location.fromJson(json['navi_location']) 
          : null,
      type: json['type'] ?? '',
      detailUrl: json['detail_url'] ?? '',
      price: json['price'] ?? '',
      overallRating: json['overall_rating'] ?? '',
      commentNum: json['comment_num'] ?? '',
      shopHours: json['shop_hours'] ?? '',
      label: json['label'] ?? '',
      children: json['children'] ?? [],
    );
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
    return Place(
      name: json['name'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      address: json['address'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      town: json['town'] ?? '',
      townCode: json['town_code'] ?? 0,
      streetId: json['street_id'] ?? '',
      detail: json['detail'] ?? 0,
      uid: json['uid'] ?? '',
      detailInfo: PlaceDetailInfo.fromJson(json['detail_info'] ?? {}),
    );
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
    return SearchPlacesResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      resultType: json['result_type'] ?? '',
      queryType: json['query_type'] ?? '',
      results: (json['results'] as List?)
          ?.map((item) => Place.fromJson(item))
          .toList() ?? [],
    );
  }
}

class WeatherResponse {
  final Map<String, dynamic> data;

  WeatherResponse({required this.data});

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(data: json);
  }
}
