import 'package:equatable/equatable.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:uuid/uuid.dart';

/// RAG (Retrieval Augmented Generation) repository for Kumi Chat.
///
/// This repository orchestrates the complete RAG pipeline:
/// 1. Receives a user question
/// 2. Generates an embedding for the question using AiService
/// 3. Searches for similar notes in the database using DatabaseService
/// 4. Constructs a system prompt with the most relevant notes
/// 5. Streams the LLM response back to the caller
///
/// This ensures all responses are grounded in the user's local notes.
class KumiRepository extends Equatable {
  /// Creates a [KumiRepository] with required dependencies.
  KumiRepository({
    required DatabaseService databaseService,
    required AiService aiService,
  }) : _databaseService = databaseService,
       _aiService = aiService;

  final DatabaseService _databaseService;
  final AiService _aiService;

  static const _uuid = Uuid();

  /// Processes a user chat message and returns the complete RAG-augmented response.
  ///
  /// This method:
  /// 1. Embeds the user's message to get a vector representation
  /// 2. Searches for the 3 most similar notes from the database
  /// 3. Builds a system prompt that includes the relevant notes
  /// 4. Streams the LLM response with embedded sources
  ///
  /// Returns a stream of [ChatMessageModel] containing the generated response
  /// and source notes that were used.
  Stream<ChatMessageModel> chatWithRag(String userMessage) async* {
    try {
      // Step 1: Validate input
      if (userMessage.trim().isEmpty) {
        yield ChatMessageModel(
          id: _uuid.v4(),
          text: 'Hmm, tu n\'as rien écrit! Dis-moi quelque chose 🐕',
          isUser: false,
          timestamp: DateTime.now(),
          sources: const [],
        );
        return;
      }

      // Step 2: Generate embedding for the user's message (in Isolate)
      final questionEmbedding = await _aiService.embedText(userMessage);

      // Step 3: Search for similar notes with optimized parameters
      // - Searches up to 1000 recent notes (covers years of daily notes)
      // - Filters by 0.6 similarity threshold (only highly relevant notes)
      // - Returns up to 5 most relevant notes (optimal for llama3.2:3b)
      final similarNotes = await _databaseService.searchSimilar(
        questionEmbedding,
        limit: 5,
        minSimilarity: 0.6,
        searchWindow: 1000,
      );

      // Step 4: Build the prompt with context
      final notesContext = _formatNotesForPrompt(similarNotes);

      // Build a single user message with context and question
      final fullPrompt = notesContext.isEmpty
          ? 'Question: $userMessage\n\nRéponds: Je ne trouve pas cette info dans tes notes.'
          : '''Voici TOUTES les informations disponibles:
$notesContext

Question: $userMessage

RÈGLES STRICTES:
- Réponds UNIQUEMENT avec les infos ci-dessus
- N'utilise AUCUNE connaissance générale
- Si l'info n'est pas dans les notes, dis: "Je ne trouve pas cette info dans tes notes"
- Réponds en 1 phrase courte

Réponse:''';

      // Step 5: Stream the LLM response with a single user message
      final messages = [
        {'role': 'user', 'content': fullPrompt},
      ];

      final responseBuffer = StringBuffer();
      await for (final token in _aiService.streamResponse(messages)) {
        responseBuffer.write(token);

        // Yield the message as it streams in
        yield ChatMessageModel(
          id: _uuid.v4(),
          text: responseBuffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          sources: similarNotes,
        );
      }
    } catch (e) {
      // Handle errors gracefully
      yield ChatMessageModel(
        id: _uuid.v4(),
        text:
            'Oups! Une erreur s\'est produite. Réessaye plus tard. (Erreur: $e)',
        isUser: false,
        timestamp: DateTime.now(),
        sources: const [],
      );
    }
  }

  /// Formats notes into a readable context string for the prompt.
  String _formatNotesForPrompt(List<NoteModel> notes) {
    if (notes.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < notes.length; i++) {
      buffer.writeln('${i + 1}. ${notes[i].content}');
    }
    return buffer.toString().trim();
  }

  /// Stores a new note in the database for future RAG augmentation.
  Future<void> addNote(String content) async {
    try {
      // Generate embedding for the note
      final embedding = await _aiService.embedText(content);

      // Create and save note model
      final note = NoteModel(
        id: _uuid.v4(),
        content: content,
        createdAt: DateTime.now(),
        embedding: embedding,
      );

      await _databaseService.saveNote(note);
    } catch (e) {
      throw KumiRepositoryException('Failed to save note: $e');
    }
  }

  /// Retrieves all stored notes.
  Future<List<NoteModel>> getAllNotes() async {
    try {
      return await _databaseService.getAllNotes();
    } catch (e) {
      throw KumiRepositoryException('Failed to retrieve notes: $e');
    }
  }

  /// Deletes a note by ID.
  Future<void> deleteNote(String noteId) async {
    try {
      await _databaseService.deleteNote(noteId);
    } catch (e) {
      throw KumiRepositoryException('Failed to delete note: $e');
    }
  }

  /// Clears all notes from the database.
  Future<void> clearAllNotes() async {
    try {
      await _databaseService.clearAllNotes();
    } catch (e) {
      throw KumiRepositoryException('Failed to clear notes: $e');
    }
  }

  /// Checks if Ollama server is available and returns health status.
  Future<Map<String, dynamic>> getHealth() async {
    try {
      return await _aiService.checkHealth();
    } catch (e) {
      return {
        'isAvailable': false,
        'models': <String>[],
        'error': e.toString(),
      };
    }
  }

  /// Gets statistics about stored notes for Insights page.
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _databaseService.getStats();
    } catch (e) {
      throw KumiRepositoryException('Failed to get stats: $e');
    }
  }

  @override
  List<Object?> get props => [_databaseService, _aiService];
}

/// Exception thrown by repository operations.
class KumiRepositoryException implements Exception {
  KumiRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'KumiRepositoryException: $message';
}
