abstract class AdminUsersEvent {}

class LoadUsersEvent extends AdminUsersEvent {
  final String? search;
  LoadUsersEvent({this.search});
}

class DepositUserBalanceEvent extends AdminUsersEvent {
  final String userId;
  final double amount;
  final String? note;

  DepositUserBalanceEvent({
    required this.userId,
    required this.amount,
    this.note,
  });
}

class DeductUserBalanceEvent extends AdminUsersEvent {
  final String userId;
  final double amount;
  final String? note;

  DeductUserBalanceEvent({
    required this.userId,
    required this.amount,
    this.note,
  });
}

class ToggleUserStatusEvent extends AdminUsersEvent {
  final String userId;
  ToggleUserStatusEvent({required this.userId});
}

class ChangeUserPasswordEvent extends AdminUsersEvent {
  final String userId;
  final String newPassword;

  ChangeUserPasswordEvent({
    required this.userId,
    required this.newPassword,
  });
}

class UpdateUserLevelEvent extends AdminUsersEvent {
  final String userId;
  final String manualLevel;

  UpdateUserLevelEvent({
    required this.userId,
    required this.manualLevel,
  });
}

class UpdateUserCustomProfitEvent extends AdminUsersEvent {
  final String userId;
  final double? customProfitPercentage;

  UpdateUserCustomProfitEvent({
    required this.userId,
    required this.customProfitPercentage,
  });
}

