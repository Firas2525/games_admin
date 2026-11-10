import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_products_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/category_item_model.dart';
import 'admin_products_event.dart';
import 'admin_products_state.dart';

class AdminProductsBloc extends Bloc<AdminProductsEvent, AdminProductsState> {
  final AdminProductsRepository repository;

  AdminProductsBloc({required this.repository})
    : super(AdminProductsInitial()) {
    on<LoadAdminProductsEvent>(_onLoadProducts);
    on<SyncAdminProductsEvent>(_onSyncProducts);
    on<ToggleProductVisibilityEvent>(_onToggleVisibility);
    on<ChangeProductMainCategoryEvent>(_onChangeMainCategory);
    on<BulkMoveCategoryEvent>(_onBulkMoveCategory);
    on<BulkToggleVisibilityEvent>(_onBulkToggleVisibility);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryItemEvent>(_onUpdateCategoryItem);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<UpdateProductCustomDetailsEvent>(_onUpdateCustomDetails);
    on<RevertProductCustomDetailsEvent>(_onRevertCustomDetails);
  }

  Future<void> _onLoadProducts(
    LoadAdminProductsEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    // 1. Immediately emit cached data if available (0ms instant warehouse display)
    AdminProductsResult? cachedData;
    List<dynamic>? cachedCats;
    try {
      cachedData = await repository.getCachedProducts();
      cachedCats = await repository.getCachedCategories();
      if (cachedData != null && cachedData.products.isNotEmpty) {
        emit(
          AdminProductsLoaded(
            products: cachedData.products,
            categories: cachedData.categories,
            sources: cachedData.sources,
            totalCount: cachedData.totalCount,
            categoryItems: (cachedCats ?? []).cast<CategoryItemModel>(),
            isSyncing: true,
          ),
        );
      } else {
        emit(AdminProductsLoading());
      }
    } catch (_) {
      emit(AdminProductsLoading());
    }

    // 2. Fetch fresh live data from Remote API in parallel for maximum speed
    final futures = await Future.wait([
      repository.getProducts(
        source: event.source,
        category: event.category,
        search: event.search,
        isVisible: event.isVisible,
      ),
      repository.getCategories(),
    ]);

    final result = futures[0] as dynamic;
    final catResult = futures[1] as dynamic;

    List<CategoryItemModel> categoryItems = [];
    catResult.fold((_) => null, (cats) {
      categoryItems = (cats as List<dynamic>).cast<CategoryItemModel>();
    });

    // 3. Emit fresh live data and update UI seamlessly
    result.fold(
      (failure) {
        if (cachedData != null && cachedData.products.isNotEmpty) {
          emit(
            AdminProductsLoaded(
              products: cachedData.products,
              categories: cachedData.categories,
              sources: cachedData.sources,
              totalCount: cachedData.totalCount,
              categoryItems: categoryItems.isNotEmpty
                  ? categoryItems
                  : (cachedCats ?? []).cast<CategoryItemModel>(),
              isSyncing: false,
            ),
          );
        } else {
          emit(AdminProductsError(message: failure.message));
        }
      },
      (data) => emit(
        AdminProductsLoaded(
          products: data.products,
          categories: data.categories,
          sources: data.sources,
          totalCount: data.totalCount,
          categoryItems: categoryItems,
          isSyncing: false,
        ),
      ),
    );
  }

