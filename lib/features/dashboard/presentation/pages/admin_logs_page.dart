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

  // Filters
  String _selectedFilter = 'all'; // 'all', 'purchase', 'check', 'errors', 'brand1card', 'roya_usd', 'roya_syp'
  String _searchQuery = '';

  // Multi-selection state
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isDeleting = false;

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
        'limit': 50,
      };

      if (_selectedFilter == 'purchase') {
        queryParams['operation'] = 'PURCHASE';
      } else if (_selectedFilter == 'check') {
        queryParams['operation'] = 'CHECK';
      } else if (_selectedFilter == 'errors') {
        queryParams['isSuccess'] = 'false';
      } else if (_selectedFilter == 'brand1card') {
        queryParams['provider'] = 'brand1card';
      } else if (_selectedFilter == 'roya_usd') {
        queryParams['provider'] = 'roya_usd';
      } else if (_selectedFilter == 'roya_syp') {
        queryParams['provider'] = 'roya_syp';
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
          _selectedIds.removeWhere((id) => !_logs.any((l) => (l['_id'] ?? l['id']) == id));
          if (_selectedIds.isEmpty) _isSelectionMode = false;
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

  // --- Deletion Handlers ---

  Future<void> _deleteSelectedLogs() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
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
          title: Row(
            children: const [
              Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('حذف السجلات المحددة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف $count سجل من سجلات اتصالات المزودين؟ لا يمكن التراجع عن هذه الخطوة.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف ($count)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await sl<ApiClient>().delete('/logs/batch', data: {'ids': _selectedIds.toList()});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف $count سجل بنجاح 🗑️'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _selectedIds.clear();
          _isSelectionMode = false;
          _fetchLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحذف: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _deleteAllLogs() async {
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
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('حذف كافة سجلات المزودين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من تفريغ كافة سجلات المزودين بالكامل؟\nسيتم حذف جميع سجلات الشراء والفحص السابقة.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد تفريغ الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await sl<ApiClient>().delete('/logs/all');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفريغ كافة سجلات المزودين بنجاح 🧹'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _selectedIds.clear();
          _isSelectionMode = false;
          _fetchLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تفريغ السجلات: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _deleteSingleLog(String logId) async {
    try {
      await sl<ApiClient>().delete('/logs/$logId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف السجل بنجاح 🗑️'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _selectedIds.remove(logId);
        _fetchLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _logs.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        for (final l in _logs) {
          final id = (l['_id'] ?? l['id'])?.toString();
          if (id != null) _selectedIds.add(id);
        }
        _isSelectionMode = true;
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
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
    final logId = (log['_id'] ?? log['id'])?.toString() ?? '';
    final isSuccess = log['isSuccess'] == true;
    final operation = log['operation']?.toString() ?? (log['type'] == 'PROVIDER_CHECK' ? 'CHECK' : 'PURCHASE');
    final method = log['method']?.toString() ?? 'GET';
    final endpoint = log['endpoint']?.toString() ?? '';
    final statusCode = log['statusCode']?.toString() ?? '200';
    final duration = '${log['durationMs'] ?? 0} ms';
    final userName = log['userName']?.toString() ?? '';
    final userEmail = log['userEmail']?.toString() ?? '';
    final provider = log['provider']?.toString() ?? 'مزود خارجي';
    final orderId = log['orderId']?.toString() ?? '';
    final productName = log['productName']?.toString() ?? '';
    final errorMsg = log['errorMessage']?.toString() ?? '';
    final createdAt = log['createdAt']?.toString() ?? '';

    final reqHeaders = _formatJson(log['requestHeaders']);
    final reqBody = _formatJson(log['requestBody'] ?? log['queryParams']);
    final resBody = _formatJson(log['responseBody']);

    final operationTitle = operation == 'CHECK'
        ? '🔍 فحص حالة طلب (Check Status)'
        : (operation == 'PROBE' ? '📡 تحقق من وجود الطلب (Probe Existence)' : '🛍️ إرسال طلب شراء (Order Dispatch)');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFF0284C7), width: 2.5)),
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
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF0284C7)),
                                  ),
                                  child: Text(
                                    operationTitle,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSuccess
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'HTTP $statusCode ${isSuccess ? '✅' : '❌'}',
                                    style: TextStyle(
                                      color: isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF38BDF8)),
                                  tooltip: 'نسخ الرابط',
                                  onPressed: () => _copy(endpoint, 'الرابط المستهدف'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _metaPill('المزود:', provider, const Color(0xFF38BDF8)),
                                _metaPill('الزمن:', duration, const Color(0xFFFACC15)),
                                if (orderId.isNotEmpty) _metaPill('رقم الطلب:', '#$orderId', const Color(0xFFA78BFA)),
                                if (userName.isNotEmpty) _metaPill('المستخدم:', '$userName ($userEmail)', Colors.white70),
                                if (productName.isNotEmpty) _metaPill('المنتج:', productName, const Color(0xFF34D399)),
                                if (createdAt.isNotEmpty) _metaPill('الوقت:', createdAt, Colors.white54),
                              ],
                            ),
                            if (errorMsg.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SelectableText(
                                        errorMsg,
                                        style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Request Payload (Headers & Body)
                      _buildCodeSection('📤 معطيات الطلب المرسل (Outgoing Payload):', reqBody, const Color(0xFF38BDF8)),
                      const SizedBox(height: 14),

                      // Provider Full Raw Response
                      _buildCodeSection('📥 استجابة سيرفر المزود الكاملة (Provider Response):', resBody, const Color(0xFF10B981)),
                      const SizedBox(height: 14),

                      // Request Headers if any
                      if (reqHeaders != 'لا توجد بيانات' && reqHeaders != '{}')
                        _buildCodeSection('🛡️ ترويسات الطلب (Headers):', reqHeaders, const Color(0xFFA78BFA)),
                      const SizedBox(height: 20),

                      // Delete this Log Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف هذا السجل من قاعدة البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _deleteSingleLog(logId);
                        },
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildCodeSection(String title, String content, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                InkWell(
                  onTap: () => _copy(content, title),
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text('نسخ', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
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

  Widget _metaPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label 📋'),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF10B981);
      case 'POST':
        return const Color(0xFF0284C7);
      case 'PUT':
      case 'PATCH':
        return const Color(0xFFF59E0B);
      case 'DELETE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B101E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    });
                  },
                )
              : null,
          title: _isSelectionMode
              ? Text(
                  'تم تحديد ${_selectedIds.length} سجل',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'سجل اتصالات المزودين',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all_rounded, color: Color(0xFF38BDF8)),
                tooltip: 'تحديد / إلغاء تحديد الكل',
                onPressed: _toggleSelectAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                tooltip: 'حذف المحدد',
                onPressed: _deleteSelectedLogs,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                tooltip: 'تفريغ كافة السجلات',
                onPressed: _deleteAllLogs,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                tooltip: 'تحديث فوري',
                onPressed: _fetchLogs,
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Stats Counter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF07111F),
              child: Row(
                children: [
                  _counterBadge('إجمالي العمليات', '${_summary['totalCount'] ?? _logs.length}', const Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  _counterBadge('الناجحة', '${_summary['successCount'] ?? 0}', const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _counterBadge('الأخطاء والرفض', '${_summary['errors'] ?? 0}', const Color(0xFFEF4444)),
                ],
              ),
            ),

            // Search Bar & Filter Chips
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
                        hintText: 'بحث برقم الطلب، اسم المنتج، الآيدي، أو الرابط...',
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
                        _filterChip('🛍️ عمليات الشراء', 'purchase'),
                        const SizedBox(width: 6),
                        _filterChip('🔍 عمليات الفحص', 'check'),
                        const SizedBox(width: 6),
                        _filterChip('❌ المرفوضة والأخطاء', 'errors'),
                        const SizedBox(width: 6),
                        _filterChip('براند كارد', 'brand1card'),
                        const SizedBox(width: 6),
                        _filterChip('رؤيا دولار', 'roya_usd'),
                        const SizedBox(width: 6),
                        _filterChip('رؤيا ليرة', 'roya_syp'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Selection Banner if active
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تم تحديد ${_selectedIds.length} من أصل ${_logs.length}',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _toggleSelectAll,
                          child: Text(
                            _selectedIds.length == _logs.length ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.delete_rounded, size: 14),
                          label: const Text('حذف المحدد', style: TextStyle(fontSize: 11)),
                          onPressed: _deleteSelectedLogs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Logs List
            Expanded(
              child: _isLoading || _isDeleting
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
                                'لا توجد اتصالات مسجلة مع المزودين حالياً',
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
            Text(count, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis),
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
    final logId = (log['_id'] ?? log['id'])?.toString() ?? '';
    final isSelected = _selectedIds.contains(logId);
    final isSuccess = log['isSuccess'] == true;
    final operation = log['operation']?.toString() ?? (log['type'] == 'PROVIDER_CHECK' ? 'CHECK' : 'PURCHASE');
    final method = log['method']?.toString() ?? 'GET';
    final endpoint = log['endpoint']?.toString() ?? '';
    final statusCode = log['statusCode']?.toString() ?? '200';
    final duration = '${log['durationMs'] ?? 0}ms';
    final userName = log['userName']?.toString() ?? '';
    final provider = log['provider']?.toString() ?? 'مزود';
    final orderId = log['orderId']?.toString() ?? '';
    final errorMsg = log['errorMessage']?.toString() ?? '';
    final createdAt = log['createdAt']?.toString() ?? '';

    final opBadge = operation == 'CHECK'
        ? '🔍 فحص'
        : (operation == 'PROBE' ? '📡 تحقق' : '🛍️ شراء');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.15) : const Color(0xFF101726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : (isSuccess
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEF4444).withValues(alpha: 0.4)),
          width: isSelected ? 1.8 : (isSuccess ? 1 : 1.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _toggleItemSelection(logId),
        onTap: () {
          if (_isSelectionMode) {
            _toggleItemSelection(logId);
          } else {
            _showLogDetails(log);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox if in selection mode or on tap
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) => _toggleItemSelection(logId),
                ),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🌐 $provider',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            opBadge,
                            style: const TextStyle(
                              color: Color(0xFFC084FC),
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
                            'HTTP $statusCode ${isSuccess ? 'OK' : 'ERR'}',
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

                    // Row 2: Target URL
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

                    // Row 3: Meta
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (orderId.isNotEmpty) ...[
                                const Icon(Icons.receipt_outlined, size: 12, color: Color(0xFFFACC15)),
                                const SizedBox(width: 3),
                                Text('#$orderId', style: const TextStyle(color: Color(0xFFFACC15), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                              ],
                              if (userName.isNotEmpty) ...[
                                const Icon(Icons.person_outline, size: 12, color: Colors.white38),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
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
            ],
          ),
        ),
      ),
    );
  }
}
