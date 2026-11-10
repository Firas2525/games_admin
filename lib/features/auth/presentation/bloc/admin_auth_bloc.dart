import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:games_admin/features/auth/domain/repositories/admin_auth_repository.dart';
import 'admin_auth_event.dart';
import 'admin_auth_state.dart';

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminAuthRepository authRepository;

  AdminAuthBloc({required this.authRepository}) : super(AdminAuthInitial()) {
    on<AdminLoginSubmitted>(_onLoginSubmitted);
    on<CheckAdminAuthStatus>(_onCheckAuthStatus);
    on<AdminLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    AdminLoginSubmitted event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(AdminAuthLoading());
    final result = await authRepository.login(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AdminAuthError(message: failure.message)),
      (admin) => emit(AdminAuthenticated(admin: admin)),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAdminAuthStatus event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(AdminAuthLoading());
    final result = await authRepository.checkAuth();
    result.fold(
      (_) => emit(AdminUnauthenticated()),
      (admin) => emit(AdminAuthenticated(admin: admin)),
    );
  }

  Future<void> _onLogoutRequested(
    AdminLogoutRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    await authRepository.logout();
    emit(AdminUnauthenticated());
  }
}
