import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class RecommendationBubble extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback? onClose;

  const RecommendationBubble({
    super.key,
    required this.lat,
    required this.lng,
    this.onClose,
  });

  @override
  State<RecommendationBubble> createState() => _RecommendationBubbleState();
}

class _RecommendationBubbleState extends State<RecommendationBubble> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<XhsPost> _recommendations = [];
  String _locationName = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      debugPrint('=== 开始加载推荐内容 ===');
      debugPrint('当前位置: ${widget.lat}, ${widget.lng}');
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 获取位置名称
      debugPrint('正在获取位置名称...');
      final address = await _apiService.getAddressByLocation(widget.lat, widget.lng);
      debugPrint('位置名称获取结果: $address');
      
      if (address != null) {
        setState(() {
          _locationName = address;
        });
      }

      // 获取小红书热门内容，使用位置信息作为搜索关键词
      final locationKeywords = _getLocationKeywords();
      debugPrint('生成的位置关键词: $locationKeywords');
      
      // 注释掉真实API调用，直接使用模拟数据
      debugPrint('跳过小红书API调用，直接使用模拟数据');
      _loadMockData();
      
      // 以下是原来的API调用代码（已注释）
      /*
      debugPrint('正在调用小红书API...');
      try {
        final response = await _apiService.getXhsHot(
          limit: 6,
          q: locationKeywords,
        );
        
        debugPrint('小红书API响应: ${response.data.length} 条数据');
        debugPrint('推荐内容详情: ${response.data.map((e) => '${e.title} (${e.author})').toList()}');

        setState(() {
          _recommendations = response.data;
          _isLoading = false;
        });
      } catch (apiError) {
        debugPrint('小红书API调用失败，使用模拟数据: $apiError');
        // 使用模拟数据
        _loadMockData();
      }
      */
      
      debugPrint('=== 推荐内容加载完成 ===');
    } catch (e) {
      debugPrint('=== 推荐内容加载失败 ===');
      debugPrint('错误详情: $e');
      setState(() {
        _error = '获取推荐内容失败: $e';
        _isLoading = false;
      });
    }
  }

  String _getLocationKeywords() {
    // 根据位置生成搜索关键词
    if (_locationName.isNotEmpty) {
      // 提取城市名称
      final cityMatch = RegExp(r'([^省市区县]+[市])').firstMatch(_locationName);
      if (cityMatch != null) {
        return '${cityMatch.group(1)} 热门';
      }
      
      // 提取区县名称
      final districtMatch = RegExp(r'([^省市区县]+[区县])').firstMatch(_locationName);
      if (districtMatch != null) {
        return '${districtMatch.group(1)} 热门';
      }
    }
    
    // 默认关键词
    return '附近热门';
  }

  void _loadMockData() {
    debugPrint('加载模拟数据...');
    final mockPosts = [
      XhsPost(
        id: '1',
        title: '北京7-9月景点红黑榜📍建议去🆚不要去',
        author: '橙大可爱',
        likes: 1200,
        excerpt: '给大家整理了北京zui新的旅游攻略，包含必去景点和避坑指南',
        postUrl: 'https://www.xiaohongshu.com/search_result/6880820c000000000b01d9ed?xsec_token=AB7oNcvMPFF4z3X5Kd4UFEL0n4O0suVGEEEgKFVWcU2vE=&xsec_source=',
      ),
      XhsPost(
        id: '2',
        title: '清明去北京玩👀就按这份旅行地图来🗺️',
        author: '游学郑老师',
        likes: 856,
        excerpt: '详细的北京旅行地图，包含景点路线和美食推荐',
        postUrl: 'https://www.xiaohongshu.com/search_result/67e4bbb0000000000603c3ab?xsec_token=ABLAQ0SyTx9jOt8uyL1YawAhK7LtkXXyd-_FKznEAdRmo=&xsec_source=',
      ),
      XhsPost(
        id: '3',
        title: '🌸北京周末去哪儿指南｜亲测20+好去处',
        author: '有时出逃',
        likes: 567,
        excerpt: '北京周末去哪儿指南，亲测20+好去处推荐',
        postUrl: 'https://www.xiaohongshu.com/search_result/68821af8000000002400c163?xsec_token=ABZsg4xlCi4PrWc1g6BXt5yLig1-P-agPZ-uVDGuwa0-k=&xsec_source=',
      ),
      XhsPost(
        id: '4',
        title: '8-9月北京5天4晚旅游攻略🔥附路线',
        author: '小晶同学',
        likes: 432,
        excerpt: '详细的北京5天4晚旅游攻略，包含完整路线规划',
        postUrl: 'https://www.xiaohongshu.com/search_result/688895130000000023038c52?xsec_token=AB4Xx4CSoQ79geMVnQn9NPw3NwTZbqcD775tAxKVcXYFc=&xsec_source=',
      ),
      XhsPost(
        id: '5',
        title: '北京9个情侣约会基地',
        author: '约会达人',
        likes: 789,
        excerpt: '北京最适合情侣约会的9个地方，浪漫指数满分',
        postUrl: 'https://www.xiaohongshu.com/search_result/67b841030000000029035b00?xsec_token=AB1IjFeP01x8z8-r9lTLfux8oLNnGAku7SLJqTtMYQGpc=&xsec_source=',
      ),
      XhsPost(
        id: '6',
        title: '北京周末去哪儿（地区版）',
        author: '本地向导',
        likes: 654,
        excerpt: '按地区划分的北京周末游玩指南，方便就近选择',
        postUrl: 'https://www.xiaohongshu.com/search_result/67e51d54000000001c002d3a?xsec_token=ABf9fp05bLAxvyYuMnvTniow7Dbr8_RV699JQXc7AprXs=&xsec_source=',
      ),
    ];

    setState(() {
      _recommendations = mockPosts;
      _isLoading = false;
    });
    
    debugPrint('模拟数据加载完成: ${mockPosts.length} 条数据');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          _buildHeader(),
          
          // 内容区域
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '附近热门推荐',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_locationName.isNotEmpty)
                  Text(
                    _locationName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在获取推荐内容...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendations,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                '暂无推荐内容',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final post = _recommendations[index];
          return _buildRecommendationItem(post, index);
        },
      ),
    );
  }

  Widget _buildRecommendationItem(XhsPost post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.pink[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${post.author}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (post.excerpt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.excerpt,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.favorite,
                size: 16,
                color: Colors.pink[400],
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likes}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // 这里可以添加打开小红书链接的功能
                  _showPostDetails(post);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  '查看详情',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.pink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostDetails(XhsPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('小红书内容'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('作者: ${post.author}'),
            Text('点赞: ${post.likes}'),
            if (post.excerpt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('摘要: ${post.excerpt}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 这里可以添加打开链接的功能
              _openPostUrl(post.postUrl);
            },
            child: const Text('打开链接'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPostUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开链接')),
          );
        }
      }
    } catch (e) {
      debugPrint('打开链接失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }
}
