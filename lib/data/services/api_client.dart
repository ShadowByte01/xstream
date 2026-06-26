import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

/// The single Dio instance used across the app.
///
/// All requests go through the Xstream backend proxy (deployed on Render),
/// which hides the TMDB + Groq API keys. The base URL is configured in
/// [AppConstants.backendBaseUrl] and can be overridden at build time with
/// `--dart-define=BACKEND_URL=...`.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.backendBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          if (kDebugMode) {
            debugPrint('ApiClient error: ${e.requestOptions.path} → ${e.message}');
          }
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Convenience GET that returns the parsed JSON body (or throws).
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get(path, queryParameters: query);
    return res.data;
  }
}
