import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminSupportLinksDialog extends StatefulWidget {
  const AdminSupportLinksDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminSupportLinksDialog(),
    );
  }

  @override
  State<AdminSupportLinksDialog> createState() => _AdminSupportLinksDialogState();
}

class _AdminSupportLinksDialogState extends State<AdminSupportLinksDialog> {
  final _whatsappController = TextEditingController();
  final _telegramController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await sl<ApiClient>().get('/settings');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _whatsappController.text = (data['whatsappSupport'] ?? '').toString();
          _telegramController.text = (data['telegramChannel'] ?? '').toString();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLinks() async {
    setState(() => _isSaving = true);
    try {
      final res = await sl<ApiClient>().patch(
        '/settings',
        data: {
          'whatsappSupport': _whatsappController.text.trim(),
          'telegramChannel': _telegramController.text.trim(),
        },
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (res.statusCode == 200 || res.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('تم حفظ وتحديث روابط الدعم والتواصل بنجاح ✅'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data?['message']?.toString() ?? 'حدث خطأ أثناء الحفظ'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: Colors.redAccent,
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
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: _isLoading
                ? const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.headset_mic_rounded,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'روابط الدعم والتواصل 💬',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'تحكم برابط واتساب وتيليغرام المعروضين لليوزر',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                              splashRadius: 18,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // WhatsApp Support Input
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF25D366).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.support_agent_rounded, color: Color(0xFF25D366), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'دعم فني عبر واتساب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'أدخل رقم الواتساب بالرمز الدولي (مثل: 9639xxxxxxxx) أو رابط wa.me',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _whatsappController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: 'https://wa.me/963912345678 أو 963912345678',
                                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                  hintTextDirection: TextDirection.ltr,
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF25D366), size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF25D366)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // WhatsApp / Telegram Channel Input
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF25D366).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.campaign_rounded, color: Color(0xFF25D366), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'قناة واتساب للعروض (أو تيليغرام)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'أدخل رابط قناة الواتساب (مثل: https://whatsapp.com/channel/...) أو رابط مجموعة واتساب أو تيليغرام',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _telegramController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: 'https://whatsapp.com/channel/... أو https://chat.whatsapp.com/...',
                                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                  hintTextDirection: TextDirection.ltr,
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF25D366), size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF25D366)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveLinks,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'حفظ وتطبيق التغييرات',
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

