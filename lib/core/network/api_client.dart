import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.1.0',
        'X-Platform': 'mobile',
      },
    ));

    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add standard headers, request IDs, or attach token securely
          options.headers['X-Request-Id'] = DateTime.now().millisecondsSinceEpoch.toString();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // You can parse successful responses globally here
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
            // Log timeout, maybe retry
          } else if (e.response?.statusCode == 401) {
            // Token expired or Unauthorized - trigger logout or token refresh
            clearAuthToken();
          } else if (e.response?.statusCode == 500) {
            // Log server error to Crashlytics
          }
          return handler.next(e);
        },
      ),
    ]);
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
