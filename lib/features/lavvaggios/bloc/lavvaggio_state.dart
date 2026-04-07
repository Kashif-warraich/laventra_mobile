import 'package:equatable/equatable.dart';
import '../data/models/lavvaggio_model.dart';
import '../data/models/lavvaggio_stats_model.dart';
import '../../../../core/models/pagination_meta.dart';

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
  final PaginationMeta       meta;
  const LavvaggiosLoaded(this.lavvaggios, this.meta);

  @override
  List<Object?> get props => [lavvaggios, meta];
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

class LavvaggioStatsLoading extends LavvaggioState {
  const LavvaggioStatsLoading();
}

class LavvaggioStatsLoaded extends LavvaggioState {
  final LavvaggioStats stats;
  const LavvaggioStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}
