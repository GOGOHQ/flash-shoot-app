class ApiConfig {
  // API 基础 URL - 使用您电脑的局域网 IP
  static const String baseUrl = 'http://172.26.35.220:9001';
  
  // 备用 URL（如果需要的话）
  static const String backupBaseUrl = 'http://172.26.35.220:9001';
  
  // 超时设置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // 重试设置
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // API 端点
  static const String xhsHotEndpoint = '/api/xhs/hot';
  static const String xhsSearchEndpoint = '/api/xhs/search';
  static const String baiduGeocodeEndpoint = '/api/baidu-maps/geocode';
  static const String baiduReverseGeocodeEndpoint = '/api/baidu-maps/reverse-geocode';
  static const String baiduSearchPlacesEndpoint = '/api/baidu-maps/search-places';
  static const String baiduWeatherEndpoint = '/api/baidu-maps/weather';
  
  // 获取完整的 API URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // 获取备用 API URL
  static String getBackupUrl(String endpoint) {
    return '$backupBaseUrl$endpoint';
  }
  
  // 检查是否是有效的 URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}
