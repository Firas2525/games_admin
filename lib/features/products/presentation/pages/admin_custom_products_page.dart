import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/admin_product_artwork.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/admin_products_bloc.dart';
import '../bloc/admin_products_event.dart';
import '../bloc/admin_products_state.dart';
import 'admin_add_custom_product_page.dart';

class AdminCustomProductsPage extends StatefulWidget {
  const AdminCustomProductsPage({super.key});

  @override
  State<AdminCustomProductsPage> createState() => _AdminCustomProductsPageState();
}

class _AdminCustomProductsPageState extends State<AdminCustomProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildInitialData(ProductEntity product) {
    return {
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
  }

  Future<void> _deleteCustomProduct(ProductEntity product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'حذف المنتج نهائياً؟',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف "${product.name}" نهائياً من مزودك الخاص؟ سيختفي المنتج فوراً من متجر المستخدمين.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text('نعم، احذف المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _deletingIds.add(product.id));
      try {
        await sl<ApiClient>().delete('/products/custom/${product.id}');
        if (mounted) {
          context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف المنتج "${product.name}" بنجاح 🗑️'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف المنتج: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _deletingIds.remove(product.id));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF080C16),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07111F),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'منتجات مزودي الخاص',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 20),
              ),
              tooltip: 'إضافة منتج جديد لمزودي الخاص',
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAddCustomProductPage()),
                );
                if (res == true && mounted) {
                  context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                }
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              ),
              tooltip: 'تحديث المنتجات',
              onPressed: () {
                context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<AdminProductsBloc, AdminProductsState>(
          builder: (context, state) {
            if (state is AdminProductsLoading && state is! AdminProductsLoaded) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              );
            }

            List<ProductEntity> allProducts = [];
            if (state is AdminProductsLoaded) {
              allProducts = state.products;
            } else if (state is AdminProductsSyncing) {
              allProducts = state.currentProducts;
            }

            // Filter for custom provider products only
            final customProducts = allProducts.where((p) => p.source == 'custom').toList();

            // Apply search query
            final query = _searchQuery.trim().toLowerCase();
            final filteredList = query.isEmpty
                ? customProducts
                : customProducts.where((p) {
                    final name = p.name.toLowerCase();
                    final cat = p.category.toLowerCase();
                    final extId = p.externalId.toLowerCase();
                    return name.contains(query) || cat.contains(query) || extId.contains(query);
                  }).toList();

            return Column(
              children: [
                // Search Bar & Stats Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'البحث في منتجات مزودي الخاص...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 10),
                      // Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded, color: Color(0xFF38BDF8), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'إجمالي منتجات مزودي: ${customProducts.length}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminAddCustomProductPage()),
                              );
                              if (res == true && mounted) {
                                context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                            label: const Text('إضافة منتج', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white38),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'لا توجد منتجات تطابق البحث'
                                    : 'لا توجد أي منتجات في مزودك الخاص بعد',
                                style: const TextStyle(fontSize: 14, color: Colors.white60, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              if (_searchQuery.isEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AdminAddCustomProductPage()),
                                    );
                                    if (res == true && mounted) {
                                      context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                                    }
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('إضافة أول منتج لمزودي الخاص'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF38BDF8),
                          backgroundColor: const Color(0xFF0F172A),
                          onRefresh: () async {
                            context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final product = filteredList[index];
                              final isDeleting = _deletingIds.contains(product.id);

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Artwork
                                    AdminProductArtworkWidget(
                                      imageUrl: product.image,
                                      title: product.name,
                                      category: product.category,
                                      mainCategory: product.mainCategory,
                                      source: product.source,
                                      width: 52,
                                      height: 52,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(width: 12),

                                    // Product Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  product.category,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF38BDF8),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'التكلفة: ${product.originalPrice > 0 ? product.originalPrice.toStringAsFixed(product.originalPrice < 0.01 ? 4 : 2) : '0'} ${product.currency}',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.amber.shade300,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'البيع: ${(product.sellingPrice ?? product.originalPrice).toStringAsFixed(2)} ${product.currency}',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Actions
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit Button
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          icon: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B), size: 18),
                                          tooltip: 'تعديل المنتج',
                                          onPressed: isDeleting
                                              ? null
                                              : () async {
                                                  final res = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AdminAddCustomProductPage(
                                                        initialProduct: _buildInitialData(product),
                                                      ),
                                                    ),
                                                  );
                                                  if (res == true && mounted) {
                                                    context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
                                                  }
                                                },
                                        ),
                                        const SizedBox(width: 6),

                                        // Delete Button
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          icon: isDeleting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                                                )
                                              : const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 18),
                                          tooltip: 'حذف المنتج نهائياً',
                                          onPressed: isDeleting ? null : () => _deleteCustomProduct(product),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

