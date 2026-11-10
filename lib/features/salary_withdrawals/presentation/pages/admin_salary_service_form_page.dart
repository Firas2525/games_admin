import 'package:games_admin/core/widgets/app_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminSalaryServiceFormPage extends StatefulWidget {
  final dynamic service;

  const AdminSalaryServiceFormPage({super.key, this.service});

  @override
  State<AdminSalaryServiceFormPage> createState() => _AdminSalaryServiceFormPageState();
}

class _AdminSalaryServiceFormPageState extends State<AdminSalaryServiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _adminReceiverIdCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _unitNameCtrl;
  late TextEditingController _feePercentageCtrl;
  late TextEditingController _coinsPerUnitCtrl;
  late TextEditingController _dollarsPerUnitCtrl;
  final TextEditingController _newFieldCtrl = TextEditingController();

  bool _isEdit = false;
  bool _isActive = true;
  String _withdrawalType = 'coins'; // 'coins' or 'dollars'
  bool _isSaving = false;
  bool _isUploadingImage = false;

  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;
  List<String> _requiredFields = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.service != null;
    final s = widget.service;

    _nameCtrl = TextEditingController(text: _isEdit ? (s['name'] ?? '') : '');
    _descCtrl = TextEditingController(text: _isEdit ? (s['description'] ?? '') : '');
    _adminReceiverIdCtrl = TextEditingController(text: _isEdit ? (s['adminReceiverId'] ?? '') : '');
    _minCtrl = TextEditingController(text: _isEdit ? (s['minQuantity']?.toString() ?? '1') : '1');
    _maxCtrl = TextEditingController(text: _isEdit ? (s['maxQuantity']?.toString() ?? '10000') : '10000');
    _withdrawalType = _isEdit ? (s['withdrawalType'] ?? 'coins') : 'coins';
    _unitNameCtrl = TextEditingController(text: _isEdit ? (s['unitName'] ?? 'كوينز') : 'كوينز');
    _feePercentageCtrl = TextEditingController(text: _isEdit ? (s['feePercentage']?.toString() ?? '0') : '0');
    _coinsPerUnitCtrl = TextEditingController(text: _isEdit ? (s['coinsPerUnit']?.toString() ?? '1000') : '1000');
    _dollarsPerUnitCtrl = TextEditingController(text: _isEdit ? (s['dollarsPerUnit']?.toString() ?? '1.0') : '1.0');
    _isActive = _isEdit ? (s['isActive'] ?? true) : true;
    _existingImageUrl = _isEdit ? (s['imageUrl'] as String?) : null;

    if (_isEdit && s['requiredFields'] is List) {
      _requiredFields = List<String>.from(s['requiredFields']);
    } else {
      _requiredFields = ['معرف الحساب / الآيدي'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _adminReceiverIdCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _unitNameCtrl.dispose();
    _feePercentageCtrl.dispose();
    _coinsPerUnitCtrl.dispose();
    _dollarsPerUnitCtrl.dispose();
    _newFieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
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
      setState(() {
        _pickedImageBytes = bytes;
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

  Future<String?> _uploadImage(Uint8List bytes) async {
    try {
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
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
    } catch (e) {
      debugPrint('Cloudinary/Backend upload error: $e');
    }
    // Fallback: If upload endpoint fails, use base64 data URI directly
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_pickedImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة للتطبيق من الاستديو'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String finalImageUrl = _existingImageUrl ?? '';

    // Upload new image if chosen
    if (_pickedImageBytes != null) {
      setState(() => _isUploadingImage = true);
      final uploaded = await _uploadImage(_pickedImageBytes!);
      if (uploaded != null && uploaded.isNotEmpty) {
        finalImageUrl = uploaded;
      }
      if (mounted) setState(() => _isUploadingImage = false);
    }

    final minQ = double.tryParse(_minCtrl.text.trim()) ?? 1.0;
    final maxQ = double.tryParse(_maxCtrl.text.trim()) ?? 10000.0;
    final coinsUnit = double.tryParse(_coinsPerUnitCtrl.text.trim()) ?? 1000.0;
    final dollarsUnit = double.tryParse(_dollarsPerUnitCtrl.text.trim()) ?? 1.0;
    final feePercentage = double.tryParse(_feePercentageCtrl.text.trim()) ?? 0.0;
    final unitName = _withdrawalType == 'coins'
        ? (_unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text.trim() : 'كوينز')
        : 'دولار';

    final body = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'imageUrl': finalImageUrl,
      'adminReceiverId': _adminReceiverIdCtrl.text.trim(),
      'withdrawalType': _withdrawalType,
      'coinsPerUnit': coinsUnit,
      'dollarsPerUnit': dollarsUnit,
      'unitName': unitName,
      'feePercentage': feePercentage,
      'minQuantity': minQ,
      'maxQuantity': maxQ,
      'requiredFields': _requiredFields,
      'isActive': _isActive,
    };

    try {
      final dio = sl<ApiClient>().dio;
      if (_isEdit) {
        await dio.put('/salary-withdrawals/admin/services/${widget.service['_id']}', data: body);
      } else {
        await dio.post('/salary-withdrawals/admin/services', data: body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'تم تحديث تطبيق السحب بنجاح' : 'تم إضافة تطبيق السحب بنجاح ✅'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1322),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEdit ? 'تعديل تطبيق سحب' : 'إضافة تطبيق سحب',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Image Upload Box (from Gallery)
                _buildImagePickerBox(),
                const SizedBox(height: 18),

                // 2. Name
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'اسم تطبيق السحب *',
                    'مثال: ببجي موبايل، فودافون كاش، سيرياتيل كاش، تيك توك...',
                    icon: Icons.apps_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى كتابة اسم التطبيق أو الخدمة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'وصف مختصر أو شروط السحب',
                    'اكتب أي تعليمات تظهر للمستخدم (مثال: يتم تنفيذ السحب خلال ساعتين، تأكد من صحة الآيدي...)',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // 3.1 Admin Receiver ID (حساب الآدمن للاستلام)
                TextFormField(
                  controller: _adminReceiverIdCtrl,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: _inputDecoration(
                    'ID حساب الآدمن للاستلام *',
                    'مثال: 987654321 (الآيدي الذي سيقوم المستخدم بتحويل الرصيد إليه داخل التطبيق)',
                    icon: Icons.account_box_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال ID حساب الآدمن لاستلام التحويل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3.2 Currency & Conversion Section (تفعيل الكوينزات أو الدولار)
                _buildWithdrawalTypeSection(),
                const SizedBox(height: 16),

                // 4. Quantities
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('أقل كمية *', '1'),
                        validator: (val) {
                          final numVal = double.tryParse(val?.trim() ?? '');
                          if (numVal == null || numVal <= 0) return 'أدخل رقماً صحيحاً';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('أكبر كمية *', '10000'),
                        validator: (val) {
                          final numVal = double.tryParse(val?.trim() ?? '');
                          if (numVal == null || numVal <= 0) return 'أدخل رقماً صحيحاً';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Dynamic Required Fields Builder
                _buildRequiredFieldsSection(),
                const SizedBox(height: 20),

                // 6. Active Toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131F35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    title: const Text(
                      'تفعيل التطبيق',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'يظهر مباشرة للمستخدمين في قسم سحب الرواتب',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    value: _isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingImage ? 'جاري رفع الصورة...' : 'جاري الحفظ...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        )
                      : Text(
                          _isEdit ? 'حفظ التعديلات ✅' : 'نشر تطبيق السحب الآن 🚀',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox() {
    final hasPicked = _pickedImageBytes != null;
    final hasExisting = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasPicked || hasExisting)
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFF0284C7).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (hasPicked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                _pickedImageBytes!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('تغيير الصورة'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _pickedImageBytes = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('حذف'),
                ),
              ],
            ),
          ] else if (hasExisting) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AppNetworkImage(
                _existingImageUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_rounded,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library_rounded, size: 16),
              label: const Text('تغيير الصورة من الاستديو'),
            ),
          ] else ...[
            InkWell(
              onTap: _pickImageFromGallery,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF38BDF8),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'رفع صورة التطبيق من الاستديو 🖼️',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'اضغط هنا لاختيار صورة اللعبة أو التطبيق من الهاتف',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWithdrawalTypeSection() {
    final isCoins = _withdrawalType == 'coins';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_exchange_rounded, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text(
                'نوع السحب ومعدل التحويل للدولار *',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented choices
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _withdrawalType = 'coins'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isCoins ? const Color(0xFF0284C7) : const Color(0xFF0B1322),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCoins ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🪙 كوينزات / نقاط',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _withdrawalType = 'dollars'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: !isCoins ? const Color(0xFF10B981) : const Color(0xFF0B1322),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isCoins ? const Color(0xFF34D399) : const Color(0xFF334155),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '💵 دولار مباشر',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isCoins) ...[
            // Custom Unit Name Input (Required for non-direct-dollar)
            TextFormField(
              controller: _unitNameCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: _inputDecoration(
                'اسم الوحدة * (يكتب يدوياً)',
                'مثال: كوينزات، توكنز، نقاط، ماسات...',
                icon: Icons.label_important_rounded,
              ),
              validator: (val) {
                if (_withdrawalType == 'coins') {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى تحديد اسم الوحدة (مثل: كوينزات، توكنز...)';
                  }
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            Text(
              'حدد معادلة التحويل (كل كمية ${_unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text.trim() : "وحدة"} كم تساوي بالدولار):',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _coinsPerUnitCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'كمية ${_unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text.trim() : "الوحدة"}',
                      'مثال: 1000',
                    ),
                    validator: (val) {
                      if (_withdrawalType == 'coins') {
                        final v = double.tryParse(val?.trim() ?? '');
                        if (v == null || v <= 0) return 'أدخل كمية صحيحة';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('=', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dollarsPerUnitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('المقابل (\$)', 'مثال: 1.0'),
                    validator: (val) {
                      if (_withdrawalType == 'coins') {
                        final v = double.tryParse(val?.trim() ?? '');
                        if (v == null || v <= 0) return 'أدخل قيمة صالحة';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Commission / Fee percentage
            TextFormField(
              controller: _feePercentageCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: _inputDecoration(
                'نسبة عمولة السحب (%) - تضاف للأرباح وتخصم من التحويل',
                'مثال: 5 (أي خصم 5% عمولة، اكتب 0 إذا كانت بدون عمولة)',
                icon: Icons.percent_rounded,
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final v = double.tryParse(val.trim());
                  if (v == null || v < 0 || v > 100) return 'النسبة يجب أن تكون بين 0 و 100';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Live explanation box
            Builder(
              builder: (_) {
                final uName = _unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text.trim() : 'وحدة';
                final cUnit = _coinsPerUnitCtrl.text.trim().isNotEmpty ? _coinsPerUnitCtrl.text.trim() : '1000';
                final dUnit = _dollarsPerUnitCtrl.text.trim().isNotEmpty ? _dollarsPerUnitCtrl.text.trim() : '1.0';
                final fee = double.tryParse(_feePercentageCtrl.text.trim()) ?? 0.0;
                final sampleGross = double.tryParse(dUnit) ?? 1.0;
                final sampleFee = (sampleGross * fee) / 100;
                final sampleNet = (sampleGross - sampleFee).clamp(0.0, double.infinity);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate_rounded, color: Color(0xFF38BDF8), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'المعادلة المعتمدة: كل $cUnit $uName = \$$dUnit',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fee > 0
                            ? '• عمولة السحب: $fee% (ربح إضافي للمنصة).\n• مثال: عند تحويل $cUnit $uName بقيمة \$$sampleGross، يُخصم \$$sampleFee ويستلم الزبون صافي: \$${sampleNet.toStringAsFixed(2)} بالدولار (أو بالليرة السورية حسب سعر الصرف إذا كان حسابه سوري).'
                            : '• بدون عمولة إضافية: يستلم الزبون كامل المبلغ بالدولار (أو بالليرة السورية حسب سعر الصرف إذا كان حسابه سوري).',
                        style: TextStyle(
                          color: fee > 0 ? const Color(0xFFF59E0B) : Colors.white70,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سحب مباشر بالدولار: الكمية التي يطلبها المستخدم هي دولارات مباشرة (1\$ = 1\$) وتضاف لمحفظته فور موافقتك (أو بالليرة السورية حسب سعر الصرف إذا كان حسابه سوري).',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequiredFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.playlist_add_check_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'البيانات المطلوبة من المستخدم لتنفيذ السحب:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Fields Chips
          if (_requiredFields.isEmpty)
            const Text(
              'لم تقم بإضافة أي حقول مطلوبة بعد (يُنصح بإضافة حقل الآيدي أو الحساب)',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _requiredFields.map((f) {
                return Chip(
                  backgroundColor: const Color(0xFF0F172A),
                  side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                  label: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  onDeleted: () {
                    setState(() {
                      _requiredFields.remove(f);
                    });
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Input for custom field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newFieldCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('اسم حقل مخصص', 'مثال: رقم الحساب، معرف اللعبة...'),
                  onSubmitted: (_) => _addNewField(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _addNewField,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Presets
          const Text('اختصارات سريعة:', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _presetChip('معرف الحساب / الآيدي'),
              _presetChip('الاسم الكامل'),
              _presetChip('رقم الواتساب'),
              _presetChip('الاسم داخل التطبيق'),
              _presetChip('رقم المحفظة / الحساب البنكي'),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewField() {
    final text = _newFieldCtrl.text.trim();
    if (text.isNotEmpty && !_requiredFields.contains(text)) {
      setState(() {
        _requiredFields.add(text);
        _newFieldCtrl.clear();
      });
    }
  }

  Widget _presetChip(String label) {
    final already = _requiredFields.contains(label);
    return ActionChip(
      backgroundColor: already ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFF0F172A),
      side: BorderSide(color: already ? const Color(0xFF38BDF8) : Colors.white12),
      label: Text(
        '+ $label',
        style: TextStyle(
          color: already ? const Color(0xFF38BDF8) : Colors.white70,
          fontSize: 11,
        ),
      ),
      onPressed: already
          ? null
          : () {
              setState(() {
                _requiredFields.add(label);
              });
            },
    );
  }

  InputDecoration _inputDecoration(String label, String hint, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF38BDF8), size: 18) : null,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
    );
  }
}

