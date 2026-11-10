import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/failures.dart';
import 'package:games_admin/features/users/domain/entities/admin_user_entity.dart';

abstract class AdminAuthRepository {
  Future<Either<Failure, AdminUserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AdminUserEntity>> checkAuth();

  Future<Either<Failure, void>> logout();
}
