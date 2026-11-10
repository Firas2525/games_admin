import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/admin_user_model.dart';

abstract class AdminUsersRemoteDataSource {
  Future<List<AdminUserModel>> getUsers({String? search});
  Future<AdminUserModel> depositBalance({
    required String userId,
    required double amount,
    String? note,
  });
  Future<AdminUserModel> deductBalance({
    required String userId,
    required double amount,
    String? note,
  });
  Future<AdminUserModel> toggleUserStatus(String userId);
  Future<AdminUserModel> changePassword({
    required String userId,
    required String newPassword,
  });
  Future<AdminUserModel> updateUserLevel({
    required String userId,
    required String manualLevel,
  });
  Future<AdminUserModel> updateCustomProfit({
    required String userId,
    required double? customProfitPercentage,
  });
}

class AdminUsersRemoteDataSourceImpl implements AdminUsersRemoteDataSource {
  final ApiClient apiClient;

  AdminUsersRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AdminUserModel>> getUsers({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await apiClient.get(
        ApiConstants.users,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => AdminUserModel.fromJson(item as Map<String, dynamic>))
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

  @override
  Future<AdminUserModel> depositBalance({
    required String userId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.users}/$userId/balance/deposit',
        data: {'amount': amount, 'note': note},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(
          (data as Map<String, dynamic>)['user'] as Map<String, dynamic>,
        ),
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

  @override
  Future<AdminUserModel> deductBalance({
    required String userId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.users}/$userId/balance/deduct',
        data: {'amount': amount, 'note': note},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(
          (data as Map<String, dynamic>)['user'] as Map<String, dynamic>,
        ),
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

  @override
  Future<AdminUserModel> toggleUserStatus(String userId) async {
    try {
      final response = await apiClient.patch(
        '${ApiConstants.users}/$userId/toggle-status',
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(data as Map<String, dynamic>),
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

  @override
  Future<AdminUserModel> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.patch(
        '${ApiConstants.users}/$userId/password',
        data: {'password': newPassword},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(data as Map<String, dynamic>),
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

  @override
  Future<AdminUserModel> updateUserLevel({
    required String userId,
    required String manualLevel,
  }) async {
    try {
      final response = await apiClient.patch(
        '${ApiConstants.users}/$userId/level',
        data: {'manualLevel': manualLevel},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(data as Map<String, dynamic>),
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

  @override
  Future<AdminUserModel> updateCustomProfit({
    required String userId,
    required double? customProfitPercentage,
  }) async {
    try {
      final response = await apiClient.patch(
        '${ApiConstants.users}/$userId/custom-profit',
        data: {'customProfitPercentage': customProfitPercentage},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(data as Map<String, dynamic>),
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

