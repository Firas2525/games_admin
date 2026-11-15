import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';

class AdminAppUpdatePage extends StatefulWidget {
  const AdminAppUpdatePage({super.key});

  @override
  State<AdminAppUpdatePage> createState() => _AdminAppUpdatePageState();
}

class _AdminAppUpdatePageState extends State<AdminAppUpdatePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  late final TextEditingController _versionController;
  late final TextEditingController _buildNumberController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _urlController;

  bool _isForceUpdate = false;
  String? _updatedAtStr;

  @override
  void initState() {
    super.initState();
    _versionController = TextEditingController(text: '1.0.0');
    _buildNumberController = TextEditingController(text: '1');
    _titleController = TextEditingController(text: 'تحديث جديد متوفر 🚀');
    _notesController = TextEditingController(
      text: 'يتوفر إصدار جديد يحتوي على تحسينات هامة وسرعة أكبر في تنفيذ الطلبات وإصلاحات عامة.',
    );
    _urlController = TextEditingController(
      text: 'https://games-backend-c0h7.onrender.com/download',
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _buildNumberController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/settings/app-update');
      if (res.data != null && res.data['data'] != null && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _versionController.text = (data['latestVersion'] ?? '1.0.0').toString();
          _buildNumberController.text = (data['latestBuildNumber'] ?? '1').toString();
          _isForceUpdate = data['isForceUpdate'] == true;
          _titleController.text = (data['updateTitle'] ?? 'تحديث جديد متوفر 🚀').toString();
          _notesController.text = (data['updateNotes'] ?? '').toString();
          _urlController.text = (data['appDownloadUrl'] ??
                  'https://games-backend-c0h7.onrender.com/download')
              .toString();
          _updatedAtStr = data['updatedAt']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر جلب إعدادات التحديث: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final version = _versionController.text.trim();
    final buildNumber = int.tryParse(_buildNumberController.text.trim()) ?? 1;
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final url = _urlController.text.trim();

    if (version.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الإصدار (مثل 1.0.1)'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await sl<ApiClient>().post(
        '/settings/app-update',
        data: {
          'appVersion': version,
          'appBuildNumber': buildNumber,
          'isForceUpdate': _isForceUpdate,
          'updateTitle': title,
          'updateNotes': notes,
          'appDownloadUrl': url,
        },
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _updatedAtStr = DateTime.now().toIso8601String();
        });

        final msg = res.data?['message'] ?? 'تم حفظ إعدادات التحديث بنجاح 🚀';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
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
            content: Text('فشل حفظ إعدادات التحديث: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isForceUpdate,
      builder: (ctx) => PopScope(
        canPop: !_isForceUpdate,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isForceUpdate ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isForceUpdate ? const Color(0xFFEF4444) : const Color(0xFF0284C7))
                      .withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badge Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isForceUpdate
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isForceUpdate
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0284C7))
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _titleController.text.trim().isNotEmpty
                      ? _titleController.text.trim()
                      : 'تحديث جديد متوفر 🚀',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),

                // Version Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    'الإصدار الجديد: v${_versionController.text.trim()} (${_buildNumberController.text.trim()})',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Type of Update Chip (إجباري / اختياري)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isForceUpdate
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isForceUpdate
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _isForceUpdate
                        ? '⚠️ تحديث إجباري: لا يمكن استخدام التطبيق دون تحديث'
                        : '💡 تحديث اختياري: يمكنك التحديث لاحقاً',
                    style: TextStyle(
                      color: _isForceUpdate ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                if (_notesController.text.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ما الجديد في هذا الإصدار:',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _notesController.text.trim(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text(
                    'تحديث الآن (الانتقال للتحميل)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),

                if (!_isForceUpdate) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'التخطي والمتابعة لاحقاً',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
              'تحديث التطبيق (App Update)',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'إشعار المستخدمين بالإصدارات الجديدة وفرض التحديث الإجباري',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'تحديث البيانات',
            onPressed: _isLoading || _isSubmitting ? null : _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Current Live Status Card
                  _buildLiveStatusCard(),

                  const SizedBox(height: 18),

                  // 2. Form Settings Card
                  _buildFormCard(),

                  const SizedBox(height: 20),

                  // 3. Save & Preview Action Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'جارٍ الحفظ...' : 'حفظ إعدادات التحديث 💾',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSubmitting ? null : _saveSettings,
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                    label: const Text(
                      'معاينة نافذة التحديث كما ستظهر للمستخدمين 📱',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _showPreviewDialog,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveStatusCard() {
    final color = _isForceUpdate ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = _isForceUpdate ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;
    final statusText = _isForceUpdate ? 'التحديث الإجباري مفعل ⚠️' : 'التحديث الاختياري مفعّل ✅';
    final descText = _isForceUpdate
        ? 'أي مستخدم يمتلك نسخة أقدم لن يتمكن من استخدام التطبيق بدون التحديث أولاً.'
        : 'سيظهر إشعار للمستخدمين بوجود نسخة جديدة، مع إمكانية التخطي والمتابعة لاحقاً.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(descText, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإصدار الحالي في السيرفر: v${_versionController.text} (${_buildNumberController.text})',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              if (_updatedAtStr != null)
                Text(
                  'آخر تحديث: ${_updatedAtStr!.split("T").first}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ بيانات الإصدار الجديد:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),

          // Version String & Build Number
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رقم الإصدار (Version):',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _versionController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '1.0.1',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF38BDF8), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Build Number:',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _buildNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '2',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Force Update Switch (الخيار الأهم للمستخدم)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isForceUpdate
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isForceUpdate
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isForceUpdate ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
                  color: _isForceUpdate ? const Color(0xFFEF4444) : Colors.white54,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجبار المستخدم على التحديث (تحديث إجباري)',
                        style: TextStyle(
                          color: _isForceUpdate ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isForceUpdate
                            ? 'مفعّل: لن يتمكن المستخدم من تخطي الشاشة أو إغلاقها حتى يُحدّث.'
                            : 'معطّل: يتيح للمستخدم خيار التخطي والمتابعة داخل التطبيق.',
                        style: TextStyle(
                          color: _isForceUpdate ? const Color(0xFFFDA4AF) : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isForceUpdate,
                  activeColor: const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _isForceUpdate = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Update Title
          const Text('عنوان التحديث (Update Title):',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'تحديث جديد متوفر 🚀',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF38BDF8), size: 18),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Release Notes
          const Text('ما الجديد في هذا التحديث (Release Notes):',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'اذكر المميزات الجديدة والتحسينات للمستخدمين...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Update / Download URL
          const Text('رابط التحديث / التحميل (Download URL):',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'https://games-backend-c0h7.onrender.com/download',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF38BDF8), size: 18),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
