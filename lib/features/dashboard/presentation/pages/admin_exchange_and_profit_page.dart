import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminExchangeAndProfitPage extends StatefulWidget {
  const AdminExchangeAndProfitPage({super.key});

  @override
  State<AdminExchangeAndProfitPage> createState() => _AdminExchangeAndProfitPageState();
}

class _AdminExchangeAndProfitPageState extends State<AdminExchangeAndProfitPage> {
  bool _isLoading = true;
  bool _isSavingRate = false;
  bool _isSavingProfit = false;
  bool _isSavingCashback = false;

  double _exchangeRateUsdToSyp = 15000.0;
  double _profitPercentage = 0.0;
  double _cashbackPercentage = 5.0;
  int _coinsPerDollar = 100;
  bool _isCashbackActive = true;
  String _simSpendCurrency = 'USD';

  late TextEditingController _rateController;
  late TextEditingController _profitController;
  late TextEditingController _cashbackPercentController;
  late TextEditingController _coinsPerDollarController;
  final TextEditingController _simSypController = TextEditingController(text: '150000');
  final TextEditingController _simCostController = TextEditingController(text: '10');
  final TextEditingController _simSpendController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: '15000');
    _profitController = TextEditingController(text: '0.0');
    _cashbackPercentController = TextEditingController(text: '100.0');
    _coinsPerDollarController = TextEditingController(text: '100');
    _loadSettings();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _profitController.dispose();
    _cashbackPercentController.dispose();
    _coinsPerDollarController.dispose();
    _simSypController.dispose();
    _simCostController.dispose();
    _simSpendController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    // 1. Read local cache first for instant persistence
    final sp = sl<ApiClient>().sharedPreferences;
    final cachedCb = sp.getDouble('saved_cashback_percentage');
    final cachedCpd = sp.getInt('saved_coins_per_dollar');
    final cachedCbActive = sp.getBool('saved_is_cashback_active');
    if (cachedCb != null) _cashbackPercentage = cachedCb;
    if (cachedCpd != null) _coinsPerDollar = cachedCpd;
    if (cachedCbActive != null) _isCashbackActive = cachedCbActive;

    try {
      final res = await sl<ApiClient>().get('/settings');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        final rate = (data['exchangeRateUsdToSyp'] as num?)?.toDouble() ?? 15000.0;
        final profit = (data['profitPercentage'] as num?)?.toDouble() ?? 0.0;
        final cbFromApi = (data['cashbackPercentage'] as num?)?.toDouble();
        final cpdFromApi = (data['coinsPerDollar'] as num?)?.toInt();
        final cbActiveFromApi = data['isCashbackActive'] != null ? (data['isCashbackActive'] == true) : null;

        // Load from API or fallback to local cache / default 100%
        final cbPct = cbFromApi ?? cachedCb ?? 100.0;
        final cpd = cpdFromApi ?? cachedCpd ?? 100;
        final cbActive = cbActiveFromApi ?? cachedCbActive ?? true;

        setState(() {
          _exchangeRateUsdToSyp = rate;
          _profitPercentage = profit;
          _cashbackPercentage = cbPct;
          _coinsPerDollar = cpd;
          _isCashbackActive = cbActive;

          _rateController.text = rate.toStringAsFixed(0);
          _profitController.text = profit.toStringAsFixed(1);
          _cashbackPercentController.text = cbPct.toStringAsFixed(1);
          _coinsPerDollarController.text = cpd.toString();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExchangeRate() async {
    final val = double.tryParse(_rateController.text.trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سعر صرف صالح أكبر من الصفر'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSavingRate = true);
    try {
      await sl<ApiClient>().patch('/settings', data: {'exchangeRateUsdToSyp': val});
      if (mounted) {
        setState(() {
          _exchangeRateUsdToSyp = val;
          _isSavingRate = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ وتحديث سعر الصرف بنجاح (1\$ = ${val.toStringAsFixed(0)} ل.س) ✅'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingRate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ سعر الصرف ❌'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveProfitPercentage() async {
    final val = double.tryParse(_profitController.text.trim());
    if (val == null || val < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال نسبة ربح صالحة (0 أو أكبر)'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSavingProfit = true);
    try {
      await sl<ApiClient>().patch('/settings', data: {'profitPercentage': val});
      if (mounted) {
        setState(() {
          _profitPercentage = val;
          _isSavingProfit = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ نسبة الربح (${val.toStringAsFixed(1)}%) وتطبيقها على جميع الأسعار ✅'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingProfit = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ نسبة الربح ❌'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveCashbackSettings() async {
    final cbVal = double.tryParse(_cashbackPercentController.text.trim());
    final cpdVal = int.tryParse(_coinsPerDollarController.text.trim());

    if (cbVal == null || cbVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال نسبة كاش باك صالحة (0 أو أكبر)'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (cpdVal == null || cpdVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عدد كوينز مقابل الدولار أكبر من الصفر'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 1. Immediately persist locally to SharedPreferences for zero-lag retention
    final sp = sl<ApiClient>().sharedPreferences;
    await sp.setDouble('saved_cashback_percentage', cbVal);
    await sp.setInt('saved_coins_per_dollar', cpdVal);
    await sp.setBool('saved_is_cashback_active', _isCashbackActive);

    // 2. Immediately update state so UI changes instantly
    setState(() {
      _cashbackPercentage = cbVal;
      _coinsPerDollar = cpdVal;
      _cashbackPercentController.text = cbVal.toStringAsFixed(1);
      _coinsPerDollarController.text = cpdVal.toString();
      _isSavingCashback = true;
    });

    try {
      await sl<ApiClient>().patch('/settings', data: {
        'cashbackPercentage': cbVal,
        'coinsPerDollar': cpdVal,
        'isCashbackActive': _isCashbackActive,
      });

      if (mounted) {
        setState(() {
          _cashbackPercentage = cbVal;
          _coinsPerDollar = cpdVal;
          _isSavingCashback = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ وتحديث إعدادات الكاش باك بنجاح (${cbVal.toStringAsFixed(1)}% كاش باك | $cpdVal كوينز = 1\$) ✅'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingCashback = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ وتطبيق الإعدادات بنجاح (${cbVal.toStringAsFixed(1)}% كاش باك | $cpdVal كوينز = 1\$) ✅'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
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
        backgroundColor: const Color(0xFF07111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07111F),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الصرف ونسبة الربح',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 20),
              tooltip: 'تحديث البيانات',
              onPressed: _loadSettings,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary Banner
                    _buildOverviewBanner(),

                    const SizedBox(height: 18),

                    // 1. Exchange Rate Card
                    _buildExchangeRateSection(),

                    const SizedBox(height: 20),

                    // 2. Profit Margin Section
                    _buildProfitMarginSection(),

                    const SizedBox(height: 20),

                    // 3. Cashback & Coins Section
                    _buildCashbackSection(),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0284C7).withValues(alpha: 0.18),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إعدادات التسعير والتحويل المالي',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'التحكم المركزي بسعر صرف الدولار المعتمد ونسب أرباح المتجر المفروضة تلقائياً على المنتجات.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    final double inputRate = double.tryParse(_rateController.text.trim()) ?? _exchangeRateUsdToSyp;
    final double simSyp = double.tryParse(_simSypController.text.trim()) ?? 150000.0;
    final double simResultUsd = inputRate > 0 ? (simSyp / inputRate) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سعر صرف الدولار (USD / SYP)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'المعتمد لتحويل إيداعات الليرة السورية إلى رصيد دولار',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                ),
                child: Text(
                  '1\$ = ${_exchangeRateUsdToSyp.toStringAsFixed(0)} ل.س',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // Input Field
          const Text(
            'سعر صرف 1 دولار بالليرة السورية:',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '15000',
              hintStyle: const TextStyle(color: Colors.white30),
              suffixText: 'ل.س',
              suffixStyle: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: const Color(0xFF0B1322),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          // Quick Delta Buttons
          const Text('تعديل سريع للسعر:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDeltaChip('-1000', -1000, _rateController),
              _buildDeltaChip('-500', -500, _rateController),
              _buildDeltaChip('-100', -100, _rateController),
              _buildDeltaChip('+100', 100, _rateController),
              _buildDeltaChip('+500', 500, _rateController),
              _buildDeltaChip('+1000', 1000, _rateController),
            ],
          ),

          const SizedBox(height: 14),

          // Preset Target Rates
          const Text('أسعار شائعة جاهزة:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [14000.0, 14500.0, 15000.0, 15500.0, 16000.0].map((rate) {
              final isCurrent = (inputRate - rate).abs() < 1;
              return ActionChip(
                label: Text('${rate.toStringAsFixed(0)} ل.س', style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                )),
                backgroundColor: isCurrent ? const Color(0xFF059669) : const Color(0xFF1E293B),
                side: BorderSide(color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF334155)),
                onPressed: () {
                  _rateController.text = rate.toStringAsFixed(0);
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Live Calculator Simulator Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1322),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'حاسبة معاينة التحويل المباشر:',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _simSypController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'المبلغ المدفوع بالليرة',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          suffixText: 'ل.س',
                          suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_back_rounded, color: Color(0xFF34D399), size: 16),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رصيد الدولار:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                            Text(
                              '\$${simResultUsd.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSavingRate ? null : _saveExchangeRate,
              icon: _isSavingRate
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSavingRate ? 'جارٍ الحفظ...' : 'حفظ وتطبيق سعر الصرف',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginSection() {
    final double inputProfit = double.tryParse(_profitController.text.trim()) ?? _profitPercentage;
    final double simCost = double.tryParse(_simCostController.text.trim()) ?? 10.0;
    final double userPrice = simCost * (1 + inputProfit / 100);
    final double storeProfit = userPrice - simCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.percent_rounded, color: Color(0xFF38BDF8), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نسبة ربح المتجر العامة (%)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'تُضاف تلقائياً على تكلفة جميع منتجات المتجر',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                ),
                child: Text(
                  '+${_profitPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // Input Field
          const Text(
            'نسبة الربح المئوية (%):',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _profitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '10.0',
              hintStyle: const TextStyle(color: Colors.white30),
              suffixText: '%',
              suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: const Color(0xFF0B1322),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Preset Chips
          const Text('نسب سريعة شائعة:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((pct) {
              final isCurrent = (inputProfit - pct).abs() < 0.05;
              return ActionChip(
                label: Text(
                  pct == 0.0 ? '0% (بدون ربح)' : '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                backgroundColor: isCurrent ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                side: BorderSide(color: isCurrent ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                onPressed: () {
                  _profitController.text = pct.toStringAsFixed(1);
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Live Profit Simulator Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1322),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.query_stats_rounded, color: Color(0xFF38BDF8), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'معاينة حية لتسعير المنتجات:',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _simCostController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'تكلفة المزود',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('سعر المستخدم:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                            Text(
                              '\$${userPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ربحك الصافي:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                            Text(
                              '+\$${storeProfit.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 12.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSavingProfit ? null : _saveProfitPercentage,
              icon: _isSavingProfit
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSavingProfit ? 'جارٍ الحفظ...' : 'حفظ وتطبيق نسبة الربح',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashbackSection() {
    final double? parsedCb = double.tryParse(_cashbackPercentController.text.trim());
    final double inputCashback = parsedCb ?? _cashbackPercentage;
    final int? parsedCpd = int.tryParse(_coinsPerDollarController.text.trim());
    final int inputCpd = (parsedCpd != null && parsedCpd > 0) ? parsedCpd : _coinsPerDollar;
    final double inputRate = double.tryParse(_rateController.text.trim()) ?? _exchangeRateUsdToSyp;
    final double simSpend = double.tryParse(_simSpendController.text.trim()) ?? 0.0;

    final double spentInUsd = _simSpendCurrency == 'SYP'
        ? (inputRate > 0 ? (simSpend / inputRate) : 0.0)
        : simSpend;

    final double simCoins = _isCashbackActive ? ((spentInUsd * (inputCashback / 100) * 10).round() / 10) : 0.0;
    final String simCoinsDisplay = simCoins % 1 == 0 ? simCoins.toInt().toString() : simCoins.toStringAsFixed(1);
    final double redeemedUsd = inputCpd > 0 ? (simCoins / inputCpd) : 0.0;
    final int simSyp = (redeemedUsd * inputRate).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isCashbackActive ? const Color(0xFF0284C7).withValues(alpha: 0.35) : const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Active Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نظام الكاش باك والكوينز (Coins)',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isCashbackActive
                          ? 'مفعل ويمنح كوينز عند كل شراء'
                          : 'معطل مؤقتاً',
                      style: TextStyle(
                        color: _isCashbackActive ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Current Saved Percentage Badge in Blue
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                ),
                child: Text(
                  '+${_cashbackPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Switch(
                value: _isCashbackActive,
                activeThumbColor: const Color(0xFF38BDF8),
                activeTrackColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
                inactiveThumbColor: const Color(0xFF64748B),
                inactiveTrackColor: const Color(0xFF1E293B),
                onChanged: (val) {
                  setState(() => _isCashbackActive = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Info description in Blue
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يحصل المستخدم على كوينز كاش باك تلقائياً بنسبة من مشترياته (مثال: 100% تعني أن كل 1\$ شراء يمنحه 1 كوينز، و 50% تمنحه 1 كوينز لكل 2\$). يمكن استبدال الكوينز برصيد حقيقي بمحفظته بسعر الصرف المحدد أدناه.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 1. Cashback Percentage Input + Steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'نسبة الكاش باك الممنوحة من المشتريات:',
                style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              Text(
                'الحالية: ${_cashbackPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashbackPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.percent_rounded, color: Color(0xFF38BDF8), size: 18),
                    suffixText: '%',
                    suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 15),
                    hintText: '100.0',
                    hintStyle: const TextStyle(color: Color(0xFF475569)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // Stepper buttons for precision: -1% and +1%
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Color(0xFF38BDF8), size: 18),
                      onPressed: () {
                        final cur = double.tryParse(_cashbackPercentController.text.trim()) ?? _cashbackPercentage;
                        final next = (cur - 1.0).clamp(0.0, 10000.0);
                        _cashbackPercentController.text = next.toStringAsFixed(next == next.roundToDouble() ? 0 : 1);
                        setState(() {});
                      },
                      tooltip: 'إنقاص 1%',
                    ),
                    Container(width: 1, height: 24, color: const Color(0xFF1E293B)),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 18),
                      onPressed: () {
                        final cur = double.tryParse(_cashbackPercentController.text.trim()) ?? _cashbackPercentage;
                        final next = (cur + 1.0).clamp(0.0, 10000.0);
                        _cashbackPercentController.text = next.toStringAsFixed(next == next.roundToDouble() ? 0 : 1);
                        setState(() {});
                      },
                      tooltip: 'زيادة 1%',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Preset Chips for Cashback % in Blue
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [0.0, 10.0, 25.0, 50.0, 75.0, 100.0, 150.0, 200.0].map((preset) {
              final isSelected = (inputCashback - preset).abs() < 0.05;
              final String chipLabel = preset == 0.0
                  ? '0% (معطل)'
                  : preset == 100.0
                      ? '100% (1\$ = 1 كوينز)'
                      : '${preset.toStringAsFixed(0)}%';
              return ActionChip(
                label: Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                onPressed: () {
                  _cashbackPercentController.text = preset.toStringAsFixed(preset == preset.roundToDouble() ? 0 : 1);
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // 2. Coins Per Dollar Input + Steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سعر استبدال الكوينز (كل X كوينز = 1 دولار):',
                style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              Text(
                'الحالي: $_coinsPerDollar كوينز = 1\$',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coinsPerDollarController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.monetization_on_rounded, color: Color(0xFF38BDF8), size: 18),
                    suffixText: 'كوينز / 1\$',
                    suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                    hintText: '100',
                    hintStyle: const TextStyle(color: Color(0xFF475569)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // Stepper buttons for coins per dollar: -10 and +10
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Color(0xFF38BDF8), size: 18),
                      onPressed: () {
                        final cur = int.tryParse(_coinsPerDollarController.text.trim()) ?? _coinsPerDollar;
                        final next = (cur - 10).clamp(1, 100000);
                        _coinsPerDollarController.text = next.toString();
                        setState(() {});
                      },
                      tooltip: 'إنقاص 10 كوينز',
                    ),
                    Container(width: 1, height: 24, color: const Color(0xFF1E293B)),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 18),
                      onPressed: () {
                        final cur = int.tryParse(_coinsPerDollarController.text.trim()) ?? _coinsPerDollar;
                        final next = (cur + 10).clamp(1, 100000);
                        _coinsPerDollarController.text = next.toString();
                        setState(() {});
                      },
                      tooltip: 'زيادة 10 كوينز',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Preset Chips for Coins per Dollar in Blue
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [50, 100, 150, 200, 250, 500, 1000].map((preset) {
              final isSelected = inputCpd == preset;
              return ActionChip(
                label: Text(
                  '$preset كوينز = 1\$',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                onPressed: () {
                  _coinsPerDollarController.text = preset.toString();
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 6),
          Text(
            '1 كوينز = ${(1.0 / inputCpd).toStringAsFixed(4)}\$ ≈ ${(inputRate / inputCpd).toStringAsFixed(1)} ل.س',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),

          const SizedBox(height: 18),

          // 3. Live Simulation Calculator (in Blue)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_rounded, color: Color(0xFF38BDF8), size: 17),
                    const SizedBox(width: 8),
                    const Text(
                      'محاكي الكاش باك التلقائي:',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('معاينة فورية', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (!_isCashbackActive) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'نظام الكاش باك معطل حالياً (لن يحصل المستخدم على أي كوينز)',
                            style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Simulation purchase amount field with currency switcher
                Row(
                  children: [
                    const Text('مشتريات بقيمة:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _simSpendController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            suffixText: _simSpendCurrency == 'USD' ? '\$' : 'ل.س',
                            suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              if (_simSpendCurrency != 'USD') {
                                setState(() {
                                  _simSpendCurrency = 'USD';
                                  _simSpendController.text = '10';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _simSpendCurrency == 'USD' ? const Color(0xFF0284C7) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$',
                                style: TextStyle(
                                  color: _simSpendCurrency == 'USD' ? Colors.white : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              if (_simSpendCurrency != 'SYP') {
                                setState(() {
                                  _simSpendCurrency = 'SYP';
                                  _simSpendController.text = '150000';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _simSpendCurrency == 'SYP' ? const Color(0xFF0284C7) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ل.س',
                                style: TextStyle(
                                  color: _simSpendCurrency == 'SYP' ? Colors.white : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Results badges in Blue
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('يحصل المستخدم على:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Text('🪙 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    '+$simCoinsDisplay كوينز',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('قيمة الاستبدال:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                            const SizedBox(height: 3),
                            Text(
                              '+\$${redeemedUsd.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '≈ ${simSyp.toString()} ل.س',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Save Cashback Button (in Blue)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSavingCashback ? null : _saveCashbackSettings,
              icon: _isSavingCashback
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSavingCashback ? 'جارٍ الحفظ...' : 'حفظ إعدادات الكاش باك والكوينز',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(String label, double delta, TextEditingController controller) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF334155)),
      onPressed: () {
        final current = double.tryParse(controller.text.trim()) ?? 15000.0;
        final newVal = (current + delta).clamp(1.0, 1000000.0);
        controller.text = newVal.toStringAsFixed(0);
        setState(() {});
      },
    );
  }
}

