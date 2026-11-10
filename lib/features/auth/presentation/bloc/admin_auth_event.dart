abstract class AdminAuthEvent {}

class AdminLoginSubmitted extends AdminAuthEvent {
  final String email;
  final String password;
  AdminLoginSubmitted({required this.email, required this.password});
}

class CheckAdminAuthStatus extends AdminAuthEvent {}

class AdminLogoutRequested extends AdminAuthEvent {}
