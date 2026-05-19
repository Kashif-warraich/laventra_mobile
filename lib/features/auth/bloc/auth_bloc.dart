import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../../../core/network/session_expired_notifier.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/biometric_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionExpiredSub;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {

    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthBiometricRequested>(_onBiometricRequested);

    // Auto-logout whenever the API interceptor fires a 401
    _sessionExpiredSub = SessionExpiredNotifier.instance.stream.listen((_) {
      if (state is AuthAuthenticated) {
        add(const AuthSessionExpired());
      }
    });
  }

  // Check stored token on app launch
  Future<void> _onStarted(
      AuthStarted event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final hasToken = await _repository.hasToken();
      if (!hasToken) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = await _repository.getStoredUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      final biometricEnabled   = await SecureStorage.instance.getBiometricEnabled();
      final biometricAvailable = await BiometricService.instance.isAvailable();
      if (biometricEnabled && biometricAvailable) {
        emit(AuthBiometricRequired(user));
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // Prompt biometrics and unlock the stored session — no API call needed.
  // This mirrors the Apple/banking-app pattern: Face ID unlocks the local Keychain
  // session. If the server token is stale, the first API call returns 401 and the
  // SessionExpiredNotifier triggers a clean logout automatically.
  Future<void> _onBiometricRequested(
      AuthBiometricRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      UserModel? user;

      if (state is AuthBiometricRequired) {
        // Triggered from splash — Face ID not yet shown, prompt now
        final success = await BiometricService.instance.authenticate();
        if (!success) {
          emit(const AuthUnauthenticated());
          return;
        }
        user = (state as AuthBiometricRequired).user;
      } else {
        // Triggered from login-screen button — Face ID already passed in the UI
        user = await _repository.getStoredUser();
      }

      if (user != null) {
        emit(AuthAuthenticated(user));
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

      // Only owners (lavvaggio operators) can use the mobile app.
      // Admins (management) use the React web admin.
      if (user.role == 'admin') {
        await _repository.logout();
        emit(const AuthLoginFailure(
          'Access denied. Please use the web dashboard.',
        ));
        return;
      }

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

  // Manual logout.
  // When Face ID is enabled we preserve local storage so the user can unlock
  // with Face ID on next launch (same as iPhone's native app behaviour).
  // The server session is always invalidated regardless.
  Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    final biometricEnabled = await SecureStorage.instance.getBiometricEnabled();
    await _repository.logout(preserveForBiometric: biometricEnabled);
    emit(const AuthUnauthenticated());
  }

  // Triggered automatically when token is expired (401 from API)
  Future<void> _onSessionExpired(
      AuthSessionExpired event,
      Emitter<AuthState> emit,
      ) async {
    // Storage already cleared by ApiClient interceptor
    emit(const AuthSessionExpiredState());
  }

  @override
  Future<void> close() {
    _sessionExpiredSub.cancel();
    return super.close();
  }
}
