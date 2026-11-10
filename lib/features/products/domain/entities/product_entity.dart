class RequiredFieldEntity {
  final String name;
  final String label;
  final String type;
  final String placeholder;
  final bool required;

  const RequiredFieldEntity({
    required this.name,
    required this.label,
    required this.type,
    required this.placeholder,
    required this.required,
  });
}

class ProductEntity {
  final String id;
  final String externalId;
  final String source;
  final String sourceName;
  final String name;

  final String category;
  final double originalPrice;
  final double? sellingPrice;
  final String currency;
  final String image;
  final bool isAvailable;
  final bool isVisible;
  final String mainCategory;
  final double discountPercent;
  final double? priceBeforeDiscount;
  final String? subCategoryId;
  final String? subCategoryName;
  final String? subCategoryImage;
  final String? providerName;
  final String? providerImage;
  final String? customName;
  final String? customImage;
  final bool isNameOverridden;
  final bool isImageOverridden;
  final List<RequiredFieldEntity> requiredFields;

  const ProductEntity({
    required this.id,
    required this.externalId,
    required this.source,
    required this.sourceName,
    required this.name,
    required this.category,
    required this.originalPrice,
    this.sellingPrice,
    required this.currency,
    required this.image,
    required this.isAvailable,
    required this.isVisible,
    this.mainCategory = 'games',
    this.discountPercent = 0.0,
    this.priceBeforeDiscount,
    this.subCategoryId,
    this.subCategoryName,
    this.subCategoryImage,
    this.providerName,
    this.providerImage,
    this.customName,
    this.customImage,
    this.isNameOverridden = false,
    this.isImageOverridden = false,
    required this.requiredFields,
  });

  double get price => sellingPrice ?? originalPrice;

  ProductEntity copyWith({
    String? name,
    String? image,
    bool? isVisible,
    double? sellingPrice,
    String? mainCategory,
    String? category,
    String? subCategoryId,
    String? subCategoryName,
    String? subCategoryImage,
    String? providerName,
    String? providerImage,
    String? customName,
    String? customImage,
    bool? isNameOverridden,
    bool? isImageOverridden,
    double? discountPercent,
    double? priceBeforeDiscount,
  }) {
    return ProductEntity(
      id: id,
      externalId: externalId,
      source: source,
      sourceName: sourceName,
      name: name ?? this.name,
      category: category ?? this.category,
      originalPrice: originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currency: currency,
      image: image ?? this.image,
      isAvailable: isAvailable,
      isVisible: isVisible ?? this.isVisible,
      mainCategory: mainCategory ?? this.mainCategory,
      discountPercent: discountPercent ?? this.discountPercent,
      priceBeforeDiscount: priceBeforeDiscount ?? this.priceBeforeDiscount,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      subCategoryImage: subCategoryImage ?? this.subCategoryImage,
      providerName: providerName ?? this.providerName,
      providerImage: providerImage ?? this.providerImage,
      customName: customName ?? this.customName,
      customImage: customImage ?? this.customImage,
      isNameOverridden: isNameOverridden ?? this.isNameOverridden,
      isImageOverridden: isImageOverridden ?? this.isImageOverridden,
      requiredFields: requiredFields,
    );
  }
}
