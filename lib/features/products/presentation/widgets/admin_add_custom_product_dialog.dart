import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
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

class AdminAddCustomProductDialog extends StatefulWidget {
  final Map<String, dynamic>? initialProduct; // For editing if passed

  const AdminAddCustomProductDialog({
    super.key,
    this.initialProduct,
  });

  static Future<bool?> show(BuildContext context, {Map<String, dynamic>? initialProduct}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminAddCustomProductDialog(initialProduct: initialProduct),
    );
  }

  @override
  State<AdminAddCustomProductDialog> createState() => _AdminAddCustomProductDialogState();
}

class _AdminAddCustomProductDialogState extends State<AdminAddCustomProductDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedMainCategory = 'games';
  String _selectedCurrency = 'USD';
  bool _isSaving = false;

  final List<CustomInputFieldConfig> _inputFields = [];

  final List<Map<String, String>> _mainCategories = [
    {'key': 'games', 'label': '🎮 ألعاب وشحن فوري'},
    {'key': 'apps', 'label': '💬 تطبيقات وبرامج'},
    {'key': 'cards', 'label': '💳 بطاقات رقمية وهدايا'},
    {'key': 'subscriptions', 'label': '🎬 اشتراكات وبث'},
    {'key': 'social', 'label': '📱 خدمات سوشيال ميديا'},
    {'key': 'numbers', 'label': '📞 أرقام وتفعيل'},
    {'key': 'payment', 'label': '⚡ شحن ومحافظ إلكترونية'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      final p = widget.initialProduct!;
      _nameController.text = p['name'] ?? '';
      _categoryController.text = p['category'] ?? '';
      _selectedMainCategory = p['mainCategory'] ?? 'games';
      _selectedCurrency = p['currency'] ?? 'USD';
      _originalPriceController.text = (p['originalPrice'] ?? 0).toString();
      _priceController.text = (p['price'] ?? 0).toString();
      _imageUrlController.text = p['image'] ?? '';
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
      // Default player id input field
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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _originalPriceController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    for (final f in _inputFields) {
      f.dispose();
    }
    super.dispose();
  }

  void _addNewField() {
    setState(() {
      final idx = _inputFields.length + 1;
      _inputFields.add(
        CustomInputFieldConfig(
          label: 'حقل إضافي $idx (مثال: سيرفر أو اسم حساب)',
          key: 'extra_field_$idx',
          type: 'text',
          required: true,
        ),
      );
    });
  }

  void _removeField(int index) {
    if (_inputFields.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إبقاء حقل إدخال واحد على الأقل للزبون')),
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
        const SnackBar(content: Text('يرجى تحديد سعر بيع صحيح أكبر من الصفر')),
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
        'currency': _selectedCurrency,
        'originalPrice': cost,
        'price': price,
        'image': _imageUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requiredFields': fields,
      };

      if (widget.initialProduct != null) {
        final id = widget.initialProduct!['_id'] ?? widget.initialProduct!['id'];
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
                  ? 'تم تحديث المنتج الخاص بنجاح! ⚡'
                  : 'تم إضافة المنتج إلى مزودي الخاص بنجاح! ⚡',
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
          SnackBar(
            content: const Text('حدث خطأ'),
            backgroundColor: const Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialProduct != null ? 'تعديل منتج في مزودي الخاص' : 'إضافة منتج جديد (مزودي الخاص ⚡)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          const Text(
                            'منتج بنظام معالجة يدوية كامل مع حقول ديناميكية للزبون',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
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

              // Form Body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        _buildSectionHeader('1. المعلومات الأساسية والتصنيف', Icons.info_outline_rounded),
                        const SizedBox(height: 12),

                        // Name
                        _buildTextField(
                          controller: _nameController,
                          label: 'اسم المنتج أو الباقة *',
                          hint: 'مثال: شحن 100 جوهرة فري فاير أو شتراك شهر VIP',
                          icon: Icons.title_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المنتج مطلوب' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // Category (Game / App name)
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                controller: _categoryController,
                                label: 'القسم أو اسم اللعبة *',
                                hint: 'مثال: Free Fire أو نتفلكس',
                                icon: Icons.category_rounded,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'القسم مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Main Category Dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'القسم الرئيسي في المتجر *',
                                    style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedMainCategory,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF1E293B),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        items: _mainCategories.map((c) {
                                          return DropdownMenuItem(
                                            value: c['key'],
                                            child: Text(c['label']!),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedMainCategory = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Pricing & Currency Section
                        _buildSectionHeader('2. التسعير والعملة وهوامش الربح', Icons.monetization_on_outlined),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // Currency selection
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('العملة *', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCurrency,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF1E293B),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        items: const [
                                          DropdownMenuItem(value: 'USD', child: Text('USD (\$) دولار')),
                                          DropdownMenuItem(value: 'SYP', child: Text('SYP (ل.س) سوري')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedCurrency = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Original Cost
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _originalPriceController,
                                label: 'سعر التكلفة عليك *',
                                hint: 'مثال: 2.0',
                                icon: Icons.price_change_outlined,
                                keyboardType: const TextInputFormatOption(),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Selling Price
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'سعر البيع للزبون *',
                                hint: 'مثال: 2.5',
                                icon: Icons.sell_rounded,
                                keyboardType: const TextInputFormatOption(),
                                onChanged: (_) => setState(() {}),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'السعر مطلوب' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Real-time Profit Preview Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 18),
                                  const SizedBox(width: 8),
                                  const Text('صافي ربحك التلقائي:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${_profit.toStringAsFixed(2)} $_selectedCurrency',
                                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(
                                'نسبة الربح: ${_profitPercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Image & Description
                        _buildSectionHeader('3. مظهر المنتج والتعليمات', Icons.image_outlined),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _imageUrlController,
                          label: 'رابط صورة أو أيقونة المنتج (اختياري)',
                          hint: 'https://...',
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _descriptionController,
                          label: 'تعليمات الشحن ووصف المنتج (اختياري)',
                          hint: 'مثال: يرجى كتابة الـ ID والتأكد من السيرفر، يتم الشحن فورا...',
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 20),

                        // Dynamic Custom Inputs Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('4. الحقول المطلوبة من الزبون عند الشراء', Icons.dynamic_form_rounded),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF38BDF8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('إضافة حقل جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _addNewField,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'هذه الحقول سيقوم الزبون بتعبئتها إجبارياً في تطبيق المستخدم لتصلك في صفحة الطلبات (مثل: معرف اللاعب، السيرفر، اسم الحساب...)',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Fields List
                        ...List.generate(_inputFields.length, (index) {
                          final f = _inputFields[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                // Field Number Badge
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Field Label (Visible to user)
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: f.labelController,
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                    decoration: InputDecoration(
                                      labelText: 'اسم الحقل للزبون *',
                                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                      hintText: 'مثال: رقم الآيدي (Player ID)',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Field Type Dropdown
                                SizedBox(
                                  width: 100,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: f.type,
                                    dropdownColor: const Color(0xFF1E293B),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                    decoration: InputDecoration(
                                      labelText: 'نوع الإدخال',
                                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'text', child: Text('نص')),
                                      DropdownMenuItem(value: 'number', child: Text('أرقام')),
                                      DropdownMenuItem(value: 'phone', child: Text('هاتف')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => f.type = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Required Checkbox
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: f.required,
                                      activeColor: const Color(0xFF0284C7),
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (val) {
                                        setState(() => f.required = val ?? true);
                                      },
                                    ),
                                    const Text('إجباري', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),

                                // Delete field button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 20),
                                  tooltip: 'حذف الحقل',
                                  onPressed: () => _removeField(index),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Dialog Footer Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF451A03),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF451A03)))
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'جاري الحفظ...'
                            : widget.initialProduct != null
                                ? 'حفظ التعديلات'
                                : 'إضافة المنتج إلى مزودي الخاص ⚡',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class TextInputFormatOption extends TextInputType {
  const TextInputFormatOption() : super.numberWithOptions(decimal: true);
}
