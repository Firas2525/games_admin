import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';

// Brand Ocean & Electric Sky Blue Theme (Matching Home Page)
const Color _kDarkBg = Color(0xFF07111F);
const Color _kCardBg = Color(0xFF0F172A);
const Color _kInnerBg = Color(0xFF131F35);
const Color _kPrimary = Color(0xFF0284C7); // Electric Ocean Blue
const Color _kAccent = Color(0xFF38BDF8); // Bright Sky Blue
const Color _kAmber = Color(0xFFF59E0B);
const Color _kEmerald = Color(0xFF10B981);
const Color _kRed = Color(0xFFEF4444);

class AdminCompetitionsPage extends StatefulWidget {
  const AdminCompetitionsPage({super.key});

  @override
  State<AdminCompetitionsPage> createState() => _AdminCompetitionsPageState();
}

class _AdminCompetitionsPageState extends State<AdminCompetitionsPage> {
  bool _isLoading = true;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _competition;
  List<Map<String, dynamic>> _topBuyers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.get('/competitions');
      if (res.data != null && res.data['data'] != null) {
        final data = res.data['data'];
        setState(() {
          _competition = data['competition'] != null
              ? Map<String, dynamic>.from(data['competition'])
              : null;
          if (data['topBuyers'] is List) {
            _topBuyers = (data['topBuyers'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          } else {
            _topBuyers = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل بيانات المسابقة: $e'),
            backgroundColor: _kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      String uploadedUrl = base64String;
      try {
        final dio = sl<ApiClient>().dio;
        final res = await dio.post('/banners/upload', data: {
          'file': base64String,
          'uploadPreset': 'ml_default',
        });
        if (res.data != null && res.data['data'] != null) {
          final url = res.data['data']['url']?.toString();
          if (url != null && url.isNotEmpty) {
            uploadedUrl = url;
          }
        }
      } catch (_) {}

      // Save banner to competitions endpoint
      final dio = sl<ApiClient>().dio;
      await dio.post('/competitions/banner', data: {
        'imageUrl': uploadedUrl,
        'title': 'مسابقة المتصدرين والتحدي',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ صورة المسابقة ونشرها لجميع المستخدمين بنجاح!'),
            backgroundColor: _kEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع صورة المسابقة: $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _confirmDeleteCompetition() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _kInnerBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: _kRed, size: 24),
              SizedBox(width: 8),
              Text('حذف المسابقة الحالية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف صورة المسابقة؟ سيظهر للمستخدمين أنه "لا توجد مسابقة حالياً".',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، حذف المسابقة'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isUploadingImage = true);
      final dio = sl<ApiClient>().dio;
      await dio.delete('/competitions/banner');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم حذف المسابقة وإلغاء تفعيلها بنجاح'),
            backgroundColor: _kAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف المسابقة: $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: _kAccent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'اختيار صورة إعلان المسابقة',
                    style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: _kInnerBg,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: _kAccent, size: 22),
                ),
                title: const Text('المعرض (Gallery)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('اختر صورة مصممة بدقة عالية من جهازك', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: _kInnerBg,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: _kEmerald, size: 22),
                ),
                title: const Text('الكاميرا (Camera)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('التقاط صورة مباشرة عبر الكاميرا', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppNetworkImage(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label بنجاح: $text ✅'),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveCompetition = _competition != null &&
        (_competition!['imageUrl']?.toString().isNotEmpty ?? false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kDarkBg,
        appBar: AppBar(
          backgroundColor: _kCardBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, color: _kAmber, size: 22),
              SizedBox(width: 8),
              Text(
                'إدارة المسابقات والمتصدرين',
                style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                backgroundColor: _kCardBg,
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  children: [
                    // Section 1: Competition Banner Management (Redesigned)
                    _buildCompetitionBannerCard(hasActiveCompetition),
                    const SizedBox(height: 24),

                    // Section 2: Leaderboard (Top 10 Buyers)
                    _buildLeaderboardHeader(),
                    const SizedBox(height: 12),
                    _buildLeaderboardList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCompetitionBannerCard(bool hasActiveCompetition) {
    final imageUrl = _competition?['imageUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasActiveCompetition
              ? _kPrimary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: hasActiveCompetition ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasActiveCompetition
                ? _kPrimary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.campaign_rounded, color: _kAccent, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صورة وإعلان المسابقة الرئيسية',
                      style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'صورة مسابقة واحدة فقط تظهر لكافة الزبائن كإعلان منافسة',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: hasActiveCompetition
                      ? _kEmerald.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasActiveCompetition
                        ? _kEmerald.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasActiveCompetition ? _kEmerald : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasActiveCompetition ? 'نشطة ومعروضة ✅' : 'غير مفعلة ⏸️',
                      style: TextStyle(
                        color: hasActiveCompetition ? _kEmerald : Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Uploading indicator
          if (_isUploadingImage)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _kInnerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _kAccent, strokeWidth: 2.8),
                  SizedBox(height: 14),
                  Text(
                    'جاري رفع ومعالجة صورة المسابقة...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'سيتم تفعيل المسابقة وتحديثها لدى الجميع فوراً',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            )
          // Active competition preview
          else if (hasActiveCompetition && imageUrl.isNotEmpty)
            Column(
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: () => _showImagePreviewDialog(imageUrl),
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kPrimary.withValues(alpha: 0.35), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AppNetworkImage(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: InkWell(
                        onTap: () => _showImagePreviewDialog(imageUrl),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, size: 14, color: _kAccent),
                              SizedBox(width: 4),
                              Text('تكبير ومعاينة', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: const Text(
                          'تغيير صورة المسابقة 🔄',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showImageSourcePicker,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kRed,
                          side: BorderSide(color: _kRed.withValues(alpha: 0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف المسابقة 🗑️', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        onPressed: _confirmDeleteCompetition,
                      ),
                    ),
                  ],
                ),
              ],
            )
          // Empty State: Beautiful Upload Dropzone
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
              decoration: BoxDecoration(
                color: _kInnerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: _kAccent,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'رفع صورة إعلان المسابقة 🖼️',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اختر صورة واضحة بنسبة (16:9) لتظهر كإعلان في قمة صفحة المسابقة لدى كافة المستخدمين',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text(
                          'المعرض (Gallery)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kAccent,
                          side: const BorderSide(color: _kAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text(
                          'الكاميرا (Camera)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _pickAndUploadImage(ImageSource.camera),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.military_tech_rounded, color: _kAmber, size: 20),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المتصدرون الأكثر شراءً',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'أفضل 10 متسابقين بالمسابقة',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${_topBuyers.length} متصدرين 🏆',
            style: const TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    if (_topBuyers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Column(
          children: [
            Icon(Icons.leaderboard_outlined, color: Colors.white24, size: 48),
            SizedBox(height: 10),
            Text(
              'لا يوجد مستخدمون بمشتريات مسجلة بعد',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _topBuyers.map((user) {
        final rank = user['rank'] ?? 0;
        final name = user['name']?.toString() ?? 'User';
        final email = user['email']?.toString() ?? '';
        final userCode = user['userCode']?.toString() ?? '';
        final totalSpent = (user['totalSpent'] as num?)?.toDouble() ?? 0.0;
        final levelName = user['levelName']?.toString() ?? 'برونزي';
        final levelEmoji = user['levelEmoji']?.toString() ?? '🥉';
        final levelBadgeUrl = user['levelBadgeUrl']?.toString() ?? '';

        Color rankBadgeBg;
        Color rankColor;
        Widget rankWidget;

        if (rank == 1) {
          rankColor = const Color(0xFFFFD700); // Gold
          rankBadgeBg = const Color(0xFFFFD700).withValues(alpha: 0.16);
          rankWidget = const Text('👑 1', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 14));
        } else if (rank == 2) {
          rankColor = const Color(0xFFE2E8F0); // Silver
          rankBadgeBg = const Color(0xFFCBD5E1).withValues(alpha: 0.16);
          rankWidget = const Text('🥈 2', style: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w900, fontSize: 14));
        } else if (rank == 3) {
          rankColor = const Color(0xFFFDBA74); // Bronze
          rankBadgeBg = const Color(0xFFFDBA74).withValues(alpha: 0.16);
          rankWidget = const Text('🥉 3', style: TextStyle(color: Color(0xFFFDBA74), fontWeight: FontWeight.w900, fontSize: 14));
        } else {
          rankColor = Colors.white70;
          rankBadgeBg = Colors.white.withValues(alpha: 0.06);
          rankWidget = Text('#$rank', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13));
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank <= 3 ? rankColor.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.07),
              width: rank <= 3 ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: rank <= 3 ? rankColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank indicator
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                ),
                child: rankWidget,
              ),
              const SizedBox(width: 10),

              // Level badge image or emoji
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kInnerBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: ClipOval(
                  child: levelBadgeUrl.isNotEmpty
                      ? AppNetworkImage(
                          levelBadgeUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(levelEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                        )
                      : Center(
                          child: Text(levelEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            levelName,
                            style: const TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _copyToClipboard(userCode, 'معرف المستخدم'),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: #$userCode',
                                style: const TextStyle(color: _kAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.copy_rounded, color: _kAccent, size: 12),
                            ],
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              email,
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Purchasing Value (قيمة الشراء) - Admin View
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kEmerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kEmerald.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'إجمالي الشراء',
                      style: TextStyle(color: Colors.white54, fontSize: 9.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _kEmerald,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


