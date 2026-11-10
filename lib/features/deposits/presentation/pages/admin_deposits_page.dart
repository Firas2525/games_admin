import 'package:games_admin/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import 'admin_deposit_methods_page.dart';

class AdminDepositsPage extends StatefulWidget {
  const AdminDepositsPage({super.key});

  @override
  State<AdminDepositsPage> createState() => _AdminDepositsPageState();
}

class _AdminDepositsPageState extends State<AdminDepositsPage> {
  String _selectedFilter = 'pending'; // pending, accepted, rejected, all
  List<dynamic> _deposits = [];
  Map<String, int> _counts = {'all': 0, 'pending': 0, 'accepted': 0, 'rejected': 0};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDeposits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeposits() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_selectedFilter != 'all') {
        queryParams['status'] = _selectedFilter;
      }
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }

      final res = await sl<ApiClient>().get('/deposits/admin', queryParameters: queryParams);
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _deposits = data['deposits'] as List? ?? [];
          final rawCounts = data['counts'] as Map<String, dynamic>?;
          if (rawCounts != null) {
            _counts = {
              'all': (rawCounts['all'] as num?)?.toInt() ?? 0,
              'pending': (rawCounts['pending'] as num?)?.toInt() ?? 0,
              'accepted': (rawCounts['accepted'] as num?)?.toInt() ?? 0,
              'rejected': (rawCounts['rejected'] as num?)?.toInt() ?? 0,
            };
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptDeposit(Map<String, dynamic> dep) async {
    final id = dep['_id'] ?? dep['id'];
    final user = dep['userId'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? dep['userName'] ?? 'الزبون';
    final userEmail = user?['email'] ?? dep['userEmail'] ?? '';
    final netAmount = dep['netAmount'] ?? dep['amount'];
    final currency = dep['creditCurrency'] ?? 'USD';

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
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 10),
              Text('اعتماد وقبول طلب الإيداع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من مراجعة الحوالة وإضافة الرصيد لحساب العميل؟',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF162032),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الزبون المستفيد:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('البريد الإلكتروني:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text(userEmail, style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5)),
                        ],
                      ),
                    ],
                    const Divider(color: Colors.white12, height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الصافي للشحن:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '$netAmount $currency',
                          style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، شحن الرصيد الآن ✅', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await sl<ApiClient>().post('/deposits/admin/$id/accept');
      _fetchDeposits();
      if (!mounted) return;
      final msg = res.data?['message'] ?? 'تم قبول الإيداع وشحن الرصيد بنجاح ✅';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _rejectDeposit(Map<String, dynamic> dep) async {
    final id = dep['_id'] ?? dep['id'];
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 10),
              Text('رفض طلب الإيداع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'يرجى كتابة سبب الرفض بوضوح ليظهر للزبون في سجل طلباته:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثال: رقم العملية غير صحيح، لم يصل التحويل لحسابنا، المبلغ غير متطابق...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                ),
              ),
            ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                if (reasonController.text.trim().length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى كتابة سبب رفض واضح (3 أحرف على الأقل)'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('تأكيد الرفض ❌', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await sl<ApiClient>().post(
        '/deposits/admin/$id/reject',
        data: {'reason': reasonController.text.trim()},
      );
      _fetchDeposits();
      if (!mounted) return;
      final msg = res.data?['message'] ?? 'تم رفض طلب الإيداع وتوثيق السبب بنجاح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showReceiptImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_rounded, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Text('صورة إشعار التحويل 📷', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppNetworkImage(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(30),
                      color: const Color(0xFF1E293B),
                      child: const Column(
                        children: [
                          Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('تعذر تحميل صورة الإشعار', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1424),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'طلبات شحن الإيداع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'تحديث القائمة',
              onPressed: _fetchDeposits,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            // Top Dedicated Operations Banner (Zero Overflow, Spacious & Executive)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.16),
                    const Color(0xFF131D31),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طرق ووسائل الإيداع',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'تعديل الحسابات، العمولات، وصور الإشعار',
                          style: TextStyle(color: Colors.white60, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDepositMethodsPage()),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('إدارة الوسائل ⚙️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs & Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1424),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  // Scrollable Status Counters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusCounterCard(
                          keyFilter: 'pending',
                          title: 'قيد المراجعة',
                          count: _counts['pending'] ?? 0,
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusCounterCard(
                          keyFilter: 'accepted',
                          title: 'المقبولة',
                          count: _counts['accepted'] ?? 0,
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusCounterCard(
                          keyFilter: 'rejected',
                          title: 'المرفوضة',
                          count: _counts['rejected'] ?? 0,
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusCounterCard(
                          keyFilter: 'all',
                          title: 'الكل',
                          count: _counts['all'] ?? 0,
                          icon: Icons.all_inclusive_rounded,
                          color: const Color(0xFF38BDF8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onSubmitted: (_) => _fetchDeposits(),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، الإيميل، رقم العملية، أو كود الإيداع...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF141D30),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _fetchDeposits();
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 18),
                              onPressed: _fetchDeposits,
                            ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),

            // Deposits List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                  : _deposits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, size: 50, color: Colors.white38),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _selectedFilter == 'pending' ? 'لا توجد طلبات إيداع معلقة حالياً 🎉' : 'لا توجد طلبات إيداع مطابقة',
                                style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedFilter == 'pending' ? 'جميع طلبات الزبائن تمت مراجعتها بنجاح' : 'جرّب تغيير معيار البحث أو الفلتر',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _fetchDeposits,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('تحديث القائمة الآن'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchDeposits,
                          color: const Color(0xFF0284C7),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                            itemCount: _deposits.length,
                            itemBuilder: (context, index) {
                              final dep = _deposits[index] as Map<String, dynamic>;
                              return _buildResponsiveDepositCard(dep);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCounterCard({
    required String keyFilter,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isSel = _selectedFilter == keyFilter;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = keyFilter);
        _fetchDeposits();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.22) : const Color(0xFF141D30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? color : Colors.white12,
            width: isSel ? 1.6 : 1.0,
          ),
          boxShadow: isSel
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSel ? color : Colors.white60),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSel ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSel ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveDepositCard(Map<String, dynamic> dep) {
    final user = dep['userId'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? dep['userName'] ?? 'الزبون';
    final userEmail = user?['email'] ?? dep['userEmail'] ?? '';
    final userBalance = (user?['balance'] as num?)?.toDouble() ?? 0.0;
    final userCurrency = user?['currency'] ?? 'USD';

    final depositId = dep['depositId'] ?? '';
    final methodTitle = dep['methodTitle'] ?? 'طريقة إيداع';
    final amount = dep['amount'] ?? 0;
    final netAmount = dep['netAmount'] ?? amount;
    final feeAmount = dep['feeAmount'] ?? 0;
    final feePercent = dep['feePercent'] ?? 0;
    final sourceCurrency = dep['sourceCurrency'] ?? 'USD';
    final creditCurrency = dep['creditCurrency'] ?? 'USD';
    final operationNumber = dep['operationNumber'] ?? '';
    final note = dep['note'] ?? '';
    final status = dep['status'] ?? 'pending';
    final rejectionReason = dep['rejectionReason'] ?? '';
    final receiptImage = dep['receiptImage'] ?? '';
    final createdAt = dep['createdAt'] ?? '';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'accepted':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'تم الشحن ✅';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'مرفوض ❌';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'قيد المراجعة ⏳';
        statusIcon = Icons.hourglass_top_rounded;
    }

    final formattedDate = createdAt.toString().isNotEmpty
        ? createdAt.toString().replaceFirst('T', ' ').split('.').first
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: User Profile, Balance, Status Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141D30),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '#$depositId',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (userEmail.isNotEmpty)
                            Flexible(
                              child: Text(
                                userEmail,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            '• رصيد: $userBalance $userCurrency',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Ticket Body: Financial breakdown & verification
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Info: Sent amount and net credit box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(methodTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ],
                          ),
                          Text(
                            '$amount $sourceCurrency',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('عمولة التحويل: $feeAmount (خصم $feePercent%)', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          if (formattedDate.isNotEmpty)
                            Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5)),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي المبلغ المعتمد للشحن:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            '$netAmount $creditCurrency',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Operation ID / TxID Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090E1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 15, color: Color(0xFFFACC15)),
                      const SizedBox(width: 4),
                      Text('رقم العملية: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5)),
                      Expanded(
                        child: SelectableText(
                          operationNumber,
                          style: const TextStyle(
                            color: Color(0xFFFACC15),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: operationNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ رقم العملية ✅'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded, color: Color(0xFFFACC15), size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                if (receiptImage.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showReceiptImageDialog(receiptImage),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_rounded, color: Color(0xFFC4B5FD), size: 16),
                          SizedBox(width: 6),
                          Text('معاينة صورة إشعار التحويل 📷', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],

                if (note.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملاحظة العميل: $note',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (status == 'rejected' && rejectionReason.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFCA5A5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'سبب الرفض: $rejectionReason',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons for Pending Requests
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 3,
                          ),
                          onPressed: () => _acceptDeposit(dep),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                          label: const Text('قبول وشحن الرصيد ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _rejectDeposit(dep),
                          icon: const Icon(Icons.cancel_outlined, size: 17),
                          label: const Text('رفض الطلب ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