  Future<void> _onSyncProducts(
    SyncAdminProductsEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    final currentList = _getCurrentProducts();
    emit(AdminProductsSyncing(currentProducts: currentList));

    final syncResult = await repository.syncFromProviders();

    await syncResult.fold(
      (failure) async => emit(
        AdminProductsError(
          message: failure.message,
          currentProducts: currentList,
        ),
      ),
      (successMsg) async {
        final reloadResult = await repository.getProducts();
        List<CategoryItemModel> categoryItems = [];
        final catResult = await repository.getCategories();
        catResult.fold(
          (_) => null,
          (cats) => categoryItems = cats.cast<CategoryItemModel>(),
        );

        reloadResult.fold(
          (failure) => emit(AdminProductsError(message: failure.message)),
          (data) => emit(
            AdminProductsLoaded(
              products: data.products,
              categories: data.categories,
              sources: data.sources,
              totalCount: data.totalCount,
              categoryItems: categoryItems,
              message: successMsg,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onToggleVisibility(
    ToggleProductVisibilityEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.toggleVisibility(event.productId);

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (updatedProduct) {
          final updatedList = currentState.products.map((p) {
            return p.id == updatedProduct.id ? updatedProduct : p;
          }).toList();

          final status = updatedProduct.isVisible
              ? 'تم إظهار العنصر في التطبيق'
              : 'تم إخفاء العنصر من التطبيق';
          emit(currentState.copyWith(products: updatedList, message: status));
        },
      );
    }
  }

  Future<void> _onChangeMainCategory(
    ChangeProductMainCategoryEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.updateProductCategory(
        event.productId,
        event.mainCategory,
        subCategoryName: event.subCategoryName,
        subCategoryImage: event.subCategoryImage,
        subCategoryId: event.subCategoryId,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (updatedProduct) {
          final updatedList = currentState.products.map((p) {
            return p.id == updatedProduct.id ? updatedProduct : p;
          }).toList();

          final mainName = _getMainCategoryName(
            event.mainCategory,
            currentState.categoryItems,
          );
          final subMsg =
              event.subCategoryName != null && event.subCategoryName!.isNotEmpty
              ? ' / ${event.subCategoryName}'
              : '';

          emit(
            currentState.copyWith(
              products: updatedList,
              message: 'تم نقل وتحديث تصنيف المنتج بنجاح ($mainName$subMsg)',
            ),
          );
        },
      );
    }
  }

  Future<void> _onBulkMoveCategory(
    BulkMoveCategoryEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.bulkUpdateCategory(
        productIds: event.productIds,
        mainCategory: event.mainCategory,
        subCategoryName: event.subCategoryName,
        subCategoryImage: event.subCategoryImage,
        subCategoryId: event.subCategoryId,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (count) {
          final targetSet = event.productIds.toSet();
          final updatedList = currentState.products.map((p) {
            if (targetSet.contains(p.id)) {
              return p.copyWith(
                mainCategory: event.mainCategory,
                category: event.subCategoryName ?? p.category,
                subCategoryName: event.subCategoryName ?? p.subCategoryName,
                subCategoryImage: event.subCategoryImage ?? p.subCategoryImage,
                subCategoryId: event.subCategoryId ?? p.subCategoryId,
              );
            }
            return p;
          }).toList();

          final destName =
              event.mainCategoryTitle ??
              _getMainCategoryName(
                event.mainCategory,
                currentState.categoryItems,
              );
          final subMsg =
              event.subCategoryName != null && event.subCategoryName!.isNotEmpty
              ? ' / ${event.subCategoryName}'
              : '';

          emit(
            currentState.copyWith(
              products: updatedList,
              message: 'تم نقل $count عنصر بنجاح إلى "$destName$subMsg"',
            ),
          );
        },
      );
    }
  }

  Future<void> _onBulkToggleVisibility(
    BulkToggleVisibilityEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.bulkUpdateVisibility(
        productIds: event.productIds,
        isVisible: event.isVisible,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (count) {
          final targetSet = event.productIds.toSet();
          final updatedList = currentState.products.map((p) {
            if (targetSet.contains(p.id)) {
              return p.copyWith(isVisible: event.isVisible);
            }
            return p;
          }).toList();

          final status = event.isVisible
              ? 'تم تفعيل $count عنصر بنجاح بالمتجر 🟢'
              : 'تم إيقاف تفعيل $count عنصر بنجاح من المتجر ⚪';
          emit(currentState.copyWith(products: updatedList, message: status));
        },
      );
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.addCategory(
        title: event.title,
        subtitle: event.subtitle,
        icon: event.icon,
        color: event.color,
        imageUrl: event.imageUrl,
        profitPercentage: event.profitPercentage,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (newCategory) {
          final updatedCategories = [
            ...currentState.categoryItems,
            newCategory as CategoryItemModel,
          ];
          emit(
            currentState.copyWith(
              categoryItems: updatedCategories,
              message: 'تم إنشاء قسم "${event.title}" بنجاح',
            ),
          );
        },
      );
    }
  }

  Future<void> _onUpdateCategoryItem(
    UpdateCategoryItemEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.updateCategoryItem(
        id: event.id,
        title: event.title,
        subtitle: event.subtitle,
        icon: event.icon,
        color: event.color,
        imageUrl: event.imageUrl,
        profitPercentage: event.profitPercentage,
        resetProfitPercentage: event.resetProfitPercentage,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (updatedCategory) {
          final updatedCat = updatedCategory as CategoryItemModel;
          final updatedCategories = currentState.categoryItems.map((c) {
            return c.id == event.id ? updatedCat : c;
          }).toList();
          emit(
            currentState.copyWith(
              categoryItems: updatedCategories,
              message: 'تم تحديث بيانات القسم بنجاح',
            ),
          );
        },
      );
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.deleteCategory(event.id);

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (_) {
          final updatedCategories = currentState.categoryItems
              .where((c) => c.id != event.id)
              .toList();
          emit(
            currentState.copyWith(
              categoryItems: updatedCategories,
              message: 'تم حذف القسم بنجاح',
            ),
          );
          add(LoadAdminProductsEvent());
        },
      );
    }
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final catResult = await repository.getCategories();
      catResult.fold((_) => null, (cats) {
        emit(
          currentState.copyWith(categoryItems: cats.cast<CategoryItemModel>()),
        );
      });
    }
  }

  Future<void> _onUpdateCustomDetails(
    UpdateProductCustomDetailsEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.updateProductCustomDetails(
        event.productId,
        name: event.name,
        image: event.image,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (updatedProduct) {
          final updatedList = currentState.products.map((p) {
            return p.id == updatedProduct.id ? updatedProduct : p;
          }).toList();
          emit(
            currentState.copyWith(
              products: updatedList,
              message: 'تم تحديث اسم وصورة المنتج بنجاح',
            ),
          );
        },
      );
    }
  }

  Future<void> _onRevertCustomDetails(
    RevertProductCustomDetailsEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    if (state is AdminProductsLoaded) {
      final currentState = state as AdminProductsLoaded;
      final result = await repository.revertProductCustomDetails(
        event.productId,
        revertName: event.revertName,
        revertImage: event.revertImage,
      );

      result.fold(
        (failure) => emit(
          AdminProductsError(
            message: failure.message,
            currentProducts: currentState.products,
          ),
        ),
        (updatedProduct) {
          final updatedList = currentState.products.map((p) {
            return p.id == updatedProduct.id ? updatedProduct : p;
          }).toList();
          emit(
            currentState.copyWith(
              products: updatedList,
              message: 'تمت استعادة الاسم والصورة الأصلية من المزود',
            ),
          );
        },
      );
    }
  }

  String _getMainCategoryName(
    String mc, [
    List<CategoryItemModel> categories = const [],
  ]) {
    for (final c in categories) {
      if (c.key == mc) return c.title;
    }
    switch (mc.toLowerCase()) {
      case 'apps':
        return 'تطبيقات';
      case 'social':
        return 'خدمات سوشل ميديا';
      case 'subscriptions':
        return 'اشتراكات';
      case 'numbers':
        return 'أرقام';
      case 'cards':
        return 'بطاقات';
      case 'payment':
        return 'دفع إلكتروني';
      case 'games':
      default:
        return 'ألعاب';
    }
  }

  List<ProductEntity> _getCurrentProducts() {
    if (state is AdminProductsLoaded) {
      return (state as AdminProductsLoaded).products;
    } else if (state is AdminProductsSyncing) {
      return (state as AdminProductsSyncing).currentProducts;
    } else if (state is AdminProductsError &&
        (state as AdminProductsError).currentProducts != null) {
      return (state as AdminProductsError).currentProducts!;
    }
    return [];
  }
}
