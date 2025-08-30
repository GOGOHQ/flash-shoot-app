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
}
