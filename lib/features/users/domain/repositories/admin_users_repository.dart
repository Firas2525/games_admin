import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_user_entity.dart';

abstract class AdminUsersRepository {
  Future<Either<Failure, List<AdminUserEntity>>> getUsers({String? search});
  Future<Either<Failure, AdminUserEntity>> depositBalance({
    required String userId,
    required double amount,
    String? note,
  });
  Future<Either<Failure, AdminUserEntity>> deductBalance({
    required String userId,
    required double amount,
    String? note,
  });
  Future<Either<Failure, AdminUserEntity>> toggleUserStatus(String userId);
  Future<Either<Failure, AdminUserEntity>> changePassword({
    required String userId,
    required String newPassword,
  });
  Future<Either<Failure, AdminUserEntity>> updateUserLevel({
    required String userId,
    required String manualLevel,
  });
  Future<Either<Failure, AdminUserEntity>> updateCustomProfit({
    required String userId,
    required double? customProfitPercentage,
  });
}
