class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String link;
  final bool isActive;
  final int order;
  final String placement;
  final String categoryKey;
  final DateTime? createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.link = '',
    this.isActive = true,
    this.order = 0,
    this.placement = 'home',
    this.categoryKey = '',
    this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] is int ? json['order'] : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      placement: json['placement']?.toString() ?? 'home',
      categoryKey: json['categoryKey']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'link': link,
      'isActive': isActive,
      'order': order,
      'placement': placement,
      'categoryKey': categoryKey,
    };
  }
}
