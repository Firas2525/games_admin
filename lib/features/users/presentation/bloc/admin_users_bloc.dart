import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_users_repository.dart';
import '../../domain/entities/admin_user_entity.dart';
import 'admin_users_event.dart';
import 'admin_users_state.dart';

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final AdminUsersRepository repository;

  AdminUsersBloc({required this.repository}) : super(AdminUsersInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<DepositUserBalanceEvent>(_onDepositBalance);
    on<DeductUserBalanceEvent>(_onDeductBalance);
    on<ToggleUserStatusEvent>(_onToggleStatus);
    on<ChangeUserPasswordEvent>(_onChangeUserPassword);
    on<UpdateUserLevelEvent>(_onUpdateUserLevel);
    on<UpdateUserCustomProfitEvent>(_onUpdateUserCustomProfit);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(AdminUsersLoading());
    final result = await repository.getUsers(search: event.search);
    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message)),
      (users) => emit(AdminUsersLoaded(users: users)),
    );
  }

  Future<void> _onDepositBalance(
    DepositUserBalanceEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.depositBalance(
      userId: event.userId,
      amount: event.amount,
      note: event.note,
    );

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: 'تم شحن رصيد بقيمة \$${event.amount.toStringAsFixed(2)} بنجاح',
        ));
      },
    );
  }

  Future<void> _onDeductBalance(
    DeductUserBalanceEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.deductBalance(
      userId: event.userId,
      amount: event.amount,
      note: event.note,
    );

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: 'تم خصم رصيد بقيمة \$${event.amount.toStringAsFixed(2)} بنجاح',
        ));
      },
    );
  }

  Future<void> _onToggleStatus(
    ToggleUserStatusEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.toggleUserStatus(event.userId);

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: 'تم تحديث حالة المستخدم بنجاح',
        ));
      },
    );
  }

  Future<void> _onChangeUserPassword(
    ChangeUserPasswordEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.changePassword(
      userId: event.userId,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: 'تم تغيير كلمة مرور المستخدم بنجاح',
        ));
      },
    );
  }

  Future<void> _onUpdateUserLevel(
    UpdateUserLevelEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.updateUserLevel(
      userId: event.userId,
      manualLevel: event.manualLevel,
    );

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: 'تم تحديث مستوى المستخدم بنجاح',
        ));
      },
    );
  }

  Future<void> _onUpdateUserCustomProfit(
    UpdateUserCustomProfitEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentUsers = _getCurrentUsers();
    emit(AdminUsersActionLoading(users: currentUsers, updatingUserId: event.userId));

    final result = await repository.updateCustomProfit(
      userId: event.userId,
      customProfitPercentage: event.customProfitPercentage,
    );

    result.fold(
      (failure) => emit(AdminUsersError(message: failure.message, currentUsers: currentUsers)),
      (updatedUser) {
        final updatedList = currentUsers.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        final msg = event.customProfitPercentage != null
            ? 'تم تعيين نسبة ربح مخصصة (${event.customProfitPercentage}%) للمستخدم بنجاح ✅'
            : 'تم إعادة نسبة ربح المستخدم إلى النسبة الافتراضية للنظام بنجاح ✅';
        emit(AdminUsersLoaded(
          users: updatedList,
          successMessage: msg,
        ));
      },
    );
  }


  List<AdminUserEntity> _getCurrentUsers() {
    if (state is AdminUsersLoaded) {
      return (state as AdminUsersLoaded).users;
    } else if (state is AdminUsersActionLoading) {
      return (state as AdminUsersActionLoading).users;
    } else if (state is AdminUsersError && (state as AdminUsersError).currentUsers != null) {
      return (state as AdminUsersError).currentUsers!;
    }
    return [];
  }
}
