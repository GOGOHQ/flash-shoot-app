import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import 'weather_screen.dart';

class PoiDetailScreen extends StatefulWidget {
  final Place poi;

  const PoiDetailScreen({
    super.key,
    required this.poi,
  });

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingWeather = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poi.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _sharePoi(context),
            icon: const Icon(Icons.share),
            tooltip: '分享',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息卡片
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            
            // 详细信息卡片（合并详细信息和位置信息）
            _buildMergedInfoCard(),
            const SizedBox(height: 16),
            
            // 照片滑动列表
            _buildPhotoSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.poi.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.poi.detailInfo.overallRating != '0')
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
                          widget.poi.detailInfo.overallRating,
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
            const SizedBox(height: 8),
            Text(
              widget.poi.address,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (widget.poi.detailInfo.classifiedPoiTag.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.poi.detailInfo.classifiedPoiTag,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMergedInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 距离信息
            _buildInfoRow(Icons.directions_walk, '距离', '${widget.poi.detailInfo.distance}m', Colors.blue),
            
            // 价格信息
            if (widget.poi.detailInfo.price.isNotEmpty)
              _buildInfoRow(Icons.attach_money, '人均消费', '¥${widget.poi.detailInfo.price}', Colors.green),
            
            // 营业时间
            if (widget.poi.detailInfo.shopHours.isNotEmpty)
              _buildInfoRow(Icons.access_time, '营业时间', widget.poi.detailInfo.shopHours, Colors.orange),
            
            // 评论数量
            if (widget.poi.detailInfo.commentNum != '0')
              _buildInfoRow(Icons.comment, '评论数量', '${widget.poi.detailInfo.commentNum}条', Colors.purple),
            
            // 标签信息
            if (widget.poi.detailInfo.tag.isNotEmpty)
              _buildInfoRow(Icons.label, '标签', widget.poi.detailInfo.tag, Colors.teal),
            
            const Divider(height: 24),
            
            const Text(
              '位置信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow(Icons.location_on, '地址', widget.poi.address, Colors.red),
            _buildInfoRow(Icons.map, '坐标', '${widget.poi.location.lat.toStringAsFixed(6)}, ${widget.poi.location.lng.toStringAsFixed(6)}', Colors.grey),
            
            if (widget.poi.province.isNotEmpty)
              _buildInfoRow(Icons.location_city, '省份', widget.poi.province, Colors.blue),
            
            if (widget.poi.city.isNotEmpty)
              _buildInfoRow(Icons.location_city, '城市', widget.poi.city, Colors.blue),
            
            if (widget.poi.area.isNotEmpty)
              _buildInfoRow(Icons.location_city, '区域', widget.poi.area, Colors.blue),
            
            const Divider(height: 24),
            
            // 天气查询按钮
            _buildWeatherButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '天气信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoadingWeather ? null : () => _getWeatherInfo(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _isLoadingWeather 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.wb_sunny),
            label: Text(_isLoadingWeather ? '查询中...' : '查询天气'),
          ),
        ),
      ],
    );
  }

  // 获取天气信息
  Future<void> _getWeatherInfo(BuildContext context) async {
    try {
      setState(() {
        _isLoadingWeather = true;
      });

      debugPrint('开始获取天气信息 - POI: ${widget.poi.name}');
      debugPrint('位置坐标: ${widget.poi.location.lat}, ${widget.poi.location.lng}');

      final weatherResponse = await _apiService.getWeatherByLocation(
        location: Location(
          lat: widget.poi.location.lat,
          lng: widget.poi.location.lng,
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
          builder: (context) => WeatherScreen(
            weatherData: weatherResponse,
            location: widget.poi.location,
          ),
        ),
      );
    } catch (e) {
      debugPrint('获取天气信息失败: $e');
      setState(() {
        _isLoadingWeather = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取天气信息失败: 请检查网络连接或稍后重试')),
      );
    }
  }

  Widget _buildPhotoSlider() {
    // 模拟照片数据，实际应用中应该从API获取
    final List<Map<String, dynamic>> photos = [
      {
        'url': 'assets/poses/单人/pose_1.png',
        'likes': 42,
        'isLiked': false,
      },
      {
        'url': 'assets/poses/双人/pose_1.png',
        'likes': 128,
        'isLiked': true,
      },
      {
        'url': 'assets/poses/多人/pose_1.png',
        'likes': 89,
        'isLiked': false,
      },
      {
        'url': 'assets/poses/情侣/pose_1.png',
        'likes': 256,
        'isLiked': true,
      },
      {
        'url': 'assets/poses/收藏/pose_1.png',
        'likes': 67,
        'isLiked': false,
      },
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '相关照片',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _buildPhotoCard(photo, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo, int index) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片区域
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Image.asset(
                    photo['url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // 底部信息区域
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 用户头像和名称
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            'U${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '用户${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 点赞按钮
                  GestureDetector(
                    onTap: () {
                      // 这里可以添加点赞逻辑
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          photo['isLiked'] ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: photo['isLiked'] ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${photo['likes']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
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

  

  void _openNavigation(BuildContext context) {
    // 构建导航 URL
    final lat = widget.poi.location.lat;
    final lng = widget.poi.location.lng;
    final name = Uri.encodeComponent(widget.poi.name);
    
    // 尝试打开百度地图导航
    final baiduUrl = 'baidumap://map/direction?destination=$lat,$lng&mode=driving&src=webapp.baidu.openAPIdemo';
    
    // 备用方案：使用高德地图
    final amapUrl = 'androidamap://navi?sourceApplication=FlashShootApp&poiname=$name&lat=$lat&lon=$lng&dev=0&style=2';
    
    // 通用方案：使用系统地图
    final systemUrl = 'geo:$lat,$lng?q=$name';
    
    _launchUrl(baiduUrl).catchError((_) {
      _launchUrl(amapUrl).catchError((_) {
        _launchUrl(systemUrl).catchError((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开导航应用')),
          );
        });
      });
    });
  }

  void _callPhone(BuildContext context) {
    // 这里可以添加电话号码信息，如果 POI 数据中包含的话
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('该地点暂无电话号码信息')),
    );
  }

  void _sharePoi(BuildContext context) {
    final shareText = '${widget.poi.name}\n地址：${widget.poi.address}\n坐标：${widget.poi.location.lat}, ${widget.poi.location.lng}';
    
    // 这里可以集成分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享内容：$shareText'),
        action: SnackBarAction(
          label: '复制',
          onPressed: () {
            // 复制到剪贴板
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('无法打开 URL: $url');
    }
  }
}
