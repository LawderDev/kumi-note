part of 'chat_cubit.dart';

/// Base class for all Chat states.
sealed class ChatState extends Equatable {
  const ChatState({
    required this.messages,
  });

  /// All messages in the current chat session.
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

/// State when Kumi is thinking/processing the response.
final class ChatLoading extends ChatState {
  const ChatLoading({
    super.messages = const [],
  });
}

/// State while Kumi is streaming a response token by token.
final class ChatStreaming extends ChatState {
  const ChatStreaming({
    required super.messages,
  });
}

/// State when a message exchange has completed successfully.
final class ChatSuccess extends ChatState {
  const ChatSuccess({
    required super.messages,
  });
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
