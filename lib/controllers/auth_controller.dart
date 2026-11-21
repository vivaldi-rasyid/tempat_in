import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/repositories.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repo;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController(this._repo);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _currentUser = await _repo.restoreSession();
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _runAuth(() => _repo.login(email, password));

  Future<bool> loginWithSso() => _runAuth(_repo.loginWithSso);

  Future<bool> signUp(String email, String password) =>
      _runAuth(() => _repo.signUp(email, password));

  Future<void> logout() async {
    await _repo.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuth(Future<User> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await action();
      return true;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Authentication failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}