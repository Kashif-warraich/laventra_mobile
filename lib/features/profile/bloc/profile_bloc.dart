import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfilePasswordUpdateRequested>(_onPasswordUpdate);
  }

  Future<void> _onLoad(
      ProfileLoadRequested event,
      Emitter<ProfileState> emit,
      ) async {
    emit(const ProfileLoading());
    try {
      final user = await _repository.getProfile(event.userId);
      emit(ProfileLoaded(user));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load profile';
      emit(ProfileError(message: msg));
    } catch (_) {
      emit(const ProfileError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onUpdate(
      ProfileUpdateRequested event,
      Emitter<ProfileState> emit,
      ) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).user
        : null;
    if (current == null) return;

    emit(ProfileUpdating(current));
    try {
      final updated = await _repository.updateProfile(
        userId: event.userId,
        data: {
          'first_name':   event.firstName,
          'last_name':    event.lastName,
          'username':     event.username,
          'email':        event.email,
          'phone_number': event.phoneNumber,
        },
      );
      emit(ProfileUpdateSuccess(
        user:    updated,
        message: 'Profile updated successfully',
      ));
      // Settle back to loaded
      await Future.delayed(const Duration(seconds: 2));
      emit(ProfileLoaded(updated));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to update profile';
      emit(ProfileError(user: current, message: msg));
      await Future.delayed(const Duration(seconds: 2));
      emit(ProfileLoaded(current));
    }
  }

  Future<void> _onPasswordUpdate(
      ProfilePasswordUpdateRequested event,
      Emitter<ProfileState> emit,
      ) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).user
        : null;
    if (current == null) return;

    emit(ProfileUpdating(current));
    try {
      await _repository.updatePassword(
        userId:               event.userId,
        password:             event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      emit(ProfileUpdateSuccess(
        user:    current,
        message: 'Password updated successfully',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(ProfileLoaded(current));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to update password';
      emit(ProfileError(user: current, message: msg));
      await Future.delayed(const Duration(seconds: 2));
      emit(ProfileLoaded(current));
    }
  }
}