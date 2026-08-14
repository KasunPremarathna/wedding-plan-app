class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  AppException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({super.message = 'Network error. Please check your connection.'})
      : super(code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException({required super.message, super.statusCode})
      : super(code: 'SERVER_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException({super.message = 'Resource not found.'})
      : super(statusCode: 404, code: 'NOT_FOUND');
}

sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final AppException exception;
  const ApiFailure(this.exception);
}
