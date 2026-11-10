import 'package:games_admin/core/widgets/app_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/admin_product_artwork.dart';
import '../bloc/admin_products_bloc.dart';
import '../bloc/admin_products_event.dart';
import '../bloc/admin_products_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/category_item_model.dart';
import 'package:games_admin/features/orders/presentation/pages/admin_custom_orders_page.dart';
import 'package:games_admin/features/products/presentation/pages/admin_add_custom_product_page.dart';
import '../widgets/admin_folder_move_dialog.dart';

class AdminProductsPage extends StatefulWidget {
  final String initialVisibility;
  final bool isOffersOnly;

  const AdminProductsPage({
    super.key,
    this.initialVisibility = 'visible',
    this.isOffersOnly = false,
  });

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedSource = 'all';
  String _selectedMainCategory = 'all';
  late String _selectedVisibility;
  String _searchQuery = '';
  String _viewMode = 'circles'; // 'circles', 'grid', 'list' - Default to the ultra-sleek circular layout!
  final Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _selectedVisibility = widget.initialVisibility;
    context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'roya_usd':
      case 'sw_games':
      case 'sw games':
        return const Color(0xFFA855F7); // Neon Purple (رؤيا دولار)
      case 'roya_syp':
        return const Color(0xFF10B981); // Emerald Green (رؤيا ليرة)
      case 'brand1card':
      case 'brand 1 card':
      case 'brand-one-card':
        return const Color(0xFFF59E0B); // Amber / Gold (براند ون كارد)
      case 'syria_card':
      case 'auto1card':
      case 'auto 1 card':
        return const Color(0xFF38BDF8); // Sky Blue (سيريا كارد)
      case 'custom':
        return const Color(0xFFF59E0B); // Amber / Gold (مزودي الخاص)
      default:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  Color _getMainCategoryColor(String mc) {
    switch (mc.toLowerCase()) {
      case 'apps':
        return const Color(0xFF10B981);
      case 'social':
        return const Color(0xFFEC4899);
      case 'subscriptions':
        return const Color(0xFFFB7185);
      case 'numbers':
        return const Color(0xFF38BDF8);
      case 'cards':
        return const Color(0xFFF59E0B);
      case 'payment':
        return const Color(0xFFA78BFA);
      case 'games':
      default:
        return const Color(0xFF0284C7);
    }
  }

  String _getMainCategoryShort(String mc) {
    switch (mc.toLowerCase()) {
      case 'apps':
        return '💬 تطبيقات';
      case 'social':
        return '📱 سوشل';
      case 'subscriptions':
        return '🎬 اشتراك';
      case 'numbers':
        return '📞 رقم';
      case 'cards':
        return '💳 بطاقة';
      case 'payment':
        return '⚡ دفع';
      case 'games':
      default:
        return '🎮 لعبة';
    }
  }

