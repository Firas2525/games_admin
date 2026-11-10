import 'package:dio/dio.dart';
import 'package:games_admin/core/network/api_client.dart';
import 'package:games_admin/core/network/api_response.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import '../models/product_model.dart';
import '../models/category_item_model.dart';
import '../../domain/repositories/admin_products_repository.dart';
import 'admin_products_local_data_source.dart';

abstract class AdminProductsRemoteDataSource {
  Future<AdminProductsResult> getProducts({
    String? source,
    String? category,
    String? search,
    bool? isVisible,
  });

  Future<String> syncFromProviders();

  Future<ProductModel> toggleVisibility(String id);

  Future<List<CategoryItemModel>> getCategories();

  Future<CategoryItemModel> addCategory({
    required String title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
  });

  Future<CategoryItemModel> updateCategoryItem({
    required String id,
    String? title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
    bool resetProfitPercentage = false,
  });

  Future<ProductModel> updateCategory(
    String id,
    String mainCategory, {
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  });

  Future<void> deleteCategory(String id);

  Future<int> bulkUpdateCategory({
    required List<String> productIds,
    required String mainCategory,
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  });

  Future<int> bulkUpdateVisibility({
    required List<String> productIds,
    required bool isVisible,
  });

  Future<ProductModel> updateProductCustomDetails(
    String id, {
    String? name,
    String? image,
  });

  Future<ProductModel> revertProductCustomDetails(
    String id, {
    bool revertName = true,
    bool revertImage = true,
  });
}

