import 'dart:convert';
import 'dart:typed_data';
import 'package:games_admin/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../dashboard/presentation/widgets/admin_banners_dialog.dart';
import '../../../products/data/models/category_item_model.dart';
import '../../../products/data/models/subcategory_item_model.dart';
import '../../../products/presentation/pages/admin_products_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/admin_organization_cache_service.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  late final AdminOrganizationCacheService _cacheService;
  bool _isLoading = true;
  List<CategoryItemModel> _categories = [];
  final TextEditingController _searchController = TextEditingController();

  // Hierarchical Folder Navigation State
  CategoryItemModel? _currentMainCategory;
  final List<SubCategoryItemModel> _breadcrumbs = [];
  List<SubCategoryItemModel> _subCategories = [];
  bool _isLoadingSubCats = false;

  static const List<Map<String, dynamic>> _presetIcons = [
    {'key': 'sports_esports_rounded', 'icon': Icons.sports_esports_rounded},
    {'key': 'gamepad_rounded', 'icon': Icons.gamepad_rounded},
    {'key': 'casino_rounded', 'icon': Icons.casino_rounded},
    {'key': 'emoji_events_rounded', 'icon': Icons.emoji_events_rounded},
    {'key': 'credit_card_rounded', 'icon': Icons.credit_card_rounded},
    {'key': 'card_giftcard_rounded', 'icon': Icons.card_giftcard_rounded},
    {'key': 'account_balance_wallet_rounded', 'icon': Icons.account_balance_wallet_rounded},
    {'key': 'monetization_on_rounded', 'icon': Icons.monetization_on_rounded},
    {'key': 'currency_exchange_rounded', 'icon': Icons.currency_exchange_rounded},
    {'key': 'payments_rounded', 'icon': Icons.payments_rounded},
    {'key': 'forum_rounded', 'icon': Icons.forum_rounded},
    {'key': 'chat_bubble_rounded', 'icon': Icons.chat_bubble_rounded},
    {'key': 'share_rounded', 'icon': Icons.share_rounded},
    {'key': 'groups_rounded', 'icon': Icons.groups_rounded},
    {'key': 'thumb_up_rounded', 'icon': Icons.thumb_up_rounded},
    {'key': 'subscriptions_rounded', 'icon': Icons.subscriptions_rounded},
    {'key': 'live_tv_rounded', 'icon': Icons.live_tv_rounded},
    {'key': 'movie_rounded', 'icon': Icons.movie_rounded},
    {'key': 'music_note_rounded', 'icon': Icons.music_note_rounded},
    {'key': 'dialpad_rounded', 'icon': Icons.dialpad_rounded},
    {'key': 'phone_iphone_rounded', 'icon': Icons.phone_iphone_rounded},
    {'key': 'sim_card_rounded', 'icon': Icons.sim_card_rounded},
    {'key': 'wifi_rounded', 'icon': Icons.wifi_rounded},
    {'key': 'language_rounded', 'icon': Icons.language_rounded},
    {'key': 'shopping_bag_rounded', 'icon': Icons.shopping_bag_rounded},
    {'key': 'shopping_cart_rounded', 'icon': Icons.shopping_cart_rounded},
    {'key': 'local_offer_rounded', 'icon': Icons.local_offer_rounded},
    {'key': 'loyalty_rounded', 'icon': Icons.loyalty_rounded},
    {'key': 'star_rounded', 'icon': Icons.star_rounded},
    {'key': 'workspace_premium_rounded', 'icon': Icons.workspace_premium_rounded},
    {'key': 'bolt_rounded', 'icon': Icons.bolt_rounded},
    {'key': 'local_fire_department_rounded', 'icon': Icons.local_fire_department_rounded},
    {'key': 'security_rounded', 'icon': Icons.security_rounded},
    {'key': 'vpn_key_rounded', 'icon': Icons.vpn_key_rounded},
    {'key': 'laptop_mac_rounded', 'icon': Icons.laptop_mac_rounded},
    {'key': 'category_rounded', 'icon': Icons.category_rounded},
  ];

  static const List<Map<String, dynamic>> _presetColors = [
    {'hex': '#0284C7', 'name': 'أزرق محيطي'},
    {'hex': '#10B981', 'name': 'أخضر زمردي'},
    {'hex': '#8B5CF6', 'name': 'بنفسجي ملكي'},
    {'hex': '#F59E0B', 'name': 'ذهبي دافئ'},
    {'hex': '#EF4444', 'name': 'أحمر قرمزي'},
    {'hex': '#EC4899', 'name': 'وردي زاهي'},
    {'hex': '#06B6D4', 'name': 'سماوي فاقع'},
    {'hex': '#6366F1', 'name': 'نيلي غامق'},
  ];

  @override
  void initState() {
    super.initState();
    _cacheService = AdminOrganizationCacheService(
      sharedPreferences: sl<SharedPreferences>(),
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cacheService.getInstantMainCategories();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _categories = cached;
          _isLoading = false;
        });
      }
    }

    if (_categories.isEmpty) {
      setState(() => _isLoading = true);
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
          final changed = _cacheService.hasCategoriesChanged(_categories, list);
          if (changed || _isLoading || _categories.isEmpty) {
            setState(() {
              _categories = list;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && _categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الأقسام: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted && _categories.isEmpty) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadCategoryImage(Uint8List bytes) async {
    final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    try {
      final dio = sl<ApiClient>().dio;
      final uploadRes = await dio.post('/banners/upload', data: {
        'file': base64String,
        'uploadPreset': 'ml_default',
      });
      if (uploadRes.data != null && uploadRes.data['data'] != null) {
        final url = uploadRes.data['data']['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    } catch (_) {}
    return base64String;
  }

  Future<void> _loadSubCategories({
    required String mainCategoryKey,
    String? parentId,
  }) async {
    setState(() => _isLoadingSubCats = true);
    try {
      final dio = sl<ApiClient>().dio;
      final queryParams = <String, dynamic>{
        'mainCategory': mainCategoryKey,
      };
      if (parentId != null) {
        queryParams['parentId'] = parentId;
      } else {
        queryParams['parentId'] = 'root';
      }

      final res = await dio.get('/products/subcategories', queryParameters: queryParams);
      if (res.data != null && res.data['data'] is List) {
        final list = (res.data['data'] as List)
            .map((e) => SubCategoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _subCategories = list;
          _isLoadingSubCats = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingSubCats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل المجلدات الفرعية: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _enterMainCategory(CategoryItemModel cat) {
    setState(() {
      _currentMainCategory = cat;
      _breadcrumbs.clear();
      _subCategories = [];
      _isLoadingSubCats = true;
    });
    _loadSubCategories(mainCategoryKey: cat.key, parentId: null);
  }

  void _enterSubCategory(SubCategoryItemModel subCat) {
    setState(() {
      _breadcrumbs.add(subCat);
      _subCategories = [];
      _isLoadingSubCats = true;
    });
    _loadSubCategories(
      mainCategoryKey: subCat.mainCategory,
      parentId: subCat.id,
    );
  }

  void _navigateUp() {
    if (_breadcrumbs.isNotEmpty) {
      setState(() {
        _breadcrumbs.removeLast();
      });
      final parentId = _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null;
      _loadSubCategories(
        mainCategoryKey: _currentMainCategory!.key,
        parentId: parentId,
      );
    } else if (_currentMainCategory != null) {
      setState(() {
        _currentMainCategory = null;
        _breadcrumbs.clear();
        _subCategories = [];
      });
    }
  }

  void _jumpToBreadcrumbIndex(int index) {
    if (index < 0) {
      setState(() {
        _currentMainCategory = null;
        _breadcrumbs.clear();
        _subCategories = [];
      });
    } else if (index == 0 && _breadcrumbs.isEmpty) {
      // Already at main category root
    } else {
      final targetSub = _breadcrumbs[index];
      setState(() {
        _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      });
      _loadSubCategories(
        mainCategoryKey: targetSub.mainCategory,
        parentId: targetSub.id,
      );
    }
  }

  void _showSubCategoryDialog({SubCategoryItemModel? subCategory}) {
    if (_currentMainCategory == null) return;
    final isEdit = subCategory != null;
    final nameCtrl = TextEditingController(text: isEdit ? subCategory.name : '');
    String existingImageUrl = isEdit ? subCategory.imageUrl : '';
    Uint8List? pickedBytes;
    bool isSaving = false;
    final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
              setModalState(() => pickedBytes = bytes);
            } catch (_) {}
          }

          Future<void> save() async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اسم الكاتيغوري مطلوب'), backgroundColor: Colors.redAccent),
              );
              return;
            }

            setModalState(() => isSaving = true);
            try {
              String finalImageUrl = existingImageUrl;
              if (pickedBytes != null) {
                finalImageUrl = await _uploadCategoryImage(pickedBytes!);
              }

              final dio = sl<ApiClient>().dio;
              if (isEdit) {
                await dio.patch('/products/subcategories/${subCategory.id}', data: {
                  'name': name,
                  'imageUrl': finalImageUrl,
                });
              } else {
                await dio.post('/products/subcategories', data: {
                  'mainCategory': _currentMainCategory!.key,
                  'name': name,
                  'imageUrl': finalImageUrl,
                  if (parentSub != null) 'parentId': parentSub.id,
                });
              }

              await _cacheService.invalidateAll();

              if (mounted) {
                Navigator.pop(modalCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'تم تحديث الكاتيغوري الفرعية بنجاح' : 'تم إنشاء الكاتيغوري الفرعية بنجاح'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                _loadSubCategories(
                  mainCategoryKey: _currentMainCategory!.key,
                  parentId: parentSub?.id,
                );
              }
            } catch (e) {
              setModalState(() => isSaving = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent),
                );
              }
            }
          }

          final parentTitle = parentSub != null ? parentSub.name : _currentMainCategory!.title;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                          color: const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'تعديل الكاتيغوري الفرعية' : 'إنشاء كاتيغوري فرعية جديدة',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'المجلد الحاضن: $parentTitle',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('اسم الكاتيغوري الفرعية *', 'مثال: ببجي عالمية، شدات فورية...'),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: pickedBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(pickedBytes!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : existingImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: AppNetworkImage(existingImageUrl, fit: BoxFit.cover, width: double.infinity),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF38BDF8), size: 30),
                                      SizedBox(height: 6),
                                      Text('اختر صورة للكاتيغوري (اختياري)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving ? null : save,
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'حفظ التعديلات' : 'إنشاء الكاتيغوري', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Text('لا يمكن حذف المجلد', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'لا يمكن حذف كاتيغوري "${subCategory.name}" لأنها غير فارغة.\n\nتحتوي على: ${subCategory.productCount} عنصر و ${subCategory.childCount} مجلد فرعي.\n\nيرجى نقل العناصر وتفريغها بالكامل أولاً لتتمكن من حذفها.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً فهمت', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // If empty: confirm deletion
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
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
          _loadSubCategories(
            mainCategoryKey: _currentMainCategory!.key,
            parentId: parentSub?.id,
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

  void _showCategoryDialog({CategoryItemModel? category}) {
    final isEdit = category != null;
    final titleCtrl = TextEditingController(text: isEdit ? category.title : '');
    final keyCtrl = TextEditingController(text: isEdit ? category.key : '');
    final subtitleCtrl = TextEditingController(text: isEdit ? category.subtitle : '');
    final profitCtrl = TextEditingController(
      text: isEdit && category.profitPercentage != null
          ? category.profitPercentage.toString()
          : '',
    );

    Uint8List? pickedImageBytes;
    String existingImageUrl = isEdit ? category.imageUrl : '';
    String selectedIcon = isEdit ? category.icon : 'sports_esports_rounded';
    String selectedColor = isEdit ? category.color : '#0284C7';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final activeColor = Color(
            int.parse('FF${selectedColor.replaceAll('#', '')}', radix: 16),
          );

          Future<void> pickImageFromGallery() async {
            try {
              final picker = ImagePicker();
              final XFile? file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              setModalState(() {
                pickedImageBytes = bytes;
              });
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تعذر اختيار الصورة: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'تعديل بيانات القسم' : 'إضافة قسم رئيسي جديد',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white60),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 10),

                      // Title
                      TextFormField(
                        controller: titleCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'عنوان القسم *',
                          'مثال: ألعاب الهواتف، اشتراكات رقمية...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                        onChanged: (val) {
                          if (!isEdit && keyCtrl.text.isEmpty) {
                            setModalState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Key (identifier)
                      TextFormField(
                        controller: keyCtrl,
                        enabled: !isEdit,
                        style: TextStyle(color: isEdit ? Colors.white38 : Colors.white),
                        decoration: _inputDecoration(
                          'المفتاح البرمجي للقسم (Key) *',
                          isEdit ? category.key : 'مثال: games, social, cards (أحرف إنجليزية فقط)',
                        ),
                        validator: (v) {
                          if (isEdit) return null;
                          if (v == null || v.trim().isEmpty) return 'المفتاح مطلوب';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      TextFormField(
                        controller: subtitleCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'الوصف / العنوان الفرعي',
                          'مثال: شحن ألعاب وتطبيقات فوري',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Gallery Image Upload Box
                      const Text(
                        'صورة القسم (من المعرض - اختياري):',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: isSaving ? null : pickImageFromGallery,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131F35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (pickedImageBytes != null || existingImageUrl.isNotEmpty)
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: const Color(0xFF0F172A),
                                  child: pickedImageBytes != null
                                      ? Image.memory(
                                          pickedImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : (existingImageUrl.isNotEmpty
                                          ? AppNetworkImage(
                                              existingImageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              Icons.add_photo_alternate_rounded,
                                              color: Color(0xFF38BDF8),
                                              size: 28,
                                            )),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pickedImageBytes != null
                                          ? 'تم اختيار صورة جديدة من المعرض'
                                          : (existingImageUrl.isNotEmpty
                                              ? 'اضغط لتغيير صورة القسم من المعرض'
                                              : 'اضغط لرفع صورة القسم من المعرض'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'يُفضّل اختيار صورة مربعة واضحة',
                                      style: TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (pickedImageBytes != null || existingImageUrl.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'إزالة الصورة',
                                  onPressed: () {
                                    setModalState(() {
                                      pickedImageBytes = null;
                                      existingImageUrl = '';
                                    });
                                  },
                                )
                              else
                                const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8), size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Profit Percentage override
                      TextFormField(
                        controller: profitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'نسبة الربح المخصصة لهذا القسم % (اختياري)',
                          'اتركه فارغاً لاعتماد نسبة الربح العامة للمتجر',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Color picker presets
                      const Text(
                        'لون تمييز القسم:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetColors.map((c) {
                          final hex = c['hex'] as String;
                          final isSelected = selectedColor.toLowerCase() == hex.toLowerCase();
                          final colorVal = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = hex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: colorVal.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Icon picker presets (Icon-only grid without text labels)
                      const Text(
                        'أيقونة القسم:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetIcons.map((i) {
                          final key = i['key'] as String;
                          final iconData = i['icon'] as IconData;
                          final isSelected = selectedIcon == key;

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setModalState(() => selectedIcon = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.22)
                                    : const Color(0xFF131F35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: activeColor.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                iconData,
                                size: 22,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() != true) return;
                                setModalState(() => isSaving = true);

                                String finalImageUrl = existingImageUrl;
                                if (pickedImageBytes != null) {
                                  finalImageUrl = await _uploadCategoryImage(pickedImageBytes!);
                                }

                                final body = <String, dynamic>{
                                  'title': titleCtrl.text.trim(),
                                  'subtitle': subtitleCtrl.text.trim(),
                                  'icon': selectedIcon,
                                  'color': selectedColor,
                                  'imageUrl': finalImageUrl,
                                };

                                if (!isEdit) {
                                  body['key'] = keyCtrl.text.trim().toLowerCase();
                                }

                                if (profitCtrl.text.trim().isNotEmpty) {
                                  body['profitPercentage'] =
                                      double.tryParse(profitCtrl.text.trim());
                                } else if (isEdit) {
                                  body['profitPercentage'] = null; // Reset to default
                                }

                                try {
                                  final dio = sl<ApiClient>().dio;
                                  if (isEdit) {
                                    await dio.patch('/products/categories/${category.id}', data: body);
                                  } else {
                                    await dio.post('/products/categories', data: body);
                                  }

                                  await _cacheService.invalidateAll();

                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? 'تم تحديث بيانات القسم بنجاح'
                                              : 'تم إنشاء القسم الجديد بنجاح',
                                        ),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                    _loadCategories(forceRefresh: true);
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('حدث خطأ: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEdit ? 'حفظ التعديلات' : 'إضافة القسم الآن',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF131F35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryItemModel category) async {
    if (!category.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف الأقسام الأساسية للنظام، يمكنك تعديلها فقط'),
          backgroundColor: Colors.orange,
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
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('تأكيد حذف القسم', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف قسم "${category.title}"؟\nسيتم إعادة تعيين تصنيف أي منتجات بداخله تلقائياً إلى قسم الألعاب الأساسي.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
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
        await dio.delete('/products/categories/${category.id}');
        await _cacheService.invalidateAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف القسم بنجاح'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadCategories(forceRefresh: true);
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
    final filteredCategories = _categories.where((c) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.key.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q);
    }).toList();

    final filteredSubCategories = _subCategories.where((s) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q);
    }).toList();

    final isAtRoot = _currentMainCategory == null;
    final currentTargetName = _breadcrumbs.isNotEmpty
        ? _breadcrumbs.last.name
        : (_currentMainCategory != null ? _currentMainCategory!.title : 'الرئيسية');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1322),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 2,
          title: Text(
            isAtRoot ? 'إدارة الأقسام والمجلدات' : 'مجلد: $currentTargetName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
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
          actions: [
            if (isAtRoot)
              IconButton(
                icon: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF06B6D4)),
                tooltip: 'إعلانات الأقسام الفرعية',
                onPressed: () => AdminBannersDialog.show(
                  context,
                  initialPlacement: 'category',
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
              tooltip: 'تحديث',
              onPressed: () {
                if (isAtRoot) {
                  _loadCategories();
                } else {
                  final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
                  _loadSubCategories(
                    mainCategoryKey: _currentMainCategory!.key,
                    parentId: parentSub?.id,
                  );
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          icon: Icon(isAtRoot ? Icons.add : Icons.create_new_folder_rounded),
          label: Text(
            isAtRoot ? 'إضافة قسم رئيسي جديد' : 'إضافة مجلد فرعي جديد',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            if (isAtRoot) {
              _showCategoryDialog();
            } else {
              _showSubCategoryDialog();
            }
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _cacheService.invalidateAll();
            if (isAtRoot) {
              await _loadCategories(forceRefresh: true);
            } else {
              final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
              await _loadSubCategories(
                mainCategoryKey: _currentMainCategory!.key,
                parentId: parentSub?.id,
              );
            }
          },
          color: const Color(0xFF38BDF8),
          backgroundColor: const Color(0xFF131F35),
          child: Column(
            children: [
              // 1. Android-style Path Breadcrumb Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: const Color(0xFF0F1A2E),
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
                                    Icon(
                                      Icons.home_filled,
                                      size: 14,
                                      color: isAtRoot ? const Color(0xFF38BDF8) : Colors.white70,
                                    ),
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
                                    _loadSubCategories(
                                      mainCategoryKey: _currentMainCategory!.key,
                                      parentId: null,
                                    );
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
              ),

              const Divider(color: Colors.white12, height: 1),

              // 2. Search & Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF0F172A),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: isAtRoot
                              ? 'بحث باسم القسم أو الرمز...'
                              : 'بحث باسم المجلد الفرعي...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF131F35),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131F35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        isAtRoot
                            ? '${filteredCategories.length} قسم'
                            : '${filteredSubCategories.length} مجلد',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Main List Content (Main Categories OR Subcategories)
              Expanded(
                child: isAtRoot
                    ? _buildMainCategoriesBody(filteredCategories)
                    : _buildSubCategoriesBody(filteredSubCategories),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategoriesBody(List<CategoryItemModel> filteredCategories) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 56, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text('لا توجد أقسام مطابقة للبحث', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 84),
      itemCount: filteredCategories.length,
      itemBuilder: (ctx, i) => _buildCategoryCard(filteredCategories[i]),
    );
  }

  void _onReorderSubCategories(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _subCategories.removeAt(oldIndex);
      _subCategories.insert(newIndex, item);
    });

    try {
      final items = _subCategories.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'sortOrder': entry.key,
        };
      }).toList();

      final dio = sl<ApiClient>().dio;
      await dio.patch('/products/subcategories/reorder', data: {'items': items});

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 8),
                Text('تم حفظ الترتيب بنجاح ✨', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الترتيب: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildSubCategoriesBody(List<SubCategoryItemModel> filteredSubCategories) {
    if (_isLoadingSubCats) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (filteredSubCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 44),
              ),
              const SizedBox(height: 14),
              const Text(
                'هذا المجلد لا يحتوي على كاتيغوريز فرعية بعد',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'اضغط على زر "إضافة مجلد فرعي جديد" بالأسفل لإنشاء كاتيغوري جديدة بداخل هذا المجلد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showSubCategoryDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('+ إنشاء كاتيغوري فرعية هنا'),
              ),
            ],
          ),
        ),
      );
    }

    final isSearching = _searchController.text.trim().isNotEmpty;
    if (isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 84),
        itemCount: filteredSubCategories.length,
        itemBuilder: (ctx, i) => _buildSubCategoryCard(
          filteredSubCategories[i],
          key: ValueKey(filteredSubCategories[i].id),
          index: i,
          canReorder: false,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Text(
                'اسحب بالضغط على مقبض السحب لتغيير ترتيب المجلدات',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 84),
            itemCount: _subCategories.length,
            onReorder: _onReorderSubCategories,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 10,
                color: Colors.transparent,
                shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                child: child,
              );
            },
            itemBuilder: (ctx, i) => _buildSubCategoryCard(
              _subCategories[i],
              key: ValueKey(_subCategories[i].id),
              index: i,
              canReorder: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryCard(
    SubCategoryItemModel subCategory, {
    Key? key,
    int index = 0,
    bool canReorder = false,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _enterSubCategory(subCategory),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (canReorder) ...[
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      margin: const EdgeInsets.only(left: 6),
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        color: Color(0xFF38BDF8),
                        size: 22,
                      ),
                    ),
                  ),
                ],
                // Thumbnail or Folder icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                  ),
                  child: subCategory.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: AppNetworkImage(
                            subCategory.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.folder_rounded,
                              color: Color(0xFF38BDF8),
                              size: 26,
                            ),
                          ),
                        )
                      : const Icon(Icons.folder_rounded, color: Color(0xFF38BDF8), size: 26),
                ),
                const SizedBox(width: 12),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subCategory.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          // Empty / Non-empty indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subCategory.canDelete
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subCategory.canDelete ? 'فارغ' : 'ممتلئ',
                              style: TextStyle(
                                color: subCategory.canDelete
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Counts badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${subCategory.productCount} عنصر',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${subCategory.childCount} مجلد فرعي',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Column
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 19),
                      tooltip: 'تعديل الكاتيغوري',
                      onPressed: () => _showSubCategoryDialog(subCategory: subCategory),
                    ),
                    IconButton(
                      icon: Icon(
                        subCategory.canDelete ? Icons.delete_outline_rounded : Icons.lock_outline_rounded,
                        color: subCategory.canDelete ? Colors.redAccent : Colors.white24,
                        size: 19,
                      ),
                      tooltip: subCategory.canDelete ? 'حذف الكاتيغوري الفارغة' : 'غير فارغة - لا يمكن الحذف',
                      onPressed: () => _deleteSubCategory(subCategory),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryItemModel category) {
    final catColor = category.displayColor;
    final catIcon = category.displayIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _enterMainCategory(category),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon or Image
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withValues(alpha: 0.35)),
                  ),
                  child: category.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: AppNetworkImage(
                            category.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              catIcon,
                              color: catColor,
                              size: 26,
                            ),
                          ),
                        )
                      : Icon(catIcon, color: catColor, size: 26),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: category.isCustom
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.isCustom ? 'مخصص' : 'نظام',
                              style: TextStyle(
                                color: category.isCustom
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF38BDF8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (category.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Key & Product count badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${category.key}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${category.productCount} منتج',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                          if (category.profitPercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ربح: ${category.profitPercentage}%',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 12),
                                SizedBox(width: 3),
                                Text(
                                  'المجلدات الفرعية',
                                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions: Sub-banners / Edit / Delete
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded, color: Color(0xFF10B981), size: 21),
                      tooltip: 'استعراض المجلدات الفرعية',
                      onPressed: () => _enterMainCategory(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_carousel_outlined, color: Color(0xFF06B6D4), size: 19),
                      tooltip: 'إعلانات هذا القسم',
                      onPressed: () => AdminBannersDialog.show(
                        context,
                        initialPlacement: 'category',
                        initialCategoryKey: category.key,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 19),
                      tooltip: 'تعديل القسم',
                      onPressed: () => _showCategoryDialog(category: category),
                    ),
                    if (category.isCustom)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
                        tooltip: 'حذف القسم',
                        onPressed: () => _deleteCategory(category),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

