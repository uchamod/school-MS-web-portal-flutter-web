import '../entities/school_entity.dart';

abstract class SchoolRepository {
  Future<SchoolEntity?> getSchoolDetails();
  Future<void> saveSchoolDetails(String schoolId, SchoolEntity school, List<dynamic> newImages);
}
