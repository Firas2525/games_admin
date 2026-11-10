import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/admin_product_artwork.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../products/data/models/category_item_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/subcategory_item_model.dart';
import '../../../products/presentation/widgets/admin_folder_move_dialog.dart';
import '../../data/datasources/admin_organization_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_categories_page.dart';

class AdminOrganizationPage extends StatefulWidget {
  const AdminOrganizationPage({super.key});

  @override
  State<AdminOrganizationPage> createState() => _AdminOrganizationPageState();
}

class _AdminOrganizationPageState extends State<AdminOrganizationPage> {
  late final AdminOrganizationCacheService _cacheService;
  bool _isLoading = true;
  String? _errorMessage;

  // Hierarchical Folder Navigation
  List<CategoryItemModel> _mainCategories = [];
  CategoryItemModel? _currentMainCategory;
  final List<SubCategoryItemModel> _breadcrumbs = [];
  List<SubCategoryItemModel> _currentSubCategories = [];
  List<ProductModel> _currentProducts = [];

  // Selection Mode (activated via long-press on items)
  final Set<String> _selectedProductIds = {};
  bool get _isSelectionActive => _selectedProductIds.isNotEmpty;

  // Transfer / Move Mode (like Android cut & paste/move)
  bool _isMoveMode = false;
  List<String> _stagedProductIds = [];
  bool _isExecutingMove = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cacheService = AdminOrganizationCacheService(
      sharedPreferences: sl<SharedPreferences>(),
    );
    _loadMainCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMainCategories({bool forceRefresh = false}) async {
    // 1. Instant Cache Render (0ms lookup)
    if (!forceRefresh) {
      final cached = _cacheService.getInstantMainCategories();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _mainCategories = cached;
          _currentMainCategory = null;
          _breadcrumbs.clear();
          _currentSubCategories = [];
          _currentProducts = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }

    if (_mainCategories.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.get('/products/categories', queryParameters: {'admin': 'true'});
      if (res.data != null && res.data['data'] is List) {
        final list = (res.data['data'] as List)
            .map((e) => CategoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        await _cacheService.saveMainCategories(list);

        if (mounted) {
          final changed = _cacheService.hasCategoriesChanged(_mainCategories, list);
          if (changed || _isLoading || _mainCategories.isEmpty) {
            setState(() {
              _mainCategories = list;
              _currentMainCategory = null;
              _breadcrumbs.clear();
              _currentSubCategories = [];
              _currentProducts = [];
              _isLoading = false;
              _errorMessage = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && _mainCategories.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل الأقسام: $e';
        });
      }
    }
  }

  Future<void> _loadFolderContents({
    required String mainCategoryKey,
    String? parentSubCategoryId,
    bool forceRefresh = false,
  }) async {
    // 1. Instant Cache Render for Folder Contents (0ms lookup)
    if (!forceRefresh) {
      final cached = _cacheService.getInstantFolder(
        mainCategoryKey: mainCategoryKey,
        parentId: parentSubCategoryId,
      );
      if (cached != null && (cached.subCategories.isNotEmpty || cached.products.isNotEmpty)) {
        setState(() {
          _currentSubCategories = cached.subCategories;
          _currentProducts = cached.products;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }

    final hasData = _currentSubCategories.isNotEmpty || _currentProducts.isNotEmpty;
    if (!hasData) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dio = sl<ApiClient>().dio;

      // 1. Fetch child subcategories (folders)
      final subParams = <String, dynamic>{
        'mainCategory': mainCategoryKey,
        'admin': 'true',
      };
      if (parentSubCategoryId != null) {
        subParams['parentId'] = parentSubCategoryId;
      } else {
        subParams['parentId'] = 'root';
      }

      final subRes = await dio.get('/products/subcategories', queryParameters: subParams);
      List<SubCategoryItemModel> subList = [];
      if (subRes.data != null && subRes.data['data'] is List) {
        subList = (subRes.data['data'] as List)
            .map((e) => SubCategoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // 2. Fetch products inside this current folder
      final prodParams = <String, dynamic>{
        'limit': 500,
      };
      if (parentSubCategoryId != null && parentSubCategoryId.isNotEmpty) {
        prodParams['subCategoryId'] = parentSubCategoryId;
      } else {
        prodParams['mainCategory'] = mainCategoryKey;
        prodParams['subCategoryId'] = 'root';
      }

      final prodRes = await dio.get('/products/admin', queryParameters: prodParams);
      List<ProductModel> prodList = [];
      if (prodRes.data != null && prodRes.data['data'] != null && prodRes.data['data']['products'] is List) {
        final rawProds = prodRes.data['data']['products'] as List;
        prodList = rawProds
            .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) {
            final pComp = a.price.compareTo(b.price);
            if (pComp != 0) return pComp;
            return a.name.compareTo(b.name);
          });
      }

      await _cacheService.saveFolder(
        mainCategoryKey: mainCategoryKey,
        parentId: parentSubCategoryId,
        subCategories: subList,
        products: prodList,
      );

      if (mounted) {
        final changed = _cacheService.hasFolderChanged(
          currentSubs: _currentSubCategories,
          currentProds: _currentProducts,
          newSubs: subList,
          newProds: prodList,
        );

        if (changed || _isLoading || !hasData) {
          setState(() {
            _currentSubCategories = subList;
            _currentProducts = prodList;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted && !hasData) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل محتويات المجلد: $e';
        });
      }
    }
  }

  void _enterMainCategory(CategoryItemModel cat) {
    _searchController.clear();
    setState(() {
      _currentMainCategory = cat;
      _breadcrumbs.clear();
      _currentSubCategories = [];
      _currentProducts = [];
      _isLoading = true;
    });
    _loadFolderContents(mainCategoryKey: cat.key, parentSubCategoryId: null);
  }

  void _enterSubCategory(SubCategoryItemModel subCat) {
    _searchController.clear();
    setState(() {
      _breadcrumbs.add(subCat);
      _currentSubCategories = [];
      _currentProducts = [];
      _isLoading = true;
    });
    _loadFolderContents(
      mainCategoryKey: subCat.mainCategory,
      parentSubCategoryId: subCat.id,
    );
  }

  void _navigateUp() {
    _searchController.clear();
    if (_breadcrumbs.isNotEmpty) {
      setState(() {
        _breadcrumbs.removeLast();
      });
      final parentId = _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null;
      _loadFolderContents(
        mainCategoryKey: _currentMainCategory!.key,
        parentSubCategoryId: parentId,
      );
    } else if (_currentMainCategory != null) {
      _loadMainCategories();
    }
  }

  void _jumpToBreadcrumbIndex(int index) {
    _searchController.clear();
    if (index < 0) {
      _loadMainCategories();
    } else if (index == 0 && _breadcrumbs.isEmpty) {
      // Already at main category root
    } else {
      final targetSub = _breadcrumbs[index];
      setState(() {
        _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      });
      _loadFolderContents(
        mainCategoryKey: targetSub.mainCategory,
        parentSubCategoryId: targetSub.id,
      );
    }
  }

  // Long press selection handler
  void _onProductLongPress(ProductModel p) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedProductIds.contains(p.id)) {
        _selectedProductIds.remove(p.id);
      } else {
        _selectedProductIds.add(p.id);
      }
    });
  }

  void _onProductTap(ProductModel p) {
    if (_isSelectionActive) {
      HapticFeedback.selectionClick();
      setState(() {
        if (_selectedProductIds.contains(p.id)) {
          _selectedProductIds.remove(p.id);
        } else {
          _selectedProductIds.add(p.id);
        }
      });
    } else {
      _showEditProductDetailsDialog(p);
    }
  }

  void _showEditProductDetailsDialog(ProductModel product) {
    final nameCtrl = TextEditingController(text: product.name);
    final imageCtrl = TextEditingController(text: product.image);
    String previewImageUrl = product.image;
    bool isSaving = false;
    bool isUploadingImage = false;

    Future<void> pickAndUploadImage(void Function(void Function()) setDlgState) async {
      try {
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 85,
        );
        if (file == null) return;
        setDlgState(() => isUploadingImage = true);

        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        try {
          final dio = sl<ApiClient>().dio;
          final res = await dio.post('/banners/upload', data: {
            'file': base64String,
            'uploadPreset': 'ml_default',
          });
          if (res.data != null && res.data['data'] != null) {
            final uploadedUrl = res.data['data']['url']?.toString();
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              imageCtrl.text = uploadedUrl;
              previewImageUrl = uploadedUrl;
            } else {
              imageCtrl.text = base64String;
              previewImageUrl = base64String;
            }
          } else {
            imageCtrl.text = base64String;
            previewImageUrl = base64String;
          }
        } catch (_) {
          imageCtrl.text = base64String;
          previewImageUrl = base64String;
        } finally {
          setDlgState(() => isUploadingImage = false);
        }
      } catch (_) {
        setDlgState(() => isUploadingImage = false);
      }
    }

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تعديل اسم وصورة المنتج',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المزود: ${product.sourceName}',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AdminProductArtworkWidget(
                              imageUrl: previewImageUrl,
                              title: nameCtrl.text.isNotEmpty ? nameCtrl.text : product.name,
                              category: product.category,
                              mainCategory: product.mainCategory,
                              width: 90,
                              height: 90,
                            ),
                          ),
                        ),
                        if (isUploadingImage)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF38BDF8)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: isUploadingImage ? null : () => pickAndUploadImage(setDlgState),
                      icon: isUploadingImage
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        isUploadingImage ? 'جاري رفع الصورة...' : 'رفع صورة من المعرض 🖼️',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('اسم المنتج المعروض للعملاء:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'أدخل اسم المنتج',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF38BDF8), size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أو رابط الصورة المباشر (URL):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      if (imageCtrl.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            imageCtrl.clear();
                            setDlgState(() => previewImageUrl = '');
                          },
                          child: const Text('مسح الرابط', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: (val) {
                      setDlgState(() {
                        previewImageUrl = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'https://example.com/image.png',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF38BDF8), size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (product.isNameOverridden || product.isImageOverridden) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 15, color: Colors.amber),
                              SizedBox(width: 6),
                              Text('بيانات المزود الأصلية:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                          if (product.providerName != null && product.providerName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الاسم الأصلي: ${product.providerName}',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber,
                                side: const BorderSide(color: Colors.amber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('استعادة وتجاهل التعديلات 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: isSaving ? null : () async {
                                setDlgState(() => isSaving = true);
                                try {
                                  final res = await sl<ApiClient>().post(
                                    '/products/${product.id}/revert-custom-details',
                                    data: {'revertName': true, 'revertImage': true},
                                  );
                                  final updatedJson = res.data['data'] as Map<String, dynamic>;
                                  final updatedModel = ProductModel.fromJson(updatedJson);

                                  final idx = _currentProducts.indexWhere((p) => p.id == product.id);
                                  if (idx != -1) {
                                    setState(() {
                                      _currentProducts[idx] = updatedModel;
                                    });
                                    await _cacheService.invalidateAll();
                                  }
                                  if (mounted) {
                                    Navigator.pop(dlgCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تمت استعادة الاسم والصورة الأصلية من المزود بنجاح 🔄'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDlgState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('فشلت الاستعادة: $e'), backgroundColor: const Color(0xFFEF4444)),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: isSaving ? null : () async {
                  final newName = nameCtrl.text.trim();
                  final newImg = imageCtrl.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم المنتج'), backgroundColor: Color(0xFFEF4444)),
                    );
                    return;
                  }

                  setDlgState(() => isSaving = true);
                  try {
                    final res = await sl<ApiClient>().patch(
                      '/products/${product.id}/custom-details',
                      data: {'name': newName, 'image': newImg},
                    );
                    final updatedJson = res.data['data'] as Map<String, dynamic>;
                    final updatedModel = ProductModel.fromJson(updatedJson);

                    final idx = _currentProducts.indexWhere((p) => p.id == product.id);
                    if (idx != -1) {
                      setState(() {
                        _currentProducts[idx] = updatedModel;
                      });
                      await _cacheService.invalidateAll();
                    }
                    if (mounted) {
                      Navigator.pop(dlgCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث اسم وصورة المنتج بنجاح ✏️'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    setDlgState(() => isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: const Color(0xFFEF4444)),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTransferMode() {
    if (_selectedProductIds.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _stagedProductIds = _selectedProductIds.toList();
      _selectedProductIds.clear();
      _isMoveMode = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✂️ تم تجهيز ${_stagedProductIds.length} عنصر للنقل. تنقل إلى أي مجلد واضغط "انقل هنا".'),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _cancelTransferMode() {
    setState(() {
      _isMoveMode = false;
      _stagedProductIds.clear();
    });
  }

  Future<void> _executeMoveHere() async {
    if (!_isMoveMode || _stagedProductIds.isEmpty || _currentMainCategory == null) return;

    final targetSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
    final targetMainCatKey = _currentMainCategory!.key;

    setState(() => _isExecutingMove = true);
    try {
      final dio = sl<ApiClient>().dio;
      final payload = <String, dynamic>{
        'productIds': _stagedProductIds,
        'mainCategory': targetMainCatKey,
      };

      if (targetSub != null) {
        payload['subCategoryId'] = targetSub.id;
        payload['subCategoryName'] = targetSub.name;
        payload['subCategoryImage'] = targetSub.imageUrl;
      } else {
        payload['clearSubCategory'] = true;
      }

      await dio.patch('/products/bulk-category', data: payload);
      await _cacheService.invalidateAll();

      final count = _stagedProductIds.length;
      final targetTitle = targetSub != null ? targetSub.name : _currentMainCategory!.title;

      setState(() {
        _isMoveMode = false;
        _stagedProductIds.clear();
        _isExecutingMove = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم نقل $count عنصر بنجاح إلى: $targetTitle'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh folder with forceRefresh
        _loadFolderContents(
          mainCategoryKey: _currentMainCategory!.key,
          parentSubCategoryId: targetSub?.id,
          forceRefresh: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExecutingMove = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل نقل العناصر: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSubCategoryDialog({SubCategoryItemModel? existingSub}) {
    if (_currentMainCategory == null) return;

    final isEdit = existingSub != null;
    final nameController = TextEditingController(text: existingSub?.name ?? '');
    String imageUrl = existingSub?.imageUrl ?? '';
    Uint8List? pickedBytes;
    bool isUploading = false;
    bool isSubmitting = false;
    final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 800,
                maxHeight: 800,
                imageQuality: 85,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              setDlgState(() {
                pickedBytes = bytes;
                isUploading = true;
              });

              final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              try {
                final dio = sl<ApiClient>().dio;
                final res = await dio.post('/banners/upload', data: {
                  'file': base64String,
                  'uploadPreset': 'ml_default',
                });
                if (res.data != null && res.data['data'] != null) {
                  imageUrl = res.data['data']['url']?.toString() ?? base64String;
                }
              } catch (_) {
                imageUrl = base64String;
              } finally {
                setDlgState(() => isUploading = false);
              }
            } catch (_) {
              setDlgState(() => isUploading = false);
            }
          }

          Future<void> submit() async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('يرجى إدخال اسم المجلد / الكاتيغوري')),
              );
              return;
            }

            setDlgState(() => isSubmitting = true);

            try {
              final dio = sl<ApiClient>().dio;
              if (isEdit) {
                final payload = <String, dynamic>{
                  'name': name,
                  'imageUrl': imageUrl,
                };
                await dio.patch('/products/subcategories/${existingSub.id}', data: payload);
              } else {
                final payload = <String, dynamic>{
                  'mainCategory': _currentMainCategory!.key,
                  'name': name,
                  'imageUrl': imageUrl,
                  if (parentSub != null) 'parentId': parentSub.id,
                };
                await dio.post('/products/subcategories', data: payload);
              }

              await _cacheService.invalidateAll();

              if (ctx.mounted) Navigator.pop(dlgCtx);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? '✅ تم تحديث المجلد بنجاح' : '✅ تم إنشاء المجلد: $name'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                _loadFolderContents(
                  mainCategoryKey: _currentMainCategory!.key,
                  parentSubCategoryId: parentSub?.id,
                  forceRefresh: true,
                );
              }
            } catch (e) {
              setDlgState(() => isSubmitting = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل حفظ المجلد: $e'), backgroundColor: Colors.redAccent),
                );
              }
            }
          }

          final parentTitle = parentSub != null ? parentSub.name : _currentMainCategory!.title;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                            color: const Color(0xFF38BDF8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'تعديل بيانات المجلد' : 'إنشاء مجلد فرعي جديد',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'المسار: $parentTitle',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                          onPressed: isSubmitting ? null : () => Navigator.pop(dlgCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Folder Name Input
                    const Text('اسم المجلد / الكاتيغوري *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: !isEdit,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'مثال: باقات التوفير، شدات فورية...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        prefixIcon: const Icon(Icons.folder_outlined, color: Color(0xFF38BDF8), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Image Section
                    const Text('صورة المجلد (اختياري)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: isUploading
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                                  ),
                                  SizedBox(height: 6),
                                  Text('جارٍ رفع الصورة...', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            )
                          : (pickedBytes != null || imageUrl.isNotEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 68,
                                          height: 68,
                                          child: pickedBytes != null
                                              ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                                              : AppNetworkImage(imageUrl, fit: BoxFit.cover),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'تم اختيار الصورة بنجاح',
                                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                InkWell(
                                                  onTap: pickImage,
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF38BDF8)),
                                                        SizedBox(width: 4),
                                                        Text('تغيير', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () {
                                                    setDlgState(() {
                                                      pickedBytes = null;
                                                      imageUrl = '';
                                                    });
                                                  },
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline, size: 13, color: Colors.redAccent),
                                                        SizedBox(width: 4),
                                                        Text('إزالة', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : InkWell(
                                  onTap: pickImage,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF38BDF8), size: 26),
                                      SizedBox(height: 4),
                                      Text('اضغط هنا لاختيار صورة من المعرض', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                    ),

                    if (isEdit && existingSub != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.drive_file_move_outlined, color: Color(0xFF10B981), size: 18),
                          label: const Text(
                            'نقل هذا المجلد مع محتوياته إلى مكان آخر ✂️',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(dlgCtx);
                            _moveSubCategory(existingSub);
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(dlgCtx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting || isUploading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    isEdit ? 'حفظ التعديلات' : 'إنشاء المجلد 🚀',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _moveSubCategory(SubCategoryItemModel subCategory) async {
    final moved = await AdminFolderMoveDialog.show(
      context,
      subCategoryIdToMove: subCategory.id,
      subCategoryNameToMove: subCategory.name,
    );
    if (moved == true && mounted) {
      await _cacheService.invalidateAll();
      final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
      if (_currentMainCategory != null) {
        _loadFolderContents(
          mainCategoryKey: _currentMainCategory!.key,
          parentSubCategoryId: parentSub?.id,
          forceRefresh: true,
        );
      } else {
        _loadMainCategories(forceRefresh: true);
      }
    }
  }

  Future<void> _deleteSubCategory(SubCategoryItemModel subCategory) async {
    // STRICT RULE: Can only delete if EMPTY!
    if (!subCategory.canDelete) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF131F35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('لا يمكن حذف المجلد', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Text(
              'لا يمكن حذف كاتيغوري "${subCategory.name}" لأنها غير فارغة.\n\nتحتوي على: ${subCategory.productCount} عنصر و ${subCategory.childCount} مجلد فرعي.\n\nيرجى تحديد العناصر ونقلها لمجلد آخر لتفريغه قبل الحذف.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً فهمت', style: TextStyle(color: Color(0xFF38BDF8))),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF131F35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('تأكيد حذف المجلد الفارغ', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف كاتيغوري "${subCategory.name}" الفارغة نهائياً؟',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف نهائياً'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final dio = sl<ApiClient>().dio;
        await dio.delete('/products/subcategories/${subCategory.id}');
        await _cacheService.invalidateAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المجلد بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
          final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
          _loadFolderContents(
            mainCategoryKey: _currentMainCategory!.key,
            parentSubCategoryId: parentSub?.id,
            forceRefresh: true,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAtRoot = _currentMainCategory == null;
    final currentTargetName = _breadcrumbs.isNotEmpty
        ? _breadcrumbs.last.name
        : (_currentMainCategory != null ? _currentMainCategory!.title : 'الرئيسية');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
              textDirection: TextDirection.ltr,
            ),
            tooltip: isAtRoot ? 'رجوع' : 'رجوع للمستوى السابق',
            onPressed: isAtRoot ? () => Navigator.pop(context) : _navigateUp,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAtRoot ? 'صفحة التنسيق' : 'مجلد: $currentTargetName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              Text(
                _isMoveMode
                    ? 'نمط النقل مفعل (${_stagedProductIds.length} عنصر)'
                    : (_isSelectionActive
                        ? 'تم تحديد ${_selectedProductIds.length} عنصر'
                        : 'اضغط مطولاً على أي عنصر لتحديده ونقله'),
                style: TextStyle(
                  color: _isMoveMode
                      ? const Color(0xFFF59E0B)
                      : (_isSelectionActive ? const Color(0xFF38BDF8) : Colors.white54),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            if (_isSelectionActive) ...[
              IconButton(
                icon: const Icon(Icons.drive_file_move_rounded, color: Color(0xFF10B981), size: 24),
                tooltip: 'نقل العناصر المحددة',
                onPressed: _startTransferMode,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                tooltip: 'إلغاء التحديد',
                onPressed: () => setState(() => _selectedProductIds.clear()),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                tooltip: 'تحديث فوري للمحتوى',
                onPressed: () async {
                  await _cacheService.invalidateAll();
                  if (isAtRoot) {
                    _loadMainCategories(forceRefresh: true);
                  } else {
                    final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
                    _loadFolderContents(
                      mainCategoryKey: _currentMainCategory!.key,
                      parentSubCategoryId: parentSub?.id,
                      forceRefresh: true,
                    );
                  }
                },
              ),
            ],
          ],
        ),
        bottomNavigationBar: _isMoveMode ? _buildTransferBottomBar(currentTargetName) : null,
        body: Column(
          children: [
            // Breadcrumbs bar
            _buildBreadcrumbsBar(isAtRoot),

            // Search Bar
            _buildSearchBar(isAtRoot, currentTargetName),

            // Main Contents Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)))
                      : isAtRoot
                          ? _buildRootCategoriesGrid()
                          : _buildFolderContentsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isAtRoot, String currentTargetName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF0B1424),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: isAtRoot
              ? 'بحث في الأقسام الرئيسية...'
              : 'بحث في مجلدات ومنتجات $currentTargetName...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF101B2E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbsBar(bool isAtRoot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: const Color(0xFF0B1424),
      child: Row(
        children: [
          if (!isAtRoot) ...[
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 18, textDirection: TextDirection.ltr),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'المستوى السابق',
              onPressed: _navigateUp,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _jumpToBreadcrumbIndex(-1),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.home_filled, size: 14, color: isAtRoot ? const Color(0xFF38BDF8) : Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'الرئيسية',
                            style: TextStyle(
                              color: isAtRoot ? const Color(0xFF38BDF8) : Colors.white70,
                              fontSize: 12,
                              fontWeight: isAtRoot ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_currentMainCategory != null) ...[
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14, textDirection: TextDirection.ltr),
                    InkWell(
                      onTap: () {
                        if (_breadcrumbs.isNotEmpty) {
                          setState(() => _breadcrumbs.clear());
                          _loadFolderContents(mainCategoryKey: _currentMainCategory!.key, parentSubCategoryId: null);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          _currentMainCategory!.title,
                          style: TextStyle(
                            color: _breadcrumbs.isEmpty ? const Color(0xFF38BDF8) : Colors.white70,
                            fontSize: 12,
                            fontWeight: _breadcrumbs.isEmpty ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                  for (int i = 0; i < _breadcrumbs.length; i++) ...[
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14, textDirection: TextDirection.ltr),
                    InkWell(
                      onTap: () => _jumpToBreadcrumbIndex(i),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          _breadcrumbs[i].name,
                          style: TextStyle(
                            color: i == _breadcrumbs.length - 1 ? const Color(0xFF38BDF8) : Colors.white70,
                            fontSize: 12,
                            fontWeight: i == _breadcrumbs.length - 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Root level: Grid of Main Categories
  Widget _buildRootCategoriesGrid() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredCategories = query.isEmpty
        ? _mainCategories
        : _mainCategories.where((c) {
            return c.title.toLowerCase().contains(query) ||
                c.key.toLowerCase().contains(query) ||
                c.subtitle.toLowerCase().contains(query);
          }).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text(
                'لا توجد أقسام مطابقة للبحث "$query"',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F172A),
      onRefresh: () async {
        await _cacheService.invalidateAll();
        await _loadMainCategories(forceRefresh: true);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final cat = filteredCategories[index];
          final catColor = cat.displayColor;

          return InkWell(
            onTap: () => _enterMainCategory(cat),
            borderRadius: BorderRadius.circular(16),
            child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101B2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: catColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: catColor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor.withValues(alpha: 0.4)),
                      ),
                      child: cat.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: AppNetworkImage(
                                cat.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(cat.displayIcon, color: catColor, size: 24),
                              ),
                            )
                          : Icon(cat.displayIcon, color: catColor, size: 24),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF07111F), borderRadius: BorderRadius.circular(6)),
                      child: Text('${cat.productCount} عنصر', style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  cat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('#${cat.key}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 12, textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // Inside Folder: Folders Grid + Products List
  Widget _buildFolderContentsView() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredSubs = query.isEmpty
        ? _currentSubCategories
        : _currentSubCategories.where((s) => s.name.toLowerCase().contains(query)).toList();
    final filteredProds = query.isEmpty
        ? _currentProducts
        : _currentProducts.where((p) {
            return p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query);
          }).toList();

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F172A),
      onRefresh: () async {
        if (_currentMainCategory != null) {
          final parentId = _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null;
          await _cacheService.invalidateFolder(_currentMainCategory!.key, parentId);
          await _loadFolderContents(
            mainCategoryKey: _currentMainCategory!.key,
            parentSubCategoryId: parentId,
            forceRefresh: true,
          );
        }
      },
      child: CustomScrollView(
      slivers: [
        // Subfolders Header & "+ مجلد فرعي جديد" & "ترتيب بالسحب"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'المجلدات الفرعية (${filteredSubs.length})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                if (filteredSubs.length > 1) ...[
                  InkWell(
                    onTap: _openReorderSubCategoriesSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 15, color: Color(0xFF38BDF8)),
                          SizedBox(width: 3),
                          Text('ترتيب', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                ElevatedButton.icon(
                  onPressed: () => _showSubCategoryDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.create_new_folder_rounded, size: 14),
                  label: const Text('+ مجلد جديد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        // Subfolders Grid with Drag and Drop Reordering
        if (filteredSubs.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sub = filteredSubs[index];
                  return _buildSubFolderDragTarget(sub, index, filteredSubs);
                },
                childCount: filteredSubs.length,
              ),
            ),
          )
        else if (query.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'لا توجد مجلدات فرعية مطابقة للبحث',
                style: TextStyle(color: Colors.white38, fontSize: 11.5),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF101B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لا توجد مجلدات فرعية مسجلة رسمياً في قاعدة البيانات لهذا القسم.',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Products Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                Text(
                  'العناصر والمنتجات المباشرة (${filteredProds.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const Spacer(),
                const Text('اضغط مطولاً للتحديد والنقل', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),

        // Products Grid / List
        if (filteredProds.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.76,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = filteredProds[index];
                  final isSelected = _selectedProductIds.contains(p.id);
                  final isStaged = _stagedProductIds.contains(p.id);

                  return InkWell(
                    onTap: () => _onProductTap(p),
                    onLongPress: () => _onProductLongPress(p),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                            : (isStaged ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFF101B2E)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF38BDF8)
                              : (isStaged ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.08)),
                          width: isSelected || isStaged ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AdminProductArtworkWidget(
                                    imageUrl: p.image,
                                    title: p.name,
                                    category: p.category,
                                    mainCategory: p.mainCategory,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(p.sellingPrice ?? p.originalPrice).toStringAsFixed(2)} ${p.currency}',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Color(0xFF0284C7),
                                child: Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                          if (isStaged)
                            const Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Color(0xFFF59E0B),
                                child: Icon(Icons.cut_rounded, size: 13, color: Colors.black),
                              ),
                            ),
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                color: (p.isNameOverridden || p.isImageOverridden)
                                    ? Colors.amber.withValues(alpha: 0.9)
                                    : Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: (p.isNameOverridden || p.isImageOverridden)
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredProds.length,
              ),
            ),
          )
        else if (query.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Text('لا توجد منتجات مطابقة للبحث', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 40),
                    const SizedBox(height: 8),
                    const Text('لا توجد عناصر مباشرة في هذا المستوى', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    if (_isMoveMode) ...[
                      const SizedBox(height: 10),
                      Text('يمكنك الضغط على "انقل هنا" بالأسفل لنقل العناصر لهذا المجلد.', style: TextStyle(color: const Color(0xFF38BDF8), fontSize: 11.5)),
                    ],
                  ],
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    ),
  );
}

  Widget _buildSubFolderDragTarget(SubCategoryItemModel sub, int index, List<SubCategoryItemModel> list) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) async {
        final fromIndex = details.data;
        final toIndex = index;
        if (fromIndex == toIndex) return;

        final draggedSub = list[fromIndex];
        final targetSub = list[toIndex];
        final realFrom = _currentSubCategories.indexWhere((s) => s.id == draggedSub.id);
        final realTo = _currentSubCategories.indexWhere((s) => s.id == targetSub.id);

        if (realFrom != -1 && realTo != -1 && realFrom != realTo) {
          setState(() {
            final moved = _currentSubCategories.removeAt(realFrom);
            _currentSubCategories.insert(realTo, moved);
          });
          HapticFeedback.mediumImpact();
          await _saveSubCategoriesOrder();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 200),
          onDragStarted: () => HapticFeedback.heavyImpact(),
          feedback: Material(
            color: Colors.transparent,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 38) / 2,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131F35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildSubFolderCard(sub, isDraggingFeedback: true),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.28,
            child: _buildSubFolderCard(sub),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isHovered
                  ? Border.all(color: const Color(0xFF38BDF8), width: 2)
                  : null,
            ),
            child: _buildSubFolderCard(sub),
          ),
        );
      },
    );
  }

  Future<void> _saveSubCategoriesOrder() async {
    try {
      final dio = sl<ApiClient>().dio;
      final items = _currentSubCategories.asMap().entries.map((e) {
        return {
          'id': e.value.id,
          'sortOrder': e.key,
        };
      }).toList();

      await dio.patch('/products/subcategories/reorder', data: {
        'items': items,
      });

      // Update local organization cache
      if (_currentMainCategory != null) {
        final parentId = _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null;
        await _cacheService.saveFolder(
          mainCategoryKey: _currentMainCategory!.id,
          parentId: parentId,
          subCategories: _currentSubCategories,
          products: _currentProducts,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ ترتيب المجلدات بنجاح وتطبيقه للمستخدمين'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ الترتيب: $e ❌'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openReorderSubCategoriesSheet() {
    if (_currentSubCategories.isEmpty) return;
    final List<SubCategoryItemModel> reorderList = List.from(_currentSubCategories);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
              ),
              child: Column(
                children: [
                  // Handle pill
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إعادة ترتيب المجلدات الفرعية',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'اضغط مطولاً واسحب المجلد للأعلى أو للأسفل لتغيير موقعه',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  // Reorderable List
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: reorderList.length,
                      onReorder: (oldIndex, newIndex) {
                        setSheetState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = reorderList.removeAt(oldIndex);
                          reorderList.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = reorderList[index];
                        return Container(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131F35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: AppNetworkImage(item.imageUrl, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.folder_rounded, color: Color(0xFF38BDF8), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.drag_handle_rounded, color: Colors.white54, size: 22),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              setState(() {
                                _currentSubCategories = List.from(reorderList);
                              });
                              await _saveSubCategoriesOrder();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isSaving ? 'جارٍ حفظ الترتيب...' : 'حفظ وتطبيق الترتيب الجديد',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubFolderCard(SubCategoryItemModel sub, {bool isDraggingFeedback = false}) {
    final isNewItems = sub.name == 'العناصر الجديدة';
    return InkWell(
      onTap: isDraggingFeedback ? null : () => _enterSubCategory(sub),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isNewItems ? const Color(0xFF1B1914) : const Color(0xFF101B2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNewItems ? const Color(0xFFF59E0B) : const Color(0xFF0284C7).withValues(alpha: 0.3),
            width: isNewItems ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isNewItems ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isNewItems
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : const Color(0xFF0284C7).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isNewItems
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                          : const Color(0xFF0284C7).withValues(alpha: 0.35),
                    ),
                  ),
                  child: sub.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            sub.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              isNewItems ? Icons.new_releases_rounded : Icons.folder_rounded,
                              color: isNewItems ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          isNewItems ? Icons.new_releases_rounded : Icons.folder_rounded,
                          color: isNewItems ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                          size: 20,
                        ),
                ),
                const Spacer(),
                if (isNewItems) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: const Text('جديد', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                ],
                if (!isDraggingFeedback) ...[
                  const Icon(Icons.drag_indicator_rounded, color: Colors.white24, size: 16),
                  const SizedBox(width: 2),
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: const Color(0xFF131F35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 18),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'خيارات المجلد',
                      onSelected: (val) {
                        switch (val) {
                          case 'move':
                            _moveSubCategory(sub);
                            break;
                          case 'edit':
                            _showSubCategoryDialog(existingSub: sub);
                            break;
                          case 'delete':
                            _deleteSubCategory(sub);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem<String>(
                          value: 'move',
                          child: Row(
                            children: [
                              Icon(Icons.drive_file_move_rounded, color: Color(0xFF10B981), size: 18),
                              SizedBox(width: 8),
                              Text('نقل المجلد بمحتوياته', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 18),
                              SizedBox(width: 8),
                              Text('تعديل المجلد', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                sub.canDelete ? Icons.delete_outline_rounded : Icons.lock_outline_rounded,
                                color: sub.canDelete ? Colors.redAccent : Colors.white30,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sub.canDelete ? 'حذف المجلد الفارغ' : 'مجلد غير فارغ (مقفل)',
                              style: TextStyle(
                                color: sub.canDelete ? Colors.redAccent : Colors.white30,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sub.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (sub.childCount > 0 && sub.productCount > 0) ...[
                      Text('${sub.productCount} عنصر', style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
                      const SizedBox(width: 4),
                      Text('• ${sub.childCount} مجلد', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5)),
                    ] else if (sub.childCount > 0) ...[
                      Text('${sub.childCount} مجلد فرعي', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5)),
                    ] else ...[
                      Text('${sub.productCount} عنصر', style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
                    ],
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 10, textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Floating transfer bar (like Android move/cut action)
  Widget _buildTransferBottomBar(String currentTargetName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36),
        border: Border(top: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: (_isExecutingMove || _currentMainCategory == null) ? null : _executeMoveHere,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isExecutingMove
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.file_download_done_rounded, size: 20),
                label: Text(
                  _currentMainCategory == null
                      ? 'اختر قسماً للنقل إليه'
                      : 'انقل (${_stagedProductIds.length}) هنا إلى ($currentTargetName)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 26),
              tooltip: 'إلغاء النقل',
              onPressed: _cancelTransferMode,
            ),
          ],
        ),
      ),
    );
  }
}

