import 'package:games_admin/core/network/api_client.dart';
import 'package:games_admin/core/network/api_response.dart';
import 'package:games_admin/core/constants/api_constants.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionsRemoteDataSource {
  Future<List<TransactionModel>> getAllTransactions();
}

class TransactionsRemoteDataSourceImpl implements TransactionsRemoteDataSource {
  final ApiClient apiClient;

  TransactionsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final response = await apiClient.get('${ApiConstants.users}/transactions/all');
      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!;
      } else {
        throw ServerException(message: apiRes.message);
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
