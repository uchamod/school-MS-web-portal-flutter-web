import 'package:equatable/equatable.dart';
import '../../domain/entities/school_entity.dart';

abstract class SchoolState extends Equatable {
  const SchoolState();

  @override
  List<Object?> get props => [];
}

class SchoolInitial extends SchoolState {}

class SchoolLoading extends SchoolState {}

class SchoolLoaded extends SchoolState {
  final SchoolEntity school;

  const SchoolLoaded(this.school);

  @override
  List<Object?> get props => [school];
}

class SchoolSaving extends SchoolState {
  final SchoolEntity school; // Preserve the current school data while saving

  const SchoolSaving(this.school);

  @override
  List<Object?> get props => [school];
}

class SchoolSaveSuccess extends SchoolState {
  final SchoolEntity school;

  const SchoolSaveSuccess(this.school);

  @override
  List<Object?> get props => [school];
}

class SchoolError extends SchoolState {
  final String message;

  const SchoolError(this.message);

  @override
  List<Object?> get props => [message];
}
