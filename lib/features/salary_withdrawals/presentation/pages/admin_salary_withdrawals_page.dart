import 'package:games_admin/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import 'admin_salary_service_form_page.dart';

class AdminSalaryWithdrawalsPage extends StatefulWidget {
  const AdminSalaryWithdrawalsPage({super.key});

  @override
  State<AdminSalaryWithdrawalsPage> createState() => _AdminSalaryWithdrawalsPageState();
}

class _AdminSalaryWithdrawalsPageState extends State<AdminSalaryWithdrawalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Requests state
  bool _isLoadingRequests = false;
  List<dynamic> _requests = [];
  String _selectedStatusFilter = 'all'; // all, pending, approved, rejected
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedRequestIds = {};

  // Services state
  bool _isLoadingServices = false;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
    _loadServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final dio = sl<ApiClient>().dio;
      String url = '/salary-withdrawals/admin/requests';
      final queryParams = <String, dynamic>{};
      // Status filtering is done client-side so the KPI counters stay accurate.
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }

      final res = await dio.get(url, queryParameters: queryParams);
      if (!mounted) return;
      if (res.data != null && res.data['data'] is List) {
        setState(() {
          _requests = res.data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الطلبات: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.get('/salary-withdrawals/admin/services');
      if (!mounted) return;
      if (res.data != null && res.data['data'] is List) {
        setState(() {
          _services = res.data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الخدمات: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status, {String? notes}) async {
    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.patch(
        '/salary-withdrawals/admin/requests/$requestId/status',
        data: {
          'status': status,
          'adminNotes': notes ?? '',
        },
      );
      if (mounted) {
        final msg = res.data?['message'] ?? 'تم تحديث حالة الطلب بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الحالة: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showRejectDialog(dynamic req) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF131F35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('رفض طلب السحب', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من رفض طلب ${req['serviceName']} للمستخدم ${req['userName']}؟',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'سبب الرفض (يظهر للمستخدم)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'مثال: رقم الحساب غير صحيح، أو تم إلغاء المعاملة...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _updateRequestStatus(req['_id'], 'rejected', notes: noteController.text.trim());
              },
              child: const Text('تأكيد الرفض'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(dynamic req) {
    final noteController = TextEditingController();
    final qty = req['quantity'] ?? 0;
    final isDollars = req['withdrawalType'] == 'dollars';
    final calcDollars = (req['calculatedDollars'] as num?)?.toDouble() ?? (isDollars ? (qty as num).toDouble() : 0.0);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF131F35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('الموافقة على طلب السحب وإيداع الرصيد', style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تأكيد قبول طلب سحب $qty ${req['unitName'] ?? (isDollars ? "دولار" : "كوينز")} لتطبيق ${req['serviceName']} لصالح ${req['userName']}؟',
                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المبلغ الصافي الذي سيتم إيداعه في محفظة المستخدم:',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            req['creditedCurrency'] == 'SYP'
                                ? '${req['creditedAmount'] ?? ''} ل.س (\$${calcDollars.toStringAsFixed(2)} USD)'
                                : '\$${calcDollars.toStringAsFixed(2)} USD',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (req['feePercentage'] != null && (req['feePercentage'] as num) > 0)
                            Text(
                              'بعد خصم عمولة ${req['feePercentage']}% (-${((req['feeDollars'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}\$)',
                              style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ملاحظة إدارية اختيارية (رقم التحويل / إشعار)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'مثال: تم التحويل بنجاح، رقم الإشعار 49281...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _updateRequestStatus(req['_id'], 'approved', notes: noteController.text.trim());
              },
              child: const Text('تأكيد القبول وإيداع الرصيد 💵'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openServiceForm({dynamic service}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSalaryServiceFormPage(service: service),
      ),
    );
    if (result == true) {
      _loadServices();
    }
  }

  Future<void> _deleteService(dynamic service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF131F35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('حذف الخدمة', style: TextStyle(color: Colors.white)),
          content: Text(
            'هل أنت متأكد من حذف "${service['name']}" نهائياً؟',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final dio = sl<ApiClient>().dio;
        await dio.delete('/salary-withdrawals/admin/services/${service['_id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الخدمة بنجاح'), backgroundColor: Colors.green),
          );
          _loadServices();
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

  // ===================== Helpers =====================

  static const _kBg = Color(0xFF080C16);
  static const _kBar = Color(0xFF07111F);
  static const _kCard = Color(0xFF0F172A);
  static const _kInner = Color(0xFF131D31);
  static const _kAccent = Color(0xFF38BDF8);
  static const _kBlue = Color(0xFF0284C7);
  static const _kGreen = Color(0xFF10B981);
  static const _kAmber = Color(0xFFF59E0B);
  static const _kRed = Color(0xFFF43F5E);

  int _countBy(String status) =>
      status == 'all' ? _requests.length : _requests.where((r) => (r['status'] ?? 'pending') == status).length;

  List<dynamic> get _filteredRequests => _selectedStatusFilter == 'all'
      ? _requests
      : _requests.where((r) => (r['status'] ?? 'pending') == _selectedStatusFilter).toList();

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label'),
        backgroundColor: _kBlue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatNum(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  Widget _serviceImage(dynamic url, {double size = 50, double radius = 12}) {
    final hasImg = url != null && url.toString().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: _kInner,
        child: hasImg
            ? AppNetworkImage(
                url.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.account_balance_wallet_rounded, color: _kAccent, size: size * 0.5),
              )
            : Icon(Icons.account_balance_wallet_rounded, color: _kAccent, size: size * 0.5),
      ),
    );
  }

  Future<void> _toggleServiceActive(dynamic service) async {
    final newVal = service['isActive'] != true;
    setState(() => service['isActive'] = newVal);
    try {
      final dio = sl<ApiClient>().dio;
      await dio.put('/salary-withdrawals/admin/services/${service['_id']}', data: {'isActive': newVal});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newVal ? 'تم تفعيل التطبيق' : 'تم تعطيل التطبيق'),
            backgroundColor: newVal ? _kGreen : Colors.grey.shade700,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => service['isActive'] = !newVal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تغيير الحالة: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ===================== Build =====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'سحب رواتب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, color: _kAccent, size: 18),
              ),
              tooltip: 'تحديث',
              onPressed: () {
                _loadRequests();
                _loadServices();
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _kInner,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kBlue, Color(0xFF0369A1)]),
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                unselectedLabelStyle: const TextStyle(fontSize: 12.5),
                tabs: [
                  Tab(height: 36, text: 'طلبات السحب (${_requests.length})'),
                  Tab(height: 36, text: 'تطبيقات السحب (${_services.length})'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildServicesTab(),
          ],
        ),
      ),
    );
  }

  // ===================== Requests Tab =====================

  Widget _buildRequestsTab() {
    final list = _filteredRequests;
    return Column(
      children: [
        // KPI cards
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: [
              _buildKpiCard(title: 'قيد الانتظار', value: '${_countBy('pending')}', icon: Icons.hourglass_top_rounded, color: _kAmber),
              const SizedBox(width: 8),
              _buildKpiCard(title: 'مقبولة', value: '${_countBy('approved')}', icon: Icons.check_circle_rounded, color: _kGreen),
              const SizedBox(width: 8),
              _buildKpiCard(title: 'مرفوضة', value: '${_countBy('rejected')}', icon: Icons.cancel_rounded, color: _kRed),
              const SizedBox(width: 8),
              _buildKpiCard(title: 'الإجمالي', value: '${_countBy('all')}', icon: Icons.assignment_rounded, color: _kBlue),
            ],
          ),
        ),

        // Filter pills
        Container(
          color: _kBar,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(label: 'قيد الانتظار', value: 'pending', color: _kAmber),
                const SizedBox(width: 8),
                _buildFilterPill(label: 'الكل', value: 'all', color: _kBlue),
                const SizedBox(width: 8),
                _buildFilterPill(label: 'مقبولة', value: 'approved', color: _kGreen),
                const SizedBox(width: 8),
                _buildFilterPill(label: 'مرفوضة', value: 'rejected', color: _kRed),
              ],
            ),
          ),
        ),

        // Search
        Container(
          color: _kBar,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onSubmitted: (_) => _loadRequests(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الطلب، اسم المستخدم، الهاتف أو التطبيق...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kAccent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white60),
                      onPressed: () {
                        _searchController.clear();
                        _loadRequests();
                      },
                    )
                  : null,
              filled: true,
              fillColor: _kInner,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: _isLoadingRequests && _requests.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kBlue))
              : RefreshIndicator(
                  color: _kBlue,
                  backgroundColor: _kCard,
                  onRefresh: _loadRequests,
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            _buildEmptyState(
                              icon: Icons.inbox_rounded,
                              title: 'لا توجد طلبات سحب في هذا القسم',
                              subtitle: _selectedStatusFilter == 'pending'
                                  ? 'كافة طلبات السحب تمت معالجتها! ✨'
                                  : 'جرب تغيير شروط البحث أو الفرز',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: list.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _buildRequestCard(list[i]),
                        ),
                ),
        ),
      ],
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
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
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

  Widget _buildFilterPill({required String label, required String value, required Color color}) {
    final isSel = _selectedStatusFilter == value;
    final count = _countBy(value);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedStatusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.22) : _kInner,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? color : Colors.white12, width: isSel ? 1.5 : 1),
          boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)] : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSel ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
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

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final status = (req['status'] ?? 'pending').toString();
    final isPending = status == 'pending';
    final reqKey = (req['_id'] ?? req['requestId'] ?? '').toString();
    final requestId = (req['requestId'] ?? reqKey).toString();
    final userName = (req['userName'] ?? 'مستخدم').toString();
    final userPhone = (req['userPhone'] ?? '').toString();
    final adminNotes = (req['adminNotes'] ?? '').toString();
    final isExpanded = _expandedRequestIds.contains(reqKey);

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = _kGreen;
        statusText = 'مقبول';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = _kRed;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = _kAmber;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.hourglass_top_rounded;
    }

    final fieldsData = req['fieldsData'];
    final Map<String, dynamic> customFields =
        (fieldsData is Map) ? Map<String, dynamic>.from(fieldsData) : {};

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? statusColor.withValues(alpha: 0.55)
              : (isPending ? _kAmber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
          width: isExpanded ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedRequestIds.remove(reqKey);
              } else {
                _expandedRequestIds.add(reqKey);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Compact header (always visible)
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
                            ),
                            child: _serviceImage(req['serviceImage'], size: 38, radius: 19),
                          ),
                          Positioned(
                            bottom: -2,
                            left: -2,
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: const BoxDecoration(color: _kCard, shape: BoxShape.circle),
                              child: Icon(statusIcon, color: statusColor, size: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (req['serviceName'] ?? 'تطبيق سحب').toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 12, color: _kAccent),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  ' • ${_formatDate(req['createdAt'])}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNum(req['quantity']),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded ? 'إخفاء' : 'تفاصيل',
                                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Expanded details
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kInner,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('رقم الطلب', '#$requestId', valueColor: _kAccent, copyValue: requestId),
                          const SizedBox(height: 7),
                          _buildDetailRow('التطبيق', (req['serviceName'] ?? '').toString(), isBold: true),
                          const SizedBox(height: 7),
                          _buildDetailRow('المستخدم', userName, copyValue: userName),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            _buildDetailRow('الهاتف', userPhone, copyValue: userPhone),
                          ],
                          const SizedBox(height: 7),
                          _buildDetailRow(
                            'الكمية المطلوبة',
                            '${_formatNum(req['quantity'])} ${req['unitName'] ?? (req['withdrawalType'] == 'dollars' ? 'دولار' : 'كوينز')}',
                            valueColor: _kGreen,
                            isBold: true,
                          ),
                          if (req['grossDollars'] != null && (req['feePercentage'] as num? ?? 0) > 0) ...[
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'المبلغ الإجمالي',
                              '\$${((req['grossDollars'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} USD',
                            ),
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'عمولة المنصة (${req['feePercentage']}%)',
                              '-\$${((req['feeDollars'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} USD',
                              valueColor: const Color(0xFFF59E0B),
                            ),
                          ],
                          if (req['calculatedDollars'] != null || req['withdrawalType'] == 'dollars') ...[
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'صافي الإيداع بالدولار',
                              '\$${((req['calculatedDollars'] as num?)?.toDouble() ?? (req['quantity'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} USD',
                              valueColor: const Color(0xFF10B981),
                              isBold: true,
                            ),
                          ],
                          if (req['creditedCurrency'] == 'SYP' || req['exchangeRate'] != null) ...[
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'المبلغ بالليرة السورية',
                              '${req['creditedAmount'] ?? ''} ل.س (صرف: 1\$ = ${req['exchangeRate'] ?? ''} ل.س)',
                              valueColor: const Color(0xFF38BDF8),
                              isBold: true,
                            ),
                          ],
                          if (req['adminReceiverId'] != null && req['adminReceiverId'].toString().isNotEmpty) ...[
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'معرّف تحويل الأدمن',
                              req['adminReceiverId'].toString(),
                              copyValue: req['adminReceiverId'].toString(),
                            ),
                          ],
                          if (req['isCredited'] == true) ...[
                            const SizedBox(height: 7),
                            _buildDetailRow(
                              'حالة الإيداع',
                              'تم إيداع ${req['creditedAmount'] ?? ''} ${req['creditedCurrency'] ?? 'USD'} في المحفظة',
                              valueColor: _kGreen,
                            ),
                          ],
                          const SizedBox(height: 7),
                          _buildDetailRow('تاريخ الطلب', _formatDate(req['createdAt'])),
                        ],
                      ),
                    ),

                    if (customFields.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.input_rounded, size: 14, color: _kAccent),
                                SizedBox(width: 6),
                                Text(
                                  'بيانات السحب المدخلة',
                                  style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...customFields.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: _buildCopyableFieldRow(e.key, '${e.value}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (adminNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 15),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                status == 'rejected' ? 'سبب الرفض: $adminNotes' : 'ملاحظة الإدارة: $adminNotes',
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    if (isPending)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kGreen,
                                foregroundColor: const Color(0xFF064E3B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 17),
                              label: const Text('قبول الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                              onPressed: () => _showApproveDialog(req),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kRed,
                                side: const BorderSide(color: _kRed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              label: const Text('رفض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _showRejectDialog(req),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('تغيير الحالة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showStatusChangeOptions(req),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    String? copyValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 11.5,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyValue != null && copyValue.isNotEmpty) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyToClipboard(copyValue, label),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy_rounded, size: 12, color: Colors.white54),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableFieldRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 11, color: _kAccent),
                SizedBox(width: 3),
                Text('نسخ', style: TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusChangeOptions(dynamic req) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعديل حالة الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.hourglass_top_rounded, color: _kAmber),
                title: const Text('إعادة إلى قيد الانتظار', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateRequestStatus(req['_id'], 'pending');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: _kGreen),
                title: const Text('قبول الطلب', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showApproveDialog(req);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: _kRed),
                title: const Text('رفض الطلب', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRejectDialog(req);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Services Tab =====================

  Widget _buildServicesTab() {
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            children: [
              _buildKpiCard(title: 'كل التطبيقات', value: '${_services.length}', icon: Icons.apps_rounded, color: _kBlue),
              const SizedBox(width: 8),
              _buildKpiCard(title: 'مفعلة', value: '$activeCount', icon: Icons.toggle_on_rounded, color: _kGreen),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'معطلة',
                value: '${_services.length - activeCount}',
                icon: Icons.toggle_off_rounded,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),

        // Add button (non-floating, same style as orders page)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openServiceForm(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kBlue, Color(0xFF0369A1)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: _kBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'إضافة تطبيق سحب',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: _isLoadingServices && _services.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kBlue))
              : RefreshIndicator(
                  color: _kBlue,
                  backgroundColor: _kCard,
                  onRefresh: _loadServices,
                  child: _services.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            _buildEmptyState(
                              icon: Icons.apps_outlined,
                              title: 'لا توجد تطبيقات سحب مضافة',
                              subtitle: 'اضغط على "إضافة تطبيق سحب" للبدء',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                          itemCount: _services.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _buildServiceCard(_services[i]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final isActive = service['isActive'] == true;
    final requiredFields = (service['requiredFields'] is List)
        ? List<String>.from(service['requiredFields'].map((e) => e.toString()))
        : <String>[];
    final description = (service['description'] ?? '').toString();
    final statusColor = isActive ? _kGreen : const Color(0xFF94A3B8);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular image with status ring (matches user-side circles)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isActive
                            ? [_kAccent, _kBlue]
                            : [Colors.white24, Colors.white10],
                      ),
                    ),
                    child: _serviceImage(service['imageUrl'], size: 58, radius: 29),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (service['name'] ?? '').toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActive ? 'مفعّل' : 'معطّل',
                                    style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Limits
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(child: _buildLimitTile('أقل كمية', _formatNum(service['minQuantity']), Icons.south_rounded, _kAmber)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildLimitTile('أكبر كمية', _formatNum(service['maxQuantity']), Icons.north_rounded, _kGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildLimitTile('حقول مطلوبة', '${requiredFields.length}', Icons.list_alt_rounded, _kAccent)),
                ],
              ),
            ),

            // Required fields
            if (requiredFields.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in requiredFields)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kInner,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 12, color: _kAccent),
                            const SizedBox(width: 3),
                            Text(f, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Footer actions
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _kGreen,
                      inactiveThumbColor: Colors.white60,
                      inactiveTrackColor: Colors.white12,
                      onChanged: (_) => _toggleServiceActive(service),
                    ),
                  ),
                  Text(
                    isActive ? 'ظاهر للمستخدمين' : 'مخفي عن المستخدمين',
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _kAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('تعديل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _openServiceForm(service: service),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _kRed.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: _kRed, size: 18),
                    tooltip: 'حذف التطبيق',
                    onPressed: () => _deleteService(service),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _kInner,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
