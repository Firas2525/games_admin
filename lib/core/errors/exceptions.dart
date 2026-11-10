class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'No Internet connection'});

  @override
  String toString() => message;
}
