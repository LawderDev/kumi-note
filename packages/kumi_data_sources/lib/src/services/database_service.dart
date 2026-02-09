import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/note_model.dart';

/// Database service for managing Kumi's local note storage and vector embeddings.
///
/// This service implements the Singleton pattern and handles:
/// - Initialization of SQLite database
/// - Storage and retrieval of notes with embeddings
/// - Semantic similarity search using vector embeddings
class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  late Database _db;
  bool _initialized = false;

  /// Initialize the database. Must be called once before using any other methods.
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dir.path, 'kumi_chat.db');

    _db = sqlite3.open(dbPath);
    _createTables();
    _initialized = true;
  }

  /// Ensures the database is initialized before operations.
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'DatabaseService must be initialized by calling initialize()',
      );
    }
  }

  /// Creates necessary tables for notes and embeddings.
  void _createTables() {
    // Table for storing notes with their metadata
    _db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        embedding BLOB NOT NULL
      )
    ''');

    // Index on created_at for efficient queries
    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_created_at ON notes(created_at DESC)
    ''');
  }

  /// Stores a note in the database.
  Future<void> saveNote(NoteModel note) async {
    _checkInitialized();

    final stmt = _db.prepare(
      '''
      INSERT OR REPLACE INTO notes (id, content, created_at, embedding)
      VALUES (?, ?, ?, ?)
      ''',
    );

    try {
      stmt.execute([
        note.id,
        note.content,
        note.createdAt.millisecondsSinceEpoch,
        _vectorToBlob(note.embedding),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Saves multiple notes in a single transaction.
  Future<void> saveNotes(List<NoteModel> notes) async {
    _checkInitialized();

    _db.execute('BEGIN TRANSACTION');
    try {
      for (final note in notes) {
        await saveNote(note);
      }
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Retrieves a note by ID.
  Future<NoteModel?> getNote(String id) async {
    _checkInitialized();

    final result = _db.select(
      'SELECT id, content, created_at, embedding FROM notes WHERE id = ?',
      [id],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return NoteModel(
      id: row['id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      embedding: _blobToVector(row['embedding'] as Uint8List),
    );
  }

  /// Retrieves all notes in the database.
  Future<List<NoteModel>> getAllNotes() async {
    _checkInitialized();

    final results = _db.select(
      'SELECT id, content, created_at, embedding FROM notes ORDER BY created_at DESC',
    );

    return [
      for (final row in results)
        NoteModel(
          id: row['id'] as String,
          content: row['content'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),
          embedding: _blobToVector(row['embedding'] as Uint8List),
        ),
    ];
  }

  /// Retrieves the N most recent notes efficiently.
  /// Uses indexed query on created_at for optimal performance.
  /// Default limit of 1000 handles years of daily notes while keeping memory low.
  Future<List<NoteModel>> getRecentNotes({int limit = 1000}) async {
    _checkInitialized();

    final stmt = _db.prepare(
      'SELECT id, content, created_at, embedding FROM notes ORDER BY created_at DESC LIMIT ?',
    );

    try {
      final results = stmt.select([limit]);
      return [
        for (final row in results)
          NoteModel(
            id: row['id'] as String,
            content: row['content'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
            embedding: _blobToVector(row['embedding'] as Uint8List),
          ),
      ];
    } finally {
      stmt.dispose();
    }
  }

  /// Searches for similar notes using vector similarity (cosine similarity).
  ///
  /// Optimized for performance:
  /// - Only searches recent notes (default 1000) using indexed query
  /// - Filters by minimum similarity threshold to exclude irrelevant results
  /// - Returns up to [limit] most similar notes above [minSimilarity]
  ///
  /// Parameters:
  /// - [queryVector]: The embedding vector to search for
  /// - [limit]: Maximum number of results to return (default 10)
  /// - [minSimilarity]: Minimum cosine similarity score 0-1 (default 0.5)
  /// - [searchWindow]: Number of recent notes to search (default 1000)
  ///
  /// Performance: O(n) where n = searchWindow, typically <50ms for 1000 notes
  Future<List<NoteModel>> searchSimilar(
    List<double> queryVector, {
    int limit = 10,
    double minSimilarity = 0.5,
    int searchWindow = 1000,
  }) async {
    _checkInitialized();

    if (queryVector.isEmpty) return [];

    // Only search recent notes for performance (uses indexed query)
    final recentNotes = await getRecentNotes(limit: searchWindow);
    if (recentNotes.isEmpty) return [];

    // Calculate cosine similarity and filter by threshold
    final scores = <(NoteModel, double)>[];
    for (final note in recentNotes) {
      final similarity = _cosineSimilarity(queryVector, note.embedding);

      // Only keep notes above similarity threshold
      if (similarity >= minSimilarity) {
        scores.add((note, similarity));
      }
    }

    // Sort by similarity (descending) and return top N
    scores.sort((a, b) => b.$2.compareTo(a.$2));
    return scores.take(limit).map((e) => e.$1).toList();
  }

  /// Deletes a note by ID.
  Future<void> deleteNote(String id) async {
    _checkInitialized();

    final stmt = _db.prepare('DELETE FROM notes WHERE id = ?');
    try {
      stmt.execute([id]);
    } finally {
      stmt.dispose();
    }
  }

  /// Clears all notes from the database.
  Future<void> clearAllNotes() async {
    _checkInitialized();
    _db.execute('DELETE FROM notes');
  }

  /// Calculates cosine similarity between two vectors.
  /// Higher similarity (closer to 1.0) = more similar vectors
  /// Returns value between -1 and 1, where 1 = identical direction
  double _cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }

    final magnitude = math.sqrt(norm1) * math.sqrt(norm2);
    if (magnitude == 0) return 0.0;

    return dotProduct / magnitude;
  }

  /// Converts a vector (List<double>) to a BLOB for storage.
  /// Uses IEEE 754 double precision binary format.
  Uint8List _vectorToBlob(List<double> vector) {
    final bytes = Uint8List(vector.length * 8);
    for (int i = 0; i < vector.length; i++) {
      bytes.buffer.asByteData().setFloat64(i * 8, vector[i], Endian.little);
    }
    return bytes;
  }

  /// Converts a BLOB back to a vector (List<double>).
  List<double> _blobToVector(Uint8List blob) {
    final vector = <double>[];
    for (int i = 0; i < blob.length; i += 8) {
      final value = blob.buffer.asByteData().getFloat64(i, Endian.little);
      vector.add(value);
    }
    return vector;
  }

  /// Gets statistics about stored notes for Insights page.
  Future<Map<String, dynamic>> getStats() async {
    _checkInitialized();

    final allNotes = await getAllNotes();
    if (allNotes.isEmpty) {
      return {
        'totalNotes': 0,
        'avgNotesPerDay': 0.0,
        'oldestNote': null,
        'newestNote': null,
        'notesLast7Days': <DateTime, int>{},
      };
    }

    allNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final oldest = allNotes.first.createdAt;
    final newest = allNotes.last.createdAt;

    final daysDiff = newest.difference(oldest).inDays + 1;
    final avgPerDay = allNotes.length / daysDiff;

    // Calculate notes per day for last 7 days
    final now = DateTime.now();
    final notesLast7Days = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      notesLast7Days[date] = 0;
    }

    for (final note in allNotes) {
      final noteDate = DateTime(
        note.createdAt.year,
        note.createdAt.month,
        note.createdAt.day,
      );
      if (notesLast7Days.containsKey(noteDate)) {
        notesLast7Days[noteDate] = notesLast7Days[noteDate]! + 1;
      }
    }

    return {
      'totalNotes': allNotes.length,
      'avgNotesPerDay': avgPerDay,
      'oldestNote': oldest,
      'newestNote': newest,
      'notesLast7Days': notesLast7Days,
    };
  }

  /// Closes the database connection. Call this during app shutdown.
  Future<void> close() async {
    _checkInitialized();
    _db.dispose();
    _initialized = false;
  }
}
