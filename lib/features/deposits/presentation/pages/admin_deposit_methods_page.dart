import 'package:games_admin/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import 'admin_deposit_method_form_page.dart';

class AdminDepositMethodsPage extends StatefulWidget {
  const AdminDepositMethodsPage({super.key});

  @override
  State<AdminDepositMethodsPage> createState() => _AdminDepositMethodsPageState();
}

class _AdminDepositMethodsPageState extends State<AdminDepositMethodsPage> {
  List<dynamic> _methods = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'all'; // all, active, disabled, usd, syp
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMethods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        const SnackBar(
          content: Text('تم تحديث حالة طريقة الإيداع بنجاح ✅'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteMethod(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 10),
              const Text('تأكيد حذف طريقة الإيداع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف طريقة الإيداع "$title" نهائياً؟\nلن يتمكن الزبائن من الإيداع عبرها بعد الحذف.',
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، حذف نهائي', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await sl<ApiClient>().delete('/deposits/admin/methods/$id');
      _fetchMethods();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف طريقة الإيداع بنجاح ✅'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _navigateToForm([Map<String, dynamic>? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDepositMethodFormPage(existingMethod: existing),
      ),
    );
    if (result == true) {
      _fetchMethods();
    }
  }

  IconData _getIconData(String? iconKey) {
    switch (iconKey) {
      case 'sham':
        return Icons.account_balance_rounded;
      case 'syriatel':
        return Icons.bolt_rounded;
      case 'binance':
        return Icons.currency_bitcoin_rounded;
      case 'usdt':
        return Icons.stream_rounded;
      case 'haram':
        return Icons.store_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'card':
      default:
        return Icons.credit_card_rounded;
    }
  }

