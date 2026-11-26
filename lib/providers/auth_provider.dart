import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  Map<String, dynamic>? _currentProvider;
  String _userType = ''; // 'customer', 'admin', 'provider'
  bool _isLoading = false;
  String _error = '';

  UserModel? get currentUser => _currentUser;
  Map<String, dynamic>? get currentProvider => _currentProvider;
  String get userType => _userType;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isLoggedIn => _currentUser != null || _currentProvider != null;

  Future<void> loadSession() async {
    try {
      await DatabaseHelper.instance.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final providerId = prefs.getInt('providerId');
      final type = prefs.getString('userType') ?? '';

      if (userId != null && type != 'provider') {
        final userData = await DatabaseHelper.instance.getUserById(userId);
        if (userData != null) {
          _currentUser = UserModel.fromMap(userData);
          _userType = type;
        }
      } else if (providerId != null) {
        final providerData = await DatabaseHelper.instance.getProviderById(providerId);
        if (providerData != null) {
          _currentProvider = providerData;
          _userType = 'provider';
        }
      }
    } catch (e) {
      debugPrint('loadSession error: $e');
    }
    notifyListeners();
  }

  Future<void> _persistSession({int? userId, int? providerId, required String userType}) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      await prefs.setString('userType', userType);
      if (userId != null) {
        await prefs.setInt('userId', userId);
        await prefs.remove('providerId');
      } else if (providerId != null) {
        await prefs.setInt('providerId', providerId);
        await prefs.remove('userId');
      }
    } catch (e) {
      debugPrint('SharedPreferences error (ignored): $e');
    }
  }

  Future<bool> loginAsCustomerOrAdmin(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final userData = await DatabaseHelper.instance.loginUser(email, password);
      if (userData != null) {
        _currentUser = UserModel.fromMap(userData);
        _userType = userData['role'] == 'admin' ? 'admin' : 'customer';
        _currentProvider = null;

        await _persistSession(userId: _currentUser!.id!, userType: _userType);
        return true;
      }

      _error = 'Invalid email or password';
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginAsProvider(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final providerData = await DatabaseHelper.instance.loginProvider(email, password);
      if (providerData != null) {
        _currentProvider = providerData;
        _userType = 'provider';
        _currentUser = null;

        await _persistSession(providerId: providerData['id'], userType: 'provider');
        return true;
      }

      _error = 'Invalid email or password';
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String address) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final exists = await DatabaseHelper.instance.emailExists(email);
      if (exists) {
        _error = 'Email already registered';
        return false;
      }

      final user = UserModel(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        role: 'customer',
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await DatabaseHelper.instance.registerUser(user.toMap());
      if (id <= 0) {
        _error = 'Registration failed. Try again.';
        return false;
      }

      _currentUser = UserModel(
        id: id,
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        role: 'customer',
        createdAt: user.createdAt,
      );
      _currentProvider = null;
      _userType = 'customer';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', id);
      await prefs.setString('userType', 'customer');
      await prefs.remove('providerId');
      return true;
    } catch (error) {
      _error = 'Could not create account. The database may not be available on this platform.';
      debugPrint('Registration failed: $error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> logout() async {
    _currentUser = null;
    _currentProvider = null;
    _userType = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}

