import '../models/user_model.dart';

/// Abstract interface for authentication service
/// Can be swapped with FirebaseAuthService without changing UI
abstract class AuthService {
  Future<UserModel?> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile(UserModel user);
  Stream<UserModel?> get authStateChanges;
}
