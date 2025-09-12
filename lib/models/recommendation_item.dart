// Class to hold a single item's data
class RecommendationItem {
  final String title;
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final int likes; // 新增点赞数
  

  RecommendationItem({
    required this.title,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    this.likes = 0,
  });
}