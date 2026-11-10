import 'package:shared_preferences/shared_preferences.dart';
import 'package:games_admin/core/constants/api_constants.dart';
import 'package:games_admin/core/network/api_client.dart';
import 'package:games_admin/core/network/api_response.dart';
import 'package:games_admin/core/errors/exceptions.dart';
import 'package:games_admin/features/users/data/models/admin_user_model.dart';

abstract class AdminAuthRemoteDataSource {
  Future<AdminUserModel> login({required String email, required String password});
  Future<AdminUserModel> checkAuth();
  Future<void> logout();
}

class AdminAuthRemoteDataSourceImpl implements AdminAuthRemoteDataSource {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  AdminAuthRemoteDataSourceImpl({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<AdminUserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.adminLogin,
        data: {'email': email, 'password': password},
      );

      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiRes.success && apiRes.data != null) {
        final token = apiRes.data!['token'] as String;
        final user = AdminUserModel.fromJson(apiRes.data!['user'] as Map<String, dynamic>);
        await sharedPreferences.setString('admin_token', token);
        return user;
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
  Future<AdminUserModel> checkAuth() async {
    try {
      final token = sharedPreferences.getString('admin_token');
      if (token == null || token.isEmpty) {
        throw ServerException(message: 'No active admin session');
      }

      final response = await apiClient.get(ApiConstants.me);
      final apiRes = ApiResponse.fromJson(
        response.data,
        (data) => AdminUserModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        if (apiRes.data!.role != 'admin') {
          await logout();
          throw ServerException(message: 'Forbidden: Admin access only');
        }
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
  Future<void> logout() async {
    await sharedPreferences.remove('admin_token');
  }
}
