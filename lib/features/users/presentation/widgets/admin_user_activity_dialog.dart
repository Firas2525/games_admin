import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../domain/entities/admin_user_entity.dart';

class AdminUserActivityDialog extends StatefulWidget {
  final AdminUserEntity user;
  final Function(AdminUserEntity updatedUser)? onUserUpdated;
  final VoidCallback? onBalanceAction;

  const AdminUserActivityDialog({
    super.key,
    required this.user,
    this.onUserUpdated,
    this.onBalanceAction,
  });

  static Future<void> show(
    BuildContext context, {
    required AdminUserEntity user,
    Function(AdminUserEntity updatedUser)? onUserUpdated,
    VoidCallback? onBalanceAction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminUserActivityDialog(
        user: user,
        onUserUpdated: onUserUpdated,
        onBalanceAction: onBalanceAction,
      ),
    );
  }

  @override
  State<AdminUserActivityDialog> createState() =>
      _AdminUserActivityDialogState();
}

class _AdminUserActivityDialogState extends State<AdminUserActivityDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Orders State
  bool _isLoadingOrders = true;
  String? _ordersError;
  List<dynamic> _orders = [];
  String _ordersFilter = 'all'; // all, completed, pending, failed

  // Transactions State
  bool _isLoadingTransactions = true;
  String? _transactionsError;
  List<dynamic> _transactions = [];
  String _transactionsFilter =
      'all'; // all, deposit, purchase, deduction, refund

  late AdminUserEntity _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserOrders();
    _loadUserTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
    });

    try {
      final res = await sl<ApiClient>().get(
        '/orders/admin',
        queryParameters: {'userId': _currentUser.id},
      );

      if (res.data != null && mounted) {
        final rawData = res.data['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['orders'] is List) {
          list = rawData['orders'];
        }

        setState(() {
          _orders = list;
          _isLoadingOrders = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
          _ordersError = 'تعذر تحميل سجل طلبات المستخدم';
        });
      }
    }
  }

  Future<void> _loadUserTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionsError = null;
    });

    try {
      final res = await sl<ApiClient>().get(
        '/users/${_currentUser.id}/transactions',
      );

      if (res.data != null && mounted) {
        final rawData = res.data['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        }

        setState(() {
          _transactions = list;
          _isLoadingTransactions = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
          _transactionsError = 'تعذر تحميل سجل عمليات الرصيد';
        });
      }
    }
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  List<dynamic> get _filteredOrders {
    if (_ordersFilter == 'all') return _orders;
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      if (_ordersFilter == 'completed') return status == 'completed';
      if (_ordersFilter == 'pending') {
        return status == 'pending' || status == 'processing';
      }
      if (_ordersFilter == 'failed') {
        return status == 'failed' || status == 'cancelled';
      }
      return true;
    }).toList();
  }

  List<dynamic> get _filteredTransactions {
    if (_transactionsFilter == 'all') return _transactions;
    return _transactions.where((t) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      return type == _transactionsFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: maxHeight,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Header: User Identity & Actions
            _buildUserHeader(),

            // Financial Summary Bar
            _buildFinancialBar(),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0284C7),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('طلبات المستخدم (${_orders.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz_rounded, size: 17),
                        const SizedBox(width: 6),
                        Text('سجل العمليات (${_transactions.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOrdersTab(), _buildTransactionsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
            child: Text(
              _currentUser.name.isNotEmpty
                  ? _currentUser.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentUser.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _currentUser.isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentUser.isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : Colors.redAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _currentUser.isActive ? 'نشط' : 'محظور',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _currentUser.isActive
                              ? const Color(0xFF34D399)
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentUser.email} • كود: #${_currentUser.displayId}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Current Balance
          Column(
            children: [
              Text(
                'الرصيد المتاح (${_currentUser.currencySymbol})',
                style: const TextStyle(fontSize: 10.5, color: Colors.white60),
              ),
              const SizedBox(height: 3),
              Text(
                '${_currentUser.balance.toStringAsFixed(_currentUser.isSyp ? 0 : 2)} ${_currentUser.currencySymbol}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _currentUser.isSyp
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 32, color: Colors.white12),

          // Total Profit
          Column(
            children: [
              const Text(
                'أرباحنا من العميل',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF6EE7B7)),
              ),
              const SizedBox(height: 3),
              Text(
                '+${_currentUser.totalProfit.toStringAsFixed(_currentUser.isSyp ? 0 : 2)} ${_currentUser.currencySymbol}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF34D399),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 32, color: Colors.white12),

          // Total Spent
          Column(
            children: [
              const Text(
                'إجمالي مشترياته',
                style: TextStyle(fontSize: 10.5, color: Colors.white60),
              ),
              const SizedBox(height: 3),
              Text(
                '${_currentUser.totalSpent.toStringAsFixed(_currentUser.isSyp ? 0 : 2)} ${_currentUser.currencySymbol}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================== ORDERS TAB ======================
  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0284C7)),
      );
    }

    if (_ordersError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            Text(
              _ordersError!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _loadUserOrders,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredOrders;

    return Column(
      children: [
        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip(
                'الكل (${_orders.length})',
                'all',
                _ordersFilter,
                (v) => setState(() => _ordersFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'مكتمل 🟢',
                'completed',
                _ordersFilter,
                (v) => setState(() => _ordersFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'قيد التنفيذ ⏳',
                'pending',
                _ordersFilter,
                (v) => setState(() => _ordersFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'ملغي / مرفوض 🔴',
                'failed',
                _ordersFilter,
                (v) => setState(() => _ordersFilter = v),
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0284C7),
            onRefresh: _loadUserOrders,
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _orders.isEmpty
                              ? 'لم يقم هذا المستخدم بأي طلبات حتى الآن'
                              : 'لا توجد طلبات مطابقة لهذا الفلتر',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = filtered[index] as Map<String, dynamic>;
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId =
        order['orderId']?.toString() ?? order['id']?.toString() ?? '';
    final productName = order['productName']?.toString() ?? 'منتج غير محدد';
    final targetId = order['targetId']?.toString() ?? '';
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final source = order['source']?.toString() ?? 'custom';
    final userPrice =
        (order['userPrice'] as num?)?.toDouble() ??
        (order['priceCharged'] as num?)?.toDouble() ??
        (order['price'] as num?)?.toDouble() ??
        0.0;
    final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
    final refunded = order['refunded'] == true;
    final rawCurrency = order['currency']?.toString().toUpperCase() ?? '';
    final isOrderSyp = rawCurrency == 'SYP' || rawCurrency == 'ل.س' || _currentUser.isSyp;
    final orderCurrencySymbol = isOrderSyp ? 'ل.س' : '\$';
    final createdAt = _formatDateTime(order['createdAt']);

    Color statusColor;
    String statusText;
    if (status == 'completed') {
      statusColor = const Color(0xFF10B981);
      statusText = 'مكتمل';
    } else if (status == 'pending' || status == 'processing') {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'قيد التنفيذ';
    } else if (status == 'failed' || status == 'cancelled') {
      statusColor = Colors.redAccent;
      statusText = 'ملغي / مرفوض';
    } else {
      statusColor = Colors.grey;
      statusText = status;
    }

    if (refunded) {
      statusText = '$statusText (مسترجع)';
      statusColor = const Color(0xFFA855F7);
    }

    String sourceLabel = 'مزودي الخاص';
    if (source == 'roya_usd' || source == 'roya_syp') {
      sourceLabel = 'موقع رؤيا';
    } else if (source == 'onecard') {
      sourceLabel = 'ون كارد';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videogame_asset_rounded,
                  color: Color(0xFF38BDF8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceLabel,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          createdAt,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (targetId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    size: 14,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الآيدي / اللاعب: ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  Expanded(
                    child: SelectableText(
                      targetId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: targetId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ آيدي اللاعب'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),

          // Order Pricing & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'المبلغ: ${userPrice.toStringAsFixed(isOrderSyp ? 0 : 2)} $orderCurrencySymbol',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  if (profit > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ربح: +${profit.toStringAsFixed(isOrderSyp ? 0 : 2)} $orderCurrencySymbol',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    '#${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade400,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رقم الطلب'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================== TRANSACTIONS TAB ======================
  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0284C7)),
      );
    }

    if (_transactionsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            Text(
              _transactionsError!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _loadUserTransactions,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredTransactions;

    return Column(
      children: [
        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip(
                'الكل (${_transactions.length})',
                'all',
                _transactionsFilter,
                (v) => setState(() => _transactionsFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'إيداعات 💰',
                'deposit',
                _transactionsFilter,
                (v) => setState(() => _transactionsFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'مشتريات 🛍️',
                'purchase',
                _transactionsFilter,
                (v) => setState(() => _transactionsFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'خصومات 🔻',
                'deduction',
                _transactionsFilter,
                (v) => setState(() => _transactionsFilter = v),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'استرجاع ↩',
                'refund',
                _transactionsFilter,
                (v) => setState(() => _transactionsFilter = v),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0284C7),
            onRefresh: _loadUserTransactions,
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _transactions.isEmpty
                              ? 'لا توجد عمليات رصيد مسجلة لهذا المستخدم'
                              : 'لا توجد عمليات مطابقة لهذا الفلتر',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filtered[index] as Map<String, dynamic>;
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type = (tx['type'] ?? 'deposit').toString().toLowerCase();
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final prevBalance = (tx['previousBalance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = (tx['newBalance'] as num?)?.toDouble() ?? 0.0;
    final currency = tx['currency']?.toString() ?? '\$';
    final note = tx['note']?.toString() ?? '';
    final productName = tx['productName']?.toString() ?? '';
    final createdAt = _formatDateTime(tx['createdAt']);
    final admin = tx['adminId'] is Map
        ? tx['adminId'] as Map<String, dynamic>
        : null;
    final adminName = admin != null ? admin['name']?.toString() : null;

    final isDeposit = type == 'deposit';
    final isRefund = type == 'refund';
    final isPurchase = type == 'purchase';

    Color color;
    IconData icon;
    String typeTitle;
    String sign;

    if (isDeposit) {
      color = const Color(0xFF10B981);
      icon = Icons.add_circle_outline_rounded;
      typeTitle = 'إيداع رصيد';
      sign = '+';
    } else if (isRefund) {
      color = const Color(0xFFA855F7);
      icon = Icons.replay_circle_filled_rounded;
      typeTitle = 'استرجاع رصيد';
      sign = '+';
    } else if (isPurchase) {
      color = const Color(0xFF0284C7);
      icon = Icons.shopping_bag_rounded;
      typeTitle = 'عملية شراء';
      sign = '-';
    } else {
      color = const Color(0xFFF43F5E);
      icon = Icons.remove_circle_outline_rounded;
      typeTitle = 'خصم رصيد';
      sign = '-';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName.isNotEmpty ? productName : typeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${amount.toStringAsFixed(currency == 'SYP' || currency == 'ل.س' ? 0 : 2)} $currency',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),

          // Balance flow & notes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حركة الرصيد: ${prevBalance.toStringAsFixed(2)} ➔ ${newBalance.toStringAsFixed(2)} $currency',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
              ),
              if (adminName != null) ...[
                Text(
                  'بواسطة: $adminName',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ],
            ],
          ),

          if (note.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'ملاحظة: $note',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
