import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/models/category_item_model.dart';
import '../../data/models/subcategory_item_model.dart';

class AdminFolderMoveDialog extends StatefulWidget {
  final List<String> productIds;
  final String? subCategoryIdToMove;
  final String? subCategoryNameToMove;
  final VoidCallback? onMovedSuccessfully;

  const AdminFolderMoveDialog({
    super.key,
    this.productIds = const [],
    this.subCategoryIdToMove,
    this.subCategoryNameToMove,
    this.onMovedSuccessfully,
  });

  static Future<bool?> show(
    BuildContext context, {
    List<String> productIds = const [],
    String? subCategoryIdToMove,
    String? subCategoryNameToMove,
    VoidCallback? onMovedSuccessfully,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminFolderMoveDialog(
        productIds: productIds,
        subCategoryIdToMove: subCategoryIdToMove,
        subCategoryNameToMove: subCategoryNameToMove,
        onMovedSuccessfully: onMovedSuccessfully,
      ),
    );
  }

  @override
  State<AdminFolderMoveDialog> createState() => _AdminFolderMoveDialogState();
}

class _AdminFolderMoveDialogState extends State<AdminFolderMoveDialog> {
  bool _isLoading = true;
  bool _isMoving = false;
  String? _errorMessage;

  bool get _isMovingFolder => widget.subCategoryIdToMove != null && widget.subCategoryIdToMove!.isNotEmpty;

