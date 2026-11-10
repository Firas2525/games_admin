import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import 'package:games_admin/core/errors/failures.dart';
import 'package:games_admin/features/users/domain/entities/admin_user_entity.dart';
import 'package:games_admin/features/auth/domain/repositories/admin_auth_repository.dart';
import 'package:games_admin/features/auth/data/datasources/admin_auth_remote_data_source.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminAuthRemoteDataSource remoteDataSource;

  AdminAuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AdminUserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(email: email, password: password);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> checkAuth() async {
    try {
      final user = await remoteDataSource.checkAuth();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
