import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/service_locator.dart';
import 'features/auth/presentation/bloc/admin_auth_bloc.dart';
import 'features/auth/presentation/bloc/admin_auth_event.dart';
import 'features/auth/presentation/bloc/admin_auth_state.dart';
import 'features/auth/presentation/pages/admin_login_page.dart';
import 'features/users/presentation/bloc/admin_users_bloc.dart';
import 'features/products/presentation/bloc/admin_products_bloc.dart';
import 'features/transactions/presentation/bloc/transactions_bloc.dart';
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/special_loading_widget.dart';
import 'core/services/fcm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmNotificationService.initialize();
  await initAdminDependencies();
  runApp(const GamesAdminApp());
}

class GamesAdminApp extends StatelessWidget {
  const GamesAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminAuthBloc>(
          create: (_) => sl<AdminAuthBloc>()..add(CheckAdminAuthStatus()),
        ),
        BlocProvider<AdminUsersBloc>(create: (_) => sl<AdminUsersBloc>()),
        BlocProvider<TransactionsBloc>(create: (_) => sl<TransactionsBloc>()),
        BlocProvider<AdminProductsBloc>(create: (_) => sl<AdminProductsBloc>()),
      ],
      child: MaterialApp(
        title: 'Gold SM Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AdminAuthWrapper(),
      ),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) { 
    return BlocBuilder<AdminAuthBloc, AdminAuthState>(
      builder: (context, state) {
        if (state is AdminAuthenticated) {
          return const AdminDashboardPage();
        } else if (state is AdminAuthInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF07111F),
            body: Center(
              child: GlowGamingLoader(
                message: 'جاري التحقق من صلاحيات المدير...',
                subtitle: 'يتم تجهيز لوحة التحكم المركزية للمتجر',
                size: 88,
              ),
            ),
          );
        }
        return const AdminLoginPage();
      },
    );
  }
}
