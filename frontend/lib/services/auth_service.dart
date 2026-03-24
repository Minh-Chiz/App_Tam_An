import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tam_an/models/user.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  // Upload profile avatar
  Future<String> uploadAvatar(XFile imageFile) async {
    try {
      FormData formData;
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          "avatar": MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          ),
        });
      } else {
        formData = FormData.fromMap({
          "avatar": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          ),
        });
      }

      final response = await _apiService.dio.post(
        '/auth/profile/avatar',
        data: formData,
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return data['data']['avatar_url'];
      }
      
      throw Exception(data['message'] ?? 'Avatar upload failed');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['token'];
        await _apiService.setToken(token);
        
        final user = User.fromJson(data['data']['user']);
        
        return {
          'success': true,
          'user': user,
          'token': token,
        };
      }
      
      throw Exception(data['message'] ?? 'Registration failed');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Login user (supports both email and phone number)
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {
          'email': identifier, // Backend accepts identifier in 'email' field
          'password': password,
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['token'];
        await _apiService.setToken(token);
        
        final user = User.fromJson(data['data']['user']);
        
        return {
          'success': true,
          'user': user,
          'token': token,
        };
      }
      
      throw Exception(data['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiService.dio.get('/auth/profile');
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return User.fromJson(data['data']['user']);
      }
      
      throw Exception(data['message'] ?? 'Failed to get profile');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Delete profile avatar
  Future<void> deleteAvatar() async {
    try {
      final response = await _apiService.dio.delete('/auth/profile/avatar');
      _apiService.handleResponse(response);
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return _apiService.handleResponse(response);
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
      return _apiService.handleResponse(response);
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
  }

  // Check if user is logged in
  bool get isLoggedIn => _apiService.token != null;
}
