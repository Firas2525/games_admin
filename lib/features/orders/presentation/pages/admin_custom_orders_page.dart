import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/admin_product_artwork.dart';
import 'package:games_admin/features/products/presentation/pages/admin_add_custom_product_page.dart';
import 'admin_all_orders_page.dart';

class AdminCustomOrdersPage extends StatefulWidget {
  const AdminCustomOrdersPage({super.key});

  @override
  State<AdminCustomOrdersPage> createState() => _AdminCustomOrdersPageState();
}

class _AdminCustomOrdersPageState extends State<AdminCustomOrdersPage> {
  String _selectedFilter = 'pending'; // pending, all, completed, rejected, cancelled
  List<dynamic> _orders = [];
  Map<String, int> _counts = {
    'all': 0,
    'pending': 0,
    'completed': 0,
    'rejected': 0,
    'cancelled': 0,
  };
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
      };
      if (_selectedFilter != 'all') {
        queryParams['status'] = _selectedFilter;
      }
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }

      final res = await sl<ApiClient>().get(
        '/orders/admin/custom-orders',
        queryParameters: queryParams,
      );

      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _orders = data['orders'] as List? ?? [];
          final rawCounts = (data['counts'] as Map<String, dynamic>?) ??
              (data['stats'] as Map<String, dynamic>?);
          if (rawCounts != null) {
            _counts = {
              'all': (rawCounts['all'] as num?)?.toInt() ?? 0,
              'pending': (rawCounts['pending'] as num?)?.toInt() ?? 0,
              'completed': (rawCounts['completed'] as num?)?.toInt() ?? 0,
              'rejected': (rawCounts['rejected'] as num?)?.toInt() ??
                  (rawCounts['failed'] as num?)?.toInt() ??
                  0,
              'cancelled': (rawCounts['cancelled'] as num?)?.toInt() ?? 0,
            };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحميل الطلبات'),
            backgroundColor: Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  // --- Complete Order Action ---
  Future<void> _completeOrder(Map<String, dynamic> order) async {
    final orderId = order['_id'] ?? order['id'];
    final productName = order['item']?['name'] ?? order['name'] ?? 'منتج خاص';
    final user = order['userId'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'الزبون';
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 24),
              SizedBox(width: 10),
              Text(
                'تأكيد وإكمال الطلب',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل أنت متأكد من معالجة وشحن هذا الطلب للزبون بنجاح؟',
                style:
                    TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الزبون: $userName',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('المنتج: $productName',
                        style: const TextStyle(
                            color: Color(0xFF38BDF8), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('ملاحظة التنفيذ أو كود التفعيل (اختياري):',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثال: تم الشحن بنجاح / كود التفعيل: XXXX',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF064E3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الإكمال بنجاح',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ApiClient>().post(
          '/orders/admin/custom-orders/$orderId/complete',
          data: {
            'adminNote': noteController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد وإكمال الطلب بنجاح! ✅'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ'),
              backgroundColor: Color(0xFFF43F5E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- Reject Order Action (Refunds User) ---
  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    final orderId = order['_id'] ?? order['id'];
    final user = order['userId'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'الزبون';
    final priceCharged =
        order['userPrice'] ?? order['priceCharged'] ?? order['price'] ?? 0;
    final currency = order['currency'] ?? 'USD';
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 24),
              SizedBox(width: 10),
              Text(
                'رفض الطلب واسترجاع الرصيد',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تنبيه: سيتم رفض هذا الطلب وإرجاع كامل المبلغ تلقائياً إلى محفظة المستخدم.',
                style: TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الزبون: $userName',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'المبلغ المسترجع: $priceCharged $currency',
                      style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('سبب الرفض (سيظهر للزبون):',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'مثال: رقم الآيدي غير صحيح أو الخدمة غير متوفرة حالياً',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('تراجع', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('يرجى كتابة سبب الرفض للزبون')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('تأكيد الرفض وإعادة الرصيد',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ApiClient>().post(
          '/orders/admin/custom-orders/$orderId/reject',
          data: {
            'reason': reasonController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('تم رفض الطلب وإعادة الرصيد لحساب العميل بنجاح 🔄'),
              backgroundColor: Color(0xFF0284C7),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ'),
              backgroundColor: Color(0xFFF43F5E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- Cancel Order Action (Refunds User) ---
  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final orderId = order['_id'] ?? order['id'];
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF64748B), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.remove_circle_outline_rounded,
                  color: Color(0xFF94A3B8), size: 24),
              SizedBox(width: 10),
              Text(
                'إلغاء الطلب واسترجاع الرصيد',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سيتم إلغاء الطلب وإرجاع المبلغ مباشرة إلى محفظة العميل.',
                style:
                    TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text('سبب الإلغاء (اختياري):',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثال: تم الإلغاء بناءً على طلب العميل',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('تراجع', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF475569),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الإلغاء وإعادة الرصيد',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ApiClient>().post(
          '/orders/admin/custom-orders/$orderId/cancel',
          data: {
            'reason': reasonController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الطلب واسترجاع الرصيد بنجاح 🔄'),
              backgroundColor: Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ'),
              backgroundColor: Color(0xFFF43F5E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSingleOrder(Map<String, dynamic> order) async {
    final orderId = order['orderId'] ?? order['_id'] ?? order['id'];
    final productName = order['productName'] ?? 'هذا الطلب';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('حذف الطلب نهائياً؟', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف طلب "$productName" (معرف: $orderId) نهائياً من سجلات مزودك الخاص؟',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، احذف الطلب'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ApiClient>().delete('/orders/admin/custom-orders/$orderId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الطلب بنجاح 🗑️'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrders();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف الطلب: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showPurgeAllCustomOrdersDialog() async {
    final confirmController = TextEditingController();
    bool isPurging = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حذف كافة طلبات مزودي الخاص',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'تنظيف شامل لقائمة طلبات المزود الخاص',
                        style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ما الذي سيتم حذفه؟',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• جميع طلبات مزودك الخاص (المعلقة، المكتملة، المرفوضة، والملغية) ستُحذف نهائياً.\n• سيتم تصفير عداد طلبات مزودي الخاص بالكامل.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ما الذي لن يتأثر وسيبقى محفوظاً 100%؟',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• المنتجات نفسها لن تُحذف وستبقى معروضة في المتجر.\n• طلبات المزودين الخارجيين الآخرين (رؤيا، براند ون كارد) لن تتأثر إطلاقاً.\n• أرصدة وحسابات المستخدمين لن تتأثر.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لتأكيد مسح كافة طلبات مزودي الخاص، اكتب كلمة "حذف" أدناه:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    enabled: !isPurging,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب "حذف" هنا...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                    onChanged: (_) {
                      setDialogState(() => errorText = null);
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPurging ? null : () => Navigator.of(dlgCtx).pop(),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isPurging
                    ? null
                    : () async {
                        final text = confirmController.text.trim();
                        if (text != 'حذف') {
                          setDialogState(() {
                            errorText = 'يرجى كتابة كلمة "حذف" للتأكيد';
                          });
                          return;
                        }

                        setDialogState(() {
                          isPurging = true;
                          errorText = null;
                        });

                        try {
                          final response = await sl<ApiClient>().delete('/orders/admin/custom-orders/all');
                          if (!mounted) return;
                          Navigator.of(dlgCtx).pop();

                          final data = response.data;
                          final msg = (data is Map && data['message'] != null)
                              ? data['message'].toString()
                              : 'تم حذف كافة طلبات مزودي الخاص بنجاح';

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );

                          _fetchOrders();
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() {
                            isPurging = false;
                            errorText = 'فشلت العملية: ${e.toString()}';
                          });
                        }
                      },
                icon: isPurging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_sweep_rounded, size: 18),
                label: Text(
                  isPurging ? 'جاري المسح...' : 'تأكيد مسح كافة الطلبات',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF080C16),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07111F),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'طلبات مزودي الخاص',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF38BDF8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 14),
              label: const Text('كافة الطلبات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAllOrdersPage()),
                );
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: Color(0xFFEF4444), size: 18),
              ),
              tooltip: 'حذف كافة طلبات مزودي الخاص',
              onPressed: _showPurgeAllCustomOrdersDialog,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF38BDF8), size: 18),
              ),
              tooltip: 'تحديث الطلبات',
              onPressed: _fetchOrders,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // KPI Summary Cards
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  _buildKpiCard(
                    title: 'قيد الانتظار',
                    value: '${_counts['pending'] ?? 0}',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    title: 'مكتملة',
                    value: '${_counts['completed'] ?? 0}',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    title: 'مرفوضة',
                    value: '${_counts['rejected'] ?? 0}',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFF43F5E),
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    title: 'إجمالي الطلبات',
                    value: '${_counts['all'] ?? 0}',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),

            // Add Custom Product Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAddCustomProductPage()),
                  );
                  if (res == true) _fetchOrders();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: Colors.white, size: 19),
                      SizedBox(width: 8),
                      Text(
                        'إضافة منتج جديد لمزودي الخاص',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Filter Chips Bar
            _buildFiltersAndStatsBar(),

            // Search input
            _buildSearchBar(),

            // Orders list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF0284C7)))
                  : _orders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFF0F172A),
                          onRefresh: _fetchOrders,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                            itemCount: _orders.length,
                            separatorBuilder: (ctx, idx) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final order =
                                  _orders[index] as Map<String, dynamic>;
                              return _buildOrderCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndStatsBar() {
    return Container(
      color: const Color(0xFF07111F),
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterPill(
              label: 'قيد الانتظار',
              value: 'pending',
              count: _counts['pending'] ?? 0,
              color: const Color(0xFF38BDF8),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'الكل',
              value: 'all',
              count: _counts['all'] ?? 0,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'مكتملة',
              value: 'completed',
              count: _counts['completed'] ?? 0,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'مرفوضة',
              value: 'rejected',
              count: _counts['rejected'] ?? 0,
              color: const Color(0xFFF43F5E),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'ملغية',
              value: 'cancelled',
              count: _counts['cancelled'] ?? 0,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String value,
    required int count,
    required Color color,
  }) {
    final isSel = _selectedFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _selectedFilter = value);
        _fetchOrders();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSel ? color.withValues(alpha: 0.22) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? color : Colors.white12,
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSel
                    ? color.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF07111F),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'ابحث برقم الطلب، اسم الزبون، معرف اللاعب أو المنتج...',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF38BDF8)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Colors.white60),
                  onPressed: () {
                    _searchController.clear();
                    _fetchOrders();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF131D31),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        onSubmitted: (_) => _fetchOrders(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          const Text(
            'لا توجد طلبات في هذا القسم حالياً',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'pending'
                ? 'كافة طلبات مزودي الخاص تمت معالجتها! ✨'
                : 'جرب تغيير شروط البحث أو الفرز',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = (order['_id'] ?? order['id'] ?? '').toString();
    final isExpanded = _expandedOrderIds.contains(orderId);
    final status = (order['status'] ?? 'pending').toString().toLowerCase();

    final user = order['userId'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? order['userName'] ?? 'زبون غير مسجل';
    final userEmail = user?['email'] ?? order['userEmail'] ?? '';
    final userBalance = (user?['balance'] as num?)?.toDouble() ?? 0.0;
    final userIsSyp = user?['isSyp'] == true;

    final item = order['item'] as Map<String, dynamic>?;
    final productName = item?['name'] ?? order['name'] ?? 'منتج خاص';
    final productCategory =
        item?['category'] ?? order['category'] ?? 'مزودي الخاص';
    final productMainCategory = item?['mainCategory'] ?? 'games';
    final productImg = item?['image'] ?? '';

    final targetId = (order['targetId'] ?? '').toString();
    final extraFields =
        order['metadata']?['extraFields'] as Map<String, dynamic>? ?? {};

    final priceCharged = (order['userPrice'] as num?)?.toDouble() ??
        (order['priceCharged'] as num?)?.toDouble() ??
        (order['price'] as num?)?.toDouble() ??
        0.0;
    final originalPrice = (order['costPrice'] as num?)?.toDouble() ??
        (order['originalPrice'] as num?)?.toDouble() ??
        0.0;
    final profit =
        (order['profit'] as num?)?.toDouble() ?? (priceCharged - originalPrice);
    final currency = order['currency'] ?? (userIsSyp ? 'SYP' : 'USD');

    final createdAt = order['createdAt'] != null
        ? () {
            final dt = DateTime.tryParse(order['createdAt'].toString());
            if (dt == null) return '';
            final g = dt.toUtc().add(const Duration(hours: 3));
            return '${g.year}/${g.month.toString().padLeft(2, '0')}/${g.day.toString().padLeft(2, '0')} ${g.hour.toString().padLeft(2, '0')}:${g.minute.toString().padLeft(2, '0')}';
          }()
        : '';
    final shortDate = createdAt.isNotEmpty ? createdAt.split(' ').first : '';
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();

    final adminNote =
        (order['adminNote'] ?? order['executionData']?['adminNote'] ?? '')
            .toString();
    final failureReason = (order['failureReason'] ?? '').toString();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
      case 'failed':
        statusColor = const Color(0xFFF43F5E);
        statusText = 'مرفوض';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
      case 'refunded':
        statusColor = const Color(0xFF94A3B8);
        statusText = 'ملغي';
        statusIcon = Icons.remove_circle_rounded;
        break;
      case 'pending':
      case 'processing':
      default:
        statusColor = const Color(0xFF38BDF8);
        statusText = 'قيد الانتظار';
        statusIcon = Icons.schedule_rounded;
        break;
    }

    final isPendingOrProcessing =
        status == 'pending' || status == 'processing';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF111C2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? statusColor.withValues(alpha: 0.45)
              : (isPendingOrProcessing
                  ? statusColor.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.07)),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.26 : 0.14),
            blurRadius: isExpanded ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedOrderIds.remove(orderId);
              } else {
                _expandedOrderIds.add(orderId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header Row (Always Visible)
                Row(
                  children: [
                    // Artwork with status badge overlay
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AdminProductArtworkWidget(
                          imageUrl: productImg,
                          title: productName,
                          category: productCategory,
                          mainCategory: productMainCategory,
                          source: 'custom',
                          width: 46,
                          height: 46,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF111C2D),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 9,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Center: Title + Status Badge & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                '#$shortId',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38BDF8),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      fontSize: 10),
                                ),
                              ),
                              const Icon(Icons.person_outline_rounded,
                                  size: 12, color: Colors.white54),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (shortDate.isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        fontSize: 10),
                                  ),
                                ),
                                Text(
                                  shortDate,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Price & Expand Chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$priceCharged $currency',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? 'إخفاء' : 'تفاصيل',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white54,
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Expandable Details Section
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                            const SizedBox(height: 10),

                            // Structured Order Info Box
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1220),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.tag_rounded,
                                    label: 'رقم العملية',
                                    value: '#$orderId',
                                    isMono: true,
                                    onCopy: () =>
                                        _copyToClipboard(orderId, 'رقم الطلب'),
                                  ),
                                  const SizedBox(height: 7),
                                  _buildDetailRow(
                                    icon: Icons.person_outline_rounded,
                                    label: 'العميل',
                                    value: userEmail.isNotEmpty
                                        ? '$userName ($userEmail)'
                                        : userName,
                                  ),
                                  const SizedBox(height: 7),
                                  _buildDetailRow(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'رصيد العميل الحالي',
                                    value: '$userBalance $currency',
                                    valueColor: const Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(height: 7),
                                  _buildDetailRow(
                                    icon: Icons.folder_open_rounded,
                                    label: 'القسم الفرعي',
                                    value: productCategory,
                                  ),
                                  const SizedBox(height: 7),
                                  _buildDetailRow(
                                    icon: Icons.payments_outlined,
                                    label: 'سعر البيع / التكلفة',
                                    value:
                                        '$priceCharged $currency (التكلفة: $originalPrice $currency)',
                                  ),
                                  const SizedBox(height: 7),
                                  _buildDetailRow(
                                    icon: Icons.trending_up_rounded,
                                    label: 'صافي الربح',
                                    value: '+$profit $currency',
                                    valueColor: const Color(0xFF10B981),
                                  ),
                                  if (createdAt.isNotEmpty) ...[
                                    const SizedBox(height: 7),
                                    _buildDetailRow(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'تاريخ ووقت الطلب',
                                      value: createdAt,
                                      isMono: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Customer Input Data Box (Target ID & Extra Fields)
                            if (targetId.isNotEmpty ||
                                extraFields.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.assignment_ind_rounded,
                                            size: 14,
                                            color: Color(0xFF38BDF8)),
                                        SizedBox(width: 6),
                                        Text(
                                          'بيانات الإدخال وشحن الحساب:',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (targetId.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: _buildCopyableFieldRow(
                                            'الآيدي / الحساب', targetId),
                                      ),
                                    ...extraFields.entries.map((entry) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: _buildCopyableFieldRow(
                                            entry.key, entry.value.toString()),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            // Admin Note or Failure Reason Banner
                            if (adminNote.isNotEmpty ||
                                failureReason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: (failureReason.isNotEmpty
                                          ? const Color(0xFFF43F5E)
                                          : const Color(0xFF10B981))
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (failureReason.isNotEmpty
                                            ? const Color(0xFFF43F5E)
                                            : const Color(0xFF10B981))
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  failureReason.isNotEmpty
                                      ? 'سبب الرفض: $failureReason'
                                      : 'ملاحظة التنفيذ: $adminNote',
                                  style: TextStyle(
                                    color: failureReason.isNotEmpty
                                        ? const Color(0xFFFDA4AF)
                                        : const Color(0xFF34D399),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            // Action Buttons for Pending Orders
                            if (isPendingOrProcessing) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                        foregroundColor:
                                            const Color(0xFF064E3B),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16),
                                      label: const Text(
                                        'تأكيد وإكمال الطلب',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12),
                                      ),
                                      onPressed: () => _completeOrder(order),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFF43F5E),
                                        side: const BorderSide(
                                            color: Color(0xFFF43F5E)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      icon: const Icon(Icons.cancel_rounded,
                                          size: 15),
                                      label: const Text(
                                        'رفض وإرجاع',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5),
                                      ),
                                      onPressed: () => _rejectOrder(order),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.05),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: Colors.white70,
                                        size: 18),
                                    tooltip: 'إلغاء واسترجاع الرصيد',
                                    onPressed: () => _cancelOrder(order),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFEF4444).withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 18),
                                    tooltip: 'حذف هذا الطلب نهائياً',
                                    onPressed: () => _deleteSingleOrder(order),
                                  ),
                                ],
                              ),
                            ] else ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                label: const Text('حذف هذا الطلب من السجل', style: TextStyle(fontSize: 12)),
                                onPressed: () => _deleteSingleOrder(order),
                              ),
                            ),
                          ],
                        ],
                      )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMono = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13.5, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white60,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white,
              fontFamily: isMono ? 'monospace' : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded,
                      size: 11, color: Color(0xFF38BDF8)),
                  SizedBox(width: 3),
                  Text(
                    'نسخ',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCopyableFieldRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: () => _copyToClipboard(value, label),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 12, color: Color(0xFF38BDF8)),
                SizedBox(width: 4),
                Text(
                  'نسخ',
                  style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
