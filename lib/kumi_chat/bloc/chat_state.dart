part of 'chat_cubit.dart';

/// Base class for all Chat states.
sealed class ChatState extends Equatable {
  const ChatState({
    required this.messages,
  });

  /// All messages in the current chat session (from database).
  final List<ChatMessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

/// Initial state when the chat interface is first loaded.
final class ChatInitial extends ChatState {
  const ChatInitial({
    super.messages = const [],
  });
}

/// State when chat has been loaded from database.
final class ChatLoaded extends ChatState {
  const ChatLoaded({
    required super.messages,
  });
}

/// State when Kumi is thinking/processing the response.
final class ChatLoading extends ChatState {
  const ChatLoading({
    required super.messages,
  });
}

/// State while Kumi is streaming a response token by token.
final class ChatStreaming extends ChatState {
  const ChatStreaming({
    required super.messages,
    required this.partialResponse,
    this.sourceNoteIds = const [],
  });

  /// The partial response being streamed (accumulated tokens).
  final String partialResponse;

  /// Note IDs that were used as sources for this response.
  final List<int> sourceNoteIds;

  @override
  List<Object?> get props => [messages, partialResponse, sourceNoteIds];
}

/// State when a message exchange has completed successfully.
final class ChatSuccess extends ChatState {
  const ChatSuccess({
    required super.messages,
    required this.lastResponse,
    this.sourceNoteIds = const [],
  });

  /// The completed response from Kumi.
  final String lastResponse;

  /// Note IDs that were used as sources for this response.
  final List<int> sourceNoteIds;

  @override
  List<Object?> get props => [messages, lastResponse, sourceNoteIds];
}

/// State when an error occurred during message processing.
final class ChatError extends ChatState {
  const ChatError({
    required this.error,
    super.messages = const [],
  });

  /// The error message to display to the user.
  final String error;

  @override
  List<Object?> get props => [error, messages];
}
