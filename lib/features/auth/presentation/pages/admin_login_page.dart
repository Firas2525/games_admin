import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:games_admin/features/auth/presentation/bloc/admin_auth_bloc.dart';
import 'package:games_admin/features/auth/presentation/bloc/admin_auth_event.dart';
import 'package:games_admin/features/auth/presentation/bloc/admin_auth_state.dart';
import 'package:games_admin/features/dashboard/presentation/pages/admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin_firas_live@example.com');
  final _passwordController = TextEditingController(text: 'AdminPassword123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdminAuthBloc>().add(
            AdminLoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111F),
        body: BlocConsumer<AdminAuthBloc, AdminAuthState>(
          listener: (context, state) {
            if (state is AdminAuthenticated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
              );
            } else if (state is AdminAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFF43F5E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AdminAuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Executive Logo
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'بوابة الإدارة المركزية',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'سجل الدخول بصلاحيات المسؤول لإدارة المتجر والعمليات',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 28),

                            // Email input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'بريد المسؤول (Admin Email)',
                                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8)),
                                filled: true,
                                fillColor: const Color(0xFF131D31),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال البريد الإلكتروني';
                                }
                                if (!value.contains('@')) {
                                  return 'صيغة البريد الإلكتروني غير صحيحة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور السرية',
                                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF38BDF8)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFF131D31),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                                shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
                              ),
                              onPressed: isLoading ? null : _onLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'دخول لوحة التحكم',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
