import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for Web/iOS/Desktop
  // THAY LINK NGROK VÀO ĐÂY NẾU MUỐN DÙNG TỪ XA
  static String? ngrokUrl = 'https://wilber-postaortic-perdurably.ngrok-free.dev'; // Ví dụ: 'https://xxxx.ngrok-free.app'

  static String get baseUrl {
    // Luôn ưu tiên dùng localhost khi chạy trực tiếp trên giả lập Web Chrome
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (ngrokUrl != null && ngrokUrl!.isNotEmpty) {
      return '$ngrokUrl/api';
    }
    
    // For native platforms, check if Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }
  
  late Dio _dio;
  String? _token;
  late Future<void> _initFuture;
  bool _initialized = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'any',
      },
    ));

    // Load token from storage
    _initFuture = _loadToken();

    // Add interceptor for logging and token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Wait for token to be loaded from SharedPreferences
        await _initFuture;
        
        // Add token to headers if available
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        print('🌐 ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _initialized = true;
      debugPrint('🔑 ApiService: Token loaded: ${_token != null ? "Yes" : "No"}');
    } catch (e) {
      debugPrint('❌ ApiService: Error loading token: $e');
      _initialized = true;
    }
  }

  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  bool get isInitialized => _initialized;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  String? get token => _token;

  Dio get dio => _dio;

  // Helper method to handle API responses
  Map<String, dynamic> handleResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Request failed with status: ${response.statusCode}',
      );
    }
  }

  // Helper method to handle errors
  String handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        return 'Server error: ${error.response!.statusCode}';
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection.';
      }
      return error.message ?? 'Unknown error occurred';
    }
    return error.toString();
  }
}
