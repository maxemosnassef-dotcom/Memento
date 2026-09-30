import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/memory.dart';
import '../../../domain/usecases/find_memories_nearby.dart';
import '../../../domain/usecases/get_on_this_day_memories.dart';
import '../../../domain/usecases/query_memories_between.dart';

sealed class MemoriesEvent extends Equatable {
  const MemoriesEvent();

  @override
  List<Object?> get props => [];
}

final class OnThisDayRequested extends MemoriesEvent {
  final DateTime referenceLocal;

  const OnThisDayRequested({required this.referenceLocal});

  @override
  List<Object?> get props => [referenceLocal];
}

final class WindowRequested extends MemoriesEvent {
  final DateTime startUtcInclusive;
  final DateTime endUtcExclusive;
  final String label;

  const WindowRequested({
    required this.startUtcInclusive,
    required this.endUtcExclusive,
    required this.label,
  });

  @override
  List<Object?> get props => [startUtcInclusive, endUtcExclusive, label];
}

final class NearbyRequested extends MemoriesEvent {
  const NearbyRequested();
}

sealed class MemoriesState extends Equatable {
  const MemoriesState();

  @override
  List<Object?> get props => [];
}

final class MemoriesInitial extends MemoriesState {
  const MemoriesInitial();
}

final class MemoriesLoadInProgress extends MemoriesState {
  const MemoriesLoadInProgress();
}

final class MemoriesReady extends MemoriesState {
  final List<Memory> memories;
  final String viewLabel;

  const MemoriesReady({required this.memories, required this.viewLabel});

  @override
  List<Object?> get props => [memories, viewLabel];
}

final class MemoriesFailureState extends MemoriesState {
  final Failure failure;

  const MemoriesFailureState(this.failure);

  @override
  List<Object?> get props => [failure];
}

class MemoriesBloc extends Bloc<MemoriesEvent, MemoriesState> {
  final GetOnThisDayMemories _onThisDay;
  final QueryMemoriesBetween _between;
  final FindMemoriesNearby _nearby;

  MemoriesBloc({
    required GetOnThisDayMemories onThisDay,
    required QueryMemoriesBetween between,
    required FindMemoriesNearby nearby,
  })  : _onThisDay = onThisDay,
        _between = between,
        _nearby = nearby,
        super(const MemoriesInitial()) {
    on<OnThisDayRequested>(_handleOnThisDay);
    on<WindowRequested>(_handleWindow);
    on<NearbyRequested>(_handleNearby);
  }

  Future<void> _handleOnThisDay(
    OnThisDayRequested event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(const MemoriesLoadInProgress());
    final result = await _onThisDay.execute(
      OnThisDayQuery(referenceLocal: event.referenceLocal),
    );
    result.fold(
      onError: (failure) => emit(MemoriesFailureState(failure)),
      onSuccess: (memories) => emit(MemoriesReady(
        memories: memories,
        viewLabel: 'On this day, across the years',
      )),
    );
  }

  Future<void> _handleWindow(
    WindowRequested event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(const MemoriesLoadInProgress());
    final result = await _between.execute(WindowQuery(
      startUtcInclusive: event.startUtcInclusive,
      endUtcExclusive: event.endUtcExclusive,
    ));
    result.fold(
      onError: (failure) => emit(MemoriesFailureState(failure)),
      onSuccess: (memories) => emit(MemoriesReady(
        memories: memories,
        viewLabel: event.label,
      )),
    );
  }

  Future<void> _handleNearby(
    NearbyRequested event,
    Emitter<MemoriesState> emit,
  ) async {
    emit(const MemoriesLoadInProgress());
    final result = await _nearby.execute(NearbyQuery(
      radius: FindMemoriesNearby.defaultRadius,
    ));
    result.fold(
      onError: (failure) => emit(MemoriesFailureState(failure)),
      onSuccess: (memories) => emit(MemoriesReady(
        memories: memories,
        viewLabel: 'Within a short walk of you',
      )),
    );
  }
}
