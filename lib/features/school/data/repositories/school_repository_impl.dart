import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/school_entity.dart';
import '../../domain/repositories/school_repository.dart';
import '../models/school_model.dart';

class SchoolRepositoryImpl implements SchoolRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<SchoolEntity?> getSchoolDetails(String schoolId) async {
    try {
      final response = await _apiClient.dio.get('/school/$schoolId');
      if (response.data == null) return null;
      
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      return SchoolModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // If profile doesn't exist yet, return null
        return null;
      }
      String errorMessage = 'An error occurred fetching school details.';
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
  Future<void> saveSchoolDetails(String schoolId, SchoolEntity school, List<dynamic> newImages) async {
    try {
      final model = SchoolModel.fromEntity(school);
      
      // Map newImages files to Dio MultipartFile bytes lists
      final List<MultipartFile> files = [];
      for (var item in newImages) {
        if (item is PlatformFile && item.bytes != null) {
          final ext = item.extension ?? 'png';
          files.add(
            MultipartFile.fromBytes(
              item.bytes!,
              filename: item.name,
              contentType: MediaType('image', ext),
            ),
          );
        }
      }

      final formData = FormData();
      
      // Add the JSON model as a String part
      formData.files.add(
        MapEntry(
          'school',
          MultipartFile.fromString(
            json.encode(model.toJson()),
            contentType: MediaType('application', 'json'),
          ),
        ),
      );

      // Add actual selected images to form data
      if (files.isNotEmpty) {
        for (var file in files) {
          formData.files.add(MapEntry('images', file));
        }
      }

      if (school.id != null && school.id!.isNotEmpty) {
        // Send PUT request to update profile
        await _apiClient.dio.put('/school/$schoolId', data: formData);
      } else {
        // Send POST request to create profile
        await _apiClient.dio.post('/school', data: formData);
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to save school profile details.';
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
}
