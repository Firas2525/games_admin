import '../../domain/entities/product_entity.dart';
import '../../data/models/category_item_model.dart';

abstract class AdminProductsState {}

class AdminProductsInitial extends AdminProductsState {}

class AdminProductsLoading extends AdminProductsState {}

class AdminProductsSyncing extends AdminProductsState {
  final List<ProductEntity> currentProducts;
  AdminProductsSyncing({required this.currentProducts});
}

class AdminProductsLoaded extends AdminProductsState {
  final List<ProductEntity> products;
  final List<String> categories;
  final List<String> sources;
  final int totalCount;
  final List<CategoryItemModel> categoryItems;
  final String? message;
  final bool isSyncing;

  AdminProductsLoaded({
    required this.products,
    required this.categories,
    required this.sources,
    required this.totalCount,
    this.categoryItems = const [],
    this.message,
    this.isSyncing = false,
  });

  AdminProductsLoaded copyWith({
    List<ProductEntity>? products,
    List<String>? categories,
    List<String>? sources,
    int? totalCount,
    List<CategoryItemModel>? categoryItems,
    String? message,
    bool? isSyncing,
  }) {
    return AdminProductsLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      sources: sources ?? this.sources,
      totalCount: totalCount ?? this.totalCount,
      categoryItems: categoryItems ?? this.categoryItems,
      message: message,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}


class AdminProductsError extends AdminProductsState {
  final String message;
  final List<ProductEntity>? currentProducts;

  AdminProductsError({
    required this.message,
    this.currentProducts,
  });
}
