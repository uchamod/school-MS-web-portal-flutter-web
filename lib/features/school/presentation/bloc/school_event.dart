import 'package:equatable/equatable.dart';
import '../../domain/entities/school_entity.dart';

abstract class SchoolEvent extends Equatable {
  const SchoolEvent();

  @override
  List<Object?> get props => [];
}

class SchoolLoadRequested extends SchoolEvent {
  final String userId;

  const SchoolLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SchoolSaveRequested extends SchoolEvent {
  final String userId;
  final SchoolEntity school;
  final List<dynamic> newImages;

  const SchoolSaveRequested({
    required this.userId,
    required this.school,
    required this.newImages,
  });

  @override
  List<Object?> get props => [userId, school, newImages];
}
