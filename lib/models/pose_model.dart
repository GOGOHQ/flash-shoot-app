class PoseCategory {
  final String id;
  final String name;
  final String path;
  final String category;

  PoseCategory({
    required this.id,
    required this.name,
    required this.path,
    required this.category,
  });

  factory PoseCategory.fromJson(Map<String, dynamic> json) {
    return PoseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['Path'] as String,   // 注意 JSON 里是大写 P
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'Path': path,
      'category': category,
    };
  }
}
