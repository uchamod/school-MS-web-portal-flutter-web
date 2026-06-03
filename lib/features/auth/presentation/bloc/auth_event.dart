import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String? phoneNumber;

  const AuthRegisterSubmitted({
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, phoneNumber];
}

class AuthPasswordResetSubmitted extends AuthEvent {
  final String email;
  final String newPassword;

  const AuthPasswordResetSubmitted({
    required this.email,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, newPassword];
}

class AuthLogoutRequested extends AuthEvent {}
