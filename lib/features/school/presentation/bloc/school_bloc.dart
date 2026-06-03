import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/entities/school_entity.dart';
import 'school_event.dart';
import 'school_state.dart';

class SchoolBloc extends Bloc<SchoolEvent, SchoolState> {
  final SchoolRepository _schoolRepository;

  SchoolBloc({required SchoolRepository schoolRepository})
      : _schoolRepository = schoolRepository,
        super(SchoolInitial()) {
    on<SchoolLoadRequested>(_onSchoolLoadRequested);
    on<SchoolSaveRequested>(_onSchoolSaveRequested);
  }

  Future<void> _onSchoolLoadRequested(
    SchoolLoadRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(SchoolLoading());
    try {
      final school = await _schoolRepository.getSchoolDetails(event.userId);
      if (school != null) {
        emit(SchoolLoaded(school));
      } else {
        // If not found, emit loaded with empty entity so they can fill it
        emit(SchoolLoaded(SchoolEntity.empty(event.userId)));
      }
    } catch (e) {
      emit(SchoolError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSchoolSaveRequested(
    SchoolSaveRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(SchoolSaving(event.school));
    try {
      await _schoolRepository.saveSchoolDetails(event.userId, event.school, event.newImages);
      
      // Fetch latest school profile details from server to reflect DB IDs and Image URLs
      final latestSchool = await _schoolRepository.getSchoolDetails(event.userId);
      final finalSchool = latestSchool ?? event.school;
      
      emit(SchoolSaveSuccess(finalSchool));
      emit(SchoolLoaded(finalSchool));
    } catch (e) {
      emit(SchoolError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
