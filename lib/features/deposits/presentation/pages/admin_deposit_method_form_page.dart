import 'package:games_admin/core/widgets/app_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminDepositMethodFormPage extends StatefulWidget {
  final Map<String, dynamic>? existingMethod;

  const AdminDepositMethodFormPage({super.key, this.existingMethod});

  @override
  State<AdminDepositMethodFormPage> createState() => _AdminDepositMethodFormPageState();
}

class _AdminDepositMethodFormPageState extends State<AdminDepositMethodFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _accountController;
  late TextEditingController _addressController;
  late TextEditingController _feeController;
  late TextEditingController _minDepositController;
  late TextEditingController _maxDepositController;
  late TextEditingController _instructionsController;

  late String _selectedCurrency;
  late String _selectedIcon;
  late bool _isEnabled;
  late bool _requiresReceiptImage;
  late bool _requiresVerification;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  bool get isEdit => widget.existingMethod != null;

  final List<Map<String, dynamic>> _iconOptions = const [
    {'key': 'sham', 'label': 'شام كاش', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF0D9488)},
    {'key': 'syriatel', 'label': 'سيريتل كاش', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEF4444)},
    {'key': 'binance', 'label': 'بينانس Pay', 'icon': Icons.currency_bitcoin_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'usdt', 'label': 'USDT كريبتو', 'icon': Icons.stream_rounded, 'color': Color(0xFF10B981)},
    {'key': 'haram', 'label': 'شركة الهرم', 'icon': Icons.store_rounded, 'color': Color(0xFF8B5CF6)},
    {'key': 'bank', 'label': 'حساب بنكي', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF3B82F6)},
    {'key': 'card', 'label': 'بطاقة بنكية', 'icon': Icons.credit_card_rounded, 'color': Color(0xFF0284C7)},
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.existingMethod;
    _titleController = TextEditingController(text: m?['title'] ?? '');
    _imageUrlController = TextEditingController(text: m?['imageUrl'] ?? m?['iconUrl'] ?? '');
    _accountController = TextEditingController(text: m?['account'] ?? '');
    _addressController = TextEditingController(text: m?['address'] ?? '');
    _feeController = TextEditingController(text: (m?['fee'] ?? 0).toString());
    _minDepositController = TextEditingController(text: (m?['minDeposit'] ?? 1).toString());
    _maxDepositController = TextEditingController(text: (m?['maxDeposit'] ?? 100000).toString());
    _instructionsController = TextEditingController(text: m?['instructions'] ?? '');

    _selectedCurrency = m?['currency'] ?? 'USD';
    _selectedIcon = m?['iconKey'] ?? 'card';
    _isEnabled = m?['isEnabled'] ?? true;
    _requiresReceiptImage = m?['requiresReceiptImage'] ?? false;
    _requiresVerification = m?['requiresVerification'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _accountController.dispose();
    _addressController.dispose();
    _feeController.dispose();
    _minDepositController.dispose();
    _maxDepositController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await sl<ApiClient>().post('/banners/upload', data: {
        'file': base64String,
        'uploadPreset': 'ml_default',
      });

      if (res.data != null && res.data['data'] != null && mounted) {
        final uploadedUrl = res.data['data']['url'] as String;
        setState(() {
          _imageUrlController.text = uploadedUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع صورة وسيلة الشحن بنجاح ✅'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء رفع الصورة'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Color _getIconColor(String key) {
    final opt = _iconOptions.firstWhere((e) => e['key'] == key, orElse: () => _iconOptions.last);
    return opt['color'] as Color;
  }

  IconData _getIconData(String key) {
    final opt = _iconOptions.firstWhere((e) => e['key'] == key, orElse: () => _iconOptions.last);
    return opt['icon'] as IconData;
  }

  Future<void> _saveMethod() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء الحقول الإلزامية'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'title': title,
      'imageUrl': _imageUrlController.text.trim(),
      'currency': _selectedCurrency,
      'iconKey': _selectedIcon,
      'account': _accountController.text.trim(),
      'address': address,
      'fee': double.tryParse(_feeController.text.trim()) ?? 0,
      'minDeposit': double.tryParse(_minDepositController.text.trim()) ?? 1,
      'maxDeposit': double.tryParse(_maxDepositController.text.trim()) ?? 100000,
      'instructions': _instructionsController.text.trim(),
      'isEnabled': _isEnabled,
      'requiresReceiptImage': _requiresReceiptImage,
      'requiresVerification': _requiresVerification,
    };

    try {
      if (isEdit) {
        final id = widget.existingMethod!['_id'] ?? widget.existingMethod!['id'];
        await sl<ApiClient>().put('/deposits/admin/methods/$id', data: payload);
      } else {
        await sl<ApiClient>().post('/deposits/admin/methods', data: payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تحديث وسيلة الإيداع بنجاح ✅' : 'تمت إضافة وسيلة الإيداع بنجاح ✅'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getIconColor(_selectedIcon);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'تعديل وسيلة الإيداع ⚙️' : 'إضافة وسيلة إيداع جديدة ✨',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
            children: [
              // Live Card Preview
              _buildLiveCardPreview(activeColor),
              const SizedBox(height: 24),

              // Section 1: Basic Info
              _buildSectionHeader('1. البيانات الأساسية ونوع الوسيلة', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildCardContainer([
                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    label: 'اسم طريقة الإيداع * (مثال: شام كاش، سيريتل كاش، USDT BEP20)',
                    icon: Icons.title_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الطريقة مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // Currency Selection (Chips)
                const Text('عملة الإيداع المعتمدة:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCurrencyChip(
                      code: 'USD',
                      title: 'دولار أمريكي (USD) 💵',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    _buildCurrencyChip(
                      code: 'SYP',
                      title: 'ليرة سورية (SYP) 🏛️',
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Icon / Type Selection
                const Text('نوع الأيقونة والوسيلة:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _iconOptions.map((opt) {
                    final isSel = _selectedIcon == opt['key'];
                    final optColor = opt['color'] as Color;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = opt['key']),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? optColor.withValues(alpha: 0.25) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? optColor : Colors.white12,
                            width: isSel ? 1.8 : 1.0,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: optColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt['icon'] as IconData, size: 18, color: isSel ? optColor : Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white70,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 24),

              // Section 2: Image / Logo
              _buildSectionHeader('2. صورة وشعار طريقة الشحن 🖼️', Icons.image_rounded),
              const SizedBox(height: 12),
              _buildCardContainer([
                const Text(
                  'يمكنك إدخال رابط مباشر لصورة الشعار أو رفع صورة مباشرة من جهازك:',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: _inputDecoration(
                    label: 'رابط صورة الشعار (URL)',
                    icon: Icons.link_rounded,
                  ).copyWith(
                    suffixIcon: _imageUrlController.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                            onPressed: () {
                              _imageUrlController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                        icon: _isUploadingImage
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2))
                            : const Icon(Icons.photo_library_rounded, size: 18),
                        label: Text(
                          _isUploadingImage ? 'جارٍ الرفع...' : 'رفع صورة من المعرض 📷',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_imageUrlController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFF0F172A),
                          child: AppNetworkImage(
                            _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'معاينة صورة طريقة الإيداع المعتمدة. ستظهر هذه الصورة للزبائن عند اختيار طريقة الشحن.',
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ]),

              const SizedBox(height: 24),

              // Section 3: Account & Address Details
              _buildSectionHeader('3. بيانات التحويل واستلام الأموال', Icons.account_balance_wallet_rounded),
              const SizedBox(height: 12),
              _buildCardContainer([
                TextFormField(
                  controller: _accountController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    label: 'اسم صاحب الحساب / المستلم المعتمد (مثال: شركة المتجر أو اسم الوكيل)',
                    icon: Icons.person_outline_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontFamily: 'monospace'),
                  decoration: _inputDecoration(
                    label: 'رقم الحساب / رقم الهاتف / عنوان المحفظة أو الآيبان *',
                    icon: Icons.qr_code_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'عنوان التحويل مطلوب' : null,
                ),
              ]),

              const SizedBox(height: 24),

              // Section 4: Financial Rules & Fees
              _buildSectionHeader('4. العمولات والحدود المالية', Icons.tune_rounded),
              const SizedBox(height: 12),
              _buildCardContainer([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'العمولة المقتطعة %',
                          icon: Icons.percent_rounded,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minDepositController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'الحد الأدنى',
                          icon: Icons.arrow_downward_rounded,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxDepositController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'الحد الأقصى',
                          icon: Icons.arrow_upward_rounded,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),

              // Section 5: Verification & Status Options
              _buildSectionHeader('5. خيارات التحقق والتفعيل', Icons.verified_user_rounded),
              const SizedBox(height: 12),
              _buildCardContainer([
                // Require Receipt Image Checkbox
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _requiresReceiptImage
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _requiresReceiptImage ? const Color(0xFF0284C7) : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إلزام الزبون بإرفاق صورة إشعار التحويل 📷',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'عند تفعيل هذا الخيار، لن يتمكن الزبون من إتمام طلب الإيداع إلا بعد رفع صورة الإشعار أو لقطة الشاشة.',
                              style: TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: _requiresReceiptImage,
                        activeColor: const Color(0xFF0284C7),
                        checkColor: Colors.white,
                        onChanged: (v) => setState(() => _requiresReceiptImage = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Requires Account Verification Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _requiresVerification
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _requiresVerification ? const Color(0xFF38BDF8) : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_requiresVerification ? const Color(0xFF38BDF8) : Colors.white24)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: _requiresVerification ? const Color(0xFF38BDF8) : Colors.white60,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تتطلب توثيق الحساب (مخصصة للموثقين فقط) 🛡️',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'إذا تم تفعيلها، ستظهر مقفلة 🔒 عند الحسابات غير الموثقة ولا يمكن استخدامها حتى يتم التوثيق',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: _requiresVerification,
                        activeColor: const Color(0xFF38BDF8),
                        checkColor: Colors.black,
                        onChanged: (v) => setState(() => _requiresVerification = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Enable / Disable Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isEnabled
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEnabled ? const Color(0xFF10B981) : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isEnabled ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEnabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                          color: _isEnabled ? const Color(0xFF10B981) : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnabled ? 'طريقة الدفع مفعلة ومتاحة للزبائن الآن' : 'طريقة الدفع معطلة ومخفية عن الزبائن',
                              style: TextStyle(
                                color: _isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'يمكنك تفعيل أو إيقاف الوسيلة مؤقتاً بأي وقت دون حذف بياناتها.',
                              style: TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isEnabled,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (v) => setState(() => _isEnabled = v),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Section 6: Instructions
              _buildSectionHeader('6. تعليمات التحويل للعميل', Icons.notes_rounded),
              const SizedBox(height: 12),
              _buildCardContainer([
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    label: 'اكتب تعليمات واضحة تظهر للعميل (مثال: يرجى التحويل كـ USDT BEP20 حصراً وتصوير رقم العملية)',
                    icon: Icons.info_outline_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ]),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.5),
                ),
                onPressed: _isSaving ? null : _saveMethod,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 22),
                label: Text(
                  _isSaving
                      ? 'جارٍ الحفظ والاعتماد...'
                      : (isEdit ? 'حفظ التعديلات على طريقة الإيداع' : 'إضافة واعتماد وسيلة الإيداع الآن'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCurrencyChip({required String code, required String title, required Color color}) {
    final isSel = _selectedCurrency == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCurrency = code),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.2) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? color : Colors.white12, width: isSel ? 1.8 : 1.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12.5),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
      filled: true,
      fillColor: const Color(0xFF162032),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }

  Widget _buildLiveCardPreview(Color activeColor) {
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'اسم طريقة الإيداع';
    final account = _accountController.text.trim().isNotEmpty ? _accountController.text.trim() : 'اسم صاحب الحساب';
    final address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : '0000 0000 0000 0000';
    final fee = _feeController.text.trim().isNotEmpty ? _feeController.text.trim() : '0';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activeColor.withValues(alpha: 0.35),
            const Color(0xFF1E1B4B).withValues(alpha: 0.6),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Chip, Icon, Currency Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: activeColor.withValues(alpha: 0.6)),
                      ),
                      child: ClipOval(
                        child: _imageUrlController.text.trim().isNotEmpty
                            ? AppNetworkImage(
                                _imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(_getIconData(_selectedIcon), color: Colors.white, size: 24),
                              )
                            : Icon(_getIconData(_selectedIcon), color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          account,
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedCurrency == 'USD'
                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                        : const Color(0xFFEF4444).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedCurrency == 'USD' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Text(
                    _selectedCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Address display in monospace
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                address,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38BDF8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Badges: Fee, Receipt image required badge, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'عمولة: $fee%',
                        style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_requiresReceiptImage) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8), size: 12),
                            SizedBox(width: 4),
                            Text('صورة إشعار إلزامية', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    if (_requiresVerification) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 12),
                            SizedBox(width: 4),
                            Text('يتطلب توثيق 🛡️', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _isEnabled ? '● مفعلة للزبائن' : '○ معطلة مؤقتاً',
                  style: TextStyle(
                    color: _isEnabled ? const Color(0xFF34D399) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
