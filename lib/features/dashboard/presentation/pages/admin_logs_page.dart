import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminLogsPage extends StatefulWidget {
  const AdminLogsPage({super.key});

  @override
  State<AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends State<AdminLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _logs = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'providers', 'purchases', 'errors', 'internal'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'limit': 30,
      };

      if (_selectedFilter == 'providers') {
        queryParams['type'] = 'PROVIDER_DISPATCH';
      } else if (_selectedFilter == 'internal') {
        queryParams['type'] = 'INTERNAL_HTTP';
      } else if (_selectedFilter == 'errors') {
        queryParams['isSuccess'] = 'false';
      } else if (_selectedFilter == 'purchases') {
        queryParams['search'] = 'purchase';
      }

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final res = await sl<ApiClient>().get('/logs', queryParameters: queryParams);

      if (res.data != null && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _logs = (data['logs'] as List<dynamic>?) ?? [];
          _summary = (data['summary'] as Map<String, dynamic>?) ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _logs = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purgeOldLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text('تفريغ السجلات القديمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'هل أنت متأكد من حذف السجلات التي مضى عليها أكثر من 30 يوماً؟',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ApiClient>().delete('/logs/purge');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تنظيف السجلات القديمة بنجاح'), backgroundColor: Colors.green),
          );
          _fetchLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'لا توجد بيانات';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _showLogDetails(Map<String, dynamic> log) {
    final isSuccess = log['isSuccess'] == true;
    final isProvider = log['type'] == 'PROVIDER_DISPATCH';
    final method = log['method']?.toString() ?? 'GET';
    final endpoint = log['endpoint']?.toString() ?? '';
    final statusCode = log['statusCode']?.toString() ?? '200';
    final duration = '${log['durationMs'] ?? 0} ms';
    final userName = log['userName']?.toString() ?? '';
    final userEmail = log['userEmail']?.toString() ?? '';
    final provider = log['provider']?.toString() ?? 'internal';
    final orderId = log['orderId']?.toString() ?? '';
    final productName = log['productName']?.toString() ?? '';
    final errorMsg = log['errorMessage']?.toString() ?? '';

    final reqHeaders = _formatJson(log['requestHeaders']);
    final reqBody = _formatJson(log['requestBody'] ?? log['queryParams']);
    final resBody = _formatJson(log['responseBody']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFF0284C7), width: 2)),
            ),
            child: Column(
              children: [
                // Modal Handle & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isProvider
                                      ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isProvider ? const Color(0xFF06B6D4) : const Color(0xFF0284C7),
                                  ),
                                ),
                                child: Text(
                                  isProvider ? '🌐 استدعاء مزود خارجي' : '📲 طلب API داخلي',
                                  style: TextStyle(
                                    color: isProvider ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSuccess
                                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$statusCode ${isSuccess ? 'OK' : 'ERROR'}',
                                  style: TextStyle(
                                    color: isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    children: [
                      // Overview Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getMethodColor(method).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    method,
                                    style: TextStyle(
                                      color: _getMethodColor(method),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SelectableText(
                                    endpoint,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _metaPill('المزود:', provider, const Color(0xFF38BDF8)),
                                _metaPill('الزمن المستغرق:', duration, const Color(0xFFFACC15)),
                                if (orderId.isNotEmpty) _metaPill('رقم الطلب:', orderId, const Color(0xFFA78BFA)),
                                if (userName.isNotEmpty) _metaPill('المستخدم:', '$userName ($userEmail)', Colors.white70),
                                if (productName.isNotEmpty) _metaPill('المنتج:', productName, const Color(0xFF34D399)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'رسالة الخطأ المسجلة:',
                                      style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      errorMsg,
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Request Headers Section
                      _buildCodeSection('ترويسات الطلب (Request Headers)', reqHeaders),

                      const SizedBox(height: 16),

                      // Request Payload Section
                      _buildCodeSection('ما تم إرساله (Request Payload / Params)', reqBody, isRequest: true),

                      const SizedBox(height: 16),

                      // Response Body Section
                      _buildCodeSection('رد واستجابة الـ API (API Response Data)', resBody, isResponse: true),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metaPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCodeSection(String title, String content, {bool isRequest = false, bool isResponse = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResponse
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isRequest ? const Color(0xFF0284C7).withValues(alpha: 0.3) : Colors.white10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ النص بنجاح'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Text('نسخ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF3B82F6);
      case 'POST':
        return const Color(0xFF8B5CF6);
      case 'PATCH':
        return const Color(0xFFF59E0B);
      case 'DELETE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text(
              'سجل العمليات و APIs',
              style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60),
            tooltip: 'تفريغ السجلات القديمة',
            onPressed: _purgeOldLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'تحديث فوري',
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Stats Counter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF07111F),
            child: Row(
              children: [
                _counterBadge('إجمالي العمليات', '${_summary['totalCount'] ?? _logs.length}', const Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                _counterBadge('طلبات المزودين', '${_summary['providerDispatches'] ?? 0}', const Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                _counterBadge('الأخطاء', '${_summary['errors'] ?? 0}', const Color(0xFFEF4444)),
              ],
            ),
          ),

          // 2. Filter Bar & Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B101E),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              children: [
                // Search Input
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'بحث في المسار، المستخدم، رقم الطلب، المنتج...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _fetchLogs();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val.trim());
                      _fetchLogs();
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('الكل', 'all'),
                      const SizedBox(width: 6),
                      _filterChip('🌐 المزودين (SW / Brand)', 'providers'),
                      const SizedBox(width: 6),
                      _filterChip('🛍️ عمليات الشراء', 'purchases'),
                      const SizedBox(width: 6),
                      _filterChip('⚠️ الأخطاء فقط', 'errors'),
                      const SizedBox(width: 6),
                      _filterChip('📲 داخلية (App)', 'internal'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                              onPressed: _fetchLogs,
                              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد عمليات مسجلة حالياً',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF0284C7),
                            onRefresh: _fetchLogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              itemCount: _logs.length,
                              itemBuilder: (ctx, index) {
                                final log = _logs[index] as Map<String, dynamic>;
                                return _buildLogCard(log);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _counterBadge(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() => _selectedFilter = key);
        _fetchLogs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isSuccess = log['isSuccess'] == true;
    final isProvider = log['type'] == 'PROVIDER_DISPATCH';
    final method = log['method']?.toString() ?? 'GET';
    final endpoint = log['endpoint']?.toString() ?? '';
    final statusCode = log['statusCode']?.toString() ?? '200';
    final duration = '${log['durationMs'] ?? 0}ms';
    final userName = log['userName']?.toString() ?? '';
    final provider = log['provider']?.toString() ?? 'internal';
    final orderId = log['orderId']?.toString() ?? '';
    final errorMsg = log['errorMessage']?.toString() ?? '';
    final createdAt = log['createdAt']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: isSuccess ? 1 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showLogDetails(log),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Direction badge, Method, Status, Duration
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isProvider
                          ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                          : const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isProvider ? '🌐 مزود: $provider' : '📲 طلب داخلي',
                      style: TextStyle(
                        color: isProvider ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getMethodColor(method).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(color: _getMethodColor(method), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      statusCode,
                      style: TextStyle(
                        color: isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    duration,
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Endpoint URL
              Text(
                endpoint,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Row 3: User or Order info
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (userName.isNotEmpty) ...[
                        const Icon(Icons.person_outline, size: 12, color: Colors.white38),
                        const SizedBox(width: 3),
                        Text(userName, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
                        const SizedBox(width: 8),
                      ],
                      if (orderId.isNotEmpty) ...[
                        const Icon(Icons.receipt_outlined, size: 12, color: Color(0xFFFACC15)),
                        const SizedBox(width: 3),
                        Text(orderId, style: const TextStyle(color: Color(0xFFFACC15), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                  Text(
                    createdAt.length >= 19 ? createdAt.substring(11, 19) : '',
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),

              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '⚠️ $errorMsg',
                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
