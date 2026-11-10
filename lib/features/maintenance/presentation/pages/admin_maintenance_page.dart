import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminMaintenancePage extends StatefulWidget {
  const AdminMaintenancePage({super.key});

  @override
  State<AdminMaintenancePage> createState() => _AdminMaintenancePageState();
}

class _AdminMaintenancePageState extends State<AdminMaintenancePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool _isMaintenance = false;
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  String? _updatedAtStr;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'أعمال صيانة وتحديث');
    _messageController = TextEditingController(
      text: 'نقوم حالياً ببعض أعمال الصيانة والتحسينات الدورية لنقدم لكم تجربة أفضل وأسرع. سنعود للعمل قريباً جداً، نشكر تفهمكم!',
    );
    _loadMaintenanceSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/settings/maintenance');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _isMaintenance = data['isMaintenance'] == true;
          final title = (data['maintenanceTitle'] ?? '').toString().trim();
          final message = (data['maintenanceMessage'] ?? '').toString().trim();
          if (title.isNotEmpty) _titleController.text = title;
          if (message.isNotEmpty) _messageController.text = message;
          _updatedAtStr = data['updatedAt']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر جلب إعدادات الصيانة: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateMaintenance(bool activate) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (activate) {
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى كتابة عنوان الصيانة أولاً'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }
      if (message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى كتابة رسالة الصيانة للمستخدمين'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await sl<ApiClient>().patch(
        '/settings/maintenance',
        data: {
          'isMaintenance': activate,
          'maintenanceTitle': title,
          'maintenanceMessage': message,
        },
      );

      if (mounted) {
        setState(() {
          _isMaintenance = activate;
          _isSubmitting = false;
        });

        final successMessage = res.data?['message'] ??
            (activate
                ? 'تم تفعيل وضع الصيانة بنجاح 🛠️'
                : 'تم إلغاء وضع الصيانة بنجاح والتطبيق متاح الآن ✅');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  activate ? Icons.construction_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    successMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: activate ? const Color(0xFFD97706) : const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث وضع الصيانة: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وضع الصيانة (Maintenance Mode)',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'إيقاف وتفعيل دخول المستخدمين وعرض رسالة الصيانة',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'تحديث الحالة',
            onPressed: _isLoading || _isSubmitting ? null : _loadMaintenanceSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Current Live Status Card
                  _buildLiveStatusCard(),

                  const SizedBox(height: 18),

                  // 2. Info Card
                  _buildInfoCard(),

                  const SizedBox(height: 18),

                  // 3. Inputs Form Card
                  _buildFormCard(),

                  const SizedBox(height: 22),

                  // 4. Action Buttons (تفعيل صيانة / الغاء صيانة)
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // 5. Live Preview of what User will see
                  _buildPreviewCard(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveStatusCard() {
    final isActive = _isMaintenance;
    final primaryColor = isActive ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final gradientColors = isActive
        ? [const Color(0xFFB45309), const Color(0xFFD97706)]
        : [const Color(0xFF047857), const Color(0xFF10B981)];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isActive ? Icons.construction_rounded : Icons.verified_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isActive ? 'وضع الصيانة: مُفَعَّل' : 'وضع الصيانة: غير مُفَعَّل',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'تطبيق المستخدم محجوب حالياً وتظهر واجهة الصيانة'
                          : 'التطبيق يعمل بشكل طبيعي ومتاح لكافة المستخدمين',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_updatedAtStr != null && _updatedAtStr!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  'آخر تحديث للحالة: ${_formatDateTime(_updatedAtStr)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الحالة الافتراضية للتطبيق هي أن الصيانة غير مفعلة. عندما تقوم بتفعيل الصيانة، سيتم فوراً حظر دخول الزبائن وعرض واجهة الصيانة المصممة بالأسفل مع العنوان والرسالة التي تحددها، حتى تعود هنا وتلغي الصيانة.',
              style: TextStyle(
                color: Color(0xFFBAE6FD),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'بيانات واجهة الصيانة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title field
          const Text(
            'عنوان الصيانة',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'مثال: أعمال صيانة وتحديث',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF38BDF8), size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          // Message field
          const Text(
            'رسالة الصيانة (تظهر للزبائن بالتفصيل)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              hintText: 'اكتب رسالة توضيحية للزبائن تفيد بوجود صيانة مؤقتة والعودة قريباً...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 1. Activate Maintenance button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _showConfirmationDialog(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: _isMaintenance ? 0 : 4,
              shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: _isMaintenance
                    ? const BorderSide(color: Colors.white30, width: 1.5)
                    : BorderSide.none,
              ),
            ),
            icon: _isSubmitting && _isMaintenance
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.build_rounded, size: 18),
            label: const Text(
              'تفعيل صيانة',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Deactivate Maintenance button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _showConfirmationDialog(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: !_isMaintenance ? 0 : 4,
              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: !_isMaintenance
                    ? const BorderSide(color: Colors.white30, width: 1.5)
                    : BorderSide.none,
              ),
            ),
            icon: _isSubmitting && !_isMaintenance
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text(
              'إلغاء صيانة',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(bool activate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: activate
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : const Color(0xFF10B981).withValues(alpha: 0.4),
          ),
        ),
        title: Row(
          children: [
            Icon(
              activate ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: activate ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              activate ? 'تأكيد تفعيل الصيانة' : 'تأكيد إلغاء الصيانة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          activate
              ? 'هل أنت متأكد من تفعيل وضع الصيانة؟\nسيتم إغلاق التطبيق في وجه كافة المستخدمين ولن يتمكنوا من الشراء حتى تلغي الصيانة.'
              : 'هل تريد إلغاء وضع الصيانة والسماح للزبائن بفتح التطبيق واستخدامه بشكل طبيعي؟',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              foregroundColor: activate ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateMaintenance(activate);
            },
            child: Text(
              activate ? 'نعم، فعّل الصيانة' : 'نعم، افتح التطبيق',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final title = _titleController.text.trim().isEmpty ? 'أعمال صيانة وتحديث' : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'نقوم حالياً ببعض أعمال الصيانة والتحسينات الدورية لنقدم لكم تجربة أفضل وأسرع. سنعود للعمل قريباً جداً، نشكر تفهمكم!'
        : _messageController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.remove_red_eye_rounded, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text(
                'معاينة شاشة الصيانة كما يراها المستخدم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Simulated Screen Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF07111F), Color(0xFF0B1728)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Glowing Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.engineering_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text(
                        'وضع الصيانة والتطوير',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                // Fake Retry Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'إعادة المحاولة / التحقق مجدداً',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

