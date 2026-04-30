import 'package:equatable/equatable.dart';
import '../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// App just launched — checking token
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Checking stored token
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Valid token found or login succeeded
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// No token, login failed or logged out
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Login request in progress
class AuthLoginInProgress extends AuthState {
  const AuthLoginInProgress();
}

// Login failed with error message
class AuthLoginFailure extends AuthState {
  final String message;

  const AuthLoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Token expired — triggers auto-logout with a brief message
class AuthSessionExpiredState extends AuthUnauthenticated {
  const AuthSessionExpiredState();
}

// Biometric prompt required — user may be null after logout (re-login via stored credentials)
class AuthBiometricRequired extends AuthState {
  final UserModel? user;
  const AuthBiometricRequired([this.user]);

  @override
  List<Object?> get props => [user];
}