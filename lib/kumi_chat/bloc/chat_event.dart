part of 'chat_cubit.dart';

/// Base class for chat events.
sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the user sends a new message.
final class SendMessage extends ChatEvent {
  const SendMessage(this.text);

  /// The user's message text.
  final String text;

  @override
  List<Object?> get props => [text];
}

/// Event to clear the entire chat history.
final class ClearChatHistory extends ChatEvent {
  const ClearChatHistory();
}

/// Event to initialize the chat (load saved messages if any).
final class InitializeChat extends ChatEvent {
  const InitializeChat();
}
