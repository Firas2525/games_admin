import '../../domain/entities/transaction_entity.dart';

abstract class TransactionsState {}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<TransactionEntity> transactions;
  TransactionsLoaded({required this.transactions});
}

class TransactionsError extends TransactionsState {
  final String message;
  TransactionsError({required this.message});
}
