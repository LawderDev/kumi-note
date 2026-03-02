import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';

part 'journal_state.dart';

/// Cubit managing journal state (list of notes).
class JournalCubit extends Cubit<JournalState> {
  JournalCubit({required KumiRepository repository})
    : _repository = repository,
      super(const JournalInitial());

  final KumiRepository _repository;

  /// Initialize and load notes
  Future<void> initialize() async {
    await loadNotes();
  }

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

  /// Refresh notes without showing loading state (for after mutations)
  Future<void> _refreshNotes() async {
    try {
      final notes = await _repository.getAllNotes();
      if (!isClosed) {
        emit(JournalLoaded(notes: notes));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(JournalError(message: 'Error refreshing notes: $e'));
      }
    }
  }

  /// Add a new note with automatic embedding generation
  /// Returns the ID of the created note
  Future<int?> addNote(String content) async {
    try {
      final noteId = await _repository.createNote(content);
      await _refreshNotes();
      return noteId;
    } on Object catch (e) {
      if (!isClosed) {
        emit(JournalError(message: 'Erreur: $e'));
      }
      return null;
    }
  }

  /// Delete a note by ID
  Future<void> deleteNote(int noteId) async {
    try {
      await _repository.deleteNote(noteId);
      await _refreshNotes();
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }

  /// Archive a note (soft delete)
  Future<void> archiveNote(int noteId) async {
    try {
      await _repository.archiveNote(noteId);
      await _refreshNotes();
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }

  /// Perform keyword search on notes
  Future<void> searchNotes(String query) async {
    try {
      if (query.isEmpty) {
        // Reset to all notes
        await loadNotes();
        return;
      }

      emit(const JournalLoading());
      final results = await _repository.keywordSearch(query);
      emit(JournalLoaded(notes: results));
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur de recherche: $e'));
    }
  }

  /// Clear all notes
  Future<void> clearAll() async {
    try {
      await _repository.clearAllNotes();
      emit(const JournalLoaded(notes: []));
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }

  /// Update an existing note's content
  Future<void> updateNote(NoteModel note) async {
    try {
      await _repository.updateNote(note.id, note.content);
      await _refreshNotes();
    } on Object catch (e) {
      emit(JournalError(message: 'Erreur: $e'));
    }
  }

  @override
  Future<void> close() async {
    await super.close();
  }
}
