import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

import '../pages/admin_deposit_methods_page.dart';

class AdminDepositMethodsDialog extends StatefulWidget {
  const AdminDepositMethodsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDepositMethodsPage()),
    );
  }

  @override
  State<AdminDepositMethodsDialog> createState() => _AdminDepositMethodsDialogState();
}

class _AdminDepositMethodsDialogState extends State<AdminDepositMethodsDialog> {
  List<dynamic> _methods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMethods();
  }

  Future<void> _fetchMethods() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/deposits/admin/methods');
      if (res.data != null && res.data['data'] != null && mounted) {
        setState(() {
          _methods = res.data['data'] as List;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMethod(String id) async {
    try {
      await sl<ApiClient>().patch('/deposits/admin/methods/$id/toggle');
      _fetchMethods();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة طريقة الدفع بنجاح ✅'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteMethod(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف طريقة الإيداع هذه نهائياً؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await sl<ApiClient>().delete('/deposits/admin/methods/$id');
      _fetchMethods();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف طريقة الإيداع بنجاح ✅'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openMethodForm([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final titleController = TextEditingController(text: existing?['title'] ?? '');
    final accountController = TextEditingController(text: existing?['account'] ?? '');
    final addressController = TextEditingController(text: existing?['address'] ?? '');
    final feeController = TextEditingController(text: (existing?['fee'] ?? 0).toString());
    final minDepositController = TextEditingController(text: (existing?['minDeposit'] ?? 1).toString());
    final maxDepositController = TextEditingController(text: (existing?['maxDeposit'] ?? 100000).toString());
    final instructionsController = TextEditingController(text: existing?['instructions'] ?? '');
    String selectedCurrency = existing?['currency'] ?? 'USD';
    String selectedIcon = existing?['iconKey'] ?? 'card';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setFormState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
            ),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_note_rounded : Icons.add_card_rounded, color: const Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'تعديل طريقة الإيداع' : 'إضافة طريقة إيداع جديدة',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'اسم طريقة الإيداع (مثال: شام كاش، سيريتل كاش)',
                        labelStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Icon(Icons.title_rounded, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCurrency,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'العملة', labelStyle: TextStyle(color: Colors.white60)),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('دولار (USD)')),
                              DropdownMenuItem(value: 'SYP', child: Text('ليرة سورية (SYP)')),
                            ],
                            onChanged: (v) => setFormState(() => selectedCurrency = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedIcon,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'الأيقونة', labelStyle: TextStyle(color: Colors.white60)),
                            items: const [
                              DropdownMenuItem(value: 'card', child: Text('بطاقة بنكية 💳')),
                              DropdownMenuItem(value: 'sham', child: Text('شام كاش 🏛️')),
                              DropdownMenuItem(value: 'syriatel', child: Text('سيريتل كاش ⚡')),
                              DropdownMenuItem(value: 'binance', child: Text('بينانس 🟡')),
                              DropdownMenuItem(value: 'usdt', child: Text('USDT كريبتو 🌐')),
                              DropdownMenuItem(value: 'haram', child: Text('حوالة الهرم 🏛️')),
                              DropdownMenuItem(value: 'bank', child: Text('حساب مصرفي 🏦')),
                            ],
                            onChanged: (v) => setFormState(() => selectedIcon = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'اسم الحساب / المستلم المعتمد',
                        labelStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'رقم الحساب / رقم الهاتف / عنوان المحفظة *',
                        labelStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Icon(Icons.pin_rounded, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: feeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'العمولة %', labelStyle: TextStyle(color: Colors.white60)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: minDepositController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'الحد الأدنى', labelStyle: TextStyle(color: Colors.white60)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxDepositController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'الحد الأقصى', labelStyle: TextStyle(color: Colors.white60)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionsController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      decoration: const InputDecoration(
                        labelText: 'تعليمات التحويل للعميل',
                        labelStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white60))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final address = addressController.text.trim();
                  if (title.isEmpty || address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى كتابة اسم الطريقة وعنوان/رقم التحويل'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }

                  final payload = {
                    'title': title,
                    'account': accountController.text.trim(),
                    'address': address,
                    'currency': selectedCurrency,
                    'iconKey': selectedIcon,
                    'fee': double.tryParse(feeController.text.trim()) ?? 0,
                    'minDeposit': double.tryParse(minDepositController.text.trim()) ?? 1,
                    'maxDeposit': double.tryParse(maxDepositController.text.trim()) ?? 100000,
                    'instructions': instructionsController.text.trim(),
                  };

                  try {
                    if (isEdit) {
                      final id = existing['_id'] ?? existing['id'];
                      await sl<ApiClient>().put('/deposits/admin/methods/$id', data: payload);
                    } else {
                      await sl<ApiClient>().post('/deposits/admin/methods', data: payload);
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (!mounted) return;
                    _fetchMethods();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'تم تحديث وسيلة الإيداع بنجاح ✅' : 'تمت إضافة وسيلة الإيداع بنجاح ✅')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة الآن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF07111F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: Color(0xFF38BDF8), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'إدارة وسائل وطرق الإيداع المعتمدة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openMethodForm(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('إضافة طريقة جديدة'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                    : _methods.isEmpty
                        ? const Center(child: Text('لا توجد طرق إيداع مضافة', style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: _methods.length,
                            itemBuilder: (context, index) {
                              final m = _methods[index] as Map<String, dynamic>;
                              final id = m['_id']?.toString() ?? m['id']?.toString() ?? '';
                              final isEnabled = m['isEnabled'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131D2E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isEnabled
                                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                m['title'] ?? '',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  m['currency'] ?? 'USD',
                                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'الحساب: ${m['account'] ?? '-'} | العنوان: ${m['address'] ?? '-'}',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Fee
                                    Text(
                                      'عمولة: ${m['fee'] ?? 0}%',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    // Enabled Switch
                                    Switch(
                                      value: isEnabled,
                                      activeThumbColor: const Color(0xFF10B981),
                                      onChanged: (_) => _toggleMethod(id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 18),
                                      tooltip: 'تعديل',
                                      onPressed: () => _openMethodForm(m),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      tooltip: 'حذف',
                                      onPressed: () => _deleteMethod(id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
