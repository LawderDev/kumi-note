/// SQLite-based data source for note operations with vector search.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:kumi_data_sources/src/models/models.dart';
import 'package:kumi_data_sources/src/services/sqlite_database.dart';

/// Exception for note-specific database errors.
class NoteDataSourceException implements Exception {
  NoteDataSourceException(this.message, {this.originalError});
  final String message;
  final Object? originalError;

  @override
  String toString() {
    final err = originalError != null ? ' ($originalError)' : '';
    return 'NoteDataSourceException: $message$err';
  }
}

/// Data source for notes using SQLite with vector search capabilities.
class SqliteNoteDataSource {
  SqliteNoteDataSource({required SQLiteDatabase database})
    : _database = database;

  final SQLiteDatabase _database;
  final _notesUpdateController = StreamController<List<NoteModel>>.broadcast();
  bool _initialized = false;

  /// Initialize the data source.
  Future<void> initialize() async {
    if (_initialized) return;
    await _database.initialize();
    _initialized = true;
    _emitNotesUpdate();
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'SqliteNoteDataSource must be initialized by calling initialize()',
      );
    }
  }

  void _emitNotesUpdate() {
    unawaited(
      Future(() async {
        try {
          if (!_notesUpdateController.isClosed) {
            final notes = await _fetchAllNotes();
            if (!_notesUpdateController.isClosed) {
              _notesUpdateController.add(notes);
            }
          }
        } on Object {
          // Ignore errors during emit
        }
      }),
    );
  }

  String _embeddingToJson(List<double> embedding) {
    return jsonEncode(embedding);
  }

  List<double> _embeddingFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list.cast<double>();
  }

  Stream<List<NoteModel>> watchNotes({bool includeArchived = false}) {
    _checkInitialized();

    return Stream.multi(
      (controller) async {
        final notes = await _fetchNotes(includeArchived: includeArchived);
        controller.add(notes);
      },
      isBroadcast: true,
    );
  }

  Future<List<NoteModel>> _fetchAllNotes() async {
    return _fetchNotes(includeArchived: true);
  }

  Future<List<NoteModel>> _fetchNotes({required bool includeArchived}) async {
    _checkInitialized();

    final db = _database.db;
    final whereClause = includeArchived ? '' : 'WHERE n.is_archived = 0';

    final result = db.select('''
      SELECT n.id, n.content, n.created_at, n.updated_at, n.is_archived,
             e.embedding
      FROM notes n
      LEFT JOIN note_embeddings e ON n.id = e.note_id
      $whereClause
      ORDER BY n.created_at DESC
    ''');

    return result.map((row) {
      final embeddingJson = row['embedding'] as String? ?? '[]';
      return NoteModel(
        id: row['id'] as int,
        content: row['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: row['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int)
            : null,
        isArchived: (row['is_archived'] as int) == 1,
        embedding: _embeddingFromJson(embeddingJson),
      );
    }).toList();
  }

  Future<int> createNote({
    required String content,
    required List<double> embedding,
    DateTime? createdAt,
  }) async {
    _checkInitialized();

    final db = _database.db;
    final now = createdAt ?? DateTime.now();

    try {
      final noteId = _database.transaction(() {
        final noteStmt = db.prepare('''
          INSERT INTO notes (content, created_at, is_archived)
          VALUES (?, ?, 0)
        ''')..execute([content, now.millisecondsSinceEpoch]);
        final id = db.lastInsertRowId;
        noteStmt.close();

        final embeddingJson = _embeddingToJson(embedding);

        if (_database.isVectorEnabled) {
          db.prepare('''
            INSERT INTO note_embeddings (note_id, embedding)
            VALUES (?, vector_as_f32(?))
          ''')
            ..execute([id, embeddingJson])
            ..close();
        } else {
          db.prepare('''
            INSERT INTO note_embeddings (note_id, embedding)
            VALUES (?, ?)
          ''')
            ..execute([id, embeddingJson])
            ..close();
        }

        return id;
      });

      _emitNotesUpdate();
      return noteId;
    } on Object catch (e) {
      throw NoteDataSourceException('Failed to create note', originalError: e);
    }
  }

  Future<void> updateNote(
    int id, {
    String? content,
    List<double>? embedding,
  }) async {
    _checkInitialized();

    final db = _database.db;

    try {
      await _database.transaction(() {
        final now = DateTime.now();

        if (content != null) {
          db.prepare('''
            UPDATE notes
            SET content = ?, updated_at = ?
            WHERE id = ?
          ''')
            ..execute([content, now.millisecondsSinceEpoch, id])
            ..close();
        }

        if (embedding != null) {
          final embeddingJson = _embeddingToJson(embedding);
          db.prepare('''
            UPDATE note_embeddings
            SET embedding = ?
            WHERE note_id = ?
          ''')
            ..execute([embeddingJson, id])
            ..close();
        }
      });

      _emitNotesUpdate();
    } on Object catch (e) {
      throw NoteDataSourceException(
        'Failed to update note $id',
        originalError: e,
      );
    }
  }

  Future<void> archiveNote(int id) async {
    _checkInitialized();

    final db = _database.db;

    try {
      db.prepare('''
        UPDATE notes
        SET is_archived = 1, updated_at = ?
        WHERE id = ?
      ''')
        ..execute([DateTime.now().millisecondsSinceEpoch, id])
        ..close();

      _emitNotesUpdate();
    } on Object catch (e) {
      throw NoteDataSourceException(
        'Failed to archive note $id',
        originalError: e,
      );
    }
  }

  Future<void> deleteNote(int id) async {
    _checkInitialized();

    final db = _database.db;

    try {
      db.prepare('DELETE FROM notes WHERE id = ?')
        ..execute([id])
        ..close();

      _emitNotesUpdate();
    } on Object catch (e) {
      throw NoteDataSourceException(
        'Failed to delete note $id',
        originalError: e,
      );
    }
  }

  Future<NoteModel?> getNote(int id) async {
    _checkInitialized();

    final db = _database.db;

    final result = db.select(
      '''
      SELECT n.id, n.content, n.created_at, n.updated_at, n.is_archived,
             e.embedding
      FROM notes n
      LEFT JOIN note_embeddings e ON n.id = e.note_id
      WHERE n.id = ?
    ''',
      [id],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final embeddingJson = row['embedding'] as String? ?? '[]';

    return NoteModel(
      id: row['id'] as int,
      content: row['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      updatedAt: row['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int)
          : null,
      isArchived: (row['is_archived'] as int) == 1,
      embedding: _embeddingFromJson(embeddingJson),
    );
  }

  Future<List<NoteModel>> keywordSearch(String query) async {
    _checkInitialized();

    if (query.isEmpty) {
      return _fetchNotes(includeArchived: false);
    }

    final db = _database.db;

    // Split query into words and match any of them (OR logic)
    final words = query
        .toLowerCase()
        .replaceAll(RegExp('[^a-zà-ÿ0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    if (words.isEmpty) {
      return _fetchNotes(includeArchived: false);
    }

    // Build OR conditions for each word
    final conditions = words.map((w) => "LOWER(n.content) LIKE ?").join(' OR ');
    final params = words.map((w) => '%$w%').toList();

    final result = db.select(
      '''
      SELECT n.id, n.content, n.created_at, n.updated_at, n.is_archived,
             e.embedding
      FROM notes n
      LEFT JOIN note_embeddings e ON n.id = e.note_id
      WHERE n.is_archived = 0 AND ($conditions)
      ORDER BY n.created_at DESC
      ''',
      params,
    );

    log(
      'keywordSearch: query="$query", words=$words, found ${result.length} notes',
    );
    if (result.isNotEmpty) {
      for (final row in result) {
        final content = row['content'] as String;
        log(
          '  - Note ${row['id']}: ${content.substring(0, content.length > 30 ? 30 : content.length)}...',
        );
      }
    }

    return result.map((row) {
      final embeddingJson = row['embedding'] as String? ?? '[]';
      return NoteModel(
        id: row['id'] as int,
        content: row['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: row['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int)
            : null,
        isArchived: (row['is_archived'] as int) == 1,
        embedding: _embeddingFromJson(embeddingJson),
      );
    }).toList();
  }

  Future<List<SearchResult>> semanticSearch({
    required List<double> queryEmbedding,
    int topK = 5,
    double minSimilarity = 0.5,
  }) async {
    _checkInitialized();

    if (queryEmbedding.isEmpty) {
      return [];
    }

    if (!_database.isVectorEnabled) {
      log('semanticSearch: vector extension not available, skipping');
      return [];
    }

    final db = _database.db;

    try {
      final queryJson = _embeddingToJson(queryEmbedding);

      final result = db.select(
        '''
        SELECT
          n.id,
          n.content,
          n.created_at,
          n.updated_at,
          n.is_archived,
          v.distance
        FROM note_embeddings AS e
        JOIN vector_full_scan(
          'note_embeddings',
          'embedding',
          vector_as_f32(?),
          ?
        ) AS v
        ON e.note_id = v.rowid
        JOIN notes n ON n.id = e.note_id
        WHERE n.is_archived = 0
        ORDER BY v.distance ASC
      ''',
        [queryJson, topK * 2],
      );

      return result
          .map((row) {
            final distance = row['distance'] as double;
            final similarity = 1.0 - distance;

            if (similarity < minSimilarity) {
              return null;
            }

            final note = NoteModel(
              id: row['id'] as int,
              content: row['content'] as String,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                row['created_at'] as int,
              ),
              updatedAt: row['updated_at'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      row['updated_at'] as int,
                    )
                  : null,
              isArchived: (row['is_archived'] as int) == 1,
              embedding: const [],
            );

            return SearchResult(note: note, similarity: similarity);
          })
          .whereType<SearchResult>()
          .toList();
    } on Object catch (e) {
      log('Vector search error: $e');
      return [];
    }
  }

  Future<List<NoteModel>> getAllNotesForVectorSearch() async {
    _checkInitialized();
    return _fetchNotes(includeArchived: false);
  }

  Future<void> clearAllNotes() async {
    _checkInitialized();

    final db = _database.db;

    try {
      await _database.transaction(() {
        db.execute('DELETE FROM notes');
      });

      _emitNotesUpdate();
    } on Object catch (e) {
      throw NoteDataSourceException(
        'Failed to clear all notes',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    _checkInitialized();

    final db = _database.db;

    final countResult = db.select(
      'SELECT COUNT(*) as count FROM notes WHERE is_archived = 0',
    );

    final totalNotes = countResult.first['count'] as int;

    if (totalNotes == 0) {
      return {
        'totalNotes': 0,
        'avgNotesPerDay': 0.0,
        'oldestNote': null,
        'newestNote': null,
        'notesLast7Days': <DateTime, int>{},
      };
    }

    final dateResult = db.select('''
      SELECT MIN(created_at) as oldest, MAX(created_at) as newest
      FROM notes WHERE is_archived = 0
    ''');

    final oldest = DateTime.fromMillisecondsSinceEpoch(
      dateResult.first['oldest'] as int,
    );
    final newest = DateTime.fromMillisecondsSinceEpoch(
      dateResult.first['newest'] as int,
    );

    final daysDiff = newest.difference(oldest).inDays + 1;
    final avgPerDay = totalNotes / daysDiff;

    final now = DateTime.now();
    final notesLast7Days = <DateTime, int>{};

    for (var i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      notesLast7Days[date] = 0;
    }

    final weekResult = db.select(
      '''
      SELECT created_at FROM notes
      WHERE is_archived = 0
      AND created_at >= ?
    ''',
      [now.subtract(const Duration(days: 7)).millisecondsSinceEpoch],
    );

    for (final row in weekResult) {
      final noteDate = DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      );
      final normalizedDate = DateTime(
        noteDate.year,
        noteDate.month,
        noteDate.day,
      );
      if (notesLast7Days.containsKey(normalizedDate)) {
        notesLast7Days[normalizedDate] = notesLast7Days[normalizedDate]! + 1;
      }
    }

    return {
      'totalNotes': totalNotes,
      'avgNotesPerDay': avgPerDay,
      'oldestNote': oldest,
      'newestNote': newest,
      'notesLast7Days': notesLast7Days,
    };
  }

  Future<void> close() async {
    await _notesUpdateController.close();
  }
}

class SearchResult {
  SearchResult({
    required this.note,
    required this.similarity,
  });

  final NoteModel note;
  final double similarity;

  @override
  String toString() => 'SearchResult(id: ${note.id}, similarity: $similarity)';
}
