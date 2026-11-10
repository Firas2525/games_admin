import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminTickerDialog extends StatefulWidget {
  const AdminTickerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminTickerDialog(),
    );
  }

  @override
  State<AdminTickerDialog> createState() => _AdminTickerDialogState();
}

class _AdminTickerDialogState extends State<AdminTickerDialog> {
  final _textController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchTicker();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicker() async {
    try {
      final res = await sl<ApiClient>().get('/settings/ticker');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _textController.text = (data['tickerText'] ?? '').toString();
          _isActive = data['isTickerActive'] != false;
          _isLoading = false;
        });
      } else {
        _fallbackFetchSettings();
      }
    } catch (_) {
      _fallbackFetchSettings();
    }
  }

  Future<void> _fallbackFetchSettings() async {
    try {
      final res = await sl<ApiClient>().get('/settings');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _textController.text = (data['tickerText'] ?? '').toString();
          _isActive = data['isTickerActive'] != false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTicker() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة نص الإعلان أو إيقاف تفعيل الشريط'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await sl<ApiClient>().patch(
        '/settings/ticker',
        data: {
          'tickerText': text,
          'isTickerActive': _isActive,
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
                  Text('تم حفظ وتحديث شريط الإعلانات بنجاح'),
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
          side: const BorderSide(color: Color(0xFF334155), width: 1.2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
            child: _isLoading
                ? const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Color(0xFFF59E0B), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'شريط الإعلانات المتحرك',
                              style: TextStyle(
                                fontSize: 16,
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
                      const SizedBox(height: 16),

                      // Toggle Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isActive
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isActive ? 'الشريط مفعّل ويظهر للمستخدمين' : 'الشريط متوقف ومخفي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isActive ? const Color(0xFFF59E0B) : Colors.white60,
                              ),
                            ),
                            Switch.adaptive(
                              value: _isActive,
                              activeTrackColor: const Color(0xFFF59E0B),
                              activeThumbColor: Colors.white,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Direct Text Editor
                      const Text(
                        'نص الإعلان:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        minLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'اكتب نص الإعلان المتحرك هنا...',
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
                            borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: _isSaving ? null : _saveTicker,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(
                                _isSaving ? 'جاري الحفظ...' : 'حفظ التعديل',
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
    );
  }
}
