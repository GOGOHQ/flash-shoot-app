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
      
      debugPrint('正在调用小红书API...');
      try {
        final response = await _apiService.getXhsHot(
          limit: 6,
          q: locationKeywords,
          skipLogin: true,
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
        title: '北京必打卡的网红咖啡店，拍照超好看！',
        author: '咖啡达人小王',
        likes: 1234,
        excerpt: '今天给大家推荐一家超级适合拍照的咖啡店，环境超美，咖啡也很好喝...',
        postUrl: 'https://www.xiaohongshu.com/mock/1',
      ),
      XhsPost(
        id: '2',
        title: '北京胡同里的隐藏美食，本地人才知道',
        author: '美食探索者',
        likes: 856,
        excerpt: '在胡同深处发现了一家超级好吃的面馆，老板做了30年，味道绝了...',
        postUrl: 'https://www.xiaohongshu.com/mock/2',
      ),
      XhsPost(
        id: '3',
        title: '北京周末好去处，文艺青年必去',
        author: '文艺小青年',
        likes: 567,
        excerpt: '发现了一个超级文艺的地方，适合周末放松，拍照也很出片...',
        postUrl: 'https://www.xiaohongshu.com/mock/3',
      ),
      XhsPost(
        id: '4',
        title: '北京最新网红打卡地，人少景美',
        author: '旅行摄影师',
        likes: 432,
        excerpt: '最近发现了一个新的打卡地，人不多但景色超美，强烈推荐...',
        postUrl: 'https://www.xiaohongshu.com/mock/4',
      ),
      XhsPost(
        id: '5',
        title: '北京必吃美食清单，本地人推荐',
        author: '北京土著',
        likes: 789,
        excerpt: '作为北京土著，给大家推荐一些真正好吃的本地美食...',
        postUrl: 'https://www.xiaohongshu.com/mock/5',
      ),
      XhsPost(
        id: '6',
        title: '北京夜景最佳观赏点，情侣必去',
        author: '夜景爱好者',
        likes: 654,
        excerpt: '北京最美的夜景观赏点，特别适合情侣约会，浪漫指数满分...',
        postUrl: 'https://www.xiaohongshu.com/mock/6',
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
