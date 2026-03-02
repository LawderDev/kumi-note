import 'package:flutter/foundation.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';

/// RAG (Retrieval Augmented Generation) repository for Kumi Chat V2.
///
/// This repository orchestrates the complete RAG pipeline:
/// 1. Receives a user question
/// 2. Generates an embedding for the question using EmbeddingService
/// 3. Performs hybrid search (keyword + semantic) on notes
/// 4. Constructs a RAG prompt with the most relevant notes
/// 5. Streams the LLM response back to the caller
///
/// This ensures all responses are grounded in the user's local notes.
class KumiRepository {
  /// Creates a [KumiRepository] with required dependencies.
  KumiRepository({
    required SqliteNoteDataSource noteDataSource,
    required SqliteChatDataSource chatDataSource,
    required EmbeddingService embeddingService,
    required LLMService llmService,
  }) : _noteDataSource = noteDataSource,
       _chatDataSource = chatDataSource,
       _embeddingService = embeddingService,
       _llmService = llmService;

  final SqliteNoteDataSource _noteDataSource;
  final SqliteChatDataSource _chatDataSource;
  final EmbeddingService _embeddingService;
  final LLMService _llmService;

  /// Watches all non-archived notes reactively.
  /// UI rebuilds automatically when notes change.
  Stream<List<NoteModel>> watchNotes() {
    return _noteDataSource.watchNotes();
  }

  /// Gets all non-archived notes.
  Future<List<NoteModel>> getAllNotes() async {
    return _noteDataSource.getAllNotesForVectorSearch();
  }

  /// Watches chat history reactively.
  Stream<List<ChatMessageModel>> watchChatHistory() {
    return _chatDataSource.watchChatHistory();
  }

  /// Performs keyword search on note content.
  /// Returns notes containing the query string (case-insensitive).
  Future<List<NoteModel>> keywordSearch(String query) async {
    return _noteDataSource.keywordSearch(query);
  }

