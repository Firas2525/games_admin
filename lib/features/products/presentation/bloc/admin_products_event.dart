abstract class AdminProductsEvent {}

class LoadAdminProductsEvent extends AdminProductsEvent {
  final String? source;
  final String? category;
  final String? search;
  final bool? isVisible;

  LoadAdminProductsEvent({
    this.source,
    this.category,
    this.search,
    this.isVisible,
  });
}

class SyncAdminProductsEvent extends AdminProductsEvent {}

class ToggleProductVisibilityEvent extends AdminProductsEvent {
  final String productId;
  ToggleProductVisibilityEvent({required this.productId});
}

class ChangeProductMainCategoryEvent extends AdminProductsEvent {
  final String productId;
  final String mainCategory;
  final String? subCategoryName;
  final String? subCategoryImage;
  final String? subCategoryId;

  ChangeProductMainCategoryEvent({
    required this.productId,
    required this.mainCategory,
    this.subCategoryName,
    this.subCategoryImage,
    this.subCategoryId,
  });
}

class BulkMoveCategoryEvent extends AdminProductsEvent {
  final List<String> productIds;
  final String mainCategory;
  final String? mainCategoryTitle;
  final String? subCategoryName;
  final String? subCategoryImage;
  final String? subCategoryId;

  BulkMoveCategoryEvent({
    required this.productIds,
    required this.mainCategory,
    this.mainCategoryTitle,
    this.subCategoryName,
    this.subCategoryImage,
    this.subCategoryId,
  });
}

class BulkToggleVisibilityEvent extends AdminProductsEvent {
  final List<String> productIds;
  final bool isVisible;

  BulkToggleVisibilityEvent({
    required this.productIds,
    required this.isVisible,
  });
}


class CreateCategoryEvent extends AdminProductsEvent {
  final String title;
  final String? subtitle;
  final String? icon;
  final String? color;
  final String? imageUrl;
  final double? profitPercentage;

  CreateCategoryEvent({
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.imageUrl,
    this.profitPercentage,
  });
}

class UpdateCategoryItemEvent extends AdminProductsEvent {
  final String id;
  final String? title;
  final String? subtitle;
  final String? icon;
  final String? color;
  final String? imageUrl;
  final double? profitPercentage;
  final bool resetProfitPercentage;

  UpdateCategoryItemEvent({
    required this.id,
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.imageUrl,
    this.profitPercentage,
    this.resetProfitPercentage = false,
  });
}

class DeleteCategoryEvent extends AdminProductsEvent {
  final String id;
  DeleteCategoryEvent({required this.id});
}

class LoadCategoriesEvent extends AdminProductsEvent {}

class UpdateProductCustomDetailsEvent extends AdminProductsEvent {
  final String productId;
  final String? name;
  final String? image;

  UpdateProductCustomDetailsEvent({
    required this.productId,
    this.name,
    this.image,
  });
}

class RevertProductCustomDetailsEvent extends AdminProductsEvent {
  final String productId;
  final bool revertName;
  final bool revertImage;

  RevertProductCustomDetailsEvent({
    required this.productId,
    this.revertName = true,
    this.revertImage = true,
  });
}

