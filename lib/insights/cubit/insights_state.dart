import 'package:equatable/equatable.dart';

/// States for Insights feature
sealed class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

/// Loading stats from database
final class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

/// Stats loaded successfully
final class InsightsLoaded extends InsightsState {
  const InsightsLoaded({
    required this.totalNotes,
    required this.avgNotesPerDay,
    required this.oldestNote,
    required this.newestNote,
    required this.notesLast7Days,
  });

  final int totalNotes;
  final double avgNotesPerDay;
  final DateTime? oldestNote;
  final DateTime? newestNote;
  final Map<DateTime, int> notesLast7Days;

  @override
  List<Object?> get props => [
        totalNotes,
        avgNotesPerDay,
        oldestNote,
        newestNote,
        notesLast7Days,
      ];
}

/// Error loading stats
final class InsightsError extends InsightsState {
  const InsightsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
