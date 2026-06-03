import '../../domain/entities/school_entity.dart';
import '../../domain/entities/school_image.dart';

class SchoolModel extends SchoolEntity {
  const SchoolModel({
    super.id,
    required super.schoolId,
    required super.name,
    required super.address,
    required super.province,
    required super.district,
    required super.discription,
    required super.type,
    required super.principal,
    required super.stCount,
    required super.techCount,
    required super.labCount,
    required super.buildingCount,
    required super.comCount,
    required super.isSportSchool,
    required super.isPrimarySchool,
    required super.isPoshkaSchool,
    super.lat,
    super.lng,
    required super.images,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String?,
      schoolId: json['schoolId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      province: json['province'] as String? ?? '',
      district: json['district'] as String? ?? '',
      discription: json['discription'] as String? ?? '',
      type: json['type'] as String? ?? 'Primary',
      principal: json['principal'] as String? ?? '',
      stCount: json['stCount'] as int? ?? 0,
      techCount: json['techCount'] as int? ?? 0,
      labCount: json['labCount'] as int? ?? 0,
      buildingCount: json['buildingCount'] as int? ?? 0,
      comCount: json['comCount'] as int? ?? 0,
      isSportSchool: json['isSportSchool'] as bool? ?? false,
      isPrimarySchool: json['isPrimarySchool'] as bool? ?? false,
      isPoshkaSchool: json['isPoshkaSchool'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => SchoolImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'schoolId': schoolId,
      'name': name,
      'address': address,
      'province': province,
      'district': district,
      'discription': discription,
      'type': type,
      'principal': principal,
      'stCount': stCount,
      'techCount': techCount,
      'labCount': labCount,
      'buildingCount': buildingCount,
      'comCount': comCount,
      'isSportSchool': isSportSchool,
      'isPrimarySchool': isPrimarySchool,
      'isPoshkaSchool': isPoshkaSchool,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  factory SchoolModel.fromEntity(SchoolEntity entity) {
    return SchoolModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      address: entity.address,
      province: entity.province,
      district: entity.district,
      discription: entity.discription,
      type: entity.type,
      principal: entity.principal,
      stCount: entity.stCount,
      techCount: entity.techCount,
      labCount: entity.labCount,
      buildingCount: entity.buildingCount,
      comCount: entity.comCount,
      isSportSchool: entity.isSportSchool,
      isPrimarySchool: entity.isPrimarySchool,
      isPoshkaSchool: entity.isPoshkaSchool,
      lat: entity.lat,
      lng: entity.lng,
      images: entity.images,
    );
  }
}
