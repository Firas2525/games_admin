class SubCategoryItemModel {
  final String id;
  final String name;
  final String mainCategory;
  final String imageUrl;
  final String? parentId;
  final int productCount;
  final int childCount;
  final bool isEmpty;
  final bool canDelete;
  final bool isVisible;

  const SubCategoryItemModel({
    required this.id,
    required this.name,
    required this.mainCategory,
    this.imageUrl = '',
    this.parentId,
    this.productCount = 0,
    this.childCount = 0,
    this.isEmpty = true,
    this.canDelete = true,
    this.isVisible = true,
  });

  factory SubCategoryItemModel.fromJson(Map<String, dynamic> json) {
    final pCount = (json['productCount'] as num?)?.toInt() ?? 0;
    final cCount = (json['childCount'] as num?)?.toInt() ?? 0;
    final isEmp = json['isEmpty'] == true || (pCount == 0 && cCount == 0);

    return SubCategoryItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mainCategory: json['mainCategory']?.toString() ?? 'games',
      imageUrl: json['imageUrl']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      productCount: pCount,
      childCount: cCount,
      isEmpty: isEmp,
      canDelete: json['canDelete'] != null ? json['canDelete'] == true : isEmp,
      isVisible: json['isVisible'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mainCategory': mainCategory,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'productCount': productCount,
      'childCount': childCount,
      'isEmpty': isEmpty,
      'canDelete': canDelete,
      'isVisible': isVisible,
    };
  }

  SubCategoryItemModel copyWith({
    String? id,
    String? name,
    String? mainCategory,
    String? imageUrl,
    String? parentId,
    int? productCount,
    int? childCount,
    bool? isEmpty,
    bool? canDelete,
    bool? isVisible,
  }) {
    return SubCategoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mainCategory: mainCategory ?? this.mainCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      productCount: productCount ?? this.productCount,
      childCount: childCount ?? this.childCount,
      isEmpty: isEmpty ?? this.isEmpty,
      canDelete: canDelete ?? this.canDelete,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

