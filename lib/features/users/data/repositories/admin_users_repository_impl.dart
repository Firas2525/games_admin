import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../../domain/repositories/admin_users_repository.dart';
import '../datasources/admin_users_remote_data_source.dart';

class AdminUsersRepositoryImpl implements AdminUsersRepository {
  final AdminUsersRemoteDataSource remoteDataSource;

  AdminUsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AdminUserEntity>>> getUsers({String? search}) async {
    try {
      final users = await remoteDataSource.getUsers(search: search);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> depositBalance({
    required String userId,
    required double amount,
    String? note,
  }) async {
    try {
      final updatedUser = await remoteDataSource.depositBalance(
        userId: userId,
        amount: amount,
        note: note,
      );
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> deductBalance({
    required String userId,
    required double amount,
    String? note,
  }) async {
    try {
      final updatedUser = await remoteDataSource.deductBalance(
        userId: userId,
        amount: amount,
        note: note,
      );
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> toggleUserStatus(String userId) async {
    try {
      final updatedUser = await remoteDataSource.toggleUserStatus(userId);
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final updatedUser = await remoteDataSource.changePassword(
        userId: userId,
        newPassword: newPassword,
      );
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> updateUserLevel({
    required String userId,
    required String manualLevel,
  }) async {
    try {
      final updatedUser = await remoteDataSource.updateUserLevel(
        userId: userId,
        manualLevel: manualLevel,
      );
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> updateCustomProfit({
    required String userId,
    required double? customProfitPercentage,
  }) async {
    try {
      final updatedUser = await remoteDataSource.updateCustomProfit(
        userId: userId,
        customProfitPercentage: customProfitPercentage,
      );
      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