  /// Performs semantic search using vector similarity.
  /// Returns top 5 notes most similar to the query.
  Future<List<SearchResult>> semanticSearch(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Generate embedding for the query
      final queryEmbedding = await _embeddingService.generateEmbedding(query);

      // Perform vector search using sqlite_vector
      return _noteDataSource.semanticSearch(
        queryEmbedding: queryEmbedding,
      );
    } on Object catch (e) {
      debugPrint('Error in semantic search: $e');
      return [];
    }
  }

  /// Performs semantic search with pre-generated embedding.
  /// More efficient when embedding is already available.
  Future<List<SearchResult>> semanticSearchWithEmbedding(
    List<double> queryEmbedding, {
    int topK = 5,
    double minSimilarity = 0.5,
  }) async {
    if (queryEmbedding.isEmpty) {
      return [];
    }

    try {
      return _noteDataSource.semanticSearch(
        queryEmbedding: queryEmbedding,
        topK: topK,
        minSimilarity: minSimilarity,
      );
    } on Object catch (e) {
      debugPrint('Error in semantic search with embedding: $e');
      return [];
    }
  }

  /// Performs hybrid search (keyword + semantic).
  /// Returns a combined, de-duplicated list with semantic results first.
  Future<List<NoteModel>> hybridSearch(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Perform both searches in parallel
      final keywordResultsFuture = _noteDataSource.keywordSearch(query);
      final semanticResultsFuture = semanticSearch(query);

      final keywordList = await keywordResultsFuture;
      final semanticList = await semanticResultsFuture;

      // De-duplicate: semantic results first (more relevant),
      // then keyword-only results
      final resultIds = <int>{};
      final combinedResults = <NoteModel>[];

      for (final result in semanticList) {
        if (resultIds.add(result.note.id)) {
          combinedResults.add(result.note);
        }
      }

      for (final note in keywordList) {
        if (resultIds.add(note.id)) {
          combinedResults.add(note);
        }
      }

      return combinedResults;
    } on Object catch (e) {
      debugPrint('Error in hybrid search: $e');
      return [];
    }
  }

  /// Creates a new note with automatic embedding generation.
  /// Returns the ID of the created note.
  Future<int> createNote(String content) async {
    if (content.isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }

    try {
      // Generate embedding for the note content
      final embedding = await _embeddingService.generateEmbedding(content);

      // Save to database (no conversion needed - already List<double>)
      return _noteDataSource.createNote(
        content: content,
        embedding: embedding,
        createdAt: DateTime.now(),
      );
    } on Object catch (e) {
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  /// Updates an existing note and regenerates its embedding.
  Future<void> updateNote(int id, String newContent) async {
    if (newContent.isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }

    try {
      // Generate new embedding
      final embedding = await _embeddingService.generateEmbedding(newContent);

      // Update in database
      return _noteDataSource.updateNote(
        id,
        content: newContent,
        embedding: embedding,
      );
    } on Object catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  /// Archives (soft deletes) a note.
  Future<void> archiveNote(int id) async {
    return _noteDataSource.archiveNote(id);
  }

  /// Permanently deletes a note.
  Future<void> deleteNote(int id) async {
    return _noteDataSource.deleteNote(id);
  }

  /// Gets a single note by ID.
  Future<NoteModel?> getNote(int id) async {
    return _noteDataSource.getNote(id);
  }

  /// Processes a user question and returns a RAG-augmented response.
  ///
  /// This method:
  /// 1. Embeds the user's question
  /// 2. Performs semantic search for relevant notes
  /// 3. Constructs a RAG prompt with context
  /// 4. Streams the LLM response
  /// 5. Saves both question and response to chat history
  ///
  /// Returns a stream of response tokens for real-time UI updates.
  Stream<String> askKumi(String question) async* {
    if (question.trim().isEmpty) {
      yield "Hmm, tu n'as rien écrit! Dis-moi quelque chose 🐕";
      return;
    }

    try {
      // Step 1: Perform hybrid search (keyword + semantic) for relevant notes
      debugPrint('askKumi: Starting hybrid search for: $question');
      final relevantNotes = await hybridSearch(question);
      debugPrint('askKumi: Found ${relevantNotes.length} relevant notes');

      // Step 2: Build the RAG prompt
      final prompt = _buildRagPrompt(question, relevantNotes);
      debugPrint('askKumi: Built prompt, length: ${prompt.length}');

      // Step 3: Stream the LLM response
      final responseBuffer = StringBuffer();
      await for (final token in _llmService.generateResponse(prompt)) {
        responseBuffer.write(token);
        yield token;
      }
      debugPrint(
        'askKumi: Completed, response: ${responseBuffer.toString().substring(0, responseBuffer.length > 50 ? 50 : responseBuffer.length)}...',
      );

      // Step 4: Save chat messages to history
      final sourceNoteIds = relevantNotes
          .map((note) => note.id)
          .toList()
          .cast<int>();
      await _chatDataSource.saveChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
        sourceNoteIds: sourceNoteIds,
      );

      await _chatDataSource.saveChatMessage(
        text: responseBuffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
        sourceNoteIds: sourceNoteIds,
      );
    } on Object catch (e) {
      debugPrint('Error in askKumi: $e');
      yield 'Désolé, une erreur est survenue. Réessaye plus tard!';
    }
  }

  /// Builds the RAG prompt with context from relevant notes.
  String _buildRagPrompt(String question, List<NoteModel> relevantNotes) {
    if (relevantNotes.isEmpty) {
      return '''
Je ne trouve pas d'informations pertinentes dans tes notes.

Question: $question

RÈGLES:
- Dis que tu n'as pas trouvé d'informations dans les notes
- Suggère d'ajouter des notes sur ce sujet
- Réponds en 1-2 phrases courtes

Réponse:''';
    }

    final notesContext = relevantNotes
        .map((e) => '[${e.id}] ${e.content}')
        .join('\n');

    return '''
Voici les informations pertinentes de tes notes:

$notesContext

Question: $question

RÈGLES STRICTES:
- Réponds UNIQUEMENT avec les infos ci-dessus
- N'utilise AUCUNE connaissance générale
- Si l'info n'est pas dans les notes, dis: "Je ne trouve pas cette info dans tes notes"
- Réponds en 1-2 phrases courtes
- Utilise les références [ID] pour les notes utilisées (ex: [3], [7])

Réponse:''';
  }

  /// Gets statistics about stored notes for analytics.
  Future<Map<String, dynamic>> getStats() async {
    return _noteDataSource.getStats();
  }

  /// Clears all chat history.
  Future<void> clearChatHistory() async {
    return _chatDataSource.clearChatHistory();
  }

  /// Clears all notes from the database.
  Future<void> clearAllNotes() async {
    return _noteDataSource.clearAllNotes();
  }

  /// Closes all services and cleans up resources.
  Future<void> close() async {
    await _noteDataSource.close();
    await _chatDataSource.close();
    await _embeddingService.close();
    await _llmService.close();
  }
}
