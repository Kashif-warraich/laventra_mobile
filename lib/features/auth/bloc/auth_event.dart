import 'package:equatable/equatable.dart';
import '../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}

// The user object stored in the bloc needs to be refreshed (e.g. the user
// just changed their password and must_change_password flipped to false).
// Local storage has already been updated by the repository.
class AuthUserRefreshed extends AuthEvent {
  final UserModel user;
  const AuthUserRefreshed(this.user);

  @override
  List<Object?> get props => [user];
}