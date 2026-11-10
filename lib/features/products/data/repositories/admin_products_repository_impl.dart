import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import 'package:games_admin/core/errors/failures.dart';
import '../models/product_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/admin_products_repository.dart';
import '../datasources/admin_products_remote_data_source.dart';
import '../datasources/admin_products_local_data_source.dart';

class AdminProductsRepositoryImpl implements AdminProductsRepository {
  final AdminProductsRemoteDataSource remoteDataSource;
  final AdminProductsLocalDataSource? localDataSource;

  AdminProductsRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<AdminProductsResult?> getCachedProducts() async {
    return await localDataSource?.getCachedProducts();
  }

  @override
  Future<List<dynamic>?> getCachedCategories() async {
    return await localDataSource?.getCachedCategories();
  }

  @override
  Future<Either<Failure, AdminProductsResult>> getProducts({
    String? source,
    String? category,
    String? search,
    bool? isVisible,
  }) async {
    try {
      final result = await remoteDataSource.getProducts(
        source: source,
        category: category,
        search: search,
        isVisible: isVisible,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> syncFromProviders() async {
    try {
      final msg = await remoteDataSource.syncFromProviders();
      return Right(msg);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductModel>> toggleVisibility(String id) async {
    try {
      final updatedProduct = await remoteDataSource.toggleVisibility(id);
      return Right(updatedProduct);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProductCategory(
    String id,
    String mainCategory, {
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  }) async {
    try {
      final updatedProduct = await remoteDataSource.updateCategory(
        id,
        mainCategory,
        subCategoryName: subCategoryName,
        subCategoryImage: subCategoryImage,
        subCategoryId: subCategoryId,
      );
      return Right(updatedProduct);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> addCategory({
    required String title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
  }) async {
    try {
      final category = await remoteDataSource.addCategory(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        imageUrl: imageUrl,
        profitPercentage: profitPercentage,
      );
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> updateCategoryItem({
    required String id,
    String? title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
    bool resetProfitPercentage = false,
  }) async {
    try {
      final category = await remoteDataSource.updateCategoryItem(
        id: id,
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        imageUrl: imageUrl,
        profitPercentage: profitPercentage,
        resetProfitPercentage: resetProfitPercentage,
      );
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> bulkUpdateCategory({
    required List<String> productIds,
    required String mainCategory,
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  }) async {
    try {
      final count = await remoteDataSource.bulkUpdateCategory(
        productIds: productIds,
        mainCategory: mainCategory,
        subCategoryName: subCategoryName,
        subCategoryImage: subCategoryImage,
        subCategoryId: subCategoryId,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> bulkUpdateVisibility({
    required List<String> productIds,
    required bool isVisible,
  }) async {
    try {
      final count = await remoteDataSource.bulkUpdateVisibility(
        productIds: productIds,
        isVisible: isVisible,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProductCustomDetails(
    String id, {
    String? name,
    String? image,
  }) async {
    try {
      final product = await remoteDataSource.updateProductCustomDetails(
        id,
        name: name,
        image: image,
      );
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> revertProductCustomDetails(
    String id, {
    bool revertName = true,
    bool revertImage = true,
  }) async {
    try {
      final product = await remoteDataSource.revertProductCustomDetails(
        id,
        revertName: revertName,
        revertImage: revertImage,
      );
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}


