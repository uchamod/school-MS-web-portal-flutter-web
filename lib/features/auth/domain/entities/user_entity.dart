import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? phoneNumber;

  const UserEntity({
    required this.id,
    required this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [id, email, phoneNumber];
}
