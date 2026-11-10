import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../pages/admin_notifications_page.dart';

class AdminNotificationsDialog extends StatefulWidget {
  const AdminNotificationsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminNotificationsDialog(),
    );
  }

  @override
  State<AdminNotificationsDialog> createState() => _AdminNotificationsDialogState();
}

class _AdminNotificationsDialogState extends State<AdminNotificationsDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final res = await sl<ApiClient>().post('/notifications', data: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'type': 'broadcast',
      });

      if (res.data != null && mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('تم إرسال الإشعار لجميع المستخدمين بنجاح 🔔'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إرسال الإشعار'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'إرسال إشعار للمستخدمين',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title Field
                  const Text(
                    'عنوان الإشعار:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب عنوان الإشعار هنا...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى كتابة عنوان الإشعار';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description Field
                  const Text(
                    'نص الإشعار:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل ونص الإشعار الذي سيظهر للمستخدمين...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى كتابة نص وتفاصيل الإشعار';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // View Sent Notifications Shortcut
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('سجل الإشعارات المرسلة 📜', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminNotificationsPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: _isSending ? null : _sendNotification,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _isSending ? 'جاري الإرسال...' : 'إرسال الإشعار للجميع',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
