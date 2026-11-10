import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key});

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  bool _isLoading = true;
  String? _updatingLevelKey;

  final List<_LevelTierItem> _tiers = [
    _LevelTierItem(
      key: 'bronze',
      name: 'المستوى البرونزي',
      nameEn: 'Bronze',
      range: 'من \$0 إلى أقل من \$51',
      defaultEmoji: '🥉',
      color: const Color(0xFFCD7F32),
      secondaryColor: const Color(0xFFD97706),
    ),
    _LevelTierItem(
      key: 'silver',
      name: 'المستوى الفضي',
      nameEn: 'Silver',
      range: 'من \$51 إلى أقل من \$101',
      defaultEmoji: '🥈',
      color: const Color(0xFF94A3B8),
      secondaryColor: const Color(0xFFCBD5E1),
    ),
    _LevelTierItem(
      key: 'gold',
      name: 'المستوى الذهبي',
      nameEn: 'Gold',
      range: 'من \$101 إلى أقل من \$501',
      defaultEmoji: '🥇',
      color: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFFBBF24),
    ),
    _LevelTierItem(
      key: 'diamond',
      name: 'المستوى الماسي',
      nameEn: 'Diamond',
      range: 'من \$501 إلى أقل من \$1001',
      defaultEmoji: '💎',
      color: const Color(0xFF06B6D4),
      secondaryColor: const Color(0xFF38BDF8),
    ),
    _LevelTierItem(
      key: 'vip',
      name: 'مستوى VIP كبار الشخصيات',
      nameEn: 'VIP',
      range: 'من \$1001 فما فوق',
      defaultEmoji: '👑',
      color: const Color(0xFFA855F7),
      secondaryColor: const Color(0xFFC084FC),
    ),
  ];

  Map<String, String> _customBadges = {};

  final Color _kBg = const Color(0xFF07111F);
  final Color _kCard = const Color(0xFF0F172A);
  final Color _kInner = const Color(0xFF131F35);
  final Color _kPrimary = const Color(0xFF0284C7);
  final Color _kGreen = const Color(0xFF10B981);
  final Color _kRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _isLoading = true);
    try {
      final dio = sl<ApiClient>().dio;
      final res = await dio.get('/settings/levels');
      if (res.data != null && res.data['data'] != null) {
        final d = res.data['data'];
        final badges = d['badges'] as Map<String, dynamic>? ?? {};
        setState(() {
          _customBadges = badges.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadBadge(String levelKey, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _updatingLevelKey = levelKey);

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

      // Save to settings
      final dio = sl<ApiClient>().dio;
      await dio.patch('/settings/levels/badge', data: {
        'levelKey': levelKey,
        'badgeUrl': uploadedUrl,
      });

      setState(() {
        _customBadges[levelKey] = uploadedUrl;
        _updatingLevelKey = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث شارة المستوى بنجاح وتفعيل الصورة للمستخدمين'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updatingLevelKey = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تعيين الشارة: $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  Future<void> _resetToDefault(String levelKey) async {
    try {
      setState(() => _updatingLevelKey = levelKey);
      final dio = sl<ApiClient>().dio;
      await dio.patch('/settings/levels/badge', data: {
        'levelKey': levelKey,
        'badgeUrl': '',
      });

      setState(() {
        _customBadges.remove(levelKey);
        _updatingLevelKey = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة الأيقونة الافتراضية للمستوى بنجاح 🔄'),
            backgroundColor: Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updatingLevelKey = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل استعادة الأيقونة: $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  void _showImagePickerSheet(String levelKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختيار صورة شارة المستوى',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8)),
                  title: const Text('المعرض (Gallery)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadBadge(levelKey, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981)),
                  title: const Text('الكاميرا (Camera)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadBadge(levelKey, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
              textDirection: TextDirection.ltr,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'مستويات الحساب والشارات 🎖️',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              tooltip: 'تحديث',
              onPressed: _loadLevels,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                color: _kPrimary,
                backgroundColor: _kCard,
                onRefresh: _loadLevels,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  children: [
                    // Intro Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تخصيص شارات المستويات بالصور 🎨',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'يمكنك رفع صورة مخصصة لكل مستوى (لوغو، وسام، شارة ذهبية...) ليتم استبدال الأيقونة الافتراضية بها وتظهر مباشرة للمستخدمين.',
                                  style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tiers List
                    ..._tiers.map((tier) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTierCard(tier),
                        )),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTierCard(_LevelTierItem tier) {
    final customUrl = _customBadges[tier.key] ?? '';
    final hasCustomBadge = customUrl.isNotEmpty;
    final isUpdatingThis = _updatingLevelKey == tier.key;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCustomBadge ? tier.color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
          width: hasCustomBadge ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: hasCustomBadge ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Badge Preview (Custom Image or Emoji)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tier.color, tier.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tier.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: hasCustomBadge
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AppNetworkImage(
                            customUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(tier.defaultEmoji, style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        )
                      : Text(tier.defaultEmoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tier.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: tier.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasCustomBadge ? 'شارة مخصصة 🖼️' : 'أيقونة افتراضية',
                            style: TextStyle(color: tier.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.range,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  icon: isUpdatingThis
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_rounded, size: 16),
                  label: Text(
                    hasCustomBadge ? 'تغيير صورة الشارة' : 'اختيار صورة للشارة',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isUpdatingThis ? null : () => _showImagePickerSheet(tier.key),
                ),
              ),
              if (hasCustomBadge) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('الافتراضية', style: TextStyle(fontSize: 11.5)),
                  onPressed: isUpdatingThis ? null : () => _resetToDefault(tier.key),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelTierItem {
  final String key;
  final String name;
  final String nameEn;
  final String range;
  final String defaultEmoji;
  final Color color;
  final Color secondaryColor;

  _LevelTierItem({
    required this.key,
    required this.name,
    required this.nameEn,
    required this.range,
    required this.defaultEmoji,
    required this.color,
    required this.secondaryColor,
  });
}

