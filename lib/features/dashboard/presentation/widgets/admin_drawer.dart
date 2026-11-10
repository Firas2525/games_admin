import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_ticker_dialog.dart';
import 'admin_banners_dialog.dart';
import 'admin_notifications_dialog.dart';
import 'admin_support_links_dialog.dart';
import '../pages/admin_logs_page.dart';
import '../pages/admin_notifications_page.dart';
import '../pages/admin_exchange_and_profit_page.dart';
import '../pages/admin_profit_reports_page.dart';
import 'package:games_admin/features/orders/presentation/pages/admin_all_orders_page.dart';
import 'package:games_admin/features/deposits/presentation/pages/admin_deposits_page.dart';
import 'package:games_admin/features/deposits/presentation/pages/admin_deposit_methods_page.dart';
import 'package:games_admin/features/salary_withdrawals/presentation/pages/admin_salary_withdrawals_page.dart';
import 'package:games_admin/features/verification/presentation/pages/admin_verification_requests_page.dart';
import 'package:games_admin/features/users/presentation/pages/admin_levels_page.dart';
import 'package:games_admin/features/competitions/presentation/pages/admin_competitions_page.dart';
import 'package:games_admin/features/categories/presentation/pages/admin_categories_page.dart';
import 'package:games_admin/features/categories/presentation/pages/admin_organization_page.dart';
import 'package:games_admin/features/maintenance/presentation/pages/admin_maintenance_page.dart';
import 'package:games_admin/features/products/presentation/pages/admin_custom_products_page.dart';
import 'package:games_admin/features/auth/presentation/bloc/admin_auth_bloc.dart';
import 'package:games_admin/features/auth/presentation/bloc/admin_auth_event.dart';

class AdminDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int index)? onNavigateTab;

  const AdminDrawer({super.key, this.currentIndex = 0, this.onNavigateTab});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من لوحة التحكم؟',
            style: TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AdminAuthBloc>().add(AdminLogoutRequested());
              },
              child: const Text(
                'تأكيد الخروج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: const Color(0xFF0B1322),
        elevation: 16,
        child: Column(
          children: [
            // Header
            _buildDrawerHeader(context),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'الأقسام الرئيسية',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'الرئيسية والعمليات',
                    tabIndex: 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    title: 'المستودع وإدارة المنتجات',
                    tabIndex: 1,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.assignment_rounded,
                    title: 'طلبات الشحن (مزودي الخاص)',
                    tabIndex: 2,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.people_rounded,
                    title: 'إدارة المستخدمين والأرصدة',
                    tabIndex: 3,
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 4),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'أدوات التحكم والإدارة',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Custom Provider Products (منتجات مزودي الخاص)
                  _buildActionItem(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'منتجات مزودي الخاص (إدارة وحذف)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCustomProductsPage(),
                        ),
                      );
                    },
                  ),

                  // Maintenance Mode (وضع الصيانة)
                  _buildActionItem(
                    icon: Icons.construction_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'وضع الصيانة',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminMaintenancePage(),
                        ),
                      );
                    },
                  ),

                  // All Orders (سجل كافة الطلبات)
                  _buildActionItem(
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'سجل كافة الطلبات (All Orders)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAllOrdersPage(),
                        ),
                      );
                    },
                  ),

                  // Profit & Financial Reports
                  _buildActionItem(
                    icon: Icons.query_stats_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'تقارير الأرباح والمبيعات',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProfitReportsPage(),
                        ),
                      );
                    },
                  ),

                  // Exchange Rate & Profit Margin
                  _buildActionItem(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'الصرف ونسبة الربح',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminExchangeAndProfitPage(),
                        ),
                      );
                    },
                  ),

                  // Deposit Requests
                  _buildActionItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'طلبات الإيداع المعلقة',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDepositsPage(),
                        ),
                      );
                    },
                  ),

                  // Deposit Payment Methods
                  _buildActionItem(
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF34D399),
                    title: 'طرق الإيداع والتحويل',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDepositMethodsPage(),
                        ),
                      );
                    },
                  ),

                  // Salary Withdrawals Management
                  _buildActionItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'سحب رواتب',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSalaryWithdrawalsPage(),
                        ),
                      );
                    },
                  ),

                  // Verification Requests (طلبات توثيق الحسابات)
                  _buildActionItem(
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'طلبات توثيق الحسابات',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminVerificationRequestsPage(),
                        ),
                      );
                    },
                  ),

                  // Account Levels & Badges (مستويات الحساب والشارات)
                  _buildActionItem(
                    icon: Icons.military_tech_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'مستويات الحساب والشارات',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLevelsPage(),
                        ),
                      );
                    },
                  ),

                  // Competitions & Top Buyers (المسابقات وقائمة الأكثر شراءً)
                  _buildActionItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'المسابقات وقائمة الأكثر شراءً',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCompetitionsPage(),
                        ),
                      );
                    },
                  ),

                  // Organization Page (Android style folder organizer)
                  _buildActionItem(
                    icon: Icons.folder_special_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'صفحة التنسيق (تنظيم المجلدات)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminOrganizationPage(),
                        ),
                      );
                    },
                  ),

                  // Categories Management
                  _buildActionItem(
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFF818CF8),
                    title: 'إدارة الأقسام',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCategoriesPage(),
                        ),
                      );
                    },
                  ),

                  // Promotional Banners (Home)
                  _buildActionItem(
                    icon: Icons.view_carousel_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'إدارة البنرات الإعلانية',
                    onTap: () {
                      Navigator.pop(context);
                      AdminBannersDialog.show(
                        context,
                        initialPlacement: 'home',
                      );
                    },
                  ),

                  // Category Sub-Banners
                  _buildActionItem(
                    icon: Icons.collections_bookmark_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    title: 'إدارة الإعلانات الفرعية للأقسام',
                    onTap: () {
                      Navigator.pop(context);
                      AdminBannersDialog.show(
                        context,
                        initialPlacement: 'category',
                      );
                    },
                  ),

                  // Ticker Banner Dialog
                  _buildActionItem(
                    icon: Icons.campaign_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'شريط الإعلانات المتحرك',
                    onTap: () {
                      Navigator.pop(context);
                      AdminTickerDialog.show(context);
                    },
                  ),

                  // Support & Social Links (واتساب وتيليغرام)
                  _buildActionItem(
                    icon: Icons.headset_mic_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'روابط الدعم والتواصل',
                    onTap: () {
                      Navigator.pop(context);
                      AdminSupportLinksDialog.show(context);
                    },
                  ),

                  // Push Notifications
                  _buildActionItem(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFA855F7),
                    title: 'إرسال إشعار للمستخدمين',
                    onTap: () {
                      Navigator.pop(context);
                      AdminNotificationsDialog.show(context);
                    },
                  ),

                  // Notifications History Page
                  _buildActionItem(
                    icon: Icons.mark_email_read_rounded,
                    iconColor: const Color(0xFFC084FC),
                    title: 'سجل الإشعارات المرسلة',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminNotificationsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout & Footer
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Games Admin • v1.0.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0B1322)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة التحكم المركزية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'المدير العام للمتجر',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                SizedBox(width: 6),
                Text(
                  'المنظومة متصلة أونلاين',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int tabIndex,
  }) {
    final isSelected = currentIndex == tabIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? const Color(0xFF0284C7).withValues(alpha: 0.15)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isSelected
              ? BorderSide(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                )
              : BorderSide.none,
        ),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            icon,
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (onNavigateTab != null) {
              onNavigateTab!(tabIndex);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white24,
          size: 12,
        ),
        onTap: onTap,
      ),
    );
  }
}