  Color _getPrimaryColor(String? iconKey) {
    switch (iconKey) {
      case 'sham':
        return const Color(0xFF0D9488);
      case 'syriatel':
        return const Color(0xFFEF4444);
      case 'binance':
        return const Color(0xFFF59E0B);
      case 'usdt':
        return const Color(0xFF10B981);
      case 'haram':
        return const Color(0xFF8B5CF6);
      case 'bank':
        return const Color(0xFF3B82F6);
      case 'card':
      default:
        return const Color(0xFF0284C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _methods.length;
    final activeCount = _methods.where((m) => m['isEnabled'] == true).length;
    final disabledCount = totalCount - activeCount;
    final requireImageCount = _methods.where((m) => m['requiresReceiptImage'] == true).length;

    final filteredMethods = _methods.where((m) {
      // Filter tab
      if (_activeFilter == 'active' && m['isEnabled'] != true) return false;
      if (_activeFilter == 'disabled' && m['isEnabled'] == true) return false;
      if (_activeFilter == 'usd' && (m['currency'] ?? 'USD') != 'USD') return false;
      if (_activeFilter == 'syp' && (m['currency'] ?? 'USD') != 'SYP') return false;

      // Search query
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final title = (m['title'] ?? '').toString().toLowerCase();
      final account = (m['account'] ?? '').toString().toLowerCase();
      final address = (m['address'] ?? '').toString().toLowerCase();
      final currency = (m['currency'] ?? '').toString().toLowerCase();
      return title.contains(query) || account.contains(query) || address.contains(query) || currency.contains(query);
    }).toList();

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
            'طرق ووسائل الإيداع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'تحديث البيانات',
              onPressed: _fetchMethods,
            ),
            const SizedBox(width: 6),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          onPressed: () => _navigateToForm(),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('إضافة وسيلة إيداع جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        body: Column(
          children: [
            // Analytics & Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1424),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prominent Add Method Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text('إضافة وسيلة إيداع جديدة +', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Scrollable Metrics Row (Zero Overflow on any screen)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMetricChip(
                          title: 'المفعلة للزبائن',
                          value: activeCount.toString(),
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          active: _activeFilter == 'active',
                          onTap: () => setState(() => _activeFilter = _activeFilter == 'active' ? 'all' : 'active'),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          title: 'المعطلة مؤقتاً',
                          value: disabledCount.toString(),
                          icon: Icons.pause_circle_rounded,
                          color: const Color(0xFFEF4444),
                          active: _activeFilter == 'disabled',
                          onTap: () => setState(() => _activeFilter = _activeFilter == 'disabled' ? 'all' : 'disabled'),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          title: 'تشترط إشعار 📷',
                          value: requireImageCount.toString(),
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF8B5CF6),
                          active: false,
                          onTap: null,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          title: 'إجمالي الطرق',
                          value: totalCount.toString(),
                          icon: Icons.tune_rounded,
                          color: const Color(0xFF38BDF8),
                          active: _activeFilter == 'all',
                          onTap: () => setState(() => _activeFilter = 'all'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، المحفظة، الحساب، أو العملة...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF141D30),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Filter Chips Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'الكل ($totalCount)', Icons.apps_rounded),
                        const SizedBox(width: 8),
                        _buildFilterPill('active', 'المفعلة ($activeCount)', Icons.check_circle_outline_rounded, activeColor: const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildFilterPill('disabled', 'المعطلة ($disabledCount)', Icons.pause_circle_outline_rounded, activeColor: const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _buildFilterPill('usd', 'دولار USD', Icons.attach_money_rounded, activeColor: const Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        _buildFilterPill('syp', 'ليرة سورية SYP', Icons.account_balance_outlined, activeColor: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                  : filteredMethods.isEmpty
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
                                child: Icon(Icons.credit_card_off_rounded, size: 50, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _searchQuery.isNotEmpty ? 'لا توجد نتائج تطابق بحثك' : 'لا توجد طرق إيداع مضافة حالياً',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty ? 'جرّب البحث باسم أو كلمة أخرى' : 'ابدأ بإضافة طرق إيداع مثل شام كاش أو سيريتل أو USDT',
                                style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _navigateToForm(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('إضافة وسيلة إيداع جديدة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchMethods,
                          color: const Color(0xFF0284C7),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: filteredMethods.length,
                            itemBuilder: (context, index) {
                              final m = filteredMethods[index] as Map<String, dynamic>;
                              return _buildRobustMethodCard(m);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool active,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.22) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.25),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, IconData icon, {Color activeColor = const Color(0xFF0284C7)}) {
    final isSel = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? activeColor.withValues(alpha: 0.2) : const Color(0xFF141D30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? activeColor : Colors.white12,
            width: isSel ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSel ? activeColor : Colors.white60),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRobustMethodCard(Map<String, dynamic> m) {
    final id = m['_id']?.toString() ?? m['id']?.toString() ?? '';
    final isEnabled = m['isEnabled'] == true;
    final requiresReceiptImage = m['requiresReceiptImage'] == true;
    final requiresVerification = m['requiresVerification'] == true;
    final title = m['title'] ?? 'طريقة دفع';
    final currency = m['currency'] ?? 'USD';
    final account = m['account'] ?? '';
    final address = m['address'] ?? '';
    final fee = m['fee'] ?? 0;
    final minDeposit = m['minDeposit'] ?? 1;
    final maxDeposit = m['maxDeposit'] ?? 100000;
    final instructions = m['instructions'] ?? '';
    final iconKey = m['iconKey'];
    final imageUrl = m['imageUrl']?.toString() ?? m['iconUrl']?.toString() ?? '';

    final brandColor = _getPrimaryColor(iconKey);
    final iconData = _getIconData(iconKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withValues(alpha: 0.14),
            const Color(0xFF11192B),
            const Color(0xFF0D1424),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled ? brandColor.withValues(alpha: 0.45) : Colors.white12,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isEnabled ? brandColor : Colors.black).withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon/Image, Title, Currency Badge, and Status Switch
            Row(
              children: [
                // Method Image / Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: brandColor.withValues(alpha: 0.55), width: 1.5),
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(iconData, color: Colors.white, size: 20),
                          )
                        : Icon(iconData, color: Colors.white, size: 20),
                  ),
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
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Currency Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currency == 'SYP'
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                  : const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: currency == 'SYP' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              currency == 'SYP' ? 'ليرة SYP' : 'دولار USD',
                              style: TextStyle(
                                color: currency == 'SYP' ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (account.toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'المستلم: $account',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade300, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Compact Switch
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isEnabled ? 'مفعلة' : 'معطلة',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isEnabled,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (_) => _toggleMethod(id),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: Account/Address Container with Copy Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF090E1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 16, color: brandColor),
                  const SizedBox(width: 6),
                  Text('العنوان: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  Expanded(
                    child: SelectableText(
                      address.toString().isNotEmpty ? address : 'لم يتم تحديد عنوان',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        fontFamily: 'monospace',
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (address.toString().isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ العنوان بنجاح ✅'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Row 3: Wrap Badges (Fee, Limits, Image required) - Zero Overflow Guaranteed!
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.percent_rounded, color: Color(0xFFF59E0B), size: 11),
                      const SizedBox(width: 3),
                      Text('عمولة: $fee%', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'الحدود: $minDeposit إلى $maxDeposit $currency',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                  ),
                ),
                if (requiresReceiptImage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 11, color: Color(0xFFC4B5FD)),
                        SizedBox(width: 4),
                        Text(
                          'إشعار إلزامي 📷',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC4B5FD)),
                        ),
                      ],
                    ),
                  ),
                if (requiresVerification)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 11, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Text(
                          'للموثقين فقط 🛡️',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (instructions.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  'تعليمات: $instructions',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.35),
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Row 4: Full-width Action Buttons (Zero Overflow)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _navigateToForm(m),
                    icon: const Icon(Icons.edit_note_rounded, size: 17),
                    label: const Text('تعديل البيانات ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _deleteMethod(id, title),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
