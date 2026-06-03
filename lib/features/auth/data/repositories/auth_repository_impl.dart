import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _activeUserKey = 'school_portal_active_user';
  final ApiClient _apiClient = ApiClient();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_activeUserKey);
    final String? token = prefs.getString('auth_token');

    if (userJson == null || token == null || token.isEmpty) return null;

    try {
      return UserModel.fromJson(json.decode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final String token = data['token'] as String;

      // Save token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Parse User details
      final user = UserModel.fromJson(data);

      // Save user details to SharedPreferences for session persistence
      await prefs.setString(_activeUserKey, json.encode(user.toJson()));

      return user;
    } on DioException catch (e) {
      String errorMessage = 'An error occurred during login. Please try again.';
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map<String, dynamic> && resData.containsKey('message')) {
          errorMessage = resData['message'] as String;
        } else if (resData is String) {
          errorMessage = resData;
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserEntity> register(
    String email,
    String password,
    String? phoneNumber,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email.trim(),
          'passwordHash': password,
          'role': 'SCHOOL',
        },
      );

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final String token = data['token'] as String;

      // Save token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Parse User details
      final user = UserModel.fromJson(data);

      // Save user details to SharedPreferences for session persistence
      await prefs.setString(_activeUserKey, json.encode(user.toJson()));

      return user;
    } on DioException catch (e) {
      String errorMessage =
          'An error occurred during registration. Please try again.';
      print("Error: $e");
      if (e.response?.data != null) {
        print(e.response?.data);
        final resData = e.response?.data;
        if (resData is Map<String, dynamic> && resData.containsKey('message')) {
          errorMessage = resData['message'] as String;
          print(errorMessage);
        } else if (resData is String) {
          errorMessage = resData;
          print(errorMessage);
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      print("Exception: ${e.toString()}");
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: {'email': email.trim(), 'password': newPassword},
      );
    } on DioException catch (e) {
      String errorMessage = 'An error occurred resetting your password.';
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map<String, dynamic> && resData.containsKey('message')) {
          errorMessage = resData['message'] as String;
        } else if (resData is String) {
          errorMessage = resData;
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove(_activeUserKey);
  }
}
