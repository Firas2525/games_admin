import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import 'admin_custom_orders_page.dart';

class AdminAllOrdersPage extends StatefulWidget {
  final String? initialDateFilter; // e.g. 'today'
  final String? initialStatusFilter; // e.g. 'all'
  final String? initialUserId;

  const AdminAllOrdersPage({
    super.key,
    this.initialDateFilter,
    this.initialStatusFilter,
    this.initialUserId,
  });

  @override
  State<AdminAllOrdersPage> createState() => _AdminAllOrdersPageState();
}

class _AdminOrdersCacheEntry {
  final List<dynamic> orders;
  final Map<String, int> counts;
  final Map<String, dynamic> stats;
  final int totalOrders;
  final int totalPages;
  final DateTime cachedAt;

  _AdminOrdersCacheEntry({
    required this.orders,
    required this.counts,
    required this.stats,
    required this.totalOrders,
    required this.totalPages,
    required this.cachedAt,
  });
}

class _AdminAllOrdersPageState extends State<AdminAllOrdersPage> {
  // Static In-Memory Cache for Admin Orders
  static final Map<String, _AdminOrdersCacheEntry> _ordersCache = {};

  // Filters
  String _dateFilter = 'today'; // 'today', 'yesterday', 'this_week', 'this_month', 'all', 'custom'
  DateTime? _customSelectedDate;
  String _statusFilter = 'all'; // 'all', 'pending', 'processing', 'completed', 'failed'
  String _sourceFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<dynamic> _orders = [];
  Map<String, int> _counts = {
    'all': 0,
    'pending': 0,
    'processing': 0,
    'completed': 0,
    'failed': 0,
    'cancelled': 0,
  };
  Map<String, dynamic> _stats = {
    'usd': {'revenue': 0, 'cost': 0, 'profit': 0, 'count': 0},
    'syp': {'revenue': 0, 'cost': 0, 'profit': 0, 'count': 0},
  };
  int _totalOrders = 0;

  // Pagination & Loading
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isBackgroundRefreshing = false;
  String? _errorMessage;
  int _page = 1;
  int _totalPages = 1;
  bool _isSyncing = false;

