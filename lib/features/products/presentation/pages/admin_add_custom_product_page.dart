import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:games_admin/core/widgets/app_network_image.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/models/category_item_model.dart';
import '../bloc/admin_products_bloc.dart';
import '../bloc/admin_products_event.dart';

class CustomInputFieldConfig {
  TextEditingController labelController;
  TextEditingController keyController;
  String type; // 'text', 'number', 'phone'
  bool required;

  CustomInputFieldConfig({
    required String label,
    required String key,
    this.type = 'text',
    this.required = true,
  })  : labelController = TextEditingController(text: label),
        keyController = TextEditingController(text: key);

  void dispose() {
    labelController.dispose();
    keyController.dispose();
  }
}

class AdminAddCustomProductPage extends StatefulWidget {
  final Map<String, dynamic>? initialProduct;

  const AdminAddCustomProductPage({
    super.key,
    this.initialProduct,
  });

  @override
  State<AdminAddCustomProductPage> createState() =>
      _AdminAddCustomProductPageState();
}

class _AdminAddCustomProductPageState extends State<AdminAddCustomProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _originalPriceController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _minQuantityController =
      TextEditingController(text: '1');
  final TextEditingController _maxQuantityController =
      TextEditingController(text: '1');
  final TextEditingController _descriptionController = TextEditingController();

  String? _uploadedImageUrl;
  Uint8List? _localPreviewBytes;
  bool _isUploadingImage = false;

  String _selectedMainCategory = 'games';
  String _selectedCurrency = 'USD';
  bool _isSaving = false;

  final List<CustomInputFieldConfig> _inputFields = [];

  List<Map<String, dynamic>> _mainCategories = [
    {
      'key': 'games',
      'label': 'ألعاب وشحن فوري',
      'icon': Icons.sports_esports_rounded,
      'color': const Color(0xFF0284C7),
      'image': null,
    },
    {
      'key': 'apps',
      'label': 'تطبيقات وبرامج',
      'icon': Icons.apps_rounded,
      'color': const Color(0xFF10B981),
      'image': null,
    },
    {
      'key': 'cards',
      'label': 'بطاقات رقمية وهدايا',
      'icon': Icons.card_giftcard_rounded,
      'color': const Color(0xFF06B6D4),
      'image': null,
    },
    {
      'key': 'subscriptions',
      'label': 'اشتراكات وبث',
      'icon': Icons.subscriptions_rounded,
      'color': const Color(0xFF6366F1),
      'image': null,
    },
    {
      'key': 'social',
      'label': 'خدمات سوشيال ميديا',
      'icon': Icons.public_rounded,
      'color': const Color(0xFFEC4899),
      'image': null,
    },
    {
      'key': 'numbers',
      'label': 'أرقام وتفعيل',
      'icon': Icons.dialpad_rounded,
      'color': const Color(0xFF38BDF8),
      'image': null,
    },
    {
      'key': 'payment',
      'label': 'شحن ودفع إلكتروني',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF8B5CF6),
      'image': null,
    },
  ];

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    _loadDynamicCategories();

    if (widget.initialProduct != null) {
      final p = widget.initialProduct!;
      _nameController.text = p['name'] ?? '';
      _categoryController.text = p['category'] ?? '';
      _selectedMainCategory = p['mainCategory'] ?? 'games';
      final rawCurr = (p['currency'] ?? '').toString().toUpperCase();
      _selectedCurrency = (rawCurr == 'SYP' || rawCurr == 'ل.س') ? 'SYP' : 'USD';
      _originalPriceController.text = (p['originalPrice'] ?? 0).toString();
      _priceController.text = (p['price'] ?? 0).toString();
      _minQuantityController.text = (p['minCount'] ?? 1).toString();
      _maxQuantityController.text =
          (p['maxCount'] ?? p['minCount'] ?? 1).toString();
      _uploadedImageUrl = p['image'];
      _descriptionController.text = p['description'] ?? '';

      final reqs = p['requiredFields'] as List? ?? [];
      for (final r in reqs) {
        if (r is Map) {
          _inputFields.add(
            CustomInputFieldConfig(
              label: r['label'] ?? '',
              key: r['key'] ?? '',
              type: r['type'] ?? 'text',
              required: r['required'] != false,
            ),
          );
        }
      }
    }

    if (_inputFields.isEmpty) {
      _inputFields.add(
        CustomInputFieldConfig(
          label: 'رقم الآيدي أو الحساب (Player ID)',
          key: 'player_id',
          type: 'text',
          required: true,
        ),
      );
    }
  }

  Future<void> _loadDynamicCategories() async {
    try {
      final res = await sl<ApiClient>().get('/products/categories');
      final rawList = res.data['data'] as List?;
      if (rawList != null && rawList.isNotEmpty && mounted) {
        final palette = [
          const Color(0xFF0284C7),
          const Color(0xFF10B981),
          const Color(0xFF6366F1),
          const Color(0xFF14B8A6),
          const Color(0xFF38BDF8),
          const Color(0xFF8B5CF6),
          const Color(0xFFEC4899),
        ];
        final loaded = <Map<String, dynamic>>[];
        for (int i = 0; i < rawList.length; i++) {
          final model =
              CategoryItemModel.fromJson(rawList[i] as Map<String, dynamic>);
          loaded.add({
            'key': model.key.isNotEmpty ? model.key : model.id,
            'label': model.title,
            'icon': model.displayIcon,
            'color': palette[i % palette.length],
            'image': model.imageUrl,
          });
        }
        setState(() {
          _mainCategories = loaded;
          if (!_mainCategories.any((c) => c['key'] == _selectedMainCategory) &&
              _mainCategories.isNotEmpty) {
            _selectedMainCategory = _mainCategories.first['key'] as String;
          }
        });
      }
    } catch (_) {
      // Keep default categories fallback
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _originalPriceController.dispose();
    _priceController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _descriptionController.dispose();
    for (final f in _inputFields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _localPreviewBytes = bytes;
        _isUploadingImage = true;
      });

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await sl<ApiClient>().post('/banners/upload', data: {
        'file': base64String,
        'uploadPreset': 'ml_default',
      });

      if (res.data != null && res.data['data'] != null && mounted) {
        final uploadedUrl = res.data['data']['url'] as String;
        setState(() {
          _uploadedImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع صورة المنتج بنجاح! 📸'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الصورة، يرجى المحاولة مرة أخرى'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addNewField({String? presetLabel, String? presetKey, String type = 'text'}) {
    setState(() {
      final idx = _inputFields.length + 1;
      _inputFields.add(
        CustomInputFieldConfig(
          label: presetLabel ?? 'حقل إدخال $idx (مثال: السيرفر أو اسم الحساب)',
          key: presetKey ?? 'field_$idx',
          type: type,
          required: true,
        ),
      );
    });
  }

  void _removeField(int index) {
    if (_inputFields.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'يجب إبقاء حقل إدخال واحد على الأقل للزبون ليتمكن من تقديم الطلب'),
          backgroundColor: Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      final removed = _inputFields.removeAt(index);
      removed.dispose();
    });
  }

  double get _profit {
    final cost = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final selling = double.tryParse(_priceController.text.trim()) ?? 0.0;
    return selling - cost;
  }

  double get _profitPercentage {
    final cost = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final profit = _profit;
    if (cost <= 0) return 0.0;
    return (profit / cost) * 100.0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد سعر بيع صحيح أكبر من الصفر'),
          backgroundColor: Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final minCount = int.tryParse(_minQuantityController.text.trim()) ?? 1;
    final maxCount =
        int.tryParse(_maxQuantityController.text.trim()) ?? minCount;

    if (minCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أقل كمية يجب أن تكون 1 على الأقل'),
          backgroundColor: Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (maxCount < minCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أقصى كمية لا يمكن أن تكون أقل من أدنى كمية'),
          backgroundColor: Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fields = _inputFields.map((f) {
      var key = f.keyController.text.trim();
      if (key.isEmpty) {
        key = f.labelController.text.trim().replaceAll(RegExp(r'\s+'), '_');
      }
      return {
        'label': f.labelController.text.trim(),
        'key': key,
        'type': f.type,
        'required': f.required,
      };
    }).toList();

    setState(() => _isSaving = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'mainCategory': _selectedMainCategory,
        'currency': _selectedCurrency == 'SYP' ? 'ل.س' : '\$',
        'originalPrice': cost,
        'price': price,
        'minCount': minCount,
        'maxCount': maxCount,
        'image': _uploadedImageUrl?.trim() ?? '',
        'description': _descriptionController.text.trim(),
        'requiredFields': fields,
      };

      if (widget.initialProduct != null) {
        final id =
            widget.initialProduct!['_id'] ?? widget.initialProduct!['id'];
        await sl<ApiClient>().patch('/products/custom/$id', data: payload);
      } else {
        await sl<ApiClient>().post('/products/custom', data: payload);
      }

      if (mounted) {
        context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialProduct != null
                  ? 'تم تحديث المنتج الخاص بنجاح! ✅'
                  : 'تم إضافة المنتج ونشره في مزودك الخاص بنجاح! 🚀',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ المنتج'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProduct() async {
    final id = widget.initialProduct!['_id'] ?? widget.initialProduct!['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'حذف المنتج نهائياً؟',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف المنتج "${_nameController.text.trim()}" نهائياً من مزودك الخاص؟ لن يتمكن الزبائن من رؤيته أو شرائه بعد الحذف.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.pop(dCtx, true),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('نعم، احذف المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await sl<ApiClient>().delete('/products/custom/$id');
        if (mounted) {
          context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المنتج من مزودك الخاص بنجاح 🗑️'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف المنتج: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: Color(0xFF34D399),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF43F5E)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    final hasImage = _localPreviewBytes != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickAndUploadImage,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131F35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : const Color(0xFF38BDF8).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_localPreviewBytes != null)
                      Image.memory(_localPreviewBytes!, fit: BoxFit.cover)
                    else if (_uploadedImageUrl != null &&
                        _uploadedImageUrl!.isNotEmpty)
                      AppNetworkImage(
                        _uploadedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFF38BDF8),
                          size: 28,
                        ),
                      )
                    else
                      const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF38BDF8),
                        size: 28,
                      ),
                    if (_isUploadingImage)
                      Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage
                        ? 'تم اختيار شعار / صورة المنتج'
                        : 'صورة المنتج أو الباقة (من الاستوديو)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isUploadingImage
                        ? 'جاري رفع الصورة إلى السحابة...'
                        : 'اضغط هنا لاختيار صورة واضحة للمنتج من المعرض',
                    style: TextStyle(
                      color: _isUploadingImage
                          ? const Color(0xFF38BDF8)
                          : Colors.white60,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage && !_isUploadingImage)
              IconButton(
                onPressed: () {
                  setState(() {
                    _localPreviewBytes = null;
                    _uploadedImageUrl = null;
                  });
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF43F5E),
                  size: 20,
                ),
                tooltip: 'إزالة الصورة',
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'استعراض',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategorySelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mainCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _mainCategories[index];
          final key = cat['key'] as String;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final color = cat['color'] as Color;
          final isSel = _selectedMainCategory == key;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedMainCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel
                    ? color.withValues(alpha: 0.2)
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? color : Colors.white.withValues(alpha: 0.08),
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSel ? color : Colors.white60,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
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

  Widget _buildCurrencySelector() {
    final currencies = [
      {
        'key': 'USD',
        'label': 'دولار (\$)',
        'icon': Icons.attach_money_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'key': 'SYP',
        'label': 'ليرة سورية (ل.س)',
        'icon': Icons.currency_exchange_rounded,
        'color': const Color(0xFF14B8A6),
      },
    ];

    return Row(
      children: currencies.map((c) {
        final key = c['key'] as String;
        final label = c['label'] as String;
        final icon = c['icon'] as IconData;
        final color = c['color'] as Color;
        final isSel = _selectedCurrency == key;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: key == 'SYP' ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedCurrency = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSel
                      ? color.withValues(alpha: 0.16)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? color : Colors.white.withValues(alpha: 0.08),
                    width: isSel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: isSel ? color : Colors.white54),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.white70,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfitPreviewBanner() {
    final profit = _profit;
    final pct = _profitPercentage;
    final isPositive = profit >= 0;
    final color =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final currencySymbol = _selectedCurrency == 'SYP' ? 'ل.س' : '\$';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive ? 'صافي ربحك المتوقع بالطلب:' : 'تنبيه: السعر أقل من التكلفة!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${isPositive ? '+' : ''}${profit.toStringAsFixed(_selectedCurrency == 'SYP' ? 0 : 2)} $currencySymbol',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredFieldsSection() {
    final presets = [
      {
        'label': 'رقم الآيدي (Player ID)',
        'key': 'player_id',
        'type': 'text',
        'icon': Icons.gamepad_rounded,
      },
      {
        'label': 'اسم الحساب / المستخدم',
        'key': 'account_name',
        'type': 'text',
        'icon': Icons.person_outline_rounded,
      },
      {
        'label': 'السيرفر (Server)',
        'key': 'server_id',
        'type': 'text',
        'icon': Icons.dns_rounded,
      },
      {
        'label': 'رقم الهاتف / واتساب',
        'key': 'phone_number',
        'type': 'phone',
        'icon': Icons.phone_android_rounded,
      },
      {
        'label': 'البريد الإلكتروني',
        'key': 'email',
        'type': 'text',
        'icon': Icons.alternate_email_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إضافة سريعة لحقول مطلوبة من الزبون:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((preset) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _addNewField(
                  presetLabel: preset['label'] as String,
                  presetKey: preset['key'] as String,
                  type: preset['type'] as String,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        preset['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...List.generate(_inputFields.length, (index) {
            final field = _inputFields[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: field.labelController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'عنوان الحقل للزبون (مثال: رقم الآيدي)',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11.5),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            filled: true,
                            fillColor: const Color(0xFF131F35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'يرجى كتابة اسم الحقل'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _removeField(index),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFF43F5E), size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'حذف الحقل',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'نوع الإدخال:',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      ...[
                        {'key': 'text', 'label': 'نص / آيدي'},
                        {'key': 'number', 'label': 'أرقام فقط'},
                        {'key': 'phone', 'label': 'رقم هاتف'},
                      ].map((t) {
                        final isSel = field.type == t['key'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                setState(() => field.type = t['key'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF0284C7)
                                        .withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF38BDF8)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                t['label'] as String,
                                style: TextStyle(
                                  color: isSel
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white60,
                                  fontSize: 10.5,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: field.required,
                            activeColor: const Color(0xFF10B981),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) =>
                                setState(() => field.required = v ?? true),
                          ),
                          const Text(
                            'إجباري',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _addNewField(),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
              label: const Text(
                'إضافة حقل مخصص آخر',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyUnit = _selectedCurrency == 'SYP' ? 'SYP' : 'USD';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1322),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _isEditing
                ? 'تعديل منتج في مزودي الخاص'
                : 'إضافة منتج جديد لمزودي الخاص',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
          ),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                tooltip: 'حذف المنتج نهائياً',
                onPressed: _isSaving ? null : _confirmDeleteProduct,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // 1. Image Picker
              _buildImagePickerSection(),
              const SizedBox(height: 16),

              // 2. Main Category & Basic Info
              _buildSectionTitle(
                  'القسم الرئيسي وبيانات المنتج', Icons.category_rounded),
              _buildMainCategorySelector(),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F35),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اسم الباقة / المنتج *',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration(
                        hint: 'مثال: شحن 325 شدة ببجي العالمية فوري',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'يرجى إدخال اسم المنتج'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'اسم اللعبة أو المجلد الفرعي *',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _categoryController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration(
                        hint: 'مثال: ببجي موبايل / فري فاير / نتفلكس',
                        icon: Icons.folder_open_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'يرجى تحديد المجلد أو اللعبة'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'وصف أو ملاحظات للزبون (اختياري)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration(
                        hint: 'مثال: يتم التنفيذ خلال 5 دقائق عبر الآيدي فقط',
                        icon: Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Pricing & Quantities
              _buildSectionTitle(
                  'العملة والتسعير والكميات', Icons.payments_rounded),
              _buildCurrencySelector(),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F35),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'التكلفة عليك',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _originalPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                onChanged: (_) => setState(() {}),
                                decoration: _inputDecoration(
                                  hint: '0.00',
                                  icon: Icons.request_quote_outlined,
                                  suffixText: currencyUnit,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'سعر البيع للزبون *',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                onChanged: (_) => setState(() {}),
                                decoration: _inputDecoration(
                                  hint: '0.00',
                                  icon: Icons.sell_outlined,
                                  suffixText: currencyUnit,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'مطلوب'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProfitPreviewBanner(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'أقل كمية للطلب',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _minQuantityController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(
                                  hint: '1',
                                  icon: Icons.remove_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'أقصى كمية للطلب',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _maxQuantityController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(
                                  hint: '1',
                                  icon: Icons.add_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Required Customer Fields
              _buildSectionTitle(
                  'حقول بيانات الزبون عند الشراء', Icons.assignment_ind_rounded),
              _buildRequiredFieldsSection(),
              const SizedBox(height: 24),

              // 5. Submit Button / Delete Button
              Row(
                children: [
                  if (_isEditing) ...[
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          foregroundColor: const Color(0xFFF87171),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: _isSaving || _isUploadingImage ? null : _confirmDeleteProduct,
                        child: const Icon(Icons.delete_forever_rounded, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSaving || _isUploadingImage ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isEditing
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.rocket_launch_rounded,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving
                              ? 'جاري الحفظ...'
                              : (_isEditing
                                  ? 'حفظ التعديلات على المنتج'
                                  : 'نشر المنتج في مزودي الخاص'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
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
  }
}
