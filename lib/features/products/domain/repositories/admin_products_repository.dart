import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/failures.dart';
import '../entities/product_entity.dart';

class AdminProductsResult {
  final List<ProductEntity> products;
  final List<String> categories;
  final List<String> sources;
  final int totalCount;

  const AdminProductsResult({
    required this.products,
    required this.categories,
    required this.sources,
    required this.totalCount,
  });
}

abstract class AdminProductsRepository {
  Future<AdminProductsResult?> getCachedProducts();
  Future<List<dynamic>?> getCachedCategories();

  Future<Either<Failure, AdminProductsResult>> getProducts({
    String? source,
    String? category,
    String? search,
    bool? isVisible,
  });

  Future<Either<Failure, String>> syncFromProviders();

  Future<Either<Failure, ProductEntity>> toggleVisibility(String id);

  Future<Either<Failure, ProductEntity>> updateProductCategory(
    String id,
    String mainCategory, {
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  });

  Future<Either<Failure, List<dynamic>>> getCategories();

  Future<Either<Failure, dynamic>> addCategory({
    required String title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
  });

  Future<Either<Failure, dynamic>> updateCategoryItem({
    required String id,
    String? title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
    bool resetProfitPercentage = false,
  });

  Future<Either<Failure, void>> deleteCategory(String id);

  Future<Either<Failure, int>> bulkUpdateCategory({
    required List<String> productIds,
    required String mainCategory,
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  });

  Future<Either<Failure, int>> bulkUpdateVisibility({
    required List<String> productIds,
    required bool isVisible,
  });

  Future<Either<Failure, ProductEntity>> updateProductCustomDetails(
    String id, {
    String? name,
    String? image,
  });

  Future<Either<Failure, ProductEntity>> revertProductCustomDetails(
    String id, {
    bool revertName = true,
    bool revertImage = true,
  });
}


