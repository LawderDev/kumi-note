import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';

part 'chat_state.dart';

/// Cubit for managing the chat UI state.
///
/// This cubit handles:
/// - Maintaining the list of chat messages from database
/// - Processing user messages through the RAG pipeline
/// - Managing loading states during AI response generation
/// - Streaming token-by-token responses
/// - Persisting chat history to SQLite
class ChatCubit extends Cubit<ChatState> {
  /// Creates a [ChatCubit] with required dependencies.
  ChatCubit({
    required KumiRepository kumiRepository,
  }) : _kumiRepository = kumiRepository,
       super(const ChatInitial());

  final KumiRepository _kumiRepository;
  StreamSubscription<List<ChatMessageModel>>? _chatHistorySubscription;

  /// Initialize the cubit by loading chat history from database.
  Future<void> initialize() async {
    try {
      // Subscribe to chat history updates
      _chatHistorySubscription = _kumiRepository.watchChatHistory().listen((
        messages,
      ) {
        // Only emit loaded state if not currently processing a response
        // Don't overwrite ChatSuccess or ChatStreaming states
        if (state is ChatInitial || state is ChatLoaded) {
          emit(ChatLoaded(messages: messages));
        }
        // Skip ChatLoading, ChatStreaming, and ChatSuccess - keep the response visible
      });
    } on Exception catch (e) {
      debugPrint('Error initializing chat: $e');
      emit(
        ChatError(
          error: "Erreur lors du chargement de l'historique: $e",
          messages: state.messages,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    unawaited(_chatHistorySubscription?.cancel());
    return super.close();
  }

  /// Processes a user message and streams the RAG-augmented response.
  Future<void> askQuestion(String userQuestion) async {
    debugPrint('ChatCubit.askQuestion: called with "$userQuestion"');
    debugPrint('ChatCubit.askQuestion: current state is $state');
    try {
      if (userQuestion.trim().isEmpty) {
        emit(
          ChatError(
            error: 'Veuillez entrer une question',
            messages: state.messages,
          ),
        );
        return;
      }

      // Emit loading state
      debugPrint('ChatCubit.askQuestion: emitting ChatLoading');
      emit(ChatLoading(messages: state.messages));

      // Get source note IDs before streaming (we need to capture this)
      final sourceNoteIds = await _getSourceNoteIds(userQuestion);

      // Stream the response from Kumi
      final responseBuffer = StringBuffer();
      debugPrint('ChatCubit.askQuestion: calling _kumiRepository.askKumi');

      await for (final token in _kumiRepository.askKumi(userQuestion)) {
        debugPrint('ChatCubit.askQuestion: got token: $token');
        responseBuffer.write(token);

        // Update UI with streamed response
        emit(
          ChatStreaming(
            messages: state.messages,
            partialResponse: responseBuffer.toString(),
            sourceNoteIds: sourceNoteIds,
          ),
        );
      }

      // Mark as success when streaming completes
      debugPrint('ChatCubit.askQuestion: emitting ChatSuccess');
      emit(
        ChatSuccess(
          messages: state.messages,
          lastResponse: responseBuffer.toString(),
          sourceNoteIds: sourceNoteIds,
        ),
      );
    } on Object catch (e, stack) {
      debugPrint('Error asking question: $e');
      debugPrint('Stack trace: $stack');
      emit(
        ChatError(
          error: 'Erreur lors de la génération de la réponse: $e',
          messages: state.messages,
        ),
      );
    }
  }

  /// Clears all chat history from the database.
  Future<void> clearHistory() async {
    try {
      await _kumiRepository.clearChatHistory();
      emit(const ChatInitial());
    } on Exception catch (e) {
      debugPrint('Error clearing history: $e');
      emit(
        ChatError(
          error: "Erreur lors de la suppression de l'historique: $e",
          messages: state.messages,
        ),
      );
    }
  }

  /// Closes the current chat overlay/response without clearing history.
  /// This just resets to the loaded state.
  void clear() {
    emit(ChatLoaded(messages: state.messages));
  }

  /// Gets source note IDs for a question using hybrid search.
  Future<List<int>> _getSourceNoteIds(String question) async {
    try {
      final notes = await _kumiRepository.hybridSearch(question);
      return notes.map((n) => n.id).toList();
    } catch (e) {
      debugPrint('Error getting source note IDs: $e');
      return [];
    }
  }
}
