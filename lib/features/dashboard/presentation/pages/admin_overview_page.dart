import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:games_admin/core/services/service_locator.dart';
import 'package:games_admin/core/network/api_client.dart';
import 'package:games_admin/features/products/presentation/bloc/admin_products_bloc.dart';
import 'package:games_admin/features/products/presentation/bloc/admin_products_event.dart';
import 'package:games_admin/features/products/presentation/bloc/admin_products_state.dart';
import 'package:games_admin/features/products/domain/entities/product_entity.dart';
import 'package:games_admin/features/users/presentation/bloc/admin_users_bloc.dart';
import 'package:games_admin/features/users/presentation/bloc/admin_users_event.dart';
import 'package:games_admin/features/users/presentation/bloc/admin_users_state.dart';
import 'package:games_admin/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:games_admin/features/transactions/presentation/bloc/transactions_event.dart';
import 'package:games_admin/features/transactions/presentation/bloc/transactions_state.dart';
import '../widgets/admin_banners_dialog.dart';
import '../widgets/admin_banners_section.dart';
import '../widgets/admin_notifications_dialog.dart';
import '../widgets/admin_ticker_dialog.dart';
import '../widgets/admin_support_links_dialog.dart';
import '../widgets/admin_drawer.dart';
import 'admin_notifications_page.dart';
import 'admin_exchange_and_profit_page.dart';
import 'admin_profit_reports_page.dart';
import 'package:games_admin/features/orders/presentation/pages/admin_all_orders_page.dart';
import 'package:games_admin/features/deposits/presentation/pages/admin_deposits_page.dart';
import 'package:games_admin/features/deposits/presentation/pages/admin_deposit_methods_page.dart';
import 'package:games_admin/features/products/presentation/pages/admin_add_custom_product_page.dart';
import 'package:games_admin/features/categories/presentation/pages/admin_categories_page.dart';
import 'package:games_admin/features/categories/presentation/pages/admin_organization_page.dart';

