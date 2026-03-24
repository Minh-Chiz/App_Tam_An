import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:tam_an/models/user.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/auth_service.dart';
import 'package:tam_an/services/settings_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  late final AuthService _authService;
  late final SettingsService _settingsService;

  User? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userSettings;
  bool _isFreshLogin = false;

  AuthProvider(this._apiService) {
    _authService = AuthService(_apiService);
    _settingsService = SettingsService(_apiService);
    _checkAuth();
  }

  Map<String, dynamic>? get userSettings => _userSettings;
  AuthService get authService => _authService;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFreshLogin => _isFreshLogin;
  bool get isAuthenticated => _user != null && _apiService.token != null;

  // Check if user is already logged in
  Future<void> _checkAuth() async {
    await _apiService.ensureInitialized();
    if (_authService.isLoggedIn) {
      try {
        _user = await _authService.getProfile();
        await loadUserSettings();
        _isFreshLogin = false; // Auto-login is not a fresh login
        notifyListeners();
      } catch (e) {
        // Token might be expired, clear it
        await _authService.logout();
      }
    }
  }

  // Load user settings from SQL Server
  Future<void> loadUserSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      _userSettings = settings;
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  // Register new user

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );

      // Don't set user - require manual login after registration
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        identifier: email,
        password: password,
      );

      _user = result['user'];
      await loadUserSettings();
      _isFreshLogin = true; // Manual login
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  // Upload avatar
  Future<bool> uploadAvatar(XFile imageFile) async {
    try {
      final avatarUrl = await _authService.uploadAvatar(imageFile);
      // Update local user object
      if (_user != null) {
        _user = User(
          id: _user!.id,
          email: _user!.email,
          name: _user!.name,
          avatarUrl: avatarUrl,
          createdAt: _user!.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete avatar
  Future<bool> deleteAvatar() async {
    try {
      await _authService.deleteAvatar();
      // Update local user object
      if (_user != null) {
        _user = User(
          id: _user!.id,
          email: _user!.email,
          name: _user!.name,
          avatarUrl: null,
          createdAt: _user!.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isFreshLogin = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
