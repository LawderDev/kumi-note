/// SQLite-based data source for chat message persistence.
library;

import 'dart:async';
import 'dart:convert';

import 'package:kumi_data_sources/src/models/models.dart';
import 'package:kumi_data_sources/src/services/sqlite_database.dart';

/// Exception for chat-specific database errors.
class ChatDataSourceException implements Exception {
  ChatDataSourceException(this.message, {this.originalError});
  final String message;
  final Object? originalError;

  @override
  String toString() {
    final err = originalError != null ? ' ($originalError)' : '';
    return 'ChatDataSourceException: $message$err';
  }
}

/// Data source for chat messages using SQLite.
class SqliteChatDataSource {
  SqliteChatDataSource({required SQLiteDatabase database})
    : _database = database;

  final SQLiteDatabase _database;
  final _messagesUpdateController =
      StreamController<List<ChatMessageModel>>.broadcast();
  bool _initialized = false;

  /// Initialize the data source.
  Future<void> initialize() async {
    if (_initialized) return;
    await _database.initialize();
    _initialized = true;
    _emitMessagesUpdate();
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'SqliteChatDataSource must be initialized by calling initialize()',
      );
    }
  }

  void _emitMessagesUpdate() {
    unawaited(
      Future.microtask(() async {
        final messages = await _fetchAllMessages();
        if (!_messagesUpdateController.isClosed) {
          _messagesUpdateController.add(messages);
        }
      }),
    );
  }

  /// Converts source_note_ids list to JSON string.
  String _sourceIdsToJson(List<int> ids) {
    return jsonEncode(ids);
  }

  /// Converts JSON string back to list of ints.
  List<int> _sourceIdsFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.cast<int>();
  }

  /// Watch chat message history reactively.
  Stream<List<ChatMessageModel>> watchChatHistory() {
    _checkInitialized();

    late StreamController<List<ChatMessageModel>> controller;
    StreamSubscription<List<ChatMessageModel>>? subscription;

    controller = StreamController<List<ChatMessageModel>>(
      onListen: () {
        unawaited(
          Future.microtask(() async {
            final messages = await _fetchAllMessages();
            if (!controller.isClosed) {
              controller.add(messages);
            }
          }),
        );

        subscription = _messagesUpdateController.stream.listen(
          (messages) {
            if (!controller.isClosed) {
              controller.add(messages);
            }
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        unawaited(subscription?.cancel());
      },
    );

    return controller.stream;
  }

  /// Fetches all messages sorted by timestamp.
  Future<List<ChatMessageModel>> _fetchAllMessages() async {
    _checkInitialized();

    final db = _database.db;

    final result = db.select('''
      SELECT id, text, is_user, timestamp, source_note_ids
      FROM chat_messages
      ORDER BY timestamp ASC
    ''');

    return result.map((row) {
      return ChatMessageModel(
        id: row['id'] as int,
        text: row['text'] as String,
        isUser: (row['is_user'] as int) == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        sourceNoteIds: _sourceIdsFromJson(row['source_note_ids'] as String?),
      );
    }).toList();
  }

  /// Retrieves all chat messages.
  Future<List<ChatMessageModel>> getAllMessages() async {
    return _fetchAllMessages();
  }

  /// Saves a chat message to the database.
  Future<int> saveChatMessage({
    required String text,
    required bool isUser,
    required DateTime timestamp,
    List<int> sourceNoteIds = const [],
  }) async {
    _checkInitialized();

    final db = _database.db;

    try {
      final stmt =
          db.prepare('''
        INSERT INTO chat_messages (text, is_user, timestamp, source_note_ids)
        VALUES (?, ?, ?, ?)
      ''')..execute([
            text,
            if (isUser) 1 else 0,
            timestamp.millisecondsSinceEpoch,
            _sourceIdsToJson(sourceNoteIds),
          ]);

      final id = db.lastInsertRowId;
      stmt.close();

      _emitMessagesUpdate();
      return id;
    } on Object catch (e) {
      throw ChatDataSourceException(
        'Failed to save chat message',
        originalError: e,
      );
    }
  }

  /// Gets a single chat message by ID.
  Future<ChatMessageModel?> getMessage(int id) async {
    _checkInitialized();

    final db = _database.db;

    final result = db.select(
      '''
      SELECT id, text, is_user, timestamp, source_note_ids
      FROM chat_messages
      WHERE id = ?
    ''',
      [id],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ChatMessageModel(
      id: row['id'] as int,
      text: row['text'] as String,
      isUser: (row['is_user'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      sourceNoteIds: _sourceIdsFromJson(row['source_note_ids'] as String?),
    );
  }

  /// Deletes a specific message by ID.
  Future<void> deleteMessage(int id) async {
    _checkInitialized();

    final db = _database.db;

    try {
      db.prepare('DELETE FROM chat_messages WHERE id = ?')
        ..execute([id])
        ..close();

      _emitMessagesUpdate();
    } on Object catch (e) {
      throw ChatDataSourceException(
        'Failed to delete message $id',
        originalError: e,
      );
    }
  }

  /// Clears all chat history from the database.
  Future<void> clearChatHistory() async {
    _checkInitialized();

    final db = _database.db;

    try {
      db.execute('DELETE FROM chat_messages');
      _emitMessagesUpdate();
    } on Object catch (e) {
      throw ChatDataSourceException(
        'Failed to clear chat history',
        originalError: e,
      );
    }
  }

  /// Closes the data source and cleans up resources.
  Future<void> close() async {
    await _messagesUpdateController.close();
  }
}