class AdminOverviewPage extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;
  final Function(String mainCategory)? onFilterCategory;

  const AdminOverviewPage({
    super.key,
    required this.onNavigateTab,
    this.onFilterCategory,
  });

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  Map<String, dynamic>? _liveCatalogStats;
  bool _isLoadingStats = false;
  double _profitPercentage = 0.0;
  double _exchangeRateUsdToSyp = 15000.0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    _fetchLiveCatalogStats();
    _fetchSettings();
    context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
    context.read<AdminUsersBloc>().add(LoadUsersEvent());
    context.read<TransactionsBloc>().add(LoadTransactionsEvent());
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await sl<ApiClient>().get('/settings');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _profitPercentage = (data['profitPercentage'] as num?)?.toDouble() ?? 0.0;
          _exchangeRateUsdToSyp = (data['exchangeRateUsdToSyp'] as num?)?.toDouble() ?? 15000.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchLiveCatalogStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final res = await sl<ApiClient>().get('/products/stats');
      if (res.data != null && res.data['data'] != null && mounted) {
        setState(() {
          _liveCatalogStats = res.data['data'] as Map<String, dynamic>;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'لوحة التحكم والعمليات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 21),
            tooltip: 'سجل وإرسال الإشعارات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminNotificationsPage()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: AdminDrawer(
        currentIndex: 0,
        onNavigateTab: widget.onNavigateTab,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF38BDF8),
        backgroundColor: const Color(0xFF0F172A),
        onRefresh: () async => _refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Status & Quick Rates Overview
              _buildExecutiveWelcomeBanner(),

              // 1.5 Live Promotional Banners (Displayed exactly like user app)
              const AdminBannersSection(),

              const SizedBox(height: 16),

              // 2. Primary KPI Executive Cards Grid
              _buildExecutiveKpiGrid(),

              const SizedBox(height: 20),

              // 3. Providers Live Health & Inventory Monitor
              _buildProvidersSection(),

              const SizedBox(height: 20),

              // 4. Categories Distribution & Quick Navigation (The 7 Core Categories)
              _buildCategoriesAnalyticsSection(),

              const SizedBox(height: 20),

              // 5. Quick Administrative Actions Grid
              _buildQuickActionsPanel(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B).withValues(alpha: 0.6),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'لوحة الإدارة والمراقبة المركزية',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'النظام متصل',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive Quick Rate & Profit Indicators (Tap to manage)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminExchangeAndProfitPage()),
                  ).then((_) => _fetchSettings());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_exchange_rounded, size: 14, color: Color(0xFF34D399)),
                      const SizedBox(width: 6),
                      Text(
                        'سعر الصرف: 1\$ = ${_exchangeRateUsdToSyp.toStringAsFixed(0)} ل.س',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminExchangeAndProfitPage()),
                  ).then((_) => _fetchSettings());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.percent_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        'نسبة الربح: +${_profitPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF64748B), textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfitReportsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.query_stats_rounded, size: 14, color: Color(0xFF818CF8)),
                      SizedBox(width: 6),
                      Text(
                        'تقارير الأرباح 📊',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF64748B), textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAllOrdersPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF38BDF8)),
                      SizedBox(width: 6),
                      Text(
                        'كافة الطلبات 📦',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF64748B), textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveKpiGrid() {
    return BlocBuilder<AdminProductsBloc, AdminProductsState>(
      builder: (context, prodState) {
        int totalProducts = 0;
        int activeInApp = 0;

        if (_liveCatalogStats != null) {
          totalProducts = (_liveCatalogStats!['totalProducts'] as num?)?.toInt() ?? 0;
          activeInApp = (_liveCatalogStats!['activeProducts'] as num?)?.toInt() ?? 0;
        }

        if (prodState is AdminProductsLoaded) {
          totalProducts = prodState.products.length;
          activeInApp = prodState.products.where((p) => p.isVisible).length;
        }

        return BlocBuilder<AdminUsersBloc, AdminUsersState>(
          builder: (context, userState) {
            int totalUsers = 0;
            int countUsdUsers = 0;
            int countSypUsers = 0;
            double balanceUsd = 0.0;
            double balanceSyp = 0.0;

            if (userState is AdminUsersLoaded) {
              totalUsers = userState.users.length;
              for (final u in userState.users) {
                if (u.isSyp) {
                  countSypUsers++;
                  balanceSyp += u.balance;
                } else {
                  countUsdUsers++;
                  balanceUsd += u.balance;
                }
              }
            }

            return BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, txState) {
                int totalTransactions = 0;
                double depositsUsd = 0.0;
                double depositsSyp = 0.0;
                double rawProfitsUsd = 0.0;
                double rawProfitsSyp = 0.0;

                if (txState is TransactionsLoaded) {
                  totalTransactions = txState.transactions.length;
                  for (final t in txState.transactions) {
                    if (t.isPurchase) {
                      if (t.isSyp) {
                        rawProfitsSyp += t.profit;
                      } else {
                        rawProfitsUsd += t.profit;
                      }
                    } else if (t.isRefund) {
                      if (t.isSyp) {
                        rawProfitsSyp -= t.profit;
                      } else {
                        rawProfitsUsd -= t.profit;
                      }
                    }
                    if (t.isDeposit) {
                      if (t.isSyp) {
                        depositsSyp += t.amount;
                      } else {
                        depositsUsd += t.amount;
                      }
                    }
                  }
                }
                final double totalProfitsUsd = rawProfitsUsd > 0 ? rawProfitsUsd : 0.0;
                final double totalProfitsSyp = rawProfitsSyp > 0 ? rawProfitsSyp : 0.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 580;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 1.4 : 1.25,
                      children: [
                        _buildKpiCard(
                          title: 'صافي الربح دولار (USD)',
                          value: txState is TransactionsLoading ? '...' : '+\$${totalProfitsUsd.toStringAsFixed(2)}',
                          subtext: 'صافي أرباح مبيعات الدولار',
                          icon: Icons.trending_up_rounded,
                          valueColor: const Color(0xFF34D399),
                          accentColor: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminProfitReportsPage()),
                            );
                          },
                        ),
                        _buildKpiCard(
                          title: 'صافي الربح سوري (SYP)',
                          value: txState is TransactionsLoading ? '...' : '+${totalProfitsSyp.toStringAsFixed(0)} ل.س',
                          subtext: 'صافي أرباح مبيعات السوري',
                          icon: Icons.insights_rounded,
                          valueColor: const Color(0xFF2DD4BF),
                          accentColor: const Color(0xFF14B8A6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminProfitReportsPage()),
                            );
                          },
                        ),
                        _buildKpiCard(
                          title: 'أموال الدولار (USD)',
                          value: userState is AdminUsersLoading ? '...' : '\$${balanceUsd.toStringAsFixed(1)}',
                          subtext: 'إيداعات: \$${depositsUsd.toStringAsFixed(0)} • $countUsdUsers حساب',
                          icon: Icons.monetization_on_rounded,
                          valueColor: const Color(0xFF7DD3FC),
                          accentColor: const Color(0xFF0EA5E9),
                          onTap: () => widget.onNavigateTab(3),
                        ),
                        _buildKpiCard(
                          title: 'أموال السوري (SYP)',
                          value: userState is AdminUsersLoading ? '...' : '${balanceSyp.toStringAsFixed(0)} ل.س',
                          subtext: 'إيداعات: ${depositsSyp.toStringAsFixed(0)} ل.س • $countSypUsers حساب',
                          icon: Icons.account_balance_wallet_rounded,
                          valueColor: const Color(0xFFA5B4FC),
                          accentColor: const Color(0xFF6366F1),
                          onTap: () => widget.onNavigateTab(3),
                        ),
                        _buildKpiCard(
                          title: 'المستخدمين والمحافظ',
                          value: userState is AdminUsersLoading ? '...' : '$totalUsers',
                          subtext: '$countUsdUsers دولار • $countSypUsers سوري',
                          icon: Icons.people_alt_rounded,
                          valueColor: const Color(0xFFD8B4FE),
                          accentColor: const Color(0xFF8B5CF6),
                          onTap: () => widget.onNavigateTab(3),
                        ),
                        _buildKpiCard(
                          title: 'المستودع والعمليات',
                          value: totalProducts > 0
                              ? '$totalProducts منتج'
                              : (_isLoadingStats || prodState is AdminProductsLoading ? '...' : '0'),
                          subtext: '$totalTransactions عملية • $activeInApp نشط',
                          icon: Icons.inventory_2_rounded,
                          valueColor: const Color(0xFF67E8F9),
                          accentColor: const Color(0xFF06B6D4),
                          onTap: () => widget.onNavigateTab(1),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    Color? valueColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F172A),
              Color.lerp(const Color(0xFF0F172A), accentColor, 0.10)!,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.28), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: valueColor ?? Colors.white,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtext,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 9, color: accentColor.withValues(alpha: 0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersSection() {
    return BlocBuilder<AdminProductsBloc, AdminProductsState>(
      builder: (context, state) {
        int royaUsdCount = 0;
        int royaSypCount = 0;
        int brand1CardCount = 0;
        int customCount = 0;

        if (_liveCatalogStats != null) {
          final sources = _liveCatalogStats!['sources'] as Map<String, dynamic>?;
          if (sources != null) {
            royaUsdCount = (sources['roya_usd'] as num?)?.toInt() ?? 0;
            royaSypCount = (sources['roya_syp'] as num?)?.toInt() ?? 0;
            brand1CardCount = (sources['brand1card'] as num?)?.toInt() ?? 0;
            customCount = (sources['custom'] as num?)?.toInt() ?? 0;
          }
        }

        if (state is AdminProductsLoaded) {
          royaUsdCount = state.products.where((p) => p.source == 'roya_usd' || p.source == 'sw_games' || p.sourceName.contains('دولار')).length;
          royaSypCount = state.products.where((p) => p.source == 'roya_syp' || p.sourceName.contains('ليرة')).length;
          brand1CardCount = state.products.where((p) => p.source == 'brand1card' || p.sourceName.contains('براند')).length;
          customCount = state.products.where((p) => p.source == 'custom' || p.sourceName.contains('خاص')).length;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_rounded, size: 17, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'مزودي الخدمات المعتمدين',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      context.read<AdminProductsBloc>().add(SyncAdminProductsEvent());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جارٍ مزامنة المنتجات من المزودين...')),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 13, color: Color(0xFF38BDF8)),
                    label: const Text('مزامنة', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Providers Cards
              _buildProviderRowItem(
                name: '👑 رؤيا دولار (SW Games Fast-API USD)',
                itemCount: royaUsdCount,
                status: royaUsdCount > 0 ? 'متصل ويعمل' : (_isLoadingStats ? 'جاري التحميل...' : 'مربوط'),
                currency: 'USD (\$)',
                icon: Icons.monetization_on_rounded,
                badge: 'SW Fast-API',
              ),
              const SizedBox(height: 8),
              _buildProviderRowItem(
                name: '🇸🇾 رؤيا ليرة (SW Games SYP)',
                itemCount: royaSypCount,
                status: royaSypCount > 0 ? 'متصل' : 'جاهز للربط بالليرة',
                currency: 'SYP (ل.س)',
                icon: Icons.currency_exchange_rounded,
                badge: 'SW SYP',
              ),
              const SizedBox(height: 8),
              _buildProviderRowItem(
                name: '💎 براند ون كارد (Brand 1 Card API)',
                itemCount: brand1CardCount,
                status: brand1CardCount > 0 ? 'متصل ويعمل بنجاح' : (_isLoadingStats ? 'جاري التحميل...' : 'مربوط'),
                currency: 'USD (\$)',
                icon: Icons.credit_card_rounded,
                badge: 'Brand 1 Card',
              ),
              const SizedBox(height: 8),
              _buildProviderRowItem(
                name: '⚡ مزودي الخاص (منتجات حصرية ومعالجة يدوية)',
                itemCount: customCount,
                status: 'نشط وجاهز للمعالجة',
                currency: 'USD / SYP',
                icon: Icons.storefront_rounded,
                badge: 'معالجة يدوية',
                onTap: () => widget.onNavigateTab(2),
                trailingAction: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF334155)),
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text('الطلبات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => widget.onNavigateTab(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderRowItem({
    required String name,
    required int itemCount,
    required String status,
    required String currency,
    required IconData icon,
    required String badge,
    VoidCallback? onTap,
    Widget? trailingAction,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$itemCount منتج • $currency',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: itemCount > 0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: itemCount > 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingAction != null) ...[
              const SizedBox(width: 8),
              trailingAction,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesAnalyticsSection() {
    return BlocBuilder<AdminProductsBloc, AdminProductsState>(
      builder: (context, state) {
        final List<ProductEntity> prods = state is AdminProductsLoaded ? state.products : <ProductEntity>[];
        final catsStats = _liveCatalogStats?['categories'] as Map<String, dynamic>?;

        int getCount(String key) {
          if (prods.isNotEmpty) {
            return prods.where((p) => p.mainCategory == key).length;
          }
          if (catsStats != null && catsStats[key] != null) {
            return (catsStats[key] as num).toInt();
          }
          return 0;
        }

        final int totalDisplayCount = prods.isNotEmpty
            ? prods.length
            : ((_liveCatalogStats?['totalProducts'] as num?)?.toInt() ?? 0);

        final cats = [
          {
            'key': 'games',
            'title': 'ألعاب',
            'desc': 'ببجي، فري فاير، روبلوكس والألعاب العالمية',
            'count': getCount('games'),
            'icon': Icons.sports_esports_rounded,
          },
          {
            'key': 'apps',
            'title': 'تطبيقات',
            'desc': 'تطبيقات الشات، البث المباشر والعملات',
            'count': getCount('apps'),
            'icon': Icons.forum_rounded,
          },
          {
            'key': 'social',
            'title': 'خدمات سوشل ميديا',
            'desc': 'متابعين، لايكات، مشاهدات تيك توك وتليجرام',
            'count': getCount('social'),
            'icon': Icons.share_rounded,
          },
          {
            'key': 'subscriptions',
            'title': 'اشتراكات',
            'desc': 'نتفلكس، شاهد، يوتيوب وباقات الترفيه',
            'count': getCount('subscriptions'),
            'icon': Icons.subscriptions_rounded,
          },
          {
            'key': 'numbers',
            'title': 'أرقام',
            'desc': 'أرقام وهمية دولية لتفعيل واتساب وتليجرام',
            'count': getCount('numbers'),
            'icon': Icons.dialpad_rounded,
          },
          {
            'key': 'cards',
            'title': 'بطاقات',
            'desc': 'بطاقات متجر، جوجل بلاي، بلايستيشن وقسائم',
            'count': getCount('cards'),
            'icon': Icons.credit_card_rounded,
          },
          {
            'key': 'payment',
            'title': 'دفع إلكتروني',
            'desc': 'شحن بنوك إلكترونية ومحافظ رقمية',
            'count': getCount('payment'),
            'icon': Icons.account_balance_wallet_rounded,
          },
        ];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.category_rounded, size: 17, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'توزيع المنتجات على الأقسام الرئيسية',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalDisplayCount > 0 ? '$totalDisplayCount عنصر' : 'جاري التحميل...',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Categories List
              ...cats.map((cat) {
                final count = cat['count'] as int;
                final percent = totalDisplayCount > 0 ? (count / totalDisplayCount) : 0.0;

                return InkWell(
                  onTap: () {
                    widget.onFilterCategory?.call(cat['key'] as String);
                    widget.onNavigateTab(1);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(cat['icon'] as IconData, size: 15, color: const Color(0xFF38BDF8)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cat['title'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                      ),
                                      Text(
                                        '$count منتج (${(percent * 100).toStringAsFixed(1)}%)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF38BDF8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat['desc'] as String,
                                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF1E293B),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'إجراءات سريعة لمدير النظام',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'صفحة التنسيق (تنظيم المجلدات) 📁',
                  icon: Icons.folder_special_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOrganizationPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'إدارة وتعديل الأقسام 🗂️',
                  icon: Icons.category_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminCategoriesPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'مزامنة كاملة للمستودع',
                  icon: Icons.cloud_sync_rounded,
                  onTap: () {
                    context.read<AdminProductsBloc>().add(SyncAdminProductsEvent());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جارٍ جلب وتحديث المنتجات من كافة المزودين...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'إدارة وتفعيل المستودع',
                  icon: Icons.inventory_2_rounded,
                  onTap: () => widget.onNavigateTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'شحن رصيد مستخدم',
                  icon: Icons.add_card_rounded,
                  onTap: () => widget.onNavigateTab(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'تقارير الأرباح والمبيعات 📊',
                  icon: Icons.query_stats_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfitReportsPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'طلبات الإيداع والشحن 💳',
                  icon: Icons.payments_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDepositsPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'وسائل وطرق الإيداع ⚙️',
                  icon: Icons.tune_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDepositMethodsPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'طلباتي ⚡',
                  icon: Icons.bolt_rounded,
                  onTap: () => widget.onNavigateTab(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: '+ إضافة منتج خاص 📦',
                  icon: Icons.add_box_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAddCustomProductPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'شريط الإعلانات المتحرك 📢',
                  icon: Icons.campaign_rounded,
                  onTap: () => AdminTickerDialog.show(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'إرسال إشعار للمستخدمين 🔔',
                  icon: Icons.notifications_active_rounded,
                  onTap: () => AdminNotificationsDialog.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'تقارير الأرباح والمبيعات 📊',
                  icon: Icons.query_stats_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfitReportsPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'إدارة الإعلانات والبنرات 🖼️',
                  icon: Icons.photo_library_rounded,
                  onTap: () => AdminBannersDialog.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'روابط الدعم والتواصل 💬',
                  icon: Icons.headset_mic_rounded,
                  onTap: () => AdminSupportLinksDialog.show(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
