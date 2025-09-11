class BaiduMapConfig {
  // 百度地图 AK
  static const String ak = '1aiol9mfe8awlvmR9PRMC5bxgg5G9Wgc';
  
  // 默认地图中心点（北京天安门）
  static const double defaultLatitude = 39.9042;
  static const double defaultLongitude = 116.4074;
  
  // 默认缩放级别
  static const int defaultZoomLevel = 15;
  
  // 地图样式配置
  static const bool enable3D = true;
  static const bool enableTraffic = false;
  static const bool enableSatellite = false;
  
  // 定位配置
  static const bool enableLocation = true;
  static const int locationInterval = 5000; // 定位间隔，毫秒
  
  // 搜索配置
  static const int searchRadius = 2000; // 搜索半径，米
  static const int maxSearchResults = 20; // 最大搜索结果数

  // 指定 POI 配置（可选）
  // 若非空：仅检索这些关键词对应的 POI（如：['故宫','天坛']）
  static const List<String> specifiedPoiKeywords = ['天坛', '天安门', '环球影城', '故宫', '雍和宫'];
  // 若非空：仅保留 UID 在白名单内的 POI（如：['592c0b3d3f...']）
  static const List<String> specifiedPoiUids = [];

  // 指定 POI 关键词别名（用于更宽松的名称匹配）
  static const Map<String, List<String>> specifiedPoiAliases = {
    '环球影城': ['北京环球度假区', 'Universal Studios Beijing', '北京环球影城', 'Universal Beijing Resort'],
    '故宫': ['故宫博物院', 'The Palace Museum'],
    '雍和宫': ['雍和宫'],
  };

  // 精准匹配的“官方名称”白名单，用于严格筛选出唯一结果
  static const Map<String, List<String>> specifiedPoiExactNames = {
    '天坛': ['天坛公园'],
    '天安门': ['天安门'],
    '环球影城': ['北京环球度假区', '北京环球影城', 'Universal Studios Beijing', 'Universal Beijing Resort'],
    '故宫': ['故宫博物院', '故宫'],
    '雍和宫': ['雍和宫', ],
  };
}
