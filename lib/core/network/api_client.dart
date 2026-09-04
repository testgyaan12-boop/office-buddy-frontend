import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return ApiClient(secureStorage);
});

class ApiClient {
  final SecureStorage _secureStorage;
  late final Dio _dio;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final code = error.response?.statusCode;
          if (code == 401 || code == 403) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              try {
                final retryResponse = await _retry(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> tryRefresh() async => _refreshToken();

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        await _secureStorage.saveToken(response.data['accessToken']);
        await _secureStorage.saveRefreshToken(response.data['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _secureStorage.getToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> downloadFile(String url, String savePath) =>
      _dio.download(url, savePath);

  Future<Response> uploadFile(
    String path, {
    required Uint8List fileBytes,
    required String fileName,
    String? fileField,
    Map<String, dynamic>? extraData,
  }) async {
    final formData = FormData.fromMap({
      if (fileField != null)
        fileField: MultipartFile.fromBytes(fileBytes, filename: fileName),
      if (extraData != null) ...extraData,
    });
    return _dio.post(path, data: formData);
  }
}
