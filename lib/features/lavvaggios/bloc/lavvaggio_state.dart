import 'package:equatable/equatable.dart';
import '../data/models/lavvaggio_model.dart';

abstract class LavvaggioState extends Equatable {
  const LavvaggioState();

  @override
  List<Object?> get props => [];
}

class LavvaggioInitial extends LavvaggioState {
  const LavvaggioInitial();
}

class LavvaggioLoading extends LavvaggioState {
  const LavvaggioLoading();
}

class LavvaggiosLoaded extends LavvaggioState {
  final List<LavvaggioModel> lavvaggios;
  const LavvaggiosLoaded(this.lavvaggios);

  @override
  List<Object?> get props => [lavvaggios];
}

class LavvaggioDetailLoaded extends LavvaggioState {
  final LavvaggioModel lavvaggio;
  const LavvaggioDetailLoaded(this.lavvaggio);

  @override
  List<Object?> get props => [lavvaggio];
}

class LavvaggioUpdating extends LavvaggioState {
  final LavvaggioModel lavvaggio;
  const LavvaggioUpdating(this.lavvaggio);

  @override
  List<Object?> get props => [lavvaggio];
}

class LavvaggioUpdateSuccess extends LavvaggioState {
  final LavvaggioModel lavvaggio;
  const LavvaggioUpdateSuccess(this.lavvaggio);

  @override
  List<Object?> get props => [lavvaggio];
}

class LavvaggioError extends LavvaggioState {
  final String message;
  const LavvaggioError(this.message);

  @override
  List<Object?> get props => [message];
}