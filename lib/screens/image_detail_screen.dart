import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/poi_content_model.dart';

class ImageDetailScreen extends StatefulWidget {
  final PoiImageItem imageItem;
  final String poiName;

  const ImageDetailScreen({
    super.key,
    required this.imageItem,
    required this.poiName,
  });

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  bool _isLiked = false;
  bool _isFavorited = false;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery() async {
    // 防止重复保存
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 显示保存提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在保存图片到相册...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 从assets加载图片数据
      final ByteData imageData = await rootBundle.load(widget.imageItem.image);
      final Uint8List bytes = imageData.buffer.asUint8List();
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final fileName = '${widget.poiName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      
      // 写入临时文件
      await tempFile.writeAsBytes(bytes);
      
      // 保存到相册
      final result = await GallerySaver.saveImage(
        tempFile.path,
        albumName: '魔拍机位',
      );
      
      // 删除临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存失败，请检查相册权限'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('保存图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    
    // 点赞时保存图片到相册
    if (_isLiked) {
      _saveImageToGallery();
    }
    
    // 这里可以添加点赞的API调用
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? '已点赞并保存到相册' : '取消点赞'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });
    
    // 这里可以添加收藏的API调用
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorited ? '已收藏' : '取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主要内容区域
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 详情图片
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: PhotoView(
                    imageProvider: AssetImage(widget.imageItem.image),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 机位导航文本
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.poiName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '机位导航',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 文本内容
                      if (widget.imageItem.text.isNotEmpty)
                        ...widget.imageItem.text.map((line) {
                          if (line.isEmpty) {
                            return const SizedBox(height: 12);
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList()
                      else
                        const Text(
                          '暂无机位导航信息',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      
                      // 底部间距，为固定浮条留出空间
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // 顶部返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // 底部固定浮条
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 点赞按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isLiked ? Colors.red[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isLiked ? Colors.red : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSaving)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaving ? '保存中...' : (_isLiked ? '已点赞' : '点赞'),
                              style: TextStyle(
                                color: _isLiked ? Colors.red : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 收藏按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isFavorited ? Colors.amber[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isFavorited ? Colors.amber : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSaving)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                _isFavorited ? Icons.star : Icons.star_border,
                                color: _isFavorited ? Colors.amber[700] : Colors.grey[600],
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaving ? '保存中...' : (_isFavorited ? '已收藏' : '收藏'),
                              style: TextStyle(
                                color: _isFavorited ? Colors.amber[700] : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
