import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password, String? phoneNumber);
  Future<void> resetPassword(String email, String newPassword);
  Future<void> logout();
}
