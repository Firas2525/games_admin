import '../../domain/entities/admin_user_entity.dart';

abstract class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUserEntity> users;
  final String? successMessage;

  AdminUsersLoaded({
    required this.users,
    this.successMessage,
  });

  AdminUsersLoaded copyWith({
    List<AdminUserEntity>? users,
    String? successMessage,
  }) {
    return AdminUsersLoaded(
      users: users ?? this.users,
      successMessage: successMessage,
    );
  }
}

class AdminUsersActionLoading extends AdminUsersState {
  final List<AdminUserEntity> users;
  final String? updatingUserId;
  AdminUsersActionLoading({
    required this.users,
    this.updatingUserId,
  });
}

class AdminUsersError extends AdminUsersState {
  final String message;
  final List<AdminUserEntity>? currentUsers;

  AdminUsersError({
    required this.message,
    this.currentUsers,
  });
}
