import '../entities/school_entity.dart';

abstract class SchoolRepository {
  Future<SchoolEntity?> getSchoolDetails(String schoolId);
  Future<void> saveSchoolDetails(String schoolId, SchoolEntity school, List<dynamic> newImages);
}
