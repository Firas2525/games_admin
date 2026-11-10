import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/category_item_model.dart';
import '../../domain/repositories/admin_products_repository.dart';

abstract class AdminProductsLocalDataSource {
  Future<AdminProductsResult?> getCachedProducts();
  Future<void> cacheProducts(Map<String, dynamic> rawJson, [AdminProductsResult? preParsed]);
  Future<List<CategoryItemModel>?> getCachedCategories();
  Future<void> cacheCategories(List<dynamic> rawJson);
}

class AdminProductsLocalDataSourceImpl implements AdminProductsLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _productsCacheKey = 'admin_products_cache_raw_v1';
  static const String _categoriesCacheKey = 'admin_categories_cache_raw_v1';

  // Fast in-memory cache for instant switching between tabs/pages
  static AdminProductsResult? _inMemoryProducts;
  static List<CategoryItemModel>? _inMemoryCategories;

  AdminProductsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<AdminProductsResult?> getCachedProducts() async {
    // 1. Return in-memory cache if available (0ms)
    if (_inMemoryProducts != null && _inMemoryProducts!.products.isNotEmpty) {
      return _inMemoryProducts;
    }

    // 2. Read from SharedPreferences
    try {
      final rawString = sharedPreferences.getString(_productsCacheKey);
      if (rawString != null && rawString.isNotEmpty) {
        final decoded = jsonDecode(rawString) as Map<String, dynamic>;
        final rawList = decoded['products'] as List<dynamic>? ?? [];
        final products = rawList
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        final categories = (decoded['categories'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final sources = (decoded['sources'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final totalCount = (decoded['totalCount'] as num?)?.toInt() ?? products.length;

        _inMemoryProducts = AdminProductsResult(
          products: products,
          categories: categories,
          sources: sources,
          totalCount: totalCount,
        );
        return _inMemoryProducts;
      }
    } catch (e) {
      // In case of parsing error, return null to fallback to remote
    }

    return null;
  }

  @override
  Future<void> cacheProducts(Map<String, dynamic> rawJson, [AdminProductsResult? preParsed]) async {
    try {
      if (preParsed != null) {
        _inMemoryProducts = preParsed;
      } else {
        final rawList = rawJson['products'] as List<dynamic>? ?? [];
        final products = rawList
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        final categories = (rawJson['categories'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final sources = (rawJson['sources'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final totalCount = (rawJson['totalCount'] as num?)?.toInt() ?? products.length;

        _inMemoryProducts = AdminProductsResult(
          products: products,
          categories: categories,
          sources: sources,
          totalCount: totalCount,
        );
      }
    } catch (_) {}
  }

  @override
  Future<List<CategoryItemModel>?> getCachedCategories() async {
    if (_inMemoryCategories != null && _inMemoryCategories!.isNotEmpty) {
      return _inMemoryCategories;
    }

    try {
      final rawString = sharedPreferences.getString(_categoriesCacheKey);
      if (rawString != null && rawString.isNotEmpty) {
        final decoded = jsonDecode(rawString) as List<dynamic>;
        _inMemoryCategories = decoded
            .map((e) => CategoryItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return _inMemoryCategories;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> cacheCategories(List<dynamic> rawJson) async {
    try {
      _inMemoryCategories = rawJson
          .map((e) => CategoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await sharedPreferences.setString(_categoriesCacheKey, jsonEncode(rawJson));
    } catch (_) {}
  }
}

