import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/repository/absen_repository.dart';
import 'package:fr3divi/features/face3divi/data/models/absen_model.dart';

// Events
abstract class AttendanceListEvent {}

class LoadAttendanceEvent extends AttendanceListEvent {}

class FilterAttendanceEvent extends AttendanceListEvent {
  final DateTime startDate;
  final DateTime endDate;
  FilterAttendanceEvent({required this.startDate, required this.endDate});
}

class RefreshAttendanceEvent extends AttendanceListEvent {}

class FetchHistoryEvent extends AttendanceListEvent {}

// States
abstract class AttendanceListState {
  const AttendanceListState();
}

class AttendanceListInitial extends AttendanceListState {
  const AttendanceListInitial();
}

class AttendanceListLoading extends AttendanceListState {
  const AttendanceListLoading();
}

class AttendanceListLoaded extends AttendanceListState {
  final List<AbsenModel> items;
  const AttendanceListLoaded(this.items);
}

class AttendanceListError extends AttendanceListState {
  final String message;
  const AttendanceListError(this.message);
}

// BLoC
class AttendanceListBloc
    extends Bloc<AttendanceListEvent, AttendanceListState> {
  final AbsenRepository _repository;

  AttendanceListBloc(this._repository) : super(const AttendanceListInitial()) {
    on<LoadAttendanceEvent>(_onLoadAttendance);
    on<FilterAttendanceEvent>(_onFilterAttendance);
    on<RefreshAttendanceEvent>(_onRefreshAttendance);
    on<FetchHistoryEvent>(_onFetchHistory);
  }

  Future<void> _onLoadAttendance(
    LoadAttendanceEvent event,
    Emitter<AttendanceListState> emit,
  ) async {
    try {
      emit(const AttendanceListLoading());

      // Subscribe to attendance changes via stream
      await emit.forEach(
        _repository.watchAttendance(),
        onData: (List<AbsenModel> items) {
          return AttendanceListLoaded(items);
        },
        onError: (error, stackTrace) {
          return AttendanceListError(error.toString());
        },
      );
    } catch (e) {
      emit(AttendanceListError(e.toString()));
    }
  }

  Future<void> _onFilterAttendance(
    FilterAttendanceEvent event,
    Emitter<AttendanceListState> emit,
  ) async {
    try {
      emit(const AttendanceListLoading());

      // Filter attendance by date range
      final items = await _repository.getAttendanceByDateRange(
        event.startDate,
        event.endDate,
      );

      items.sort((a, b) => a.jamAbsen.compareTo(b.jamAbsen));

      emit(AttendanceListLoaded(items));
    } catch (e) {
      emit(AttendanceListError(e.toString()));
    }
  }

  Future<void> _onRefreshAttendance(
    RefreshAttendanceEvent event,
    Emitter<AttendanceListState> emit,
  ) async {
    try {
      emit(const AttendanceListLoading());
      final items = await _repository.getAllAttendance();
      emit(AttendanceListLoaded(items));
    } catch (e) {
      emit(AttendanceListError(e.toString()));
    }
  }

  Future<void> _onFetchHistory(
    FetchHistoryEvent event,
    Emitter<AttendanceListState> emit,
  ) async {
    try {
      emit(const AttendanceListLoading());
      await _repository.clearAllAbsen();
      final items = await _repository.fetchAttendanceHistory();
      for (final item in items) {
        await _repository.addAbsen(item);
      }
      emit(AttendanceListLoaded(items));
    } catch (e) {
      emit(AttendanceListError(e.toString()));
    }
  }
}
