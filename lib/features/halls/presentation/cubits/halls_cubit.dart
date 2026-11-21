import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/hall_model.dart';
import '../../data/repos/halls_repository.dart';

abstract class HallsState {
  const HallsState();
}

class HallsInitial extends HallsState {
  const HallsInitial();
}

class HallsLoading extends HallsState {
  const HallsLoading();
}

class HallsLoaded extends HallsState {
  final List<Hall> halls;
  const HallsLoaded(this.halls);
}

class HallsError extends HallsState {
  final String message;
  const HallsError(this.message);
}

class HallsCubit extends Cubit<HallsState> {
  final HallsRepository _repository;

  HallsCubit(this._repository) : super(const HallsInitial());

  Future<void> loadHalls() async {
    emit(const HallsLoading());
    try {
      final halls = await _repository.getHalls();
      emit(HallsLoaded(halls));
    } catch (e) {
      emit(HallsError(e.toString()));
    }
  }

  Future<void> addHall(Hall hall) async {
    try {
      await _repository.addHall(hall);
      await loadHalls();
    } catch (e) {
      emit(HallsError(e.toString()));
    }
  }

  Future<void> deleteHall(String id) async {
    try {
      await _repository.deleteHall(id);
      await loadHalls();
    } catch (e) {
      emit(HallsError(e.toString()));
    }
  }
}
