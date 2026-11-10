import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio dio;
  final SharedPreferences sharedPreferences;

  ApiClient({required this.sharedPreferences}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = sharedPreferences.getString('admin_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Console log for debugging
          // ignore: avoid_print
          print('🌐 [API REQ] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ [API RES ${response.statusCode}] ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          String message = 'حدث خطأ';
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          if (responseData is Map && responseData['message'] != null) {
            final raw = responseData['message'].toString().trim();
            final lower = raw.toLowerCase();
            if (raw.isNotEmpty &&
                !lower.contains('timeout') &&
                !lower.contains('connection') &&
                !lower.contains('dioexception') &&
                !lower.contains('socket') &&
                !lower.contains('error:') &&
                !lower.contains('failed host lookup') &&
                !lower.contains('message:') &&
                !raw.contains('مهلة')) {
              message = raw;
            } else {
              message = 'حدث خطأ';
            }
          } else {
            message = 'حدث خطأ';
          }

          // Full debug print in console
          // ignore: avoid_print
          print('❌ [API ERROR $statusCode] ${error.requestOptions.uri}');
          // ignore: avoid_print
          print('   Message: $message');
          if (responseData != null) {
            // ignore: avoid_print
            print('   Response Data: $responseData');
          }

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ServerException(
                message: message,
                statusCode: statusCode,
              ),
              message: message,
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  Never _handleDioError(DioException e) {
    if (e.error is ServerException) {
      throw e.error as ServerException;
    }
    throw ServerException(
      message: e.message ?? 'حدث خطأ في الاتصال بالخادم',
      statusCode: e.response?.statusCode,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.put(path, data: data, options: options);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.patch(path, data: data, options: options);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.delete(path, data: data, options: options);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }
}
