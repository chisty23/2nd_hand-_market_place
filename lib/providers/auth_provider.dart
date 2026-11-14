import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _firebaseUser;
  UserModel? _userProfile;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userProfileSubscription;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _init();
  }

  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      _userProfileSubscription?.cancel();
      if (user != null) {
        _userProfileSubscription =
            _authService.streamUserProfile(user.uid).listen((profile) {
          _userProfile = profile;
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String department = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        department: department,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userProfileSubscription?.cancel();
    await _authService.logout();
    _userProfile = null;
    _firebaseUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanError(String error) {
    if (error.contains('user-not-found')) return 'No user found for that email.';
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('email-already-in-use')) return 'Email already registered.';
    if (error.contains('weak-password')) return 'Password should be at least 6 characters.';
    if (error.contains('invalid-email')) return 'Invalid email address.';
    return error.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userProfileSubscription?.cancel();
    super.dispose();
  }
}
