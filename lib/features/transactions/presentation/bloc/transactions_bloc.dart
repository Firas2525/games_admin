import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transactions_repository.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionsRepository repository;

  TransactionsBloc({required this.repository}) : super(TransactionsInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());
    final result = await repository.getAllTransactions();
    result.fold(
      (failure) => emit(TransactionsError(message: failure.message)),
      (transactions) => emit(TransactionsLoaded(transactions: transactions)),
    );
  }
}
