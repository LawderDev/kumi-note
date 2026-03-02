/// SQLite Database initialization with vector extension support.
library;

import 'dart:developer';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vector/sqlite_vector.dart';

/// Exception thrown when database operations fail.
class DatabaseException implements Exception {
  DatabaseException(this.message, {this.originalError});
  final String message;
  final Object? originalError;

  @override
  String toString() {
    final err = originalError != null ? ' ($originalError)' : '';
    return 'DatabaseException: $message$err';
  }
}

/// Manages SQLite database connection with vector extension.
///
/// Handles:
/// - Database file creation in appropriate Android directories
/// - sqlite_vector extension loading
/// - Schema initialization
/// - Proper resource cleanup
class SQLiteDatabase {
  SQLiteDatabase._();
  static final SQLiteDatabase _instance = SQLiteDatabase._();
  static SQLiteDatabase get instance => _instance;

  Database? _db;
  bool _initialized = false;
  bool _vectorEnabled = false;

  /// Whether vector search is available
  bool get isVectorEnabled => _vectorEnabled;

  /// Gets the database connection. Must call initialize() first.
  Database get db {
    if (!_initialized || _db == null) {
      throw StateError(
        'SQLiteDatabase must be initialized by calling initialize()',
      );
    }
    return _db!;
  }

  /// Initializes the database:
  /// 1. Loads sqlite_vector extension
  /// 2. Opens database file in Android app directory
  /// 3. Creates schema if not exists
  /// 4. Initializes vector index
  Future<void> initialize({int embeddingDimensions = 384}) async {
    if (_initialized) return;

    try {
      // Get Android app documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docsDir.path, 'kumi_note.db');

      // Open database
      _db = sqlite3.open(dbPath);

      // Try to load sqlite_vector extension
      try {
        sqlite3.loadSqliteVectorExtension();
        _vectorEnabled = true;
        log('sqlite_vector extension loaded successfully');
      } on Object catch (e) {
        log('Warning: Failed to load sqlite_vector extension: $e');
        _vectorEnabled = false;
      }

      // Create schema
      _createSchema(embeddingDimensions);

      _initialized = true;
    } on Object catch (e) {
      throw DatabaseException(
        'Failed to initialize database',
        originalError: e,
      );
    }
  }

  /// Creates database tables and vector index.
  void _createSchema(int embeddingDimensions) {
    if (_db == null) return;

    // Main notes table
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        is_archived INTEGER DEFAULT 0
      )
    ''');

    // Notes table for vector storage (separate table for embeddings)
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS note_embeddings (
        note_id INTEGER PRIMARY KEY,
        embedding BLOB,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Chat messages table
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        source_note_ids TEXT
      )
    ''');

    // Create indexes for performance
    _db!.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_created
      ON notes(created_at DESC)
    ''');
    _db!.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_archived
      ON notes(is_archived)
    ''');
    _db!.execute('''
      CREATE INDEX IF NOT EXISTS idx_chat_timestamp
      ON chat_messages(timestamp)
    ''');

    // Initialize vector index if extension is loaded
    if (_vectorEnabled) {
      try {
        _db!.execute('''
          SELECT vector_init('note_embeddings', 'embedding',
            'type=FLOAT32,dimension=$embeddingDimensions')
        ''');
      } on Object catch (e) {
        log('Warning: Failed to initialize vector index: $e');
        _vectorEnabled = false;
      }
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_db != null) {
      _db!.close();
      _db = null;
      _initialized = false;
    }
  }

  /// Executes a transaction with automatic rollback on error.
  Future<T> transaction<T>(T Function() action) async {
    if (_db == null) {
      throw StateError('Database not initialized');
    }

    try {
      _db!.execute('BEGIN TRANSACTION');
      final result = action();
      _db!.execute('COMMIT');
      return result;
    } on Object {
      _db!.execute('ROLLBACK');
      rethrow;
    }
  }
}
