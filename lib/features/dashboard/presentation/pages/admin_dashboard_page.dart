import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_overview_page.dart';
import 'package:games_admin/features/users/presentation/pages/admin_users_page.dart';
import 'package:games_admin/features/products/presentation/pages/admin_products_page.dart';
import 'package:games_admin/features/orders/presentation/pages/admin_custom_orders_page.dart';
import 'package:games_admin/features/products/presentation/bloc/admin_products_bloc.dart';
import 'package:games_admin/features/products/presentation/bloc/admin_products_event.dart';
import 'package:games_admin/features/users/presentation/bloc/admin_users_bloc.dart';
import 'package:games_admin/features/users/presentation/bloc/admin_users_event.dart';
import '../../../../core/services/fcm_notification_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FcmNotificationService.subscribeToAdminTopics();
  }

  void _onNavigateTab(int index) {
    if (index < 0 || index >= 4) return;
    setState(() => _currentIndex = index);
    if (index == 0) {
      context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
      context.read<AdminUsersBloc>().add(LoadUsersEvent());
    } else if (index == 1) {
      context.read<AdminProductsBloc>().add(LoadAdminProductsEvent());
    } else if (index == 2) {
      // Custom orders tab
    } else if (index == 3) {
      context.read<AdminUsersBloc>().add(LoadUsersEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminOverviewPage(onNavigateTab: _onNavigateTab),
      const AdminProductsPage(),
      const AdminCustomOrdersPage(),
      const AdminUsersPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111F),
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF07111F),
            border: Border(
              top: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.25), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: const Color(0xFF07111F),
            elevation: 0,
            height: 65,
            indicatorColor: const Color(0xFF0284C7).withValues(alpha: 0.22),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _onNavigateTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, color: Colors.white60, size: 20),
                selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF38BDF8), size: 22),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined, color: Colors.white60, size: 20),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF38BDF8), size: 22),
                label: 'المستودع',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined, color: Colors.white60, size: 20),
                selectedIcon: Icon(Icons.assignment_rounded, color: Color(0xFF38BDF8), size: 22),
                label: 'طلباتي',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded, color: Colors.white60, size: 20),
                selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF38BDF8), size: 22),
                label: 'المستخدمين',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
