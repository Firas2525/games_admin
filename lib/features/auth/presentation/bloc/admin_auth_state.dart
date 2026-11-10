import 'package:games_admin/features/users/domain/entities/admin_user_entity.dart';

abstract class AdminAuthState {}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthenticated extends AdminAuthState {
  final AdminUserEntity admin;
  AdminAuthenticated({required this.admin});
}

class AdminUnauthenticated extends AdminAuthState {}

class AdminAuthError extends AdminAuthState {
  final String message;
  AdminAuthError({required this.message});
}
