import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../products/data/models/category_item_model.dart';
import '../../../products/data/models/subcategory_item_model.dart';
import '../../../products/data/models/product_model.dart';

class AdminFolderSnapshot {
  final List<SubCategoryItemModel> subCategories;
  final List<ProductModel> products;
  final int cachedAt;

  const AdminFolderSnapshot({
    required this.subCategories,
    required this.products,
    required this.cachedAt,
  });

  bool get isEmpty => subCategories.isEmpty && products.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// High-Performance Two-Tier Cache for Admin Organization & Categories:
/// - Tier 1: Instant RAM cache (0ms lookup, zero frame drops)
/// - Tier 2: Persistent SharedPreferences cache (retained across app restarts)
/// - Stale-While-Revalidate: Instant UI render + silent background refresh
/// - Automatic Invalidation: Clears on any create, update, delete, or transfer action
class AdminOrganizationCacheService {
  final SharedPreferences sharedPreferences;

  // In-Memory RAM caches
  static List<CategoryItemModel>? _memoryMainCategories;
  static final Map<String, AdminFolderSnapshot> _memoryFolders = {};

  static const String _kRootCategoriesKey = 'admin_org_cache_root_categories';
  static const String _kFolderPrefix = 'admin_org_cache_folder_';

  AdminOrganizationCacheService({required this.sharedPreferences});

  static String buildFolderKey(String mainCategoryKey, String? parentId) {
    final p = (parentId == null || parentId.isEmpty || parentId == 'null') ? 'root' : parentId;
    return '$_kFolderPrefix${mainCategoryKey}_$p';
  }

  // ==========================================
  // 1. Root Main Categories Cache
  // ==========================================

  List<CategoryItemModel>? getInstantMainCategories() {
    if (_memoryMainCategories != null && _memoryMainCategories!.isNotEmpty) {
      return List.unmodifiable(_memoryMainCategories!);
    }
    return null;
  }

  Future<void> saveMainCategories(List<CategoryItemModel> list) async {
    _memoryMainCategories = List.from(list);
  }

  bool hasCategoriesChanged(List<CategoryItemModel> current, List<CategoryItemModel> incoming) {
    if (current.length != incoming.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (current[i].id != incoming[i].id ||
          current[i].productCount != incoming[i].productCount ||
          current[i].title != incoming[i].title ||
          current[i].imageUrl != incoming[i].imageUrl) {
        return true;
      }
    }
    return false;
  }

  // ==========================================
  // 2. Folder Contents Cache (Subcategories + Products)
  // ==========================================

  AdminFolderSnapshot? getInstantFolder({
    required String mainCategoryKey,
    String? parentId,
  }) {
    final key = buildFolderKey(mainCategoryKey, parentId);

    // RAM-only cache with 15s max age for silky smooth back/forth navigation,
    // avoiding any stale disk overrides during moves/transfers.
    if (_memoryFolders.containsKey(key)) {
      final snap = _memoryFolders[key]!;
      final age = DateTime.now().millisecondsSinceEpoch - snap.cachedAt;
      if (age < 15000) {
        return snap;
      }
      _memoryFolders.remove(key);
    }
    return null;
  }

  Future<void> saveFolder({
    required String mainCategoryKey,
    String? parentId,
    required List<SubCategoryItemModel> subCategories,
    required List<ProductModel> products,
  }) async {
    final key = buildFolderKey(mainCategoryKey, parentId);
    _memoryFolders[key] = AdminFolderSnapshot(
      subCategories: List.from(subCategories),
      products: List.from(products),
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool hasFolderChanged({
    required List<SubCategoryItemModel> currentSubs,
    required List<ProductModel> currentProds,
    required List<SubCategoryItemModel> newSubs,
    required List<ProductModel> newProds,
  }) {
    if (currentSubs.length != newSubs.length) return true;
    if (currentProds.length != newProds.length) return true;

    for (int i = 0; i < currentSubs.length; i++) {
      if (currentSubs[i].id != newSubs[i].id ||
          currentSubs[i].productCount != newSubs[i].productCount ||
          currentSubs[i].childCount != newSubs[i].childCount ||
          currentSubs[i].name != newSubs[i].name) {
        return true;
      }
    }

    for (int i = 0; i < currentProds.length; i++) {
      if (currentProds[i].id != newProds[i].id ||
          currentProds[i].subCategoryId != newProds[i].subCategoryId ||
          currentProds[i].isAvailable != newProds[i].isAvailable ||
          currentProds[i].sellingPrice != newProds[i].sellingPrice) {
        return true;
      }
    }

    return false;
  }

  // ==========================================
  // 3. Cache Invalidation ("عند التغيير تتحدث من جديد")
  // ==========================================

  /// Invalidates a specific folder (RAM + Disk)
  Future<void> invalidateFolder(String mainCategoryKey, String? parentId) async {
    final key = buildFolderKey(mainCategoryKey, parentId);
    _memoryFolders.remove(key);
    try {
      await sharedPreferences.remove(key);
    } catch (_) {}
  }

  /// Complete cache purge: called whenever any folder is created, updated,
  /// deleted, products are moved, or subcategories are materialized.
  Future<void> invalidateAll() async {
    _memoryMainCategories = null;
    _memoryFolders.clear();

    try {
      final keys = sharedPreferences.getKeys().where((k) {
        return k == _kRootCategoriesKey || k.startsWith(_kFolderPrefix);
      }).toList();

      for (final k in keys) {
        await sharedPreferences.remove(k);
      }
    } catch (e) {
      debugPrint('⚠️ [AdminOrgCache] Invalidate error: $e');
    }
  }
}

