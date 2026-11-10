import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../widgets/admin_notifications_dialog.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/notifications');
      if (res.data != null && res.data['data'] != null && mounted) {
        final list = (res.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text('حذف الإشعار', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذا الإشعار؟ لن يظهر للمستخدمين بعد الآن.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await sl<ApiClient>().delete('/notifications/$id');
      if (mounted) {
        setState(() {
          _notifications.removeWhere((item) => (item['_id'] ?? item['id']) == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإشعار بنجاح'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل حذف الإشعار'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _openSendDialog() async {
    await AdminNotificationsDialog.show(context);
    _fetchHistory();
  }

  Future<void> _sendTestNotification() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إرسال إشعار تجريبي إلى جهازك عبر Firebase...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final res = await sl<ApiClient>().post('/orders/admin/test-notification');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text('نجاح الإرسال', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Text(
              'تم إرسال الإشعار التجريبي بنجاح عبر Firebase!\n\n${res.data?['message'] ?? 'تحقق من شريط الإشعارات بهاتفك الآن.'}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('تنبيه Firebase', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Text(
              'تعذر إرسال الإشعار:\n$e\n\nتأكد من إضافة متغير FIREBASE_SERVICE_ACCOUNT في إعدادات Render.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
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
          title: const Text(
            'سجل الإشعارات المرسلة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.phonelink_ring_rounded, color: Colors.amberAccent),
              tooltip: 'تجربة وصول إشعار لجهازي 🔔',
              onPressed: _sendTestNotification,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'تحديث السجل',
              onPressed: _fetchHistory,
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('إرسال إشعار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _openSendDialog,
        ),
        body: RefreshIndicator(
          color: const Color(0xFF38BDF8),
          backgroundColor: const Color(0xFF0F172A),
          onRefresh: _fetchHistory,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 54, color: Colors.white.withValues(alpha: 0.15)),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد إشعارات مرسلة حتى الآن',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _openSendDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('إرسال أول إشعار الآن'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final id = (item['_id'] ?? item['id'] ?? '').toString();
                        final title = (item['title'] ?? '').toString();
                        final desc = (item['description'] ?? '').toString();
                        final date = _formatDateTime(item['createdAt']);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.notifications_rounded, color: Color(0xFF38BDF8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (date.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            date,
                                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: 'حذف الإشعار',
                                    onPressed: () => _deleteNotification(id),
                                  ),
                                ],
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131D31),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    desc,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

