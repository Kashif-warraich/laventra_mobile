import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {

    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // Check stored token on app launch
  Future<void> _onStarted(
      AuthStarted event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final hasToken = await _repository.hasToken();
      if (hasToken) {
        final user = await _repository.getStoredUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // Login request
  Future<void> _onLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoginInProgress());
    try {
      final user = await _repository.login(
        email:    event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final errors = e.response?.data?['errors'];
      final message = (errors is List && errors.isNotEmpty)
          ? errors.first.toString()
          : 'Login failed. Please try again.';
      emit(AuthLoginFailure(message));
    } catch (_) {
      emit(const AuthLoginFailure('An unexpected error occurred.'));
    }
  }

  // Logout
  Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}