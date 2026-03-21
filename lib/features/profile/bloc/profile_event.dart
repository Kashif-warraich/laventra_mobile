import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final int userId;
  const ProfileLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final int    userId;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;

  const ProfileUpdateRequested({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    userId, firstName, lastName, username, email, phoneNumber
  ];
}

class ProfilePasswordUpdateRequested extends ProfileEvent {
  final int    userId;
  final String password;
  final String passwordConfirmation;

  const ProfilePasswordUpdateRequested({
    required this.userId,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [userId, password, passwordConfirmation];
}