import 'package:dartz/dartz.dart';
import 'package:games_admin/core/errors/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionsRepository {
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions();
}
