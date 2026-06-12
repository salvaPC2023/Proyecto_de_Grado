import 'package:dio/dio.dart';
import '../local/token_storage.dart';

const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.add(AuthInterceptor(_tokenStorage));
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);
  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