  List<CategoryItemModel> _mainCategories = [];
  CategoryItemModel? _currentMainCategory;
  final List<SubCategoryItemModel> _breadcrumbs = [];
  List<SubCategoryItemModel> _currentSubCategories = [];

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
  }

  Future<void> _loadMainCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.get('/products/categories', queryParameters: {'admin': 'true'});
      if (res.data != null && res.data['data'] is List) {
        final list = (res.data['data'] as List)
            .map((e) => CategoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _mainCategories = list;
          _currentMainCategory = null;
          _breadcrumbs.clear();
          _currentSubCategories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الأقسام: $e';
      });
    }
  }

  Future<void> _loadSubCategories({
    required String mainCategoryKey,
    String? parentId,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dio = sl<ApiClient>().dio;
      final queryParams = <String, dynamic>{
        'mainCategory': mainCategoryKey,
        'admin': 'true',
      };
      if (parentId != null) {
        queryParams['parentId'] = parentId;
      } else {
        queryParams['parentId'] = 'root';
      }

      final res = await dio.get('/products/subcategories', queryParameters: queryParams);
      if (res.data != null && res.data['data'] is List) {
        var list = (res.data['data'] as List)
            .map((e) => SubCategoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (_isMovingFolder) {
          list = list.where((s) => s.id != widget.subCategoryIdToMove).toList();
        }
        setState(() {
          _currentSubCategories = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل المجلدات الفرعية: $e';
      });
    }
  }

  void _enterMainCategory(CategoryItemModel mainCat) {
    setState(() {
      _currentMainCategory = mainCat;
      _breadcrumbs.clear();
    });
    _loadSubCategories(mainCategoryKey: mainCat.key, parentId: null);
  }

  void _enterSubCategory(SubCategoryItemModel subCat) {
    setState(() {
      _breadcrumbs.add(subCat);
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
        _currentSubCategories = [];
      });
    }
  }

  void _jumpToBreadcrumbIndex(int index) {
    if (index < 0) {
      // Jump to Main Categories Root
      setState(() {
        _currentMainCategory = null;
        _breadcrumbs.clear();
        _currentSubCategories = [];
      });
    } else if (index == 0 && _breadcrumbs.isEmpty) {
      // Already at current main cat root
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

  Future<void> _executeMoveHere() async {
    if (_currentMainCategory == null) return;

    final targetSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;
    final targetMainCatKey = _currentMainCategory!.key;

    setState(() => _isMoving = true);
    try {
      final dio = sl<ApiClient>().dio;

      if (_isMovingFolder) {
        final payload = <String, dynamic>{
          'mainCategory': targetMainCatKey,
          'parentId': targetSub != null ? targetSub.id : 'root',
        };

        await dio.patch('/products/subcategories/${widget.subCategoryIdToMove}', data: payload);

        if (mounted) {
          final targetName = targetSub != null ? targetSub.name : _currentMainCategory!.title;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم نقل مجلد "${widget.subCategoryNameToMove}" ومحتوياته بنجاح إلى: $targetName'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onMovedSuccessfully?.call();
          Navigator.pop(context, true);
        }
        return;
      }

      final payload = <String, dynamic>{
        'productIds': widget.productIds,
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

      if (mounted) {
        final targetName = targetSub != null ? targetSub.name : _currentMainCategory!.title;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم نقل ${widget.productIds.length} عنصر بنجاح إلى: $targetName'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onMovedSuccessfully?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMoving = false);
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

  void _showCreateSubCategoryDialog() {
    if (_currentMainCategory == null) return;

    final nameController = TextEditingController();
    String imageUrl = '';
    Uint8List? pickedBytes;
    bool isUploading = false;
    final parentSub = _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;

    showDialog(
      context: context,
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
              });

              // Upload immediately
              setDlgState(() => isUploading = true);
              final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              try {
                final dio = sl<ApiClient>().dio;
                final res = await dio.post('/banners/upload', data: {
                  'file': base64String,
                  'uploadPreset': 'ml_default',
                });
                if (res.data != null && res.data['data'] != null) {
                  final url = res.data['data']['url']?.toString();
                  if (url != null && url.isNotEmpty) {
                    imageUrl = url;
                  }
                }
              } catch (_) {
                imageUrl = base64String;
              } finally {
                setDlgState(() => isUploading = false);
              }
            } catch (e) {
              setDlgState(() => isUploading = false);
            }
          }

          Future<void> submit() async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يرجى إدخال اسم الكاتيغوري الفرعية'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            Navigator.pop(dlgCtx);
            setState(() => _isLoading = true);

            try {
              final dio = sl<ApiClient>().dio;
              final payload = {
                'mainCategory': _currentMainCategory!.key,
                'name': name,
                'imageUrl': imageUrl,
                if (parentSub != null) 'parentId': parentSub.id,
              };

              await dio.post('/products/subcategories', data: payload);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ تم إنشاء مجلد فرعي جديد: $name'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Reload current folder contents
              _loadSubCategories(
                mainCategoryKey: _currentMainCategory!.key,
                parentId: parentSub?.id,
              );
            } catch (e) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('فشل إنشاء المجلد: $e'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          final parentTitle = parentSub != null ? parentSub.name : _currentMainCategory!.title;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'إنشاء كاتيغوري فرعية جديدة',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'اسم الكاتيغوري الفرعية *',
                        hintText: 'مثال: ببجي عالمية، شدات فورية، بطاقات شحن...',
                        labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        prefixIcon: const Icon(Icons.folder_outlined, color: Color(0xFF38BDF8), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Image Picker / Preview
                    InkWell(
                      onTap: isUploading ? null : pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: isUploading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2))
                            : pickedBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(pickedBytes!, fit: BoxFit.cover, width: double.infinity),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton.icon(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('إنشاء الكاتيغوري'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTargetName = _breadcrumbs.isNotEmpty
        ? _breadcrumbs.last.name
        : (_currentMainCategory != null ? _currentMainCategory!.title : 'الرئيسية');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF07111F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Top Header: Title & Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.drive_file_move_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMovingFolder
                              ? 'نقل مجلد: "${widget.subCategoryNameToMove}" 📁'
                              : 'نقل ${widget.productIds.length} عنصر محدد 📁',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMovingFolder
                              ? 'اختر القسم أو المجلد الوجهة لنقل هذا المجلد بكامل محتوياته'
                              : 'تنقل داخل المجلدات أو أنشئ كاتيغوري فرعية جديدة ثم اضغط "انقل هنا"',
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Breadcrumb Navigation Bar (Android Path Bar style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF0F1A2E),
              child: Row(
                children: [
                  if (_currentMainCategory != null) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 18, textDirection: TextDirection.ltr),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'رجوع للمستوى السابق',
                      onPressed: _navigateUp,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // RTL natural flow
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
                                    size: 15,
                                    color: _currentMainCategory == null ? const Color(0xFF38BDF8) : Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الرئيسية',
                                    style: TextStyle(
                                      color: _currentMainCategory == null ? const Color(0xFF38BDF8) : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: _currentMainCategory == null ? FontWeight.bold : FontWeight.normal,
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
                                  _loadSubCategories(mainCategoryKey: _currentMainCategory!.key, parentId: null);
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

            // Action Bar for Current Folder: "انقل هنا" + "أنشئ كاتيغوري فرعية جديدة"
            if (_currentMainCategory != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E36),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: _isMoving ? null : _executeMoveHere,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _isMoving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.file_download_done_rounded, size: 19),
                        label: Text(
                          _isMoving ? 'جاري النقل...' : '📥 انقل هنا إلى ($currentTargetName)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _showCreateSubCategoryDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                        label: const Text(
                          '+ مجلد فرعي',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Contents Area (Folders / Categories Grid)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2.5),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_currentMainCategory == null) {
                                      _loadMainCategories();
                                    } else {
                                      _loadSubCategories(
                                        mainCategoryKey: _currentMainCategory!.key,
                                        parentId: _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null,
                                      );
                                    }
                                  },
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (_currentMainCategory == null
                          // 1. Root Level: Show Main Categories
                          ? _buildMainCategoriesList()
                          // 2. Inside Category / SubCategory: Show Sub-folders
                          : _buildSubCategoriesList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _mainCategories.length,
      itemBuilder: (context, index) {
        final cat = _mainCategories[index];
        final catColor = cat.displayColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131F35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: () => _enterMainCategory(cat),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withValues(alpha: 0.4)),
              ),
              child: cat.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: AppNetworkImage(
                        cat.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(cat.displayIcon, color: catColor, size: 22),
                      ),
                    )
                  : Icon(cat.displayIcon, color: catColor, size: 22),
            ),
            title: Text(
              cat.title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${cat.productCount} عنصر مسجل',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text('دخول 📂', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCategoriesList() {
    if (_currentSubCategories.isEmpty) {
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
                child: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'لا توجد مجلدات فرعية داخل هذا القسم بعد',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك النقل إلى هذا القسم مباشرة بالضغط على "انقل هنا"، أو الضغط على "+ مجلد فرعي" لإنشاء كاتيغوري فرعية جديدة بداخله.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _currentSubCategories.length,
      itemBuilder: (context, index) {
        final sub = _currentSubCategories[index];

        return InkWell(
          onTap: () => _enterSubCategory(sub),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF131F35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: sub.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppNetworkImage(
                                sub.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.folder_rounded, color: Color(0xFF38BDF8), size: 20),
                              ),
                            )
                          : const Icon(Icons.folder_rounded, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
                  ],
                ),
                const Spacer(),
                Text(
                  sub.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sub.productCount} عنصر',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    if (sub.childCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${sub.childCount} مجلد',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

