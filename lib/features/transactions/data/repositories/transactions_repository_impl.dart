import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import 'package:games_admin/core/errors/failures.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_remote_data_source.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsRemoteDataSource remoteDataSource;

  TransactionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions() async {
    try {
      final transactions = await remoteDataSource.getAllTransactions();
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
