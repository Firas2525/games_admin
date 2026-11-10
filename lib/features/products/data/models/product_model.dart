import '../../domain/entities/product_entity.dart';

class RequiredFieldModel extends RequiredFieldEntity {
  const RequiredFieldModel({
    required super.name,
    required super.label,
    required super.type,
    required super.placeholder,
    required super.required,
  });

  factory RequiredFieldModel.fromJson(Map<String, dynamic> json) {
    return RequiredFieldModel(
      name: json['name'] as String? ?? json['key'] as String? ?? 'Player_ID',
      label: json['label'] as String? ?? json['name'] as String? ?? 'ايدي اللاعب',
      type: json['type'] as String? ?? 'text',
      placeholder: json['placeholder'] as String? ?? '',
      required: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type,
      'placeholder': placeholder,
      'required': required,
    };
  }
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.externalId,
    required super.source,
    required super.sourceName,
    required super.name,
    required super.category,
    required super.originalPrice,
    super.sellingPrice,
    required super.currency,
    required super.image,
    required super.isAvailable,
    required super.isVisible,
    super.mainCategory = 'games',
    super.discountPercent = 0.0,
    super.priceBeforeDiscount,
    super.subCategoryId,
    super.subCategoryName,
    super.subCategoryImage,
    super.providerName,
    super.providerImage,
    super.customName,
    super.customImage,
    super.isNameOverridden = false,
    super.isImageOverridden = false,
    required super.requiredFields,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final fields = (json['requiredFields'] as List<dynamic>? ?? [])
        .map((f) => RequiredFieldModel.fromJson(f as Map<String, dynamic>))
        .toList();

    final rawSource = (json['source'] as String? ?? 'custom').toLowerCase();
    final rawSourceName = json['sourceName'] as String? ?? '';
    String normalizedSource = rawSource;
    String normalizedSourceName = rawSourceName;

    if (rawSource == 'sw_games' || rawSource == 'roya_usd' || rawSourceName.contains('SW') || rawSourceName.contains('دولار')) {
      normalizedSource = 'roya_usd';
      normalizedSourceName = 'رؤيا دولار';
    } else if (rawSource == 'roya_syp' || rawSourceName.contains('ليرة')) {
      normalizedSource = 'roya_syp';
      normalizedSourceName = 'رؤيا ليرة';
    } else if (rawSource == 'brand1card' || rawSourceName.contains('براند') || rawSourceName.toLowerCase().contains('brand')) {
      normalizedSource = 'brand1card';
      normalizedSourceName = 'براند ون كارد';
    } else if (rawSource == 'custom' || rawSourceName.contains('خاص')) {
      normalizedSource = 'custom';
      normalizedSourceName = 'مزودي الخاص';
    }

    final rawDiscount = (json['discountPercent'] as num?)?.toDouble() ?? 0.0;
    final rawPriceBefore = (json['priceBeforeDiscount'] as num?)?.toDouble() ??
        (json['calculatedPrice'] as num?)?.toDouble();

    final subId = json['subCategoryId'] is Map
        ? (json['subCategoryId']['_id'] ?? json['subCategoryId']['id'])?.toString()
        : json['subCategoryId']?.toString();

    return ProductModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      externalId: json['externalId']?.toString() ?? '',
      source: normalizedSource,
      sourceName: normalizedSourceName,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      mainCategory: json['mainCategory'] as String? ?? 'games',
      subCategoryId: subId,
      subCategoryName: json['subCategoryName'] as String? ?? json['category'] as String?,
      subCategoryImage: json['subCategoryImage'] as String?,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble(),
      discountPercent: rawDiscount,
      priceBeforeDiscount: rawPriceBefore,
      currency: json['currency'] as String? ?? '\$',
      image: json['image'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      isVisible: json['isVisible'] as bool? ?? false,
      providerName: json['providerName'] as String?,
      providerImage: json['providerImage'] as String?,
      customName: json['customName'] as String?,
      customImage: json['customImage'] as String?,
      isNameOverridden: json['isNameOverridden'] as bool? ?? false,
      isImageOverridden: json['isImageOverridden'] as bool? ?? false,
      requiredFields: fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'externalId': externalId,
      'source': source,
      'sourceName': sourceName,
      'name': name,
      'category': category,
      'mainCategory': mainCategory,
      'subCategoryId': subCategoryId,
      'subCategoryName': subCategoryName,
      'subCategoryImage': subCategoryImage,
      'originalPrice': originalPrice,
      'sellingPrice': sellingPrice,
      'discountPercent': discountPercent,
      'priceBeforeDiscount': priceBeforeDiscount,
      'currency': currency,
      'image': image,
      'isAvailable': isAvailable,
      'isVisible': isVisible,
      'providerName': providerName,
      'providerImage': providerImage,
      'customName': customName,
      'customImage': customImage,
      'isNameOverridden': isNameOverridden,
      'isImageOverridden': isImageOverridden,
      'requiredFields': requiredFields.map((f) {
        if (f is RequiredFieldModel) return f.toJson();
        return {
          'name': f.name,
          'label': f.label,
          'type': f.type,
          'placeholder': f.placeholder,
          'required': f.required,
        };
      }).toList(),
    };
  }
}
