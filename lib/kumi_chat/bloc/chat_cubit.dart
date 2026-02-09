import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';
import 'package:uuid/uuid.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Cubit for managing the chat UI state.
///
/// This cubit handles:
/// - Maintaining the list of chat messages
/// - Processing user messages through the RAG pipeline
/// - Managing loading states during AI response generation
/// - Streaming token-by-token responses
class ChatCubit extends Cubit<ChatState> {
  /// Creates a [ChatCubit] with required dependencies.
  ChatCubit({
    required KumiRepository kumiRepository,
  }) : _kumiRepository = kumiRepository,
       super(const ChatInitial());

  final KumiRepository _kumiRepository;
  static const _uuid = Uuid();

  /// Processes a user message and streams the RAG-augmented response.
  Future<void> sendMessage(String userText) async {
    try {
      // Add the user's message to the chat
      final userMessage = ChatMessageModel(
        id: _uuid.v4(),
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
        sources: const [],
      );

      final currentMessages = [...state.messages, userMessage];
      emit(ChatLoading(messages: currentMessages));

      // Stream the response from Kumi
      ChatMessageModel? latestResponse;
      await for (final response in _kumiRepository.chatWithRag(userText)) {
        latestResponse = response;

        // Update messages with the latest streamed response
        emit(ChatStreaming(messages: [...currentMessages, response]));
      }

      // Mark as success when streaming completes
      if (latestResponse != null) {
        emit(ChatSuccess(messages: [...currentMessages, latestResponse]));
      }
    } on Object catch (e) {
      emit(
        ChatError(
          error: 'Erreur lors de la génération de la réponse: $e',
          messages: state.messages,
        ),
      );
    }
  }

  /// Clears all messages from the chat history.
  Future<void> clearHistory() async {
    emit(const ChatInitial());
  }

  /// Initializes the chat (can load previous messages if needed).
  Future<void> initialize() async {
    // For now, just ensure we're in initial state
    emit(const ChatInitial());
  }
}
