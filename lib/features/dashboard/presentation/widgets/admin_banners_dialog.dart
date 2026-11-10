import 'package:flutter/material.dart';
import 'admin_banners_section.dart';

class AdminBannersDialog extends StatelessWidget {
  final String initialPlacement;
  final String initialCategoryKey;

  const AdminBannersDialog({
    super.key,
    this.initialPlacement = 'home',
    this.initialCategoryKey = '',
  });

  static Future<void> show(
    BuildContext context, {
    String initialPlacement = 'home',
    String initialCategoryKey = '',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminBannersDialog(
        initialPlacement: initialPlacement,
        initialCategoryKey: initialCategoryKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 580.0 : screenWidth * 0.95;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          initialPlacement == 'category'
                              ? Icons.collections_bookmark_rounded
                              : Icons.campaign_rounded,
                          color: const Color(0xFF38BDF8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          initialPlacement == 'category'
                              ? 'إدارة إعلانات الأقسام الفرعية'
                              : 'إعلانات وبنرات المتجر',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminBannersSection(
                  initialPlacement: initialPlacement,
                  initialCategoryKey: initialCategoryKey,
                  showPlacementTabs: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
