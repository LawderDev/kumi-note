import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';

part 'journal_state.dart';

/// Cubit managing journal state (list of notes)
class JournalCubit extends Cubit<JournalState> {
  JournalCubit({required KumiRepository repository})
      : _repository = repository,
        super(const JournalInitial());

  final KumiRepository _repository;

  /// Load all notes from database
  Future<void> loadNotes() async {
    emit(const JournalLoading());

    try {
      final notes = await _repository.getAllNotes();
      emit(JournalLoaded(notes: notes));
    } on Object catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  /// Add a new note - REAL implementation with embedding generation
  Future<void> addNote(String content) async {
    try {
      // This calls the REAL addNote which:
      // 1. Generates embedding via AiService
      // 2. Stores in SQLite with vector
      await _repository.addNote(content);

      // Reload the list
      await loadNotes();
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      await loadNotes();
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }
}
