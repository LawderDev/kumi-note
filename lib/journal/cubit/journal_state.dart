part of 'journal_cubit.dart';

/// Base class for journal states
sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object> get props => [];
}

/// Initial state
final class JournalInitial extends JournalState {
  const JournalInitial();
}

/// Loading notes from database
final class JournalLoading extends JournalState {
  const JournalLoading();
}

/// Notes loaded successfully
final class JournalLoaded extends JournalState {
  const JournalLoaded({required this.notes});

  final List<NoteModel> notes;

  @override
  List<Object> get props => [notes];
}

/// Error occurred
final class JournalError extends JournalState {
  const JournalError({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