  // Expanded items
  final Set<String> _checkingOrderIds = {};
  final Set<String> _expandedOrderIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialDateFilter != null) {
      _dateFilter = widget.initialDateFilter!;
    }
    if (widget.initialStatusFilter != null) {
      _statusFilter = widget.initialStatusFilter!;
    }
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatYmd(DateTime dt) {
    final g = dt.toUtc().add(const Duration(hours: 3));
    return '${g.year}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '---';
    try {
      final dt = DateTime.parse(raw.toString()).toUtc().add(const Duration(hours: 3));
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  String _getDateFilterTitle() {
    switch (_dateFilter) {
      case 'today':
        return 'اليوم';
      case 'yesterday':
        return 'أمس';
      case 'this_week':
        return 'آخر 7 أيام';
      case 'this_month':
        return 'هذا الشهر';
      case 'custom':
        return _customSelectedDate != null ? _formatYmd(_customSelectedDate!) : 'تاريخ مخصص';
      case 'all':
      default:
        return 'كافة الأيام';
    }
  }

  String _getCacheKey() {
    final search = _searchController.text.trim().toLowerCase();
    final customDate = _customSelectedDate != null ? _formatYmd(_customSelectedDate!) : '';
    return '${widget.initialUserId ?? ''}|$_dateFilter|$customDate|$_statusFilter|$_sourceFilter|$search';
  }

  Future<void> _fetchOrders({bool resetPage = true, bool forceNetwork = false}) async {
    final cacheKey = _getCacheKey();

    if (resetPage) {
      final cached = _ordersCache[cacheKey];
      if (cached != null && !forceNetwork) {
        // Show cached orders immediately in 0ms!
        setState(() {
          _orders = List.from(cached.orders);
          _counts = Map<String, int>.from(cached.counts);
          _stats = Map<String, dynamic>.from(cached.stats);
          _totalOrders = cached.totalOrders;
          _totalPages = cached.totalPages;
          _isLoading = false;
          _isBackgroundRefreshing = true;
          _errorMessage = null;
          _page = 1;
        });
      } else {
        setState(() {
          _isLoading = true;
          _isBackgroundRefreshing = false;
          _errorMessage = null;
          _page = 1;
        });
      }
    }

    try {
      final queryParams = <String, dynamic>{
        'limit': 50,
        'page': _page,
      };

      if (widget.initialUserId != null && widget.initialUserId!.isNotEmpty) {
        queryParams['userId'] = widget.initialUserId;
      }

      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }

      if (_sourceFilter != 'all') {
        queryParams['source'] = _sourceFilter;
      }

      if (_dateFilter == 'custom' && _customSelectedDate != null) {
        queryParams['date'] = _formatYmd(_customSelectedDate!);
      } else if (_dateFilter != 'all') {
        queryParams['date'] = _dateFilter;
      }

      final querySearch = _searchController.text.trim();
      if (querySearch.isNotEmpty) {
        queryParams['search'] = querySearch;
      }

      final res = await sl<ApiClient>().get(
        '/orders/admin',
        queryParameters: queryParams,
      ).timeout(const Duration(seconds: 25));

      if (res.data != null && mounted) {
        final rawData = res.data['data'];
        List<dynamic> fetchedOrders = [];
        Map<String, dynamic> rawCounts = {};
        Map<String, dynamic> rawStats = {};
        int total = 0;
        int totalPgs = 1;

        if (rawData is Map) {
          fetchedOrders = rawData['orders'] as List? ?? [];
          total = (rawData['total'] as num?)?.toInt() ?? fetchedOrders.length;
          final pagination = rawData['pagination'] as Map<String, dynamic>?;
          totalPgs = (pagination?['totalPages'] as num?)?.toInt() ?? 1;

          if (rawData['counts'] is Map) {
            rawCounts = Map<String, dynamic>.from(rawData['counts']);
          }
          if (rawData['stats'] is Map) {
            rawStats = Map<String, dynamic>.from(rawData['stats']);
          }
        } else if (rawData is List) {
          fetchedOrders = rawData;
          total = rawData.length;
        }

        final parsedCounts = rawCounts.isNotEmpty
            ? {
                'all': (rawCounts['all'] as num?)?.toInt() ?? 0,
                'pending': (rawCounts['pending'] as num?)?.toInt() ?? 0,
                'processing': (rawCounts['processing'] as num?)?.toInt() ?? 0,
                'completed': (rawCounts['completed'] as num?)?.toInt() ?? 0,
                'failed': (rawCounts['failed'] as num?)?.toInt() ?? 0,
                'cancelled': (rawCounts['cancelled'] as num?)?.toInt() ?? 0,
              }
            : _counts;

        final parsedStats = rawStats.isNotEmpty ? rawStats : _stats;

        setState(() {
          if (resetPage) {
            _orders = List.from(fetchedOrders);
          } else {
            _orders.addAll(fetchedOrders);
          }

          _totalOrders = total;
          _totalPages = totalPgs;
          _counts = parsedCounts;
          _stats = parsedStats;
          _isLoading = false;
          _isLoadingMore = false;
          _isBackgroundRefreshing = false;
          _errorMessage = null;
        });

        if (resetPage) {
          _ordersCache[cacheKey] = _AdminOrdersCacheEntry(
            orders: List.from(fetchedOrders),
            counts: parsedCounts,
            stats: parsedStats,
            totalOrders: total,
            totalPages: totalPgs,
            cachedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isBackgroundRefreshing = false;
          if (_orders.isEmpty) {
            _errorMessage = 'تعذر تحميل سجل الطلبات، يرجى المحاولة ثانية';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل سجل الطلبات، يرجى المحاولة ثانية'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _page += 1;
    });
    await _fetchOrders(resetPage: false);
  }

  // --- Sync Pending Orders from External Providers ---
  Future<void> _syncPendingOrders() async {
    setState(() => _isSyncing = true);
    try {
      final res = await sl<ApiClient>().post('/orders/admin/sync-pending');
      final message = res.data?['message'] ?? 'تم فحص وتحديث الطلبات المعلقة بنجاح';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message ✅'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحديث الطلبات المعلقة مع المزودات'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // --- Check Individual Order Status ---
  Future<void> _checkSingleOrderStatus(Map<String, dynamic> order) async {
    final orderId = (order['orderId'] ?? order['_id'] ?? order['id']).toString();
    setState(() => _checkingOrderIds.add(orderId));

    try {
      final res = await sl<ApiClient>().post('/orders/$orderId/check-status');
      final updatedOrder = res.data?['data']?['order'];
      final message = res.data?['message'] ?? 'تم فحص حالة الطلب من المزود بنجاح';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (updatedOrder is Map) {
          setState(() {
            final idx = _orders.indexWhere((o) =>
                (o['orderId'] ?? o['_id'] ?? o['id']).toString() == orderId);
            if (idx != -1) {
              final Map<String, dynamic> merged =
                  Map<String, dynamic>.from(updatedOrder);
              if (merged['userId'] is! Map && _orders[idx]['userId'] is Map) {
                merged['userId'] = _orders[idx]['userId'];
              }
              _orders[idx] = merged;
            }
          });
        } else {
          _fetchOrders();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل فحص حالة الطلب: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: const Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingOrderIds.remove(orderId));
      }
    }
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

  void _copyOrderReceipt(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? order['_id'] ?? '---';
    final rawUser = order['userId'];
    final user = rawUser is Map<String, dynamic>
        ? rawUser
        : (rawUser is Map ? Map<String, dynamic>.from(rawUser) : null);
    final userName = user?['name'] ?? 'مستخدم';
    final userCode = user?['userCode'] != null ? '#${user!['userCode']}' : '';
    final userPhone = user?['phone'] ?? '';
    final productName = order['productName'] ?? order['item']?['name'] ?? 'منتج';
    final targetId = order['targetId'] ?? '';
    final price = order['userPrice'] ?? order['priceCharged'] ?? order['price'] ?? 0;
    final currency = _formatCurrencySymbol(order);
    final statusArabic = _getStatusArabic(order['status']);
    final dateStr = _formatDateTime(order['createdAt']);

    final buffer = StringBuffer();
    buffer.writeln('📋 تفاصيل الطلب: $orderId');
    buffer.writeln('👤 الزبون: $userName $userCode');
    if (userPhone.isNotEmpty) buffer.writeln('📱 الهاتف: $userPhone');
    buffer.writeln('📦 المنتج: $productName');
    if (targetId.isNotEmpty) buffer.writeln('🎮 معرف اللاعب (ID): $targetId');

    final extraFields = order['extraFields'] as Map<String, dynamic>?;
    if (extraFields != null && extraFields.isNotEmpty) {
      extraFields.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          buffer.writeln('▫️ $key: $value');
        }
      });
    }

    buffer.writeln('💰 السعر: $price $currency');
    buffer.writeln('📌 الحالة: $statusArabic');
    buffer.writeln('🕒 التاريخ: $dateStr');

    final providerOrderId = order['providerOrderId'];
    if (providerOrderId != null && providerOrderId.toString().isNotEmpty) {
      buffer.writeln('⚡ رقم الطلب عند المزود: $providerOrderId');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ ملخص تفاصيل الطلب بنجاح 📋'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تحديد فترة الطلبات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  _buildDateSheetOption(ctx, 'today', 'اليوم ☀️', Icons.today_rounded),
                  _buildDateSheetOption(ctx, 'yesterday', 'أمس ⏳', Icons.history_rounded),
                  _buildDateSheetOption(ctx, 'this_week', 'آخر 7 أيام 📅', Icons.date_range_rounded),
                  _buildDateSheetOption(ctx, 'this_month', 'هذا الشهر 📊', Icons.calendar_month_rounded),
                  _buildDateSheetOption(ctx, 'all', 'كافة الأيام 🌐', Icons.all_inclusive_rounded),
                  ListTile(
                    leading: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF38BDF8)),
                    title: Text(
                      _customSelectedDate != null
                          ? 'تاريخ مخصص: ${_formatYmd(_customSelectedDate!)}'
                          : 'اختيار تاريخ مخصص من التقويم...',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickCustomDate();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSheetOption(BuildContext ctx, String key, String title, IconData icon) {
    final isSelected = _dateFilter == key;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF38BDF8) : Colors.white60, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF38BDF8), size: 18) : null,
      onTap: () {
        Navigator.pop(ctx);
        if (_dateFilter != key) {
          setState(() {
            _dateFilter = key;
            _customSelectedDate = null;
          });
          _fetchOrders();
        }
      },
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? now,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF0284C7),
                onPrimary: Colors.white,
                surface: Color(0xFF0F172A),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0F172A),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = 'custom';
        _customSelectedDate = picked;
      });
      _fetchOrders();
    }
  }

  void _showFinancialSummaryModal() {
    final usd = _stats['usd'] as Map<String, dynamic>? ?? {};
    final syp = _stats['syp'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إحصائيات الفترة (${_getDateFilterTitle()})',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // USD box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text('💵 مبيعات الدولار (USD)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبيعات:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('\$${usd['revenue'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الربح:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('+${usd['profit'] ?? 0} \$', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('عدد الطلبات:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('${usd['count'] ?? 0} طلب', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // SYP box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text('🇸🇾 مبيعات الليرة (SYP)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبيعات:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('${syp['revenue'] ?? 0} ل.س', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الربح:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('+${syp['profit'] ?? 0} ل.س', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('عدد الطلبات:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('${syp['count'] ?? 0} طلب', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF38BDF8))),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrencySymbol(Map<String, dynamic> order) {
    final rawCurrency = (order['currency'] ?? '').toString();
    final rawUser = order['userId'];
    final user = rawUser is Map<String, dynamic>
        ? rawUser
        : (rawUser is Map ? Map<String, dynamic>.from(rawUser) : null);
    final isSyp = rawCurrency == 'SYP' ||
        rawCurrency == 'syp' ||
        rawCurrency == 'ل.س' ||
        user?['currency'] == 'SYP';
    return isSyp ? 'ل.س' : '\$';
  }

  String _getStatusArabic(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'انتظار';
      case 'processing':
        return 'قيد التنفيذ';
      case 'failed':
        return 'فاشل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status?.toString() ?? 'غير محدد';
    }
  }

  IconData _getStatusIcon(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'processing':
        return Icons.autorenew_rounded;
      case 'failed':
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'processing':
        return const Color(0xFF38BDF8); // Cyan
      case 'failed':
      case 'cancelled':
        return const Color(0xFFF43F5E); // Rose
      default:
        return Colors.grey;
    }
  }

  String _getSourceBadgeTitle(Map<String, dynamic> order) {
    final s = (order['source'] ?? '').toString().toLowerCase();
    final isManual = order['providerPayload']?['isManual'] == true ||
        order['providerPayload']?['provider'] == 'مزودي الخاص';

    if (s == 'custom' || isManual || s.isEmpty) {
      return 'مزودي الخاص (يدوي)';
    } else if (s.contains('sw') || s == 'roya_usd') {
      return 'سيرفر 1 (SwGames)';
    } else if (s == 'roya_syp') {
      return 'سيرفر 2 (Roya SYP)';
    } else if (s.contains('brand')) {
      return 'Brand1Card';
    } else if (s.contains('auto')) {
      return 'Auto1Card';
    }
    return s.toUpperCase();
  }

  Color _getSourceBadgeColor(Map<String, dynamic> order) {
    final s = (order['source'] ?? '').toString().toLowerCase();
    final isManual = order['providerPayload']?['isManual'] == true ||
        order['providerPayload']?['provider'] == 'مزودي الخاص';

    if (s == 'custom' || isManual || s.isEmpty) {
      return const Color(0xFFA855F7);
    } else if (s.contains('sw') || s == 'roya_usd') {
      return const Color(0xFF0284C7);
    } else if (s == 'roya_syp') {
      return const Color(0xFF0D9488);
    } else if (s.contains('brand')) {
      return const Color(0xFFE11D48);
    }
    return const Color(0xFF475569);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF080C16),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // 1. Search Bar + Date Dropdown (Single Compact Row)
            _buildTopSearchAndDateBar(),

            // 2. Status Pills Bar (Compact Horizontal Scroll)
            _buildStatusFilterBar(),

            // 3. Mini Financial Ribbon (1-line sleek summary)
            _buildMiniFinancialRibbon(),

            if (_isBackgroundRefreshing)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
              ),

            // 4. Compact Orders List
            Expanded(
              child: _isLoading && _orders.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                    )
                  : _orders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFF0F172A),
                          onRefresh: () => _fetchOrders(resetPage: true, forceNetwork: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (!_isLoadingMore &&
                                  scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent - 200 &&
                                  _page < _totalPages) {
                                _loadMoreOrders();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == _orders.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0284C7),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final order = _orders[index] as Map<String, dynamic>;
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF07111F),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'سجل كافة الطلبات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
            ),
            child: Text(
              '$_totalOrders',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Financial summary dialog button
        IconButton(
          icon: const Icon(Icons.analytics_outlined, color: Color(0xFF38BDF8), size: 20),
          tooltip: 'إحصائيات الأرباح والمبيعات',
          onPressed: _showFinancialSummaryModal,
        ),
        // Sync pending orders
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
          tooltip: 'فحص الطلبات المعلقة',
          onPressed: _isSyncing ? null : _syncPendingOrders,
        ),
        // Switch to custom orders or refresh menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          onSelected: (val) {
            if (val == 'custom') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCustomOrdersPage()),
              );
            } else if (val == 'refresh') {
              _fetchOrders(resetPage: true);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text('تحديث السجل', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'custom',
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFC084FC)),
                  SizedBox(width: 8),
                  Text('طلبات المزود الخاص فقط', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // --- 1. Top Search + Date Dropdown in a Single Row ---
  Widget _buildTopSearchAndDateBar() {
    return Container(
      color: const Color(0xFF07111F),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchOrders(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'بحث برقم الطلب، الزبون، الكود، ID...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _fetchOrders();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Date Dropdown Trigger Button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _showDateFilterSheet,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _dateFilter != 'all'
                    ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dateFilter != 'all'
                      ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: _dateFilter != 'all' ? const Color(0xFF38BDF8) : Colors.white60,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _getDateFilterTitle(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _dateFilter != 'all' ? const Color(0xFF38BDF8) : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Status Filter Pills (Compact horizontal scroll) ---
  Widget _buildStatusFilterBar() {
    final statusPills = [
      {'key': 'all', 'label': 'الكل', 'count': _counts['all'] ?? _totalOrders},
      {'key': 'pending', 'label': 'انتظار', 'count': _counts['pending'] ?? 0},
      {'key': 'processing', 'label': 'تنفيذ', 'count': _counts['processing'] ?? 0},
      {'key': 'completed', 'label': 'مكتمل', 'count': _counts['completed'] ?? 0},
      {
        'key': 'failed',
        'label': 'ملغي/فاشل',
        'count': (_counts['failed'] ?? 0) + (_counts['cancelled'] ?? 0)
      },
    ];

    return Container(
      color: const Color(0xFF07111F),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: statusPills.map((pill) {
            final isSelected = _statusFilter == pill['key'];
            final count = pill['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (_statusFilter != pill['key']) {
                    setState(() => _statusFilter = pill['key'] as String);
                    _fetchOrders();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pill['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- 3. Mini Financial Ribbon (1-line sleek summary) ---
  Widget _buildMiniFinancialRibbon() {
    final usd = _stats['usd'] as Map<String, dynamic>? ?? {};
    final syp = _stats['syp'] as Map<String, dynamic>? ?? {};
    final usdProfit = usd['profit'] ?? 0;
    final sypProfit = syp['profit'] ?? 0;

    return InkWell(
      onTap: _showFinancialSummaryModal,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_rounded, size: 13, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            const Text('أرباح الفترة: ', style: TextStyle(fontSize: 10.5, color: Colors.white54)),
            Text('+$usdProfit \$', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const Text(' • ', style: TextStyle(color: Colors.white24, fontSize: 11)),
            Text('+$sypProfit ل.س', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const Spacer(),
            const Text('تفاصيل المبيعات', style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: Color(0xFF38BDF8)),
          ],
        ),
      ),
    );
  }

  // --- 4. Order Card: Compact & Expandable (Exactly like User Orders!) ---
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? order['_id'] ?? '---').toString();
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final statusArabic = _getStatusArabic(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final dateStr = _formatDateTime(order['createdAt']);
    final isExpanded = _expandedOrderIds.contains(orderId);

    // Customer
    final rawUser = order['userId'];
    final user = rawUser is Map<String, dynamic>
        ? rawUser
        : (rawUser is Map ? Map<String, dynamic>.from(rawUser) : null);
    final userName = user?['name'] ?? 'مستخدم';
    final userCode = user?['userCode'] != null ? '#${user!['userCode']}' : '';
    final userPhone = (user?['phone'] ?? '').toString();
    final userCurrency = (user?['currency'] ?? 'USD').toString();

    // Product & Target ID
    final productName = order['productName'] ?? order['item']?['name'] ?? 'طلب شحن';
    final targetId = (order['targetId'] ?? '').toString().trim();

    // Financial
    final currencySymbol = _formatCurrencySymbol(order);
    final userPrice = (order['userPrice'] ?? order['priceCharged'] ?? order['price'] ?? 0);
    final costPrice = (order['costPrice'] ?? order['cost'] ?? 0);
    final profit = (order['profit'] ?? (userPrice - costPrice));

    // Provider & Execution
    final sourceBadge = _getSourceBadgeTitle(order);
    final sourceColor = _getSourceBadgeColor(order);
    final providerOrderId = (order['providerOrderId'] ?? '').toString();
    final isCheckingThis = _checkingOrderIds.contains(orderId);

    // Failure error
    final failureReason = (order['errorMessage'] ??
            order['providerResponse']?['message'] ??
            order['providerResponse']?['error'] ??
            order['adminNote'] ??
            '')
        .toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? statusColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.07),
          width: isExpanded ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. COMPACT HEADER (Always visible - ~48px height)
                Row(
                  children: [
                    // Status icon box (34x34)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 9),

                    // Title + Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  productName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  statusArabic,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Order ID + Customer Name + Time
                          Row(
                            children: [
                              Text(
                                '#${orderId.length > 14 ? orderId.substring(orderId.length - 8) : orderId}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: Colors.white30, fontSize: 10)),
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (userCode.isNotEmpty) ...[
                                const SizedBox(width: 3),
                                Text(userCode, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ],
                              const Text(' • ', style: TextStyle(color: Colors.white30, fontSize: 10)),
                              Text(
                                dateStr.contains(' ') ? dateStr.split(' ')[1] : dateStr,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Price + Expand Arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$userPrice $currencySymbol',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? 'إخفاء' : 'تفاصيل',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // 2. EXPANDED SECTION (Opens smoothly on tap!)
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 8),

                  // Customer & Order detail container
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        // Order ID full row
                        _buildDetailRow(
                          'رقم الطلب الكامل:',
                          orderId,
                          valueColor: const Color(0xFF38BDF8),
                          canCopy: true,
                          onCopy: () => _copyToClipboard(orderId, 'رقم الطلب'),
                        ),
                        const SizedBox(height: 5),

                        // Date and Time
                        _buildDetailRow('تاريخ ووقت الطلب:', dateStr),
                        const SizedBox(height: 5),

                        // Customer Details
                        _buildDetailRow(
                          'الزبون:',
                          '$userName ($userCurrency) ${userCode.isNotEmpty ? userCode : ""}',
                        ),

                        if (userPhone.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildDetailRow(
                            'هاتف الزبون:',
                            userPhone,
                            canCopy: true,
                            onCopy: () => _copyToClipboard(userPhone, 'رقم الهاتف'),
                          ),
                        ],

                        // Player ID (Target ID)
                        if (targetId.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildDetailRow(
                            'معرف اللاعب (ID):',
                            targetId,
                            valueColor: const Color(0xFF38BDF8),
                            isBold: true,
                            canCopy: true,
                            onCopy: () => _copyToClipboard(targetId, 'معرف اللاعب'),
                          ),
                        ],

                        // Extra fields
                        ..._buildExtraFieldsRows(order),

                        const SizedBox(height: 6),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 6),

                        // Financial breakdown: User Price, Cost, Net Profit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المبلغ المدفوع', style: TextStyle(fontSize: 9.5, color: Colors.white54)),
                                Text('$userPrice $currencySymbol', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('التكلفة', style: TextStyle(fontSize: 9.5, color: Colors.white54)),
                                Text('$costPrice $currencySymbol', style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('الربح الصافي', style: TextStyle(fontSize: 9.5, color: Colors.white54)),
                                Text('+$profit $currencySymbol', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 6),

                        // Provider Info
                        _buildDetailRow('مزود التنفيذ:', sourceBadge, valueColor: sourceColor),

                        if (providerOrderId.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildDetailRow(
                            'رقم المزود:',
                            providerOrderId,
                            canCopy: true,
                            onCopy: () => _copyToClipboard(providerOrderId, 'رقم طلب المزود'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // If failed error message
                  if ((status == 'failed' || status == 'cancelled') &&
                      failureReason.isNotEmpty &&
                      failureReason != 'null') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFF43F5E)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'السبب: $failureReason',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFFFDA4AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action buttons row (Compact!)
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 12),
                          label: const Text('نسخ الملخص', style: TextStyle(fontSize: 10.5)),
                          onPressed: () => _copyOrderReceipt(order),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.18),
                            foregroundColor: const Color(0xFF38BDF8),
                            elevation: 0,
                            side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isCheckingThis
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFF38BDF8)),
                                )
                              : const Icon(Icons.sync_rounded, size: 13),
                          label: Text(
                            isCheckingThis ? 'جارٍ الفحص...' : 'فحص الحالة',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          onPressed: isCheckingThis ? null : () => _checkSingleOrderStatus(order),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (canCopy)
          InkWell(
            onTap: onCopy,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.copy_rounded, size: 13, color: Color(0xFF38BDF8)),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildExtraFieldsRows(Map<String, dynamic> order) {
    final extraFields = order['extraFields'] as Map<String, dynamic>?;
    if (extraFields == null || extraFields.isEmpty) {
      return [];
    }

    final valid = extraFields.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();

    return valid.map((e) {
      return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: _buildDetailRow('${e.key}:', e.value.toString()),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    final isError = _errorMessage != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                isError ? Icons.wifi_off_rounded : Icons.inbox_rounded,
                size: 40,
                color: isError ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isError ? 'تعذر جلب الطلبات' : 'لا توجد طلبات مطابقة للفلتر',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isError
                  ? (_errorMessage ?? 'تحقق من الاتصال بالإنترنت')
                  : 'جرب تغيير فترة التاريخ أو حالة الطلبات أو كلمة البحث',
              style: const TextStyle(fontSize: 11.5, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isError ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
                side: BorderSide(color: isError ? const Color(0xFFF43F5E) : const Color(0xFF0284C7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isError ? Icons.refresh_rounded : Icons.filter_alt_off_rounded, size: 15),
              label: Text(isError ? 'إعادة المحاولة' : 'إعادة ضبط الفلاتر', style: const TextStyle(fontSize: 12)),
              onPressed: () {
                if (isError) {
                  _fetchOrders(resetPage: true, forceNetwork: true);
                } else {
                  setState(() {
                    _dateFilter = 'all';
                    _statusFilter = 'all';
                    _sourceFilter = 'all';
                    _customSelectedDate = null;
                    _searchController.clear();
                  });
                  _fetchOrders();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
