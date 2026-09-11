import 'dart:async';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'user_store.dart';

/// Mock authentication service — delegates account lookup to UserStore.
/// Replace with FirebaseAuthService for production.
class MockAuthService implements AuthService {
  final _authController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final account = UserStore.instance.getAccount(email);
    if (account == null) {
      throw Exception('No account found with this email address.');
    }
    if (account['password'] != password) {
      throw Exception('Incorrect password. Please try again.');
    }
    final user = account['user'] as UserModel;
    if (!user.isActive) {
      throw Exception('This account has been deactivated. Contact admin.');
    }

    _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Stream<UserModel?> get authStateChanges => _authController.stream;

  void dispose() {
    _authController.close();
  }
}
