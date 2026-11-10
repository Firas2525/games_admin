import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminProfitReportsPage extends StatefulWidget {
  const AdminProfitReportsPage({super.key});

  @override
  State<AdminProfitReportsPage> createState() => _AdminProfitReportsPageState();
}

class _AdminProfitReportsPageState extends State<AdminProfitReportsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedPeriod = 'monthly'; // 'weekly', 'monthly', 'yearly', 'all'
  String _selectedCurrency = 'USD'; // 'USD' or 'SYP'

  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _usdData;
  Map<String, dynamic>? _sypData;

  // Active view lists based on _selectedCurrency
  List<dynamic> _timeline = [];
  List<dynamic> _topProducts = [];
  List<dynamic> _categories = [];

  // Selected bar in timeline for detail tooltip
  int? _selectedTimelineIndex;

  final List<Map<String, String>> _periodOptions = [
    {'key': 'weekly', 'label': 'أسبوعي (7 أيام)', 'icon': '🗓️'},
    {'key': 'monthly', 'label': 'شهري (30 يوم)', 'icon': '📊'},
    {'key': 'yearly', 'label': 'سنوي (هذا العام)', 'icon': '📈'},
    {'key': 'all', 'label': 'شامل (الكل)', 'icon': '🌐'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedTimelineIndex = null;
    });

    try {
      final res = await sl<ApiClient>().get(
        '/orders/admin/profit-reports',
        queryParameters: {'period': _selectedPeriod},
      );

      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _summary = data['summary'] as Map<String, dynamic>?;
          _usdData = data['usd'] as Map<String, dynamic>?;
          _sypData = data['syp'] as Map<String, dynamic>?;
          _updateActiveCurrencyData();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'لم يتم استرجاع بيانات صالحة من السيرفر';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل جلب تقارير الأرباح: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _updateActiveCurrencyData() {
    final activeData = _selectedCurrency == 'USD' ? _usdData : _sypData;
    if (activeData != null) {
      _timeline = (activeData['timeline'] as List<dynamic>?) ?? [];
      _topProducts = (activeData['topProducts'] as List<dynamic>?) ?? [];
      _categories = (activeData['categories'] as List<dynamic>?) ?? [];
    } else {
      _timeline = [];
      _topProducts = [];
      _categories = [];
    }
  }

  void _switchCurrency(String currency) {
    if (_selectedCurrency != currency) {
      setState(() {
        _selectedCurrency = currency;
        _selectedTimelineIndex = null;
        _updateActiveCurrencyData();
      });
    }
  }

  String _formatAmount(num amount, {String? currency}) {
    final cur = currency ?? _selectedCurrency;
    if (cur == 'SYP') {
      return '${_formatNumber(amount.round())} ل.س';
    } else {
      final val = amount.toDouble();
      return '\$${val.toStringAsFixed(val >= 100 ? 1 : 2)}';
    }
  }

  String _formatNumber(num number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07111F),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
              textDirection: TextDirection.ltr,
            ),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'تقارير الأرباح والمبيعات',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 22),
              tooltip: 'تحديث البيانات',
              onPressed: _fetchReports,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: RefreshIndicator(
          color: const Color(0xFF10B981),
          backgroundColor: const Color(0xFF0F172A),
          onRefresh: _fetchReports,
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text(
                        'جاري تجميع وحساب تقارير الأرباح...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildReportsContent(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline_rounded, size: 54, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'حدث خطأ أثناء تحميل البيانات',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _fetchReports,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        // 1. Period Selector Pills
        _buildPeriodSelector(),
        const SizedBox(height: 14),

        // 2. Currency Isolation Notice Bar (Clear notice: No exchange rate mixing)
        _buildCurrencyIsolationBar(),
        const SizedBox(height: 16),

        // 3. Two Executive KPI Profit Cards (USD Card & SYP Card completely separated)
        _buildExecutiveKpiCards(),
        const SizedBox(height: 20),

        // 4. Detail Currency View Switcher Pills
        _buildDetailCurrencySelector(),
        const SizedBox(height: 14),

        // 5. Active Currency 4 Sub-Metrics Grid
        _buildActiveCurrencySubKpis(),
        const SizedBox(height: 22),

        // 6. Interactive Trend Visualizer for active currency
        _buildTimelineChart(),
        const SizedBox(height: 22),

        // 7. Category Profit Breakdown for active currency
        _buildCategoryBreakdown(),
        const SizedBox(height: 22),

        // 8. Top Profitable Products for active currency
        _buildTopProductsList(),
        const SizedBox(height: 32),
      ],
    );
  }

  // 1. Period Selector
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periodOptions.map((opt) {
          final isSelected = _selectedPeriod == opt['key'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                if (_selectedPeriod != opt['key']) {
                  setState(() => _selectedPeriod = opt['key']!);
                  _fetchReports();
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(opt['icon']!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      opt['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Currency Isolation Notice Bar
  Widget _buildCurrencyIsolationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'فصل مالي تام بين العملات (بدون تحويل بسعر الصرف)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'أرباح حسابات الليرة مستقلة تماماً عن أرباح حسابات الدولار، ولا يتم دمجهما حسب سعر الصرف.',
                  style: TextStyle(color: Colors.white60, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Executive KPI Cards: Separate USD & SYP Grand Cards
  Widget _buildExecutiveKpiCards() {
    final s = _summary ?? {};
    final profitUsd = (s['totalProfitUsd'] as num?)?.toDouble() ?? 0.0;
    final revUsd = (s['totalRevenueUsd'] as num?)?.toDouble() ?? 0.0;
    final costUsd = (s['totalCostUsd'] as num?)?.toDouble() ?? 0.0;
    final ordersCountUsd = (s['ordersCountUsd'] as num?)?.toInt() ?? 0;
    final profitMarginUsd = (s['profitMarginUsd'] as num?)?.toDouble() ?? 0.0;
    final profitGrowthUsd = (s['profitGrowthUsd'] as num?)?.toDouble() ?? 0.0;

    final profitSyp = (s['totalProfitSyp'] as num?)?.toDouble() ?? 0.0;
    final revSyp = (s['totalRevenueSyp'] as num?)?.toDouble() ?? 0.0;
    final costSyp = (s['totalCostSyp'] as num?)?.toDouble() ?? 0.0;
    final ordersCountSyp = (s['ordersCountSyp'] as num?)?.toInt() ?? 0;
    final profitMarginSyp = (s['profitMarginSyp'] as num?)?.toDouble() ?? 0.0;
    final profitGrowthSyp = (s['profitGrowthSyp'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        // USD Highlight Card
        _buildHeroProfitCard(
          currency: 'USD',
          title: 'أرباح حسابات الدولار (\$)',
          icon: Icons.attach_money_rounded,
          iconColor: const Color(0xFF34D399),
          profitText: '+\$${profitUsd.toStringAsFixed(profitUsd >= 100 ? 1 : 2)}',
          profitColor: const Color(0xFF34D399),
          gradientColors: const [Color(0xFF064E3B), Color(0xFF0F172A)],
          borderColor: _selectedCurrency == 'USD'
              ? const Color(0xFF10B981)
              : const Color(0xFF059669).withValues(alpha: 0.35),
          growth: profitGrowthUsd,
          revenueText: '\$${revUsd.toStringAsFixed(1)}',
          costText: '\$${costUsd.toStringAsFixed(1)}',
          ordersCount: ordersCountUsd,
          margin: profitMarginUsd,
          isSelected: _selectedCurrency == 'USD',
          onTap: () => _switchCurrency('USD'),
        ),
        const SizedBox(height: 12),

        // SYP Highlight Card
        _buildHeroProfitCard(
          currency: 'SYP',
          title: 'أرباح حسابات الليرة السورية (ل.س)',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF38BDF8),
          profitText: '+${_formatNumber(profitSyp.round())} ل.س',
          profitColor: const Color(0xFF38BDF8),
          gradientColors: const [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          borderColor: _selectedCurrency == 'SYP'
              ? const Color(0xFF818CF8)
              : const Color(0xFF6366F1).withValues(alpha: 0.35),
          growth: profitGrowthSyp,
          revenueText: '${_formatNumber(revSyp.round())} ل.س',
          costText: '${_formatNumber(costSyp.round())} ل.س',
          ordersCount: ordersCountSyp,
          margin: profitMarginSyp,
          isSelected: _selectedCurrency == 'SYP',
          onTap: () => _switchCurrency('SYP'),
        ),
      ],
    );
  }

  Widget _buildHeroProfitCard({
    required String currency,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String profitText,
    required Color profitColor,
    required List<Color> gradientColors,
    required Color borderColor,
    required double growth,
    required String revenueText,
    required String costText,
    required int ordersCount,
    required double margin,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: isSelected ? 0.25 : 0.08),
              blurRadius: 14,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'المعروضة',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildGrowthBadge(growth),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              profitText,
              style: TextStyle(
                color: profitColor,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'مبيعات: $revenueText • تكلفة: $costText',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$ordersCount طلب ($margin%)',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Detail Currency View Switcher Pills
  Widget _buildDetailCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _switchCurrency('USD'),
              borderRadius: BorderRadius.circular(11),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedCurrency == 'USD'
                      ? const Color(0xFF0284C7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💵', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'تفاصيل أرباح الدولار (\$)',
                        style: TextStyle(
                          color: _selectedCurrency == 'USD' ? Colors.white : Colors.white60,
                          fontWeight: _selectedCurrency == 'USD' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _switchCurrency('SYP'),
              borderRadius: BorderRadius.circular(11),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedCurrency == 'SYP'
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🇸🇾', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'تفاصيل أرباح الليرة (ل.س)',
                        style: TextStyle(
                          color: _selectedCurrency == 'SYP' ? Colors.white : Colors.white60,
                          fontWeight: _selectedCurrency == 'SYP' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Active Currency 4 Sub-Metrics Grid
  Widget _buildActiveCurrencySubKpis() {
    final activeData = _selectedCurrency == 'USD' ? _usdData : _sypData;
    final activeSummary = (activeData?['summary'] as Map<String, dynamic>?) ?? {};

    final rev = (activeSummary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final cost = (activeSummary['totalCost'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = (activeSummary['ordersCount'] as num?)?.toInt() ?? 0;
    final margin = (activeSummary['profitMargin'] as num?)?.toDouble() ?? 0.0;
    final revGrowth = (activeSummary['revenueGrowth'] as num?)?.toDouble() ?? 0.0;

    final curSymbol = _selectedCurrency == 'USD' ? '\$' : 'ل.س';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSubKpiCard(
                title: 'إجمالي المبيعات',
                value: _formatAmount(rev),
                subValue: 'مبيعات طلبات $curSymbol',
                icon: Icons.point_of_sale_rounded,
                iconColor: const Color(0xFF38BDF8),
                growth: revGrowth,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSubKpiCard(
                title: 'تكلفة المشتريات',
                value: _formatAmount(cost),
                subValue: 'تكلفة طلبات $curSymbol',
                icon: Icons.shopping_cart_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSubKpiCard(
                title: 'الطلبات المكتملة',
                value: '${_formatNumber(ordersCount)} طلب',
                subValue: 'طلبات $curSymbol الناجحة',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSubKpiCard(
                title: 'نسبة الهامش',
                value: '$margin%',
                subValue: 'صافي الربح من المبيعات',
                icon: Icons.percent_rounded,
                iconColor: const Color(0xFFA78BFA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubKpiCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color iconColor,
    double? growth,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              if (growth != null) _buildMiniGrowthBadge(growth),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthBadge(double growth) {
    final isPositive = growth >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isPositive ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: isPositive ? const Color(0xFF34D399) : Colors.redAccent,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? "+" : ""}${growth.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? const Color(0xFF34D399) : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGrowthBadge(double growth) {
    final isPositive = growth >= 0;
    return Text(
      '${isPositive ? "+" : ""}${growth.toStringAsFixed(1)}%',
      style: TextStyle(
        color: isPositive ? const Color(0xFF34D399) : Colors.redAccent,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 4. Interactive Trend Visualizer
  Widget _buildTimelineChart() {
    if (_timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.white24),
              SizedBox(height: 8),
              Text(
                'لا توجد عمليات مكتملة في هذه الفترة لعرض الرسم البياني',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate max profit to scale bars
    double maxProfit = 0;
    for (final item in _timeline) {
      final p = (item['profit'] as num?)?.toDouble() ?? 0.0;
      if (p > maxProfit) maxProfit = p;
    }
    if (maxProfit <= 0) maxProfit = 1.0;

    final selectedItem = _selectedTimelineIndex != null &&
            _selectedTimelineIndex! < _timeline.length
        ? _timeline[_selectedTimelineIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'مسار الأرباح اليومية / الشهرية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_timeline.length} نقطة زمنية',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Callout if a bar is tapped
          if (selectedItem != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'التاريخ: ${selectedItem['date']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'الربح: ${_formatAmount((selectedItem['profit'] as num?) ?? 0)}',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الطلبات: ${selectedItem['ordersCount']}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                  ),
                ],
              ),
            ),

          // Bar Chart Container
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_timeline.length, (index) {
                final item = _timeline[index];
                final profit = (item['profit'] as num?)?.toDouble() ?? 0.0;
                final heightFactor = (profit / maxProfit).clamp(0.06, 1.0);
                final isSelected = _selectedTimelineIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimelineIndex = isSelected ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip on top when selected
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '\$${profit.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),

                          // The Animated Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 95 * heightFactor,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                                    : [const Color(0xFF10B981), const Color(0xFF047857)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Date label below bar
                          Text(
                            _formatTimelineLabel(item['date'] as String?),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white38,
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '💡 انقر على أي عمود لعرض تفاصيل ذلك اليوم أو الشهر',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimelineLabel(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      // Return "MM/DD"
      return '${parts[1]}/${parts[2]}';
    } else if (parts.length == 2) {
      // Return "M"
      return parts[1];
    }
    return dateStr;
  }

  // 5. Category Profit Breakdown
  Widget _buildCategoryBreakdown() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category_rounded, color: Color(0xFFA78BFA), size: 20),
              SizedBox(width: 8),
              Text(
                'توزيع الأرباح حسب الأقسام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._categories.map((cat) {
            final catName = _translateCategory(cat['category'] as String?);
            final profit = (cat['totalProfit'] as num?)?.toDouble() ?? 0.0;
            final share = (cat['profitShare'] as num?)?.toDouble() ?? 0.0;
            final count = cat['ordersCount'] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                catName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($count طلب)',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatAmount(profit),
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$share%',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (share / 100).clamp(0.01, 1.0),
                      backgroundColor: const Color(0xFF1E293B),
                      color: _getCategoryColor(cat['category'] as String?),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _translateCategory(String? cat) {
    if (cat == null || cat.isEmpty) return 'عام';
    switch (cat.toLowerCase()) {
      case 'games':
        return 'الألعاب 🎮';
      case 'apps':
        return 'التطبيقات 📱';
      case 'cards':
        return 'البطاقات الرقمية 💳';
      case 'numbers':
        return 'الأرقام المميزة 🔢';
      case 'payment':
        return 'بنوك ومحافظ 🏦';
      case 'custom':
        return 'مزودي الخاص 📦';
      default:
        return cat;
    }
  }

  Color _getCategoryColor(String? cat) {
    if (cat == null) return const Color(0xFF10B981);
    switch (cat.toLowerCase()) {
      case 'games':
        return const Color(0xFF38BDF8);
      case 'apps':
        return const Color(0xFF10B981);
      case 'cards':
        return const Color(0xFFA78BFA);
      case 'numbers':
        return const Color(0xFFF59E0B);
      case 'payment':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF10B981);
    }
  }

  // 6. Top Profitable Products
  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(
          child: Text(
            'لا توجد مبيعات مكتملة لعرض أكثر المنتجات ربحية',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 20),
              SizedBox(width: 8),
              Text(
                'أعلى 10 منتجات تحقيقاً للأرباح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._topProducts.map((p) {
            final rank = p['rank'] ?? 1;
            final name = p['productName'] ?? 'منتج غير محدد';
            final img = p['image'] as String?;
            final profit = (p['totalProfit'] as num?)?.toDouble() ?? 0.0;
            final rev = (p['totalRevenue'] as num?)?.toDouble() ?? 0.0;
            final count = p['ordersCount'] ?? 0;
            final margin = (p['profitMargin'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rank == 1
                      ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
                      : const Color(0xFF334155),
                ),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getRankColor(rank).withValues(alpha: 0.2),
                      border: Border.all(color: _getRankColor(rank)),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: _getRankColor(rank),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img != null && img.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: img,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF0F172A),
                              child: const Icon(Icons.image, size: 18, color: Colors.white24),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF0F172A),
                              child: const Icon(Icons.games_rounded, size: 18, color: Colors.white38),
                            ),
                          )
                        : Container(
                            width: 38,
                            height: 38,
                            color: const Color(0xFF0F172A),
                            child: const Icon(Icons.inventory_2_rounded, size: 18, color: Colors.white38),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$count طلب مكتمل • هامش: $margin%',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // Profit figures
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(profit),
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مبيعات: ${_formatAmount(rev)}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24); // Gold
      case 2:
        return const Color(0xFF94A3B8); // Silver
      case 3:
        return const Color(0xFFD97706); // Bronze
      default:
        return Colors.white54;
    }
  }
}

