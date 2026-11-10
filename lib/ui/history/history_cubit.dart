import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<List<RecordedShot>?> {
  final ShotRepository _repository;

  HistoryCubit(this._repository) : super(null);

  Future<void> load() async => emit(await _repository.list());
}
