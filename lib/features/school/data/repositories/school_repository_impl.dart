import 'dart:convert';
import 'dart:typed_data';

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
  Future<SchoolEntity?> getSchoolDetails() async {
    try {
      // First try to fetch using the standard microservice route: GET /school/profile
      // Since the API gateway extracts schoolId from the Authorization token,
      // the backend fetches the correct profile context automatically.
      Response response;

      response = await _apiClient.dio.get('/school/getSchoolById');
      if (response.statusCode == 404) {
        // Profile does not exist yet
        return null;
      }

      if (response.data == null) return null;

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      return SchoolModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
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
  Future<void> saveSchoolDetails(
    String schoolId,
    SchoolEntity school,
    List<dynamic> newImages,
  ) async {
    try {
      final model = SchoolModel.fromEntity(school);

      // Map picked file items to Dio MultipartFile parts
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

      // Add the JSON school model as a RequestPart
      formData.files.add(
        MapEntry(
          'school',
          MultipartFile.fromString(
            json.encode(model.toJson()),
            contentType: MediaType('application', 'json'),
          ),
        ),
      );

      // Add the picked images list as a RequestPart
      if (files.isNotEmpty) {
        for (var file in files) {
          formData.files.add(MapEntry('images', file));
        }
      }else{
        formData.files.add(MapEntry('images',MultipartFile.fromBytes(Uint8List(0),filename: '', contentType: MediaType('application', 'json'),)));
      }
      final response;
      if (school.id != null && school.id!.isNotEmpty) {
        // Send PUT request to update profile
         response = await _apiClient.dio.put(
          '/school/updateprofile',
          data: formData,
          options: Options(responseType: ResponseType.plain),
        );
      } else {
        // Send POST request to complete profile
         response = await _apiClient.dio.post(
          '/school/profile',
          data: formData,
          options: Options(responseType: ResponseType.plain),
        );
      }
      if(response.statusCode != 200){
        print("Response Data: ${response.data}");
        throw Exception(response.data);
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