class AdminProductsRemoteDataSourceImpl
    implements AdminProductsRemoteDataSource {
  final ApiClient apiClient;
  final AdminProductsLocalDataSource? localDataSource;

  AdminProductsRemoteDataSourceImpl({
    required this.apiClient,
    this.localDataSource,
  });

  @override
  Future<AdminProductsResult> getProducts({
    String? source,
    String? category,
    String? search,
    bool? isVisible,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (source != null && source.isNotEmpty && source != 'all') {
        queryParams['source'] = source;
      }
      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isVisible != null) {
        queryParams['isVisible'] = isVisible.toString();
      }

      final response = await apiClient.get(
        '/products/admin',
        queryParameters: queryParams,
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        final pData = apiRes.data!;
        final rawList = pData['products'] as List<dynamic>? ?? [];
        final products = rawList
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        final categories = (pData['categories'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final sources = (pData['sources'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final totalCount =
            (pData['totalCount'] as num?)?.toInt() ?? products.length;

        final result = AdminProductsResult(
          products: products,
          categories: categories,
          sources: sources,
          totalCount: totalCount,
        );

        if (queryParams.isEmpty && localDataSource != null) {
          localDataSource!.cacheProducts(pData, result);
        }

        return result;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      // ignore: avoid_print
      print('❌ [getProducts DioException]: $msg');
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [getProducts Unexpected Error]: $e\n$stack');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> syncFromProviders() async {
    try {
      // ignore: avoid_print
      print('🔄 [syncFromProviders] بدء طلب المزامنة من المزودين الخارجيين...');
      final response = await apiClient.post(
        '/products/sync',
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        final total = apiRes.data!['totalSynced'] ?? 0;
        final swUsd =
            apiRes.data!['royaUsdCount'] ?? apiRes.data!['swGamesCount'] ?? 0;
        final swSyp = apiRes.data!['royaSypCount'] ?? 0;
        final brand1 = apiRes.data!['brand1CardCount'] ?? 0;
        final resultMsg =
            'تمت مزامنة $total منتج بنجاح (رؤيا دولار: $swUsd, رؤيا ليرة: $swSyp, براند كارد: $brand1)';
        // ignore: avoid_print
        print('✅ [syncFromProviders]: $resultMsg');
        return resultMsg;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      // ignore: avoid_print
      print('❌ [syncFromProviders DioException]: $msg');
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [syncFromProviders Unexpected Error]: $e\n$stack');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> toggleVisibility(String id) async {
    try {
      final response = await apiClient.patch('/products/$id/toggle-visibility');
      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => ProductModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      // ignore: avoid_print
      print('❌ [toggleVisibility DioException]: $msg');
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [toggleVisibility Unexpected Error]: $e\n$stack');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> updateCategory(
    String id,
    String mainCategory, {
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  }) async {
    try {
      final payload = <String, dynamic>{'mainCategory': mainCategory};
      if (subCategoryName != null && subCategoryName.isNotEmpty) {
        payload['subCategoryName'] = subCategoryName;
        payload['category'] = subCategoryName;
      }
      if (subCategoryImage != null && subCategoryImage.isNotEmpty) {
        payload['subCategoryImage'] = subCategoryImage;
      }
      if (subCategoryId != null && subCategoryId.isNotEmpty) {
        payload['subCategoryId'] = subCategoryId;
      } else {
        payload['clearSubCategory'] = true;
      }

      final response = await apiClient.patch(
        '/products/$id/category',
        data: payload,
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        return ProductModel.fromJson(apiRes.data!);
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CategoryItemModel>> getCategories() async {
    try {
      final response = await apiClient.get('/products/categories');
      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => (data as List<dynamic>)
            .map((e) => CategoryItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (apiRes.success && apiRes.data != null) {
        if (localDataSource != null &&
            response.data != null &&
            response.data['data'] is List) {
          localDataSource!.cacheCategories(
            response.data['data'] as List<dynamic>,
          );
        }
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CategoryItemModel> addCategory({
    required String title,
    String? subtitle,
    String? icon,
    String? color,
    String? imageUrl,
    double? profitPercentage,
  }) async {
    try {
      final response = await apiClient.post(
        '/products/categories',
        data: {
          'title': title,
          if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          'profitPercentage': ?profitPercentage,
        },
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => CategoryItemModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CategoryItemModel> updateCategoryItem({
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
      final response = await apiClient.patch(
        '/products/categories/$id',
        data: {
          if (title != null && title.isNotEmpty) 'title': title,
          if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          'profitPercentage': ?profitPercentage,
          if (resetProfitPercentage) 'profitPercentage': null,
        },
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => CategoryItemModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final response = await apiClient.delete('/products/categories/$id');
      final apiRes = ApiResponse.fromJson(response.data, (_) => null);
      if (!apiRes.success) {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<int> bulkUpdateCategory({
    required List<String> productIds,
    required String mainCategory,
    String? subCategoryName,
    String? subCategoryImage,
    String? subCategoryId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'productIds': productIds,
        'mainCategory': mainCategory,
      };
      if (subCategoryName != null && subCategoryName.isNotEmpty) {
        payload['subCategoryName'] = subCategoryName;
        payload['category'] = subCategoryName;
      }
      if (subCategoryImage != null && subCategoryImage.isNotEmpty) {
        payload['subCategoryImage'] = subCategoryImage;
      }
      if (subCategoryId != null && subCategoryId.isNotEmpty) {
        payload['subCategoryId'] = subCategoryId;
      } else {
        payload['clearSubCategory'] = true;
      }

      final response = await apiClient.patch(
        '/products/bulk-category',
        data: payload,
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        return (apiRes.data!['modifiedCount'] as num?)?.toInt() ??
            productIds.length;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<int> bulkUpdateVisibility({
    required List<String> productIds,
    required bool isVisible,
  }) async {
    try {
      final response = await apiClient.patch(
        '/products/bulk-visibility',
        data: {'productIds': productIds, 'isVisible': isVisible},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        return (apiRes.data!['modifiedCount'] as num?)?.toInt() ??
            productIds.length;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> updateProductCustomDetails(
    String id, {
    String? name,
    String? image,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (image != null) data['image'] = image;

      final response = await apiClient.patch(
        '/products/$id/custom-details',
        data: data,
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> revertProductCustomDetails(
    String id, {
    bool revertName = true,
    bool revertImage = true,
  }) async {
    try {
      final response = await apiClient.post(
        '/products/$id/revert-custom-details',
        data: {
          'revertName': revertName,
          'revertImage': revertImage,
        },
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final msg = _extractDioError(e);
      throw ServerException(message: msg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  String _extractDioError(DioException e) {
    if (e.error is ServerException) {
      final s = (e.error as ServerException).message;
      if (s.isNotEmpty &&
          !s.toLowerCase().contains('timeout') &&
          !s.toLowerCase().contains('connection') &&
          !s.contains('مهلة')) {
        return s;
      }
      return 'حدث خطأ';
    }
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      final raw = e.response!.data['message'].toString();
      if (raw.isNotEmpty &&
          !raw.toLowerCase().contains('timeout') &&
          !raw.toLowerCase().contains('connection') &&
          !raw.contains('مهلة')) {
        return raw;
      }
      return 'حدث خطأ';
    }
    return 'حدث خطأ';
  }
}
