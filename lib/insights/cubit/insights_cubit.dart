import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_note/insights/cubit/insights_state.dart';
import 'package:kumi_repository/kumi_repository.dart';

/// Cubit for managing Insights state
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit({required KumiRepository repository})
    : _repository = repository,
      super(const InsightsLoading());

  final KumiRepository _repository;

  /// Loads statistics from the repository
  Future<void> loadStats() async {
    emit(const InsightsLoading());

    try {
      final stats = await _repository.getStats();

      emit(
        InsightsLoaded(
          totalNotes: stats['totalNotes'] as int,
          avgNotesPerDay: stats['avgNotesPerDay'] as double,
          oldestNote: stats['oldestNote'] as DateTime?,
          newestNote: stats['newestNote'] as DateTime?,
          notesLast7Days: stats['notesLast7Days'] as Map<DateTime, int>,
        ),
      );
    } on Exception catch (e) {
      emit(InsightsError('Impossible de charger les statistiques: $e'));
    }
  }
}