  String _getMainCategoryName(String mc) {
    switch (mc.toLowerCase()) {
      case 'apps':
        return '💬 تطبيقات';
      case 'social':
        return '📱 خدمات سوشل ميديا';
      case 'subscriptions':
        return '🎬 اشتراكات';
      case 'numbers':
        return '📞 أرقام';
      case 'cards':
        return '💳 بطاقات';
      case 'payment':
        return '⚡ دفع إلكتروني';
      case 'games':
      default:
        return '🎮 ألعاب';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تصفية المستودع والمزودين',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (_selectedSource != 'all' || _selectedVisibility != 'visible')
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFF87171)),
                            label: const Text('إعادة ضبط', style: TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setSheetState(() {
                                _selectedSource = 'all';
                                _selectedVisibility = 'visible';
                              });
                              setState(() {
                                _selectedSource = 'all';
                                _selectedVisibility = 'visible';
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('تصفية حسب المزود الخارجي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChipSheet('جميع المزودين', 'all', _selectedSource, (v) {
                          setSheetState(() => _selectedSource = v);
                          setState(() => _selectedSource = v);
                        }),
                        _filterChipSheet('👑 رؤيا دولار', 'roya_usd', _selectedSource, (v) {
                          setSheetState(() => _selectedSource = v);
                          setState(() => _selectedSource = v);
                        }, color: const Color(0xFFA855F7)),
                        _filterChipSheet('🇸🇾 رؤيا ليرة', 'roya_syp', _selectedSource, (v) {
                          setSheetState(() => _selectedSource = v);
                          setState(() => _selectedSource = v);
                        }, color: const Color(0xFF10B981)),
                        _filterChipSheet('💎 براند ون كارد', 'brand1card', _selectedSource, (v) {
                          setSheetState(() => _selectedSource = v);
                          setState(() => _selectedSource = v);
                        }, color: const Color(0xFFF59E0B)),
                        _filterChipSheet('⚡ مزودي الخاص', 'custom', _selectedSource, (v) {
                          setSheetState(() => _selectedSource = v);
                          setState(() => _selectedSource = v);
                        }, color: const Color(0xFFF59E0B)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('تصفية حسب حالة العرض:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChipSheet('الكل (المعروض والمخفي)', 'all', _selectedVisibility, (v) {
                          setSheetState(() => _selectedVisibility = v);
                          setState(() => _selectedVisibility = v);
                        }),
                        _filterChipSheet('المعروضة بالتطبيق 🟢', 'visible', _selectedVisibility, (v) {
                          setSheetState(() => _selectedVisibility = v);
                          setState(() => _selectedVisibility = v);
                        }, color: const Color(0xFF10B981)),
                        _filterChipSheet('المخفية بالمستودع ⚪', 'hidden', _selectedVisibility, (v) {
                          setSheetState(() => _selectedVisibility = v);
                          setState(() => _selectedVisibility = v);
                        }, color: const Color(0xFF94A3B8)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إغلاق وتطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChipSheet(
    String label,
    String value,
    String current,
    Function(String) onSelect, {
    Color? color,
  }) {
    final isSel = current == value;
    final activeColor = color ?? const Color(0xFF0284C7);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? activeColor.withValues(alpha: 0.22) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? activeColor : Colors.white12,
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSel) ...[
              Icon(Icons.check_circle_rounded, size: 14, color: activeColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isOffersOnly ? 'إدارة العروض والخصومات 🏷️' : 'مستودع المنتجات والمزودين',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          // Custom Orders quick icon
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFF59E0B),
                size: 19,
              ),
            ),
            tooltip: 'طلبات مزودي الخاص ⚡',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminCustomOrdersPage()),
            ),
          ),
          const SizedBox(width: 4),

          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Icon(
                _viewMode == 'circles'
                    ? Icons.bubble_chart_rounded
                    : (_viewMode == 'grid' ? Icons.grid_view_rounded : Icons.view_list_rounded),
                color: const Color(0xFF38BDF8),
                size: 19,
              ),
            ),
            tooltip: _viewMode == 'circles'
                ? 'عرض الدوائر الحديث (اضغط للتبديل إلى شبكة البطاقات)'
                : (_viewMode == 'grid'
                    ? 'عرض شبكة البطاقات (اضغط للتبديل إلى القائمة)'
                    : 'عرض القائمة المفصلة (اضغط للتبديل إلى الدوائر)'),
            onPressed: () {
              setState(() {
                if (_viewMode == 'circles') {
                  _viewMode = 'grid';
                } else if (_viewMode == 'grid') {
                  _viewMode = 'list';
                } else {
                  _viewMode = 'circles';
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<AdminProductsBloc, AdminProductsState>(
        listener: (context, state) {
          if (state is AdminProductsLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
            );
          } else if (state is AdminProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFF43F5E), behavior: SnackBarBehavior.floating),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminProductsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
          }

          if (state is AdminProductsSyncing) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0284C7)),
                    SizedBox(height: 18),
                    Text('جاري مزامنة المستودع مع المزودين الخارجيين...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            );
          }

          List<ProductEntity> products = [];
          List<CategoryItemModel> categoryItems = [];
          bool isSyncing = false;
          if (state is AdminProductsLoaded) {
            products = state.products;
            categoryItems = state.categoryItems;
            isSyncing = state.isSyncing;
          } else if (state is AdminProductsError && state.currentProducts != null) {
            products = state.currentProducts!;
          }

          if (state is AdminProductsError && products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر جلب منتجات المستودع',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filterProducts(products);

          return Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: _selectedProductIds.isNotEmpty
                ? _buildBulkActionBar(filtered, categoryItems)
                : null,
            body: _buildProductListSection(products, filtered, categoryItems, isSyncing: isSyncing),
          );
        },
      ),
    );
  }

  List<ProductEntity> _filterProducts(List<ProductEntity> allItems) {
    return allItems.where((p) {
      if (_selectedVisibility == 'visible' && !p.isVisible) return false;
      if (_selectedVisibility == 'hidden' && p.isVisible) return false;
      if (_selectedVisibility == 'discounted' && p.discountPercent <= 0) return false;

      if (_selectedSource != 'all') {
        final src = p.source.toLowerCase();
        final sel = _selectedSource.toLowerCase();
        final matchDirect = src == sel || p.sourceName == _selectedSource;
        final matchLegacy = (sel == 'roya_usd' && (src == 'sw_games' || p.sourceName.contains('دولار'))) ||
            (sel == 'roya_syp' && p.sourceName.contains('ليرة')) ||
            (sel == 'brand1card' && (src == 'brand1card' || p.sourceName.contains('براند'))) ||
            (sel == 'syria_card' && (src == 'auto1card' || (src != 'brand1card' && p.sourceName.contains('كارد')))) ||
            (sel == 'custom' && (src == 'custom' || p.sourceName.contains('خاص')));
        if (!matchDirect && !matchLegacy) return false;
      }

      if (_selectedMainCategory != 'all' && p.mainCategory != _selectedMainCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _toggleSelectFiltered(List<ProductEntity> filtered) {
    if (filtered.isEmpty) return;
    setState(() {
      final allSelected = filtered.every((p) => _selectedProductIds.contains(p.id));
      if (allSelected) {
        for (final p in filtered) {
          _selectedProductIds.remove(p.id);
        }
      } else {
        for (final p in filtered) {
          _selectedProductIds.add(p.id);
        }
      }
    });
  }

  int _countForSource(List<ProductEntity> allItems, String sourceKey) {
    if (sourceKey == 'all') return allItems.length;
    return allItems.where((p) {
      final src = p.source.toLowerCase();
      final sel = sourceKey.toLowerCase();
      if (src == sel || p.sourceName == sourceKey) return true;
      if (sel == 'roya_usd' && (src == 'sw_games' || p.sourceName.contains('دولار'))) return true;
      if (sel == 'roya_syp' && p.sourceName.contains('ليرة')) return true;
      if (sel == 'brand1card' && (src == 'brand1card' || p.sourceName.contains('براند'))) return true;
      if (sel == 'syria_card' && (src == 'auto1card' || (src != 'brand1card' && p.sourceName.contains('كارد')))) return true;
      if (sel == 'custom' && (src == 'custom' || p.sourceName.contains('خاص'))) return true;
      return false;
    }).length;
  }

  Widget _buildQuickProviderPill(
    String label,
    String value,
    List<ProductEntity> allItems, {
    Color? color,
  }) {
    final isSel = _selectedSource == value;
    final activeColor = color ?? const Color(0xFF0284C7);
    final count = _countForSource(allItems, value);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedSource = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? activeColor.withValues(alpha: 0.22) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? activeColor : Colors.white10,
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSel ? activeColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListSection(
    List<ProductEntity> allItems,
    List<ProductEntity> filtered,
    List<CategoryItemModel> categoryItems, {
    bool isSyncing = false,
  }) {
    int visibleCount = 0;
    int hiddenCount = 0;
    int discountedCount = 0;
    for (final p in allItems) {
      if (p.isVisible) {
        visibleCount++;
      } else {
        hiddenCount++;
      }
      if (p.discountPercent > 0) discountedCount++;
    }

    return Column(
      children: [
        if (isSyncing)
          const LinearProgressIndicator(
            minHeight: 2.5,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
          ),
        // Clean Search & Quick Filter Bar
        Container(
          color: const Color(0xFF101827),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'بحث باسم المنتج أو الباقة...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF38BDF8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white60),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_selectedSource != 'all' || _selectedVisibility != 'all')
                        ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                        : const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selectedSource != 'all' || _selectedVisibility != 'all')
                          ? const Color(0xFF0284C7)
                          : Colors.white10,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Text('تصفية', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Quick Provider Tabs directly on screen for effortless instant switching
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _buildQuickProviderPill('الكل', 'all', allItems),
              const SizedBox(width: 6),
              _buildQuickProviderPill('👑 رؤيا دولار', 'roya_usd', allItems, color: const Color(0xFFA855F7)),
              const SizedBox(width: 6),
              _buildQuickProviderPill('🇸🇾 رؤيا ليرة', 'roya_syp', allItems, color: const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _buildQuickProviderPill('💎 براند ون كارد', 'brand1card', allItems, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _buildQuickProviderPill('⚡ مزودي الخاص', 'custom', allItems, color: const Color(0xFF0284C7)),
            ],
          ),
        ),

        // Row 2: Status / Visibility Filter (المفعل، غير المفعل، الكل، العروض)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _buildVisibilityPill(
                label: '🌐 الكل (${allItems.length})',
                value: 'all',
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(width: 6),
              _buildVisibilityPill(
                label: '🟢 المفعل ($visibleCount)',
                value: 'visible',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              _buildVisibilityPill(
                label: '🔴 غير المفعل ($hiddenCount)',
                value: 'hidden',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 6),
              _buildVisibilityPill(
                label: '🏷️ العروض والخصومات ($discountedCount)',
                value: 'discounted',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),

        // Row 3: Categories Filter (فلترة الأقسام والتصنيفات)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _buildCategorySegment('الكل (${allItems.length})', 'all', const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              if (categoryItems.isNotEmpty)
                ...categoryItems.map((cat) {
                  final count = allItems.where((p) => p.mainCategory == cat.key).length;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildCategorySegment(
                      '${cat.title} ($count)',
                      cat.key,
                      cat.displayColor,
                      cat: cat,
                    ),
                  );
                })
              else ...[
                _buildCategorySegment('🎮 ألعاب (${allItems.where((p) => p.mainCategory == 'games').length})', 'games', const Color(0xFF0284C7)),
                const SizedBox(width: 6),
                _buildCategorySegment('💬 تطبيقات (${allItems.where((p) => p.mainCategory == 'apps').length})', 'apps', const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildCategorySegment('📱 سوشل (${allItems.where((p) => p.mainCategory == 'social').length})', 'social', const Color(0xFFEC4899)),
                const SizedBox(width: 6),
                _buildCategorySegment('🎬 اشتراك (${allItems.where((p) => p.mainCategory == 'subscriptions').length})', 'subscriptions', const Color(0xFFFB7185)),
                const SizedBox(width: 6),
                _buildCategorySegment('📞 أرقام (${allItems.where((p) => p.mainCategory == 'numbers').length})', 'numbers', const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                _buildCategorySegment('💳 بطاقات (${allItems.where((p) => p.mainCategory == 'cards').length})', 'cards', const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                _buildCategorySegment('⚡ دفع (${allItems.where((p) => p.mainCategory == 'payment').length})', 'payment', const Color(0xFFA78BFA)),
              ],
              const SizedBox(width: 8),
              // Button to Add New Category
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _showCreateCategoryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Text(
                        'إضافة قسم جديد +',
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
              const SizedBox(width: 8),
              // Button to Manage All Category Images
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showManageCategoryImagesSheet(categoryItems),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text(
                        'إدارة صور الأقسام 🖼️',
                        style: TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 11.5,
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

        // Interactive Results & Select-All Bar for Filtered items
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              // 1. Select All Checkbox / Button for Filtered Items
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: filtered.isEmpty ? null : () => _toggleSelectFiltered(filtered),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id)))
                          ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id)))
                            ? const Color(0xFF38BDF8)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id)))
                              ? Icons.check_box_rounded
                              : (filtered.any((p) => _selectedProductIds.contains(p.id))
                                  ? Icons.indeterminate_check_box_rounded
                                  : Icons.check_box_outline_blank_rounded),
                          size: 16,
                          color: (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id))) ||
                                  filtered.any((p) => _selectedProductIds.contains(p.id))
                              ? const Color(0xFF38BDF8)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id)))
                                ? 'إلغاء التحديد'
                                : 'تحديد الكل (${filtered.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: (filtered.isNotEmpty && filtered.every((p) => _selectedProductIds.contains(p.id)))
                                  ? const Color(0xFFBAE6FD)
                                  : Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Summary stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'النتائج: ${filtered.length}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '🟢 ${filtered.where((p) => p.isVisible).length}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 3-Mode Segmented View Switcher: Circles / Grid / List
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D31),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeIconBtn('circles', Icons.bubble_chart_rounded, 'دوائر'),
                        _buildViewModeIconBtn('grid', Icons.grid_view_rounded, 'شبكة'),
                        _buildViewModeIconBtn('list', Icons.view_list_rounded, 'قائمة'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Products List / Grid with Scroll-to-Refresh
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0284C7),
            backgroundColor: const Color(0xFF0F172A),
            onRefresh: () async {
              context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
            },
            child: filtered.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'لا توجد منتجات مطابقة للبحث أو التصفية\nاسحب للأسفل للتحديث',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, height: 1.5),
                        ),
                      ),
                    ),
                  )
                : (_viewMode == 'circles'
                    ? _buildCircularGrid(filtered, categoryItems)
                    : (_viewMode == 'grid'
                        ? _buildGrid(filtered, categoryItems)
                        : _buildList(filtered, categoryItems))),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityPill({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSel = _selectedVisibility == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedVisibility = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? color : Colors.white12, width: isSel ? 1.4 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySegment(
    String label,
    String value,
    Color color, {
    CategoryItemModel? cat,
  }) {
    final isSel = _selectedMainCategory == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedMainCategory = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? color : Colors.white10, width: isSel ? 1.4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cat != null && cat.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AppNetworkImage(
                  cat.imageUrl,
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(cat.displayIcon, size: 14, color: color),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (cat != null && cat.profitPercentage != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  '${cat.profitPercentage}%',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34D399),
                  ),
                ),
              ),
            ],
            if (cat != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showEditCategoryDialog(cat),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 11,
                    color: isSel ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(List<ProductEntity> currentFilteredItems, List<CategoryItemModel> categoryItems) {
    final allFilteredSelected = currentFilteredItems.isNotEmpty &&
        currentFilteredItems.every((p) => _selectedProductIds.contains(p.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Selection Status, Filtered Select/Deselect, and Cancel
            Row(
              children: [
                // Selection Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 15),
                      const SizedBox(width: 5),
                      Text(
                        '${_selectedProductIds.length} عنصر محدد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Select / Deselect Filtered Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleSelectFiltered(currentFilteredItems),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          allFilteredSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                          size: 14,
                          color: const Color(0xFFBAE6FD),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          allFilteredSelected
                              ? 'إلغاء المعروض'
                              : 'تحديد المعروض (${currentFilteredItems.length})',
                          style: const TextStyle(
                            color: Color(0xFFBAE6FD),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Clear All Selection Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                  tooltip: 'إلغاء التحديد بالكامل',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedProductIds.clear()),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Top Row: Bulk Visibility Controls (Deactivate All / Activate All)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: const Text(
                      'إلغاء التفعيل ⚪',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _bulkSetVisibility(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text(
                      'تفعيل بالمتجر 🟢',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _bulkSetVisibility(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bottom Row: Organization & Discount Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => _showGroupIntoSubCategoryDialog(
                      _selectedProductIds.toList(),
                      currentFilteredItems,
                    ),
                    child: const Text(
                      'تجميع 📦',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => _showBulkMoveDialog(
                      _selectedProductIds.toList(),
                      categoryItems,
                    ),
                    child: const Text(
                      'نقل لمجلد 📂',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => _showDiscountDialog(
                      _selectedProductIds.toList(),
                    ),
                    child: const Text(
                      'خصم 🏷️',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkSetVisibility(bool isVisible) async {
    final ids = _selectedProductIds.toList();
    if (ids.isEmpty) return;

    final actionLabel = isVisible ? 'تفعيل' : 'إلغاء تفعيل';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Row(
            children: [
              Icon(
                isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: isVisible ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '$actionLabel ${ids.length} عنصر؟',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isVisible
                ? 'سيتم تفعيل هذه العناصر وإظهارها للمستخدمين في التطبيق.'
                : 'سيتم إيقاف تفعيل هذه العناصر وإخفاؤها من التطبيق فلن يتمكن الزبائن من رؤيتها أو طلبها.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isVisible ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dCtx, true),
              child: Text(
                'نعم، $actionLabel الكل',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AdminProductsBloc>().add(
        BulkToggleVisibilityEvent(productIds: ids, isVisible: isVisible),
      );
      setState(() => _selectedProductIds.clear());
    }
  }

  Widget _buildViewModeIconBtn(String mode, IconData icon, String label) {
    final isSel = _viewMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0284C7).withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSel ? const Color(0xFF38BDF8) : Colors.white60,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _detectGroupKey(String name, String category) {
    final combined = '$name $category'.toLowerCase();

    // 1. Popular Game Families
    if (combined.contains('pubg') || combined.contains('ببجي') || combined.contains('بوبجي')) {
      return 'ببجي موبايل (PUBG Mobile)';
    }
    if (combined.contains('free fire') || combined.contains('freefire') || combined.contains('فري فاير') || combined.contains('فاير')) {
      return 'فري فاير (Free Fire)';
    }
    if (combined.contains('roblox') || combined.contains('روبلوكس')) {
      return 'روبلوكس (Roblox)';
    }
    if (combined.contains('call of duty') || combined.contains('codm') || combined.contains('كول اوف ديوتي') || combined.contains('كود موبايل')) {
      return 'كول أوف ديوتي (Call of Duty)';
    }
    if (combined.contains('mobile legends') || combined.contains('موبايل ليجند') || combined.contains('mlbb')) {
      return 'موبايل ليجندز (Mobile Legends)';
    }
    if (combined.contains('yalla ludo') || combined.contains('يلا لودو') || combined.contains('لودو')) {
      return 'يلا لودو (Yalla Ludo)';
    }
    if (combined.contains('jawaker') || combined.contains('جواكر')) {
      return 'جواكر (Jawaker)';
    }
    if (combined.contains('clash of clans') || combined.contains('كلاش اوف كلانس')) {
      return 'كلاش أوف كلانس (Clash of Clans)';
    }
    if (combined.contains('clash royale') || combined.contains('كلاش رويال')) {
      return 'كلاش رويال (Clash Royale)';
    }
    if (combined.contains('brawl stars') || combined.contains('براول ستارز')) {
      return 'براول ستارز (Brawl Stars)';
    }
    if (combined.contains('fifa') || combined.contains('fc mobile') || combined.contains('فيفا') || combined.contains('اف سي')) {
      return 'إي إيه إف سي (EA FC Mobile)';
    }
    if (combined.contains('genshin') || combined.contains('قنشن') || combined.contains('جينشن')) {
      return 'جينشين إمباكت (Genshin Impact)';
    }

    // 2. Apps & Subscriptions
    if (combined.contains('tiktok') || combined.contains('تيك توك')) {
      return 'تيك توك (TikTok)';
    }
    if (combined.contains('likee') || combined.contains('لايكي')) {
      return 'لايكي (Likee)';
    }
    if (combined.contains('bigo') || combined.contains('بيجو')) {
      return 'بيجو لايف (Bigo Live)';
    }
    if (combined.contains('telegram') || combined.contains('تليجرام') || combined.contains('تلغرام')) {
      return 'تليجرام بريميوم (Telegram)';
    }
    if (combined.contains('netflix') || combined.contains('نتفلكس') || combined.contains('نتفليكس')) {
      return 'نتفلكس (Netflix)';
    }
    if (combined.contains('shahid') || combined.contains('شاهد')) {
      return 'شاهد VIP (Shahid)';
    }

    // 3. Digital Cards & Wallets
    if (combined.contains('google play') || combined.contains('جوجل بلاي')) {
      return 'بطاقات جوجل بلاي (Google Play)';
    }
    if (combined.contains('itunes') || combined.contains('apple') || combined.contains('ايتونز') || combined.contains('ابل')) {
      return 'بطاقات آيتونز (Apple iTunes)';
    }
    if (combined.contains('playstation') || combined.contains('بلايستيشن') || combined.contains('psn')) {
      return 'بطاقات بلايستيشن (PlayStation)';
    }
    if (combined.contains('xbox') || combined.contains('اكس بوكس')) {
      return 'بطاقات إكس بوكس (Xbox)';
    }
    if (combined.contains('razer') || combined.contains('رايزر')) {
      return 'بطاقات رايزر جولد (Razer Gold)';
    }
    if (combined.contains('steam') || combined.contains('ستيم')) {
      return 'بطاقات ستيم (Steam)';
    }

    // Default: Clean extraction
    String clean = name
        .replaceAll(RegExp(r'\d+\s*(شدة|جوهرة|ماسة|كوينز|نقطة|UC|Diamond|Coins|Gems)', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-–—|/\\].*'), '')
        .trim();
    if (clean.length > 3) return clean;
    return category.isNotEmpty ? category : name;
  }

  Widget _buildCircularGrid(List<ProductEntity> items, List<CategoryItemModel> categoryItems) {
    final Map<String, List<ProductEntity>> grouped = {};
    final Map<String, String> groupImages = {};
    final Map<String, int> groupActiveCounts = {};

    for (final p in items) {
      String groupKey = '';
      if (p.category.trim().isNotEmpty && p.category.trim() != 'عام' && p.category.trim() != 'Uncategorized') {
        groupKey = p.category.trim();
      } else {
        groupKey = _detectGroupKey(p.name, p.category);
      }

      grouped.putIfAbsent(groupKey, () => []).add(p);
      if (!groupImages.containsKey(groupKey) && p.image.isNotEmpty) {
        groupImages[groupKey] = p.image;
      }
      if (p.isVisible) {
        groupActiveCounts[groupKey] = (groupActiveCounts[groupKey] ?? 0) + 1;
      }
    }

    final groupKeys = grouped.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 6
            : (constraints.maxWidth > 650 ? 5 : (constraints.maxWidth > 420 ? 4 : 3));

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemCount: groupKeys.length,
          itemBuilder: (context, index) {
            final groupName = groupKeys[index];
            final groupItems = grouped[groupName]!;
            final primary = groupItems.first;
            final groupImage = groupImages[groupName] ?? primary.image;
            final activeCount = groupActiveCounts[groupName] ?? 0;
            final allActive = activeCount == groupItems.length;
            final noneActive = activeCount == 0;

            return _buildCircularItem(
              title: groupName,
              image: groupImage,
              groupProducts: groupItems,
              categoryItems: categoryItems,
              activeCount: activeCount,
              allActive: allActive,
              noneActive: noneActive,
            );
          },
        );
      },
    );
  }

  Widget _buildCircularItem({
    required String title,
    required String image,
    required List<ProductEntity> groupProducts,
    required List<CategoryItemModel> categoryItems,
    required int activeCount,
    required bool allActive,
    required bool noneActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showGroupPackagesModal(title, image, groupProducts, categoryItems),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Glowing Circular Avatar with Gradient Ring
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: noneActive
                            ? [Colors.white24, Colors.white12]
                            : const [
                                Color(0xFF0284C7), // Electric Ocean Blue
                                Color(0xFF0EA5E9), // Vivid Sky
                                Color(0xFF38BDF8), // Cyan Accent
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: noneActive
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F172A),
                      ),
                      child: ClipOval(
                        child: AdminProductArtworkWidget(
                          imageUrl: image,
                          title: title,
                          category: groupProducts.first.category,
                          mainCategory: groupProducts.first.mainCategory,
                          source: groupProducts.first.source,
                          width: 71,
                          height: 71,
                        ),
                      ),
                    ),
                  ),

                  // Active / Inactive Badge (Top Right)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: noneActive ? const Color(0xFF64748B) : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF07111F), width: 2),
                        boxShadow: noneActive
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                    ),
                  ),

                  // Packages Count Badge (Bottom Center)
                  Positioned(
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07111F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${groupProducts.length} باقة',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title underneath in bold
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // Status indicator
              Text(
                noneActive ? '⚪ معطل بالمتجر' : '🟢 $activeCount مفعلة',
                style: TextStyle(
                  fontSize: 10,
                  color: noneActive ? Colors.white38 : const Color(0xFF34D399),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupPackagesModal(
    String groupTitle,
    String groupImage,
    List<ProductEntity> packages,
    List<CategoryItemModel> categoryItems,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final activeCount = packages.where((p) => p.isVisible).length;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF07111F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),

                    // Header: Circle Avatar + Title + Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: ClipOval(
                              child: AdminProductArtworkWidget(
                                imageUrl: groupImage,
                                title: groupTitle,
                                category: packages.first.category,
                                mainCategory: packages.first.mainCategory,
                                source: packages.first.source,
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupTitle,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${packages.length} باقة إجمالية',
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '🟢 $activeCount مفعلة',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Quick Bulk Action Buttons for this Group
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                              label: const Text('تفعيل الكل 🟢', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                for (final p in packages) {
                                  if (!p.isVisible) {
                                    context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: p.id));
                                  }
                                }
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF43F5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.visibility_off_rounded, size: 15),
                              label: const Text('إلغاء تفعيل الكل ⚪', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                for (final p in packages) {
                                  if (p.isVisible) {
                                    context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: p.id));
                                  }
                                }
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.drive_file_move_rounded, size: 16, color: Color(0xFFF59E0B)),
                            ),
                            tooltip: 'تجميع وتعديل كقسم فرعي 📦',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showGroupIntoSubCategoryDialog(packages.map((p) => p.id).toList(), packages);
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white12, height: 16),

                    // Packages List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: packages.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final pkg = packages[idx];
                          final sourceColor = _getSourceColor(pkg.source);

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: pkg.isVisible
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AdminProductArtworkWidget(
                                    imageUrl: pkg.image,
                                    title: pkg.name,
                                    category: pkg.category,
                                    mainCategory: pkg.mainCategory,
                                    source: pkg.source,
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Title & Pricing
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            '${pkg.originalPrice} ${pkg.currency}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber.shade300,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: sourceColor.withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              pkg.sourceName,
                                              style: TextStyle(fontSize: 8.5, color: sourceColor, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit Name/Image Icon
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_note_rounded,
                                    size: 20,
                                    color: (pkg.isNameOverridden || pkg.isImageOverridden)
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  tooltip: (pkg.isNameOverridden || pkg.isImageOverridden)
                                      ? 'تعديل الاسم والصورة (معدل يدوياً)'
                                      : 'تعديل الاسم والصورة',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showEditProductDetailsDialog(pkg);
                                  },
                                ),

                                // Edit Inspector Icon
                                IconButton(
                                  icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF38BDF8)),
                                  tooltip: 'تعديل السعر والبيانات',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showProductInspector(pkg, categoryItems);
                                  },
                                ),

                                // Toggle Visibility Switch
                                Transform.scale(
                                  scale: 0.78,
                                  child: Switch(
                                    value: pkg.isVisible,
                                    activeThumbColor: const Color(0xFF34D399),
                                    activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    onChanged: (val) {
                                      context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: pkg.id));
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<ProductEntity> items, List<CategoryItemModel> categoryItems) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        final sourceColor = _getSourceColor(product.source);
        final isSelected = _selectedProductIds.contains(product.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0284C7)
                  : (product.isVisible ? const Color(0xFF10B981).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.07)),
              width: isSelected ? 1.6 : (product.isVisible ? 1.2 : 1),
            ),
          ),
          child: Row(
            children: [
              // Multi-select Checkbox
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedProductIds.remove(product.id);
                    } else {
                      _selectedProductIds.add(product.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 2),
                  child: Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isSelected ? const Color(0xFF38BDF8) : Colors.white30,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  AdminProductArtworkWidget(
                    imageUrl: product.image,
                    title: product.name,
                    category: product.category,
                    mainCategory: product.mainCategory,
                    source: product.source,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercent.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Source
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: sourceColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(product.sourceName, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: sourceColor)),
                        ),

                        // Main Category Pill (Click to change)
                        InkWell(
                          onTap: () => _showChangeCategoryDialog(product, categoryItems),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _getMainCategoryColor(product.mainCategory).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getMainCategoryColor(product.mainCategory).withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_getMainCategoryShort(product.mainCategory), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: _getMainCategoryColor(product.mainCategory))),
                                const SizedBox(width: 2),
                                Icon(Icons.edit_rounded, size: 9, color: _getMainCategoryColor(product.mainCategory)),
                              ],
                            ),
                          ),
                        ),

                        // Cost Price
                        Text(
                          '${product.originalPrice > 0 ? product.originalPrice.toStringAsFixed(product.originalPrice < 0.01 ? 5 : 2) : '0'} ${product.currency}',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.amber.shade300),
                        ),

                        // Discount Badge if active
                        if (product.discountPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                            ),
                            child: Text(
                              '🏷️ خصم ${product.discountPercent.toInt()}%',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Name / Image
              IconButton(
                icon: Icon(
                  Icons.edit_note_rounded,
                  size: 22,
                  color: (product.isNameOverridden || product.isImageOverridden)
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF94A3B8),
                ),
                tooltip: (product.isNameOverridden || product.isImageOverridden)
                    ? 'تعديل الاسم والصورة (معدل يدوياً)'
                    : 'تعديل الاسم والصورة',
                onPressed: () => _showEditProductDetailsDialog(product),
              ),

              // Info Inspector
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF38BDF8)),
                tooltip: 'تفاصيل المنتج',
                onPressed: () => _showProductInspector(product, categoryItems),
              ),

              // Instant Switch
              Transform.scale(
                scale: 0.78,
                child: Switch(
                  value: product.isVisible,
                  activeThumbColor: const Color(0xFF34D399),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                  onChanged: (val) {
                    context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: product.id));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<ProductEntity> items, List<CategoryItemModel> categoryItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 520 ? 3 : 2);
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            final sourceColor = _getSourceColor(product.source);
            final isSelected = _selectedProductIds.contains(product.id);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showProductInspector(product, categoryItems),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : (product.isVisible ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.white10),
                    width: isSelected ? 1.6 : (product.isVisible ? 1.4 : 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Checkbox
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProductIds.remove(product.id);
                              } else {
                                _selectedProductIds.add(product.id);
                              }
                            });
                          },
                          child: Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: sourceColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              product.sourceName,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: sourceColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.72,
                          child: Switch(
                            value: product.isVisible,
                            activeThumbColor: const Color(0xFF34D399),
                            onChanged: (_) {
                              context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: product.id));
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AdminProductArtworkWidget(
                              imageUrl: product.image,
                              title: product.name,
                              category: product.category,
                              mainCategory: product.mainCategory,
                              source: product.source,
                              width: 40,
                              height: 40,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            if (product.discountPercent > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '-${product.discountPercent.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.originalPrice} ${product.currency}',
                                style: TextStyle(fontSize: 9.5, color: Colors.amber.shade300, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      product.category,
                      style: const TextStyle(fontSize: 9, color: Color(0xFFBAE6FD)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductInspector(ProductEntity product, List<CategoryItemModel> categoryItems) {
    final sourceColor = _getSourceColor(product.source);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AdminProductArtworkWidget(
                      imageUrl: product.image,
                      title: product.name,
                      category: product.category,
                      mainCategory: product.mainCategory,
                      source: product.source,
                      width: 54,
                      height: 54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: sourceColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                                child: Text(product.sourceName, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: sourceColor)),
                              ),
                              const SizedBox(width: 8),
                              Text('ID: ${product.externalId}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.white10),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'التكلفة من المزود',
                        value: '${product.originalPrice > 0 ? product.originalPrice.toStringAsFixed(product.originalPrice < 0.01 ? 5 : 2) : '0'} ${product.currency}',
                        color: Colors.amber.shade300,
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'التصنيف الأساسي',
                        value: _getMainCategoryName(product.mainCategory),
                        color: _getMainCategoryColor(product.mainCategory),
                        icon: Icons.category_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'القسم الفرعي',
                        value: product.category,
                        color: const Color(0xFFBAE6FD),
                        icon: Icons.folder_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'حالة العرض بالتطبيق',
                        value: product.isVisible ? '🟢 معروض للعملاء' : '⚪ مخفي بالمستودع',
                        color: product.isVisible ? const Color(0xFF10B981) : Colors.white60,
                        icon: product.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      ),
                    ),
                  ],
                ),

                if (product.requiredFields.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('الحقول المطلوبة من الزبون عند الطلب (${product.requiredFields.length}):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.requiredFields.map((field) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.input_rounded, size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(field.label.isNotEmpty ? field.label : field.name, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 22),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.local_offer_rounded, size: 18),
                  label: Text(
                    product.discountPercent > 0
                        ? 'خصم (${product.discountPercent.toInt()}%)'
                        : 'خصم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(bottomCtx);
                    _showDiscountDialog([product.id], currentDiscount: product.discountPercent, singleProduct: product);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product.isVisible ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(product.isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                  label: Text(product.isVisible ? 'إخفاء' : 'إظهار', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(bottomCtx);
                    context.read<AdminProductsBloc>().add(ToggleProductVisibilityEvent(productId: product.id));
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('تعديل الاسم والصورة ✏️', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _showEditProductDetailsDialog(product);
                        },
                      ),
                    ),
                    if (product.isNameOverridden || product.isImageOverridden) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFFFBBF24),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                          ),
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('استعادة الأصل 🔄', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _confirmRevertProductDetails(product);
                        },
                      ),
                    ],
                  ],
                ),
                if (product.source == 'custom') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text('تعديل المنتج الخاص ✏️', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            Navigator.pop(bottomCtx);
                            final initialData = {
                              'id': product.id,
                              '_id': product.id,
                              'name': product.name,
                              'category': product.category,
                              'mainCategory': product.mainCategory,
                              'currency': product.currency,
                              'originalPrice': product.originalPrice,
                              'price': product.sellingPrice ?? product.originalPrice,
                              'image': product.image,
                              'requiredFields': product.requiredFields.map((f) => {
                                'label': f.label,
                                'key': f.name,
                                'type': f.type,
                                'required': f.required,
                              }).toList(),
                            };
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminAddCustomProductPage(initialProduct: initialData),
                              ),
                            );
                            if (res == true && mounted) {
                              context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFFF87171),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(bottomCtx);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('حذف المنتج الخاص؟', style: TextStyle(color: Colors.white)),
                                content: Text('هل أنت متأكد من حذف "${product.name}" نهائياً من مزودك الخاص؟', style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('نعم، احذف', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (confirm == true && mounted) {
                            try {
                              await sl<ApiClient>().delete('/products/custom/${product.id}');
                              if (mounted) {
                                context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم حذف المنتج الخاص بنجاح 🗑️'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('حدث خطأ'), backgroundColor: const Color(0xFFEF4444)),
                                );
                              }
                            }
                          }
                        },
                        child: const Icon(Icons.delete_forever_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRevertProductDetails(ProductEntity product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.restore_rounded, color: Color(0xFFFBBF24), size: 22),
              SizedBox(width: 8),
              Text('استعادة بيانات المزود الأصلية', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل أنت متأكد من تجاهل التعديلات واستعادة الاسم والصورة الأصلية من المزود؟',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (product.providerName != null && product.providerName!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('الاسم الأصلي: ${product.providerName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text('نعم، استعد الأصل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      context.read<AdminProductsBloc>().add(
        RevertProductCustomDetailsEvent(productId: product.id),
      );
    }
  }

  void _showEditProductDetailsDialog(ProductEntity product) {
    final nameCtrl = TextEditingController(text: product.name);
    final imageCtrl = TextEditingController(text: product.image);
    String previewImageUrl = product.image;
    bool isUploadingImage = false;

    Future<void> pickAndUploadImage(void Function(void Function()) setDlgState) async {
      try {
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 85,
        );
        if (file == null) return;
        setDlgState(() => isUploadingImage = true);

        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        try {
          final dio = sl<ApiClient>().dio;
          final res = await dio.post('/banners/upload', data: {
            'file': base64String,
            'uploadPreset': 'ml_default',
          });
          if (res.data != null && res.data['data'] != null) {
            final uploadedUrl = res.data['data']['url']?.toString();
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              imageCtrl.text = uploadedUrl;
              previewImageUrl = uploadedUrl;
            } else {
              imageCtrl.text = base64String;
              previewImageUrl = base64String;
            }
          } else {
            imageCtrl.text = base64String;
            previewImageUrl = base64String;
          }
        } catch (_) {
          imageCtrl.text = base64String;
          previewImageUrl = base64String;
        } finally {
          setDlgState(() => isUploadingImage = false);
        }
      } catch (_) {
        setDlgState(() => isUploadingImage = false);
      }
    }

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تعديل اسم وصورة المنتج',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المزود: ${product.sourceName}',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AdminProductArtworkWidget(
                              imageUrl: previewImageUrl,
                              title: nameCtrl.text.isNotEmpty ? nameCtrl.text : product.name,
                              category: product.category,
                              mainCategory: product.mainCategory,
                              source: product.source,
                              width: 90,
                              height: 90,
                            ),
                          ),
                        ),
                        if (isUploadingImage)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF38BDF8)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: isUploadingImage ? null : () => pickAndUploadImage(setDlgState),
                      icon: isUploadingImage
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        isUploadingImage ? 'جاري رفع الصورة...' : 'رفع صورة من المعرض 🖼️',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('اسم المنتج المعروض للعملاء:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'أدخل اسم المنتج',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF38BDF8), size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أو رابط الصورة المباشر (URL):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      if (imageCtrl.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            imageCtrl.clear();
                            setDlgState(() => previewImageUrl = '');
                          },
                          child: const Text('مسح الرابط', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: (val) {
                      setDlgState(() {
                        previewImageUrl = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'https://example.com/image.png',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF38BDF8), size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (product.isNameOverridden || product.isImageOverridden) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 15, color: Colors.amber),
                              SizedBox(width: 6),
                              Text('بيانات المزود الأصلية:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                          if (product.providerName != null && product.providerName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الاسم الأصلي: ${product.providerName}',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber,
                                side: const BorderSide(color: Colors.amber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('استعادة وتجاهل التعديلات 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                _confirmRevertProductDetails(product);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  final newImg = imageCtrl.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم المنتج'), backgroundColor: Color(0xFFEF4444)),
                    );
                    return;
                  }
                  Navigator.pop(dlgCtx);
                  context.read<AdminProductsBloc>().add(
                    UpdateProductCustomDetailsEvent(
                      productId: product.id,
                      name: newName,
                      image: newImg,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorDetailBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSubCategoriesForMain(String mainCat) async {
    try {
      final res = await sl<ApiClient>().get('/products/subcategories', queryParameters: {'mainCategory': mainCat});
      if (res.data != null && res.data['data'] is List) {
        return (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    }
    return [];
  }

  void _showChangeCategoryDialog(ProductEntity product, List<CategoryItemModel> categoryItems) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _CategoryMoveDialogContent(
        product: product,
        categoryItems: categoryItems,
        fetchSubCats: _fetchSubCategoriesForMain,
        onCreateMainCat: _showCreateCategoryDialog,
        onDone: (newMainCat, newSubName, newSubId, newSubImage) {
          context.read<AdminProductsBloc>().add(
            ChangeProductMainCategoryEvent(
              productId: product.id,
              mainCategory: newMainCat,
              subCategoryName: newSubName,
              subCategoryId: newSubId,
              subCategoryImage: newSubImage,
            ),
          );
        },
      ),
    );
  }

  void _showChangeSubCategoryDialog(ProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _SubCategoryOnlyDialogContent(
        product: product,
        fetchSubCats: _fetchSubCategoriesForMain,
        onDone: (newSubName, newSubId, newSubImage) {
          context.read<AdminProductsBloc>().add(
            ChangeProductMainCategoryEvent(
              productId: product.id,
              mainCategory: product.mainCategory,
              subCategoryName: newSubName,
              subCategoryId: newSubId,
              subCategoryImage: newSubImage,
            ),
          );
        },
      ),
    );
  }

  void _showBulkMoveDialog(List<String> productIds, List<CategoryItemModel> categoryItems) {
    AdminFolderMoveDialog.show(
      context,
      productIds: productIds,
      onMovedSuccessfully: () {
        context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
        setState(() => _selectedProductIds.clear());
      },
    );
  }

  void _showGroupIntoSubCategoryDialog(List<String> productIds, List<ProductEntity> currentItems) {
    final selectedProducts = currentItems.where((p) => productIds.contains(p.id)).toList();
    final defaultTitle = selectedProducts.isNotEmpty ? selectedProducts.first.category : '';
    final defaultImage = selectedProducts.firstWhere((p) => p.image.isNotEmpty, orElse: () => selectedProducts.first).image;
    final defaultMainCategory = selectedProducts.isNotEmpty ? selectedProducts.first.mainCategory : 'games';

    final nameController = TextEditingController(text: defaultTitle != 'عام' ? defaultTitle : '');
    final imageUrlController = TextEditingController(text: defaultImage);
    String selectedMainCat = defaultMainCategory;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickAndUploadImage() async {
            try {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (image == null) return;
              setDialogState(() => isUploadingImage = true);

              final bytes = await image.readAsBytes();
              final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

              final res = await sl<ApiClient>().post('/banners/upload', data: {
                'file': base64String,
                'uploadPreset': 'ml_default',
              });

              if (res.data != null && res.data['data'] != null) {
                final uploadedUrl = res.data['data']['url'] as String;
                setDialogState(() {
                  imageUrlController.text = uploadedUrl;
                  isUploadingImage = false;
                });
              } else {
                setDialogState(() => isUploadingImage = false);
              }
            } catch (e) {
              setDialogState(() => isUploadingImage = false);
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تجميع ${productIds.length} منتج في ساب كاتيغوري',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '💡 ستظهر هذه المنتجات مجمعة باسم وصورة واحدة للمستخدم في الصفحة الرئيسية للقسم، وعند الضغط عليها تظهر جميع باقاتها للشحن.',
                        style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('اسم التصنيف الفرعي (مثلاً: ببجي موبايل):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم التصنيف / اللعبة...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صورة التصنيف الفرعي:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: isUploadingImage ? null : pickAndUploadImage,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isUploadingImage
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                    : const Icon(Icons.cloud_upload_rounded, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  isUploadingImage ? 'جاري الرفع...' : 'رفع من الجهاز ☁️',
                                  style: const TextStyle(color: Color(0xFFFACC15), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: imageUrlController,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'رابط الصورة (Cloudinary)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                      ),
                    ),
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppNetworkImage(
                            imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFF131D31),
                              alignment: Alignment.center,
                              child: const Text('تعذر تحميل معاينة الصورة', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('تجميع وحفظ', style: TextStyle(fontWeight: FontWeight.w900)),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى كتابة اسم التصنيف الفرعي'), backgroundColor: Color(0xFFF43F5E)),
                      );
                      return;
                    }
                    Navigator.pop(dialogCtx);
                    try {
                      await sl<ApiClient>().post('/products/subcategories', data: {
                        'name': name,
                        'imageUrl': imageUrlController.text.trim(),
                        'mainCategory': selectedMainCat,
                        'productIds': productIds,
                      });
                      if (mounted) {
                        setState(() => _selectedProductIds.clear());
                        context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تجميع ${productIds.length} منتج في "$name" بنجاح! 🎉'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final profitController = TextEditingController();
    String selectedIcon = 'category_rounded';
    String selectedColor = '#6366F1';
    bool isUploadingImage = false;

    final availableIcons = [
      {'name': 'games', 'label': '🎮 ألعاب'},
      {'name': 'apps', 'label': '💬 تطبيقات'},
      {'name': 'social', 'label': '📱 سوشل'},
      {'name': 'subscriptions', 'label': '🎬 اشتراك'},
      {'name': 'numbers', 'label': '📞 أرقام'},
      {'name': 'cards', 'label': '💳 بطاقات'},
      {'name': 'payment', 'label': '⚡ دفع'},
      {'name': 'shop', 'label': '🛍️ تسوق'},
      {'name': 'offer', 'label': '🏷️ عروض'},
      {'name': 'star', 'label': '⭐ مميز'},
    ];

    final availableColors = [
      '#6366F1', // Indigo
      '#10B981', // Emerald
      '#EC4899', // Pink
      '#F59E0B', // Amber
      '#38BDF8', // Sky
      '#8B5CF6', // Purple
      '#F43F5E', // Rose
      '#14B8A6', // Teal
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickAndUploadImage() async {
            try {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (image == null) return;

              setDialogState(() => isUploadingImage = true);

              final bytes = await image.readAsBytes();
              final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

              final res = await sl<ApiClient>().post('/banners/upload', data: {
                'file': base64String,
                'uploadPreset': 'ml_default',
              });

              if (res.data != null && res.data['data'] != null) {
                final uploadedUrl = res.data['data']['url'] as String;
                setDialogState(() {
                  imageUrlController.text = uploadedUrl;
                  isUploadingImage = false;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم رفع صورة القسم إلى Cloudinary بنجاح! ☁️'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                setDialogState(() => isUploadingImage = false);
              }
            } catch (e) {
              setDialogState(() => isUploadingImage = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('حدث خطأ'),
                    backgroundColor: const Color(0xFFF43F5E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.create_new_folder_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'إضافة قسم رئيسي جديد',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم القسم (مطلوب):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: عروض وتخفيضات خاصة',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('وصف مختصر للقسم (اختياري):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: بطاقات وقسائم مخفضة لفترة محدودة',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text('نسبة ربح مخصصة للقسم (اختياري):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.percent_rounded, size: 14, color: Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: profitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'اتركه فارغاً لاعتماد نسبة ربح النظام الافتراضية',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        prefixIcon: const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF10B981)),
                        suffixText: '%',
                        suffixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '💡 ستطبق هذه النسبة على كل المنتجات داخل هذا القسم تلقائياً',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    const SizedBox(height: 12),

                    // Cloudinary Image Upload Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صورة القسم (Cloudinary):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: isUploadingImage ? null : pickAndUploadImage,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isUploadingImage
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                    : const Icon(Icons.cloud_upload_rounded, size: 14, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 4),
                                Text(
                                  isUploadingImage ? 'جاري الرفع...' : 'رفع من الجهاز ☁️',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: imageUrlController,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'رابط الصورة المرفوعة على Cloudinary',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        suffixIcon: imageUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                onPressed: () {
                                  imageUrlController.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 90,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppNetworkImage(
                            imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFF131D31),
                              alignment: Alignment.center,
                              child: const Text('تعذر تحميل معاينة الصورة', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Text('اختر أيقونة القسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((ic) {
                        final isSel = selectedIcon == ic['name'];
                        return ChoiceChip(
                          label: Text(ic['label']!, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFF131D31),
                          onSelected: (_) => setDialogState(() => selectedIcon = ic['name']!),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('اختر لون القسم المميز:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: availableColors.map((hex) {
                        final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                        final isSel = selectedColor == hex;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)] : null,
                            ),
                            child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى كتابة عنوان القسم'), backgroundColor: Color(0xFFF43F5E)),
                      );
                      return;
                    }
                    final parsedProfit = double.tryParse(profitController.text.trim());
                    Navigator.pop(ctx);
                    context.read<AdminProductsBloc>().add(CreateCategoryEvent(
                      title: title,
                      subtitle: subtitleController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                      imageUrl: imageUrlController.text.trim(),
                      profitPercentage: parsedProfit,
                    ));
                  },
                  child: const Text('إنشاء القسم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(CategoryItemModel cat) {
    final titleController = TextEditingController(text: cat.title);
    final subtitleController = TextEditingController(text: cat.subtitle);
    final imageUrlController = TextEditingController(text: cat.imageUrl);
    final profitController = TextEditingController(
      text: cat.profitPercentage != null
          ? (cat.profitPercentage! % 1 == 0
              ? cat.profitPercentage!.toInt().toString()
              : cat.profitPercentage!.toString())
          : '',
    );
    String selectedIcon = cat.icon.isNotEmpty ? cat.icon : 'category_rounded';
    String selectedColor = cat.color.isNotEmpty ? cat.color : '#6366F1';
    bool isUploadingImage = false;

    final availableIcons = [
      {'name': 'games', 'label': '🎮 ألعاب'},
      {'name': 'apps', 'label': '💬 تطبيقات'},
      {'name': 'social', 'label': '📱 سوشل'},
      {'name': 'subscriptions', 'label': '🎬 اشتراك'},
      {'name': 'numbers', 'label': '📞 أرقام'},
      {'name': 'cards', 'label': '💳 بطاقات'},
      {'name': 'payment', 'label': '⚡ دفع'},
      {'name': 'shop', 'label': '🛍️ تسوق'},
      {'name': 'offer', 'label': '🏷️ عروض'},
      {'name': 'star', 'label': '⭐ مميز'},
    ];

    final availableColors = [
      '#6366F1', // Indigo
      '#10B981', // Emerald
      '#EC4899', // Pink
      '#F59E0B', // Amber
      '#38BDF8', // Sky
      '#8B5CF6', // Purple
      '#F43F5E', // Rose
      '#14B8A6', // Teal
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickAndUploadImage() async {
            try {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (image == null) return;

              setDialogState(() => isUploadingImage = true);

              final bytes = await image.readAsBytes();
              final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

              final res = await sl<ApiClient>().post('/banners/upload', data: {
                'file': base64String,
                'uploadPreset': 'ml_default',
              });

              if (res.data != null && res.data['data'] != null) {
                final uploadedUrl = res.data['data']['url'] as String;
                setDialogState(() {
                  imageUrlController.text = uploadedUrl;
                  isUploadingImage = false;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم رفع صورة القسم إلى Cloudinary بنجاح! ☁️'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                setDialogState(() => isUploadingImage = false);
              }
            } catch (e) {
              setDialogState(() => isUploadingImage = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('حدث خطأ'),
                    backgroundColor: const Color(0xFFF43F5E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تعديل قسم: ${cat.title}',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cat.isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 20),
                      tooltip: 'حذف القسم',
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AdminProductsBloc>().add(DeleteCategoryEvent(id: cat.id));
                      },
                    ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم القسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('وصف القسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('نسبة ربح مخصصة للقسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.percent_rounded, size: 14, color: Color(0xFF10B981)),
                          ],
                        ),
                        if (profitController.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                profitController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.refresh_rounded, size: 12, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 3),
                                  Text('استعادة الافتراضي ↺', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: profitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'فارغ = اعتماد النسبة العامة للنظام',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        prefixIcon: const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF10B981)),
                        suffixText: '%',
                        suffixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profitController.text.trim().isNotEmpty
                          ? '🎯 سيتم احتساب ربح ${profitController.text.trim()}% لجميع منتجات هذا القسم'
                          : '⚙️ يتبع هذا القسم حالياً نسبة الربح العامة للنظام',
                      style: TextStyle(
                        color: profitController.text.trim().isNotEmpty ? const Color(0xFF10B981) : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cloudinary Image Upload Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صورة القسم (Cloudinary):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: isUploadingImage ? null : pickAndUploadImage,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isUploadingImage
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                    : const Icon(Icons.cloud_upload_rounded, size: 14, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 4),
                                Text(
                                  isUploadingImage ? 'جاري الرفع...' : 'رفع من الجهاز ☁️',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: imageUrlController,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'رابط صورة القسم على Cloudinary',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF131D31),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        suffixIcon: imageUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                onPressed: () {
                                  imageUrlController.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 90,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppNetworkImage(
                            imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFF131D31),
                              alignment: Alignment.center,
                              child: const Text('تعذر تحميل معاينة الصورة', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Text('أيقونة القسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((ic) {
                        final isSel = selectedIcon == ic['name'];
                        return ChoiceChip(
                          label: Text(ic['label']!, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: const Color(0xFF38BDF8),
                          backgroundColor: const Color(0xFF131D31),
                          onSelected: (_) => setDialogState(() => selectedIcon = ic['name']!),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('لون القسم:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: availableColors.map((hex) {
                        final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                        final isSel = selectedColor == hex;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)] : null,
                            ),
                            child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى كتابة عنوان القسم'), backgroundColor: Color(0xFFF43F5E)),
                      );
                      return;
                    }
                    final profitText = profitController.text.trim();
                    final parsedProfit = double.tryParse(profitText);
                    final shouldReset = profitText.isEmpty && cat.profitPercentage != null;

                    Navigator.pop(ctx);
                    context.read<AdminProductsBloc>().add(UpdateCategoryItemEvent(
                      id: cat.id,
                      title: title,
                      subtitle: subtitleController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                      imageUrl: imageUrlController.text.trim(),
                      profitPercentage: parsedProfit,
                      resetProfitPercentage: shouldReset,
                    ));
                  },
                  child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  void _showManageCategoryImagesSheet(List<CategoryItemModel> categoryItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final items = categoryItems;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFFFACC15), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إدارة وتعيين صور الأقسام',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ارفع صور الأقسام من جهازك مباشرة إلى Cloudinary لتظهر لدى المستخدمين',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  if (items.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('لا توجد أقسام مسجلة حالياً', style: TextStyle(color: Colors.white60)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cat = items[index];
                          final hasImage = cat.imageUrl.isNotEmpty;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasImage
                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Preview or "لا يوجد صورة"
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFF0F172A),
                                    child: hasImage
                                        ? AppNetworkImage(
                                            cat.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Center(
                                              child: Text('خطأ', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.hide_image_outlined, size: 20, color: Colors.white38),
                                              SizedBox(height: 2),
                                              Text('لا يوجد صورة', style: TextStyle(fontSize: 8.5, color: Colors.white38, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title and Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.title,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'المفتاح: ${cat.key} • عدد الخدمات: ${cat.productCount}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        hasImage ? '✅ الصورة مفعلة ومربوطة' : '⚠️ لا توجد صورة مرفوعة',
                                        style: TextStyle(
                                          color: hasImage ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0284C7),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final picker = ImagePicker();
                                          final XFile? image = await picker.pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1200,
                                            maxHeight: 1200,
                                            imageQuality: 85,
                                          );
                                          if (image == null) return;

                                          final bytes = await image.readAsBytes();
                                          final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

                                          final res = await sl<ApiClient>().post('/banners/upload', data: {
                                            'file': base64String,
                                            'uploadPreset': 'ml_default',
                                          });

                                          if (res.data != null && res.data['data'] != null) {
                                            final uploadedUrl = res.data['data']['url'] as String;
                                            if (context.mounted) {
                                              context.read<AdminProductsBloc>().add(UpdateCategoryItemEvent(
                                                id: cat.id,
                                                title: cat.title,
                                                subtitle: cat.subtitle,
                                                icon: cat.icon,
                                                color: cat.color,
                                                imageUrl: uploadedUrl,
                                              ));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('تم رفع وحفظ صورة قسم ${cat.title} بنجاح! ☁️'),
                                                  backgroundColor: const Color(0xFF10B981),
                                                ),
                                              );
                                              Navigator.pop(sheetCtx);
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: const Text('حدث خطأ'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.cloud_upload_rounded, size: 14, color: Colors.white),
                                      label: const Text('رفع صورة', style: TextStyle(fontSize: 11, color: Colors.white)),
                                    ),
                                    const SizedBox(height: 6),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: const BorderSide(color: Colors.white24),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(sheetCtx);
                                        _showEditCategoryDialog(cat);
                                      },
                                      icon: const Icon(Icons.edit_rounded, size: 14),
                                      label: const Text('تعديل', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDiscountDialog(
    List<String> productIds, {
    double? currentDiscount,
    ProductEntity? singleProduct,
  }) {
    if (productIds.isEmpty) return;

    double selectedDiscount = (currentDiscount ?? 0.0);
    double profitPercentage = 15.0;
    bool isLoadingSettings = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingSettings) {
            sl<ApiClient>().get('/settings').then((res) {
              if (res.data != null && res.data['data'] != null) {
                final p = (res.data['data']['profitPercentage'] as num?)?.toDouble() ?? 15.0;
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    profitPercentage = p;
                    isLoadingSettings = false;
                  });
                }
              } else {
                if (sheetCtx.mounted) {
                  setSheetState(() => isLoadingSettings = false);
                }
              }
            }).catchError((_) {
              if (sheetCtx.mounted) {
                setSheetState(() => isLoadingSettings = false);
              }
            });
          }

          void updateDiscountValue(double val) {
            final clamped = val.clamp(0.0, profitPercentage);
            setSheetState(() {
              selectedDiscount = clamped;
            });
          }

          final baseSampleCost = singleProduct != null && singleProduct.originalPrice > 0
              ? singleProduct.originalPrice
              : 10.0;
          final regularPrice = baseSampleCost * (1 + profitPercentage / 100);
          final netProfitPercent = (profitPercentage - selectedDiscount).clamp(0.0, double.infinity);
          final discountedPrice = baseSampleCost * (1 + netProfitPercent / 100);
          final profitRemaining = discountedPrice - baseSampleCost;
          final currency = singleProduct?.currency ?? '\$';

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 25,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تحديد نسبة الخصم والتخفيض',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  productIds.length == 1
                                      ? (singleProduct?.name ?? 'منتج واحد محدد')
                                      : 'تطبيق جماعي على ${productIds.length} منتجات محددة',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (isLoadingSettings)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFEF4444)),
                          ),
                        )
                      else ...[
                        // 1. Profit Margin Protection Badge (درع الأمان المالي)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.security_rounded, color: Color(0xFFFBBF24), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'نسبة أرباح النظام: ',
                                          style: TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                        Text(
                                          '+${profitPercentage.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Color(0xFF34D399),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'أقصى خصم: ${profitPercentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'تم تقييد الخصم تلقائياً ليكون أصغر أو يساوي نسبة الربح لضمان عدم البيع بخسارة.',
                                      style: TextStyle(color: Colors.white54, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Large Central Percentage Dial & Steppers
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFEF4444).withValues(alpha: 0.12),
                                const Color(0xFF0F172A),
                              ],
                              radius: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selectedDiscount > 0
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                  : Colors.white10,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Decrement button (-1%)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: selectedDiscount > 0
                                        ? () => updateDiscountValue(selectedDiscount - 1)
                                        : null,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: const Icon(Icons.remove_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),

                                  // Central Big Percentage Display
                                  Column(
                                    children: [
                                      Text(
                                        selectedDiscount > 0 ? '${selectedDiscount.toInt()}%' : '0%',
                                        style: TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w900,
                                          color: selectedDiscount > 0
                                              ? const Color(0xFFEF4444)
                                              : Colors.white54,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      Text(
                                        selectedDiscount > 0 ? 'خصم فعال على المنتج' : 'السعر الطبيعي بدون تخفيض',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: selectedDiscount > 0 ? const Color(0xFFFCA5A5) : Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Increment button (+1%)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: selectedDiscount < profitPercentage
                                        ? () => updateDiscountValue(selectedDiscount + 1)
                                        : null,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Interactive Slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFEF4444),
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: const Color(0xFFEF4444),
                                  overlayColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  trackHeight: 5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                                ),
                                child: Slider(
                                  value: selectedDiscount.clamp(0.0, profitPercentage),
                                  min: 0.0,
                                  max: profitPercentage > 0 ? profitPercentage : 1.0,
                                  divisions: profitPercentage > 0 ? profitPercentage.toInt() : 1,
                                  onChanged: (val) => updateDiscountValue(val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. Quick Presets
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDiscountPresetChip(
                                label: 'بدون خصم (0%)',
                                isSelected: selectedDiscount == 0,
                                color: const Color(0xFF64748B),
                                onTap: () => updateDiscountValue(0),
                              ),
                              const SizedBox(width: 6),
                              if (profitPercentage >= 5) ...[
                                _buildDiscountPresetChip(
                                  label: '5%',
                                  isSelected: selectedDiscount == 5,
                                  color: const Color(0xFFF59E0B),
                                  onTap: () => updateDiscountValue(5),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (profitPercentage >= 10) ...[
                                _buildDiscountPresetChip(
                                  label: '10%',
                                  isSelected: selectedDiscount == 10,
                                  color: const Color(0xFFEC4899),
                                  onTap: () => updateDiscountValue(10),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (profitPercentage >= 15) ...[
                                _buildDiscountPresetChip(
                                  label: '15%',
                                  isSelected: selectedDiscount == 15,
                                  color: const Color(0xFF8B5CF6),
                                  onTap: () => updateDiscountValue(15),
                                ),
                                const SizedBox(width: 6),
                              ],
                              _buildDiscountPresetChip(
                                label: 'أقصى خصم (${profitPercentage.toInt()}%) 🔥',
                                isSelected: selectedDiscount == profitPercentage,
                                color: const Color(0xFFEF4444),
                                onTap: () => updateDiscountValue(profitPercentage),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Financial Simulation Preview Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.analytics_outlined, size: 15, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      singleProduct != null
                                          ? 'المعاينة المالية لمنتج: ${singleProduct.name}'
                                          : 'محاكاة لمنتج بتكلفة 10.00 $currency من المزود:',
                                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('السعر قبل الخصم', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${regularPrice.toStringAsFixed(2)} $currency',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: selectedDiscount > 0 ? Colors.white38 : Colors.white,
                                          decoration: selectedDiscount > 0 ? TextDecoration.lineThrough : null,
                                          decorationColor: const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 26, color: Colors.white12),
                                  Column(
                                    children: [
                                      const Text('سعر الزبون النهائي', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${discountedPrice.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF34D399),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 26, color: Colors.white12),
                                  Column(
                                    children: [
                                      const Text('ربح المتجر الصافي', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                      const SizedBox(height: 2),
                                      Text(
                                        profitRemaining.abs() < 0.0001
                                            ? '0.00 $currency'
                                            : (profitRemaining > 0
                                                ? '+${profitRemaining.toStringAsFixed(2)} $currency'
                                                : '${profitRemaining.toStringAsFixed(2)} $currency'),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          color: profitRemaining >= -0.0001 ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 5. Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isSubmitting ? null : () => Navigator.pop(sheetCtx),
                                child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final bloc = context.read<AdminProductsBloc>();
                                        final nav = Navigator.of(sheetCtx);

                                        setSheetState(() => isSubmitting = true);
                                        try {
                                          await sl<ApiClient>().patch('/products/discount', data: {
                                            'productIds': productIds,
                                            'discountPercent': selectedDiscount,
                                          });

                                          if (mounted) {
                                            bloc.add(LoadAdminProductsEvent());
                                            setState(() {
                                              _selectedProductIds.clear();
                                            });
                                            nav.pop();
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  selectedDiscount > 0
                                                      ? 'تم تطبيق خصم ${selectedDiscount.toInt()}% على المنتجات بنجاح! 🏷️'
                                                      : 'تم إلغاء الخصم بنجاح',
                                                ),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setSheetState(() => isSubmitting = false);
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: const Text('حدث خطأ'),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            selectedDiscount > 0 ? 'حفظ وتطبيق الخصم 🏷️' : 'إزالة الخصم بالكامل',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFF0284C7);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.3) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CASCADING CATEGORY & SUBCATEGORY DIALOGS
// ==========================================

class _CategoryMoveDialogContent extends StatefulWidget {
  final ProductEntity product;
  final List<CategoryItemModel> categoryItems;
  final Future<List<Map<String, dynamic>>> Function(String) fetchSubCats;
  final VoidCallback onCreateMainCat;
  final void Function(String mainCat, String subName, String? subId, String? subImage) onDone;

  const _CategoryMoveDialogContent({
    required this.product,
    required this.categoryItems,
    required this.fetchSubCats,
    required this.onCreateMainCat,
    required this.onDone,
  });

  @override
  State<_CategoryMoveDialogContent> createState() => _CategoryMoveDialogContentState();
}

class _CategoryMoveDialogContentState extends State<_CategoryMoveDialogContent> {
  late String _selectedMainCat;
  late TextEditingController _subCatController;
  String? _selectedSubId;
  String? _selectedSubImage;
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoadingSubCats = true;

  final List<Map<String, dynamic>> _fallbackMainCats = const [
    {'key': 'games', 'title': '🎮 ألعاب', 'color': Color(0xFF0284C7)},
    {'key': 'apps', 'title': '💬 تطبيقات', 'color': Color(0xFF10B981)},
    {'key': 'social', 'title': '📱 سوشيال ميديا', 'color': Color(0xFFEC4899)},
    {'key': 'subscriptions', 'title': '🎬 اشتراكات', 'color': Color(0xFFFB7185)},
    {'key': 'numbers', 'title': '📞 أرقام وهمية', 'color': Color(0xFF38BDF8)},
    {'key': 'cards', 'title': '💳 بطاقات وقسائم', 'color': Color(0xFFF59E0B)},
    {'key': 'payment', 'title': '⚡ دفع إلكتروني', 'color': Color(0xFFA78BFA)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMainCat = widget.product.mainCategory.isNotEmpty ? widget.product.mainCategory : 'games';
    _subCatController = TextEditingController(text: widget.product.subCategoryName ?? widget.product.category);
    _selectedSubId = widget.product.subCategoryId;
    _selectedSubImage = widget.product.subCategoryImage;
    _loadSubCategories(_selectedMainCat);
  }

  @override
  void dispose() {
    _subCatController.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategories(String mainCat) async {
    setState(() => _isLoadingSubCats = true);
    final list = await widget.fetchSubCats(mainCat);
    if (mounted) {
      setState(() {
        _subCategories = list;
        _isLoadingSubCats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMainCats = widget.categoryItems.isNotEmpty
        ? widget.categoryItems.map((c) => {'key': c.key, 'title': c.title, 'color': c.displayColor}).toList()
        : _fallbackMainCats;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.drive_file_move_rounded, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نقل وتصنيف المنتج',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.product.name,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Body (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Path Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'المسار الحالي: ${widget.product.mainCategory} > ${widget.product.subCategoryName ?? widget.product.category}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Step 1: Main Category
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '1. اختر القسم الرئيسي الجديد 📂',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onCreateMainCat();
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF38BDF8)),
                              label: const Text('+ قسم جديد', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableMainCats.map((cat) {
                            final key = cat['key'] as String;
                            final title = cat['title'] as String;
                            final color = (cat['color'] as Color?) ?? const Color(0xFF0284C7);
                            final isSelected = _selectedMainCat == key;

                            return InkWell(
                              onTap: () {
                                if (_selectedMainCat != key) {
                                  setState(() {
                                    _selectedMainCat = key;
                                    _selectedSubId = null;
                                    _selectedSubImage = null;
                                  });
                                  _loadSubCategories(key);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.white12,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Step 2: Subcategory
                        const Text(
                          '2. اختر أو اكتب القسم الفرعي (الخدمة التابعة) 🏷️',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Subcategory Suggestions
                        if (_isLoadingSubCats)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                              ),
                            ),
                          )
                        else if (_subCategories.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Text(
                              'لا توجد أقسام فرعية مسجلة في هذا القسم حالياً. يمكنك كتابة اسم جديد بالأسفل وسيتم إنشاؤه تلقائياً!',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subCategories.map((sub) {
                              final name = (sub['name'] ?? sub['title'] ?? '').toString();
                              final id = sub['id']?.toString();
                              final img = sub['image']?.toString();
                              final isSelected = _subCatController.text.trim() == name;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _subCatController.text = name;
                                    _selectedSubId = id;
                                    _selectedSubImage = img;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (img != null && img.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: AppNetworkImage(
                                            img,
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 12),

                        // Subcategory text input
                        TextField(
                          controller: _subCatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'اسم القسم الفرعي',
                            hintText: 'اكتب اسم القسم الفرعي أو اختر من المقترحات أعلاه...',
                            labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            prefixIcon: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 20),
                            suffixIcon: _subCatController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                    onPressed: () => setState(() {
                                      _subCatController.clear();
                                      _selectedSubId = null;
                                      _selectedSubImage = null;
                                    }),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _subCatController.text.trim().isEmpty
                            ? null
                            : () {
                                final subName = _subCatController.text.trim();
                                Navigator.pop(context);
                                widget.onDone(
                                  _selectedMainCat,
                                  subName,
                                  _selectedSubId,
                                  _selectedSubImage,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('حفظ ونقل المنتج 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubCategoryOnlyDialogContent extends StatefulWidget {
  final ProductEntity product;
  final Future<List<Map<String, dynamic>>> Function(String) fetchSubCats;
  final void Function(String subName, String? subId, String? subImage) onDone;

  const _SubCategoryOnlyDialogContent({
    required this.product,
    required this.fetchSubCats,
    required this.onDone,
  });

  @override
  State<_SubCategoryOnlyDialogContent> createState() => _SubCategoryOnlyDialogContentState();
}

class _SubCategoryOnlyDialogContentState extends State<_SubCategoryOnlyDialogContent> {
  late TextEditingController _subCatController;
  String? _selectedSubId;
  String? _selectedSubImage;
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subCatController = TextEditingController(text: widget.product.subCategoryName ?? widget.product.category);
    _selectedSubId = widget.product.subCategoryId;
    _selectedSubImage = widget.product.subCategoryImage;
    _load();
  }

  @override
  void dispose() {
    _subCatController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await widget.fetchSubCats(widget.product.mainCategory);
    if (mounted) {
      setState(() {
        _subCategories = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تعديل القسم الفرعي للمنتج',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'القسم الرئيسي: ${widget.product.mainCategory}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختر من الأقسام الفرعية الحالية أو اكتب اسماً جديداً:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              ),
                            ),
                          )
                        else if (_subCategories.isEmpty)
                          const Text(
                            'لا توجد أقسام فرعية مقترحة حالياً.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subCategories.map((sub) {
                              final name = (sub['name'] ?? sub['title'] ?? '').toString();
                              final id = sub['id']?.toString();
                              final img = sub['image']?.toString();
                              final isSelected = _subCatController.text.trim() == name;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _subCatController.text = name;
                                    _selectedSubId = id;
                                    _selectedSubImage = img;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF10B981) : Colors.white12,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (img != null && img.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: AppNetworkImage(
                                            img,
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _subCatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'اسم القسم الفرعي',
                            hintText: 'اكتب اسم القسم الفرعي...',
                            labelStyle: const TextStyle(color: Color(0xFF10B981)),
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            prefixIcon: const Icon(Icons.folder_open_rounded, color: Color(0xFF10B981), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _subCatController.text.trim().isEmpty
                            ? null
                            : () {
                                final subName = _subCatController.text.trim();
                                Navigator.pop(context);
                                widget.onDone(
                                  subName,
                                  _selectedSubId,
                                  _selectedSubImage,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('حفظ القسم الفرعي 💾', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkMoveDialogContent extends StatefulWidget {
  final List<String> productIds;
  final List<CategoryItemModel> categoryItems;
  final Future<List<Map<String, dynamic>>> Function(String) fetchSubCats;
  final VoidCallback onCreateMainCat;
  final void Function(String mainCat, String subName, String? subId, String? subImage, String title) onDone;

  const _BulkMoveDialogContent({
    required this.productIds,
    required this.categoryItems,
    required this.fetchSubCats,
    required this.onCreateMainCat,
    required this.onDone,
  });

  @override
  State<_BulkMoveDialogContent> createState() => _BulkMoveDialogContentState();
}

class _BulkMoveDialogContentState extends State<_BulkMoveDialogContent> {
  late String _selectedMainCat;
  late TextEditingController _subCatController;
  String? _selectedSubId;
  String? _selectedSubImage;
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoadingSubCats = true;

  final List<Map<String, dynamic>> _fallbackMainCats = const [
    {'key': 'games', 'title': '🎮 ألعاب', 'color': Color(0xFF0284C7)},
    {'key': 'apps', 'title': '💬 تطبيقات', 'color': Color(0xFF10B981)},
    {'key': 'social', 'title': '📱 سوشيال ميديا', 'color': Color(0xFFEC4899)},
    {'key': 'subscriptions', 'title': '🎬 اشتراكات', 'color': Color(0xFFFB7185)},
    {'key': 'numbers', 'title': '📞 أرقام وهمية', 'color': Color(0xFF38BDF8)},
    {'key': 'cards', 'title': '💳 بطاقات وقسائم', 'color': Color(0xFFF59E0B)},
    {'key': 'payment', 'title': '⚡ دفع إلكتروني', 'color': Color(0xFFA78BFA)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMainCat = widget.categoryItems.isNotEmpty ? widget.categoryItems.first.key : 'games';
    _subCatController = TextEditingController();
    _loadSubCategories(_selectedMainCat);
  }

  @override
  void dispose() {
    _subCatController.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategories(String mainCat) async {
    setState(() => _isLoadingSubCats = true);
    final list = await widget.fetchSubCats(mainCat);
    if (mounted) {
      setState(() {
        _subCategories = list;
        _isLoadingSubCats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMainCats = widget.categoryItems.isNotEmpty
        ? widget.categoryItems.map((c) => {'key': c.key, 'title': c.title, 'color': c.displayColor}).toList()
        : _fallbackMainCats;

    final selectedCatObj = availableMainCats.firstWhere(
      (c) => c['key'] == _selectedMainCat,
      orElse: () => availableMainCats.first,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.drive_file_move_rounded, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نقل ${widget.productIds.length} عنصر محدد',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'اختر القسم الرئيسي والقسم الفرعي المستهدف للمجموعة',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '1. اختر القسم الرئيسي المستهدف 📂',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onCreateMainCat();
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF38BDF8)),
                              label: const Text('+ قسم جديد', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableMainCats.map((cat) {
                            final key = cat['key'] as String;
                            final title = cat['title'] as String;
                            final color = (cat['color'] as Color?) ?? const Color(0xFF0284C7);
                            final isSelected = _selectedMainCat == key;

                            return InkWell(
                              onTap: () {
                                if (_selectedMainCat != key) {
                                  setState(() {
                                    _selectedMainCat = key;
                                    _selectedSubId = null;
                                    _selectedSubImage = null;
                                  });
                                  _loadSubCategories(key);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.white12,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '2. القسم الفرعي المستهدف (اختياري/موصى به) 🏷️',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingSubCats)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                              ),
                            ),
                          )
                        else if (_subCategories.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subCategories.map((sub) {
                              final name = (sub['name'] ?? sub['title'] ?? '').toString();
                              final id = sub['id']?.toString();
                              final img = sub['image']?.toString();
                              final isSelected = _subCatController.text.trim() == name;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _subCatController.text = name;
                                    _selectedSubId = id;
                                    _selectedSubImage = img;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (img != null && img.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: AppNetworkImage(
                                            img,
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _subCatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'اسم القسم الفرعي (اتركه فارغاً للإبقاء على القسم الحالي لكل منتج)',
                            hintText: 'اكتب اسم القسم الفرعي الموحد...',
                            labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            prefixIcon: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 20),
                            suffixIcon: _subCatController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                    onPressed: () => setState(() {
                                      _subCatController.clear();
                                      _selectedSubId = null;
                                      _selectedSubImage = null;
                                    }),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final subName = _subCatController.text.trim();
                          final mainTitle = (selectedCatObj['title'] as String?) ?? _selectedMainCat;
                          Navigator.pop(context);
                          widget.onDone(
                            _selectedMainCat,
                            subName,
                            _selectedSubId,
                            _selectedSubImage,
                            mainTitle,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text('نقل ${widget.productIds.length} عنصر 🚀', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


