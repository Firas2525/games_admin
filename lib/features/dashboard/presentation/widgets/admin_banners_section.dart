import 'package:games_admin/core/widgets/app_network_image.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../products/data/models/category_item_model.dart';
import '../../data/models/banner_model.dart';

class AdminBannersSection extends StatefulWidget {
  final String initialPlacement; // 'home' or 'category'
  final String initialCategoryKey;
  final bool showPlacementTabs;

  const AdminBannersSection({
    super.key,
    this.initialPlacement = 'home',
    this.initialCategoryKey = '',
    this.showPlacementTabs = false,
  });

  @override
  State<AdminBannersSection> createState() => AdminBannersSectionState();
}

class AdminBannersSectionState extends State<AdminBannersSection> {
  final PageController _pageController = PageController();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  late String _selectedPlacement;
  late String _selectedCategoryKey;

  List<Map<String, dynamic>> _categories = [
    {'key': '', 'title': 'كل الأقسام (عام)', 'icon': Icons.public_rounded},
    {
      'key': 'games',
      'title': 'الألعاب',
      'icon': Icons.sports_esports_rounded,
    },
    {'key': 'apps', 'title': 'التطبيقات', 'icon': Icons.apps_rounded},
    {
      'key': 'cards',
      'title': 'البطاقات',
      'icon': Icons.card_giftcard_rounded,
    },
    {
      'key': 'subscriptions',
      'title': 'الاشتراكات',
      'icon': Icons.subscriptions_rounded,
    },
    {'key': 'social', 'title': 'سوشيال ميديا', 'icon': Icons.share_rounded},
    {'key': 'numbers', 'title': 'الأرقام', 'icon': Icons.dialpad_rounded},
    {
      'key': 'payment',
      'title': 'دفع إلكتروني',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  static const List<BannerModel> _defaultHomeBanners = [
    BannerModel(
      id: 'def_1',
      title: 'عروض حصرية وشحن فوري لجميع الألعاب',
      imageUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1200&q=80',
      order: 1,
      isActive: true,
      placement: 'home',
    ),
    BannerModel(
      id: 'def_2',
      title: 'بطاقات الهدايا والشحن الرقمي المباشر',
      imageUrl:
          'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=1200&q=80',
      order: 2,
      isActive: true,
      placement: 'home',
    ),
    BannerModel(
      id: 'def_3',
      title: 'أفضل أسعار العملات واشتراكات البث VIP',
      imageUrl:
          'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=1200&q=80',
      order: 3,
      isActive: true,
      placement: 'home',
    ),
  ];

  final Set<String> _dismissedDefaultIds = {};

  List<BannerModel> get _activeBanners {
    if (_banners.isNotEmpty) return _banners;
    if (_selectedPlacement == 'category') return [];
    return _defaultHomeBanners
        .where((b) => !_dismissedDefaultIds.contains(b.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedPlacement = widget.initialPlacement;
    _selectedCategoryKey = widget.initialCategoryKey;
    _loadDynamicCategories();
    fetchBanners();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDynamicCategories() async {
    try {
      final res = await sl<ApiClient>().get('/products/categories');
      final rawList = res.data?['data'] as List?;
      if (rawList != null && rawList.isNotEmpty && mounted) {
        final loaded = <Map<String, dynamic>>[
          {'key': '', 'title': 'كل الأقسام (عام)', 'icon': Icons.public_rounded},
        ];
        for (final item in rawList) {
          final model =
              CategoryItemModel.fromJson(Map<String, dynamic>.from(item));
          loaded.add({
            'key': model.key.isNotEmpty ? model.key : model.id,
            'title': model.title,
            'icon': model.displayIcon,
          });
        }
        setState(() {
          _categories = loaded;
        });
      }
    } catch (_) {
      // Keep default categories fallback
    }
  }

  String _categoryLabelForKey(String key) {
    if (key.isEmpty) return 'كل الأقسام';
    for (final c in _categories) {
      if (c['key'] == key) return c['title'] as String;
    }
    return key;
  }

  Future<void> fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{
        'placement': _selectedPlacement,
      };
      if (_selectedPlacement == 'category' && _selectedCategoryKey.isNotEmpty) {
        queryParams['category'] = _selectedCategoryKey;
      }

      final res = await sl<ApiClient>().get(
        '/banners',
        queryParameters: queryParams,
      );
      if (res.data != null && res.data['data'] != null && mounted) {
        var list = (res.data['data'] as List)
            .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
            .where((b) => b.isActive && b.imageUrl.isNotEmpty)
            .toList();

        if (_selectedPlacement == 'category' &&
            _selectedCategoryKey.isNotEmpty) {
          list = list
              .where((b) =>
                  b.categoryKey == _selectedCategoryKey || b.categoryKey.isEmpty)
              .toList();
        }

        setState(() {
          _banners = list;
          _currentIndex = 0;
          _isLoading = false;
        });

        _startAutoPlay();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    final items = _activeBanners;
    if (items.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % items.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> pickAndAddBanner() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 88,
      );

      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;
      final confirmed = await _showConfirmDialog(bytes);
      if (confirmed != true || !mounted) return;

      _uploadAndSaveBanner(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(Uint8List bytes) {
    final targetLabel = _selectedPlacement == 'category'
        ? 'قسم: ${_categoryLabelForKey(_selectedCategoryKey)}'
        : 'الواجهة الرئيسية';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'معاينة الإعلان قبل النشر',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      'مكان العرض: $targetLabel',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('نشر الإعلان',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSaveBanner(Uint8List bytes) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Color(0xFF0284C7)),
                ),
                SizedBox(width: 14),
                Text(
                  'جاري نشر الإعلان في التطبيق...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final uploadRes = await sl<ApiClient>().post('/banners/upload', data: {
        'file': base64String,
        'uploadPreset': 'ml_default',
      });

      String? uploadedUrl;
      if (uploadRes.data != null && uploadRes.data['data'] != null) {
        uploadedUrl = uploadRes.data['data']['url'] as String?;
      }

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('فشل الحصول على رابط الصورة المرفوعة');
      }

      await sl<ApiClient>().post('/banners', data: {
        'imageUrl': uploadedUrl,
        'title': '',
        'isActive': true,
        'placement': _selectedPlacement,
        'categoryKey':
            _selectedPlacement == 'category' ? _selectedCategoryKey : '',
      });

      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الإعلان بنجاح في التطبيق ✅'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await fetchBanners();
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text('حذف الإعلان',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً من التطبيق؟',
            style: TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الحذف',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFEF4444)),
      ),
    );

    try {
      if (!banner.id.startsWith('def_')) {
        await sl<ApiClient>().delete('/banners/${banner.id}');
      }

      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);

        setState(() {
          _banners.removeWhere((b) => b.id == banner.id);
          _dismissedDefaultIds.add(banner.id);
          if (_currentIndex >= _activeBanners.length && _currentIndex > 0) {
            _currentIndex = _activeBanners.length - 1;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإعلان بنجاح ✅'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await fetchBanners();
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPlacementSwitchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                if (_selectedPlacement != 'home') {
                  setState(() => _selectedPlacement = 'home');
                  fetchBanners();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedPlacement == 'home'
                      ? const Color(0xFF0284C7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 15,
                      color: _selectedPlacement == 'home'
                          ? Colors.white
                          : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إعلانات الرئيسية',
                      style: TextStyle(
                        color: _selectedPlacement == 'home'
                            ? Colors.white
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                if (_selectedPlacement != 'category') {
                  setState(() => _selectedPlacement = 'category');
                  fetchBanners();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedPlacement == 'category'
                      ? const Color(0xFF0284C7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.collections_bookmark_rounded,
                      size: 15,
                      color: _selectedPlacement == 'category'
                          ? Colors.white
                          : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إعلانات داخل الأقسام',
                      style: TextStyle(
                        color: _selectedPlacement == 'category'
                            ? Colors.white
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectorBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر القسم لإدارة إعلاناته الفرعية:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final key = cat['key'] as String;
              final title = cat['title'] as String;
              final icon = cat['icon'] as IconData;
              final isSel = _selectedCategoryKey == key;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _selectedCategoryKey = key);
                  fetchBanners();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                        : const Color(0xFF0B1322),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSel ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color:
                            isSel ? const Color(0xFF38BDF8) : Colors.white54,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        title,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.white70,
                          fontSize: 11.5,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = _activeBanners;
    final headerTitle = _selectedPlacement == 'category'
        ? 'إعلانات ${_categoryLabelForKey(_selectedCategoryKey)}'
        : 'إعلانات الواجهة الرئيسية';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showPlacementTabs) _buildPlacementSwitchBar(),
        if (_selectedPlacement == 'category') _buildCategorySelectorBar(),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      headerTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (banners.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${banners.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Header Action
            Tooltip(
              message: 'إضافة إعلان جديد',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: pickAndAddBanner,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 15, color: Color(0xFF38BDF8)),
                        SizedBox(width: 5),
                        Text(
                          'إضافة إعلان',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Carousel / Content Area
        if (_isLoading)
          Container(
            height: 155,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0284C7)),
              ),
            ),
          )
        else if (banners.isEmpty)
          Container(
            height: 145,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1322),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 34, color: Colors.white30),
                  const SizedBox(height: 8),
                  Text(
                    _selectedPlacement == 'category'
                        ? 'لا توجد إعلانات فرعية في (${_categoryLabelForKey(_selectedCategoryKey)}) حالياً'
                        : 'لا توجد إعلانات معروضة حالياً',
                    style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickAndAddBanner,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'رفع إعلان من المعرض',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 155,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: banners.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final banner = banners[index];

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1E1B4B),
                                      Color(0xFF312E81)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      size: 36, color: Colors.white24),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFF07111F),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (_selectedPlacement == 'category')
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  banner.categoryKey.isEmpty
                                      ? 'يظهر في: كل الأقسام'
                                      : 'قسم: ${_categoryLabelForKey(banner.categoryKey)}',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Top Action Bar Overlaid Directly on Top of the Banner
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Tooltip(
                                  message: 'حذف هذا الإعلان',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _deleteBanner(banner),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A)
                                              .withValues(alpha: 0.82),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.7),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Color(0xFFF87171),
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (banners.length > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${index + 1} / ${banners.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Tooltip(
                                  message: 'إضافة إعلان جديد',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: pickAndAddBanner,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0284C7),
                                              Color(0xFF6366F1)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.8),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    final isSelected = _currentIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 18 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0284C7)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
