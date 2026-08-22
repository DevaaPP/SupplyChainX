import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio _dio;
  String? _authToken;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('[API Client Error] ${e.requestOptions.path} -> ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<Response<T>?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } catch (e) {
      debugPrint('[GET Error] $path: $e');
      return null;
    }
  }

  Future<Response<T>?> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      debugPrint('[POST Error] $path: $e');
      return null;
    }
  }

  Dio get rawDio => _dio;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
