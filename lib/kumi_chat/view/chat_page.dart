import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_note/kumi_chat/bloc/bloc.dart';
import 'package:kumi_note/kumi_chat/view/theme/theme.dart';
import 'package:kumi_note/kumi_chat/view/widgets/widgets.dart';

/// Main chat page for interacting with Kumi.
///
/// Displays:
/// - Kumi mascot in the header
/// - List of chat messages with proper styling
/// - Input field for user messages
/// - Real-time response streaming
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KumiTheme.cream,
      appBar: _buildAppBar(context),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          // Auto-scroll to the latest message when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        builder: (context, state) {
          return Column(
            children: [
              // Chat messages list
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return ChatBubble(message: message);
                        },
                      ),
              ),

              // Error state display
              if (state is ChatError) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(KumiTheme.spacingM),
                  color: KumiTheme.errorRed.withValues(alpha: 0.1),
                  child: Text(
                    state.error,
                    style: KumiTheme.bodyStyle.copyWith(
                      color: KumiTheme.errorRed,
                    ),
                  ),
                ),
              ],

              // Message input field
              _buildInputField(context, state),
            ],
          );
        },
      ),
    );
  }

  /// Builds the app bar with Kumi mascot
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: KumiTheme.cream,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const SizedBox(height: 8),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final mascotState = _getMascotState(state);
              return KumiMascot(
                state: mascotState,
                size: 56,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Kumi',
            style: KumiTheme.subtitleStyle.copyWith(
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: KumiTheme.anthraciteGray,
          onPressed: () => _showClearConfirmation(context),
        ),
      ],
    );
  }

  /// Builds the empty state display
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const KumiMascot(state: MascotState.idle, size: 80),
          const SizedBox(height: KumiTheme.spacingL),
          Text(
            'Hey! I\'m Kumi 🐕',
            style: KumiTheme.titleStyle,
          ),
          const SizedBox(height: KumiTheme.spacingS),
          Text(
            'Start a conversation with me.\nI\'ll remember everything!',
            style: KumiTheme.bodyStyle.copyWith(
              color: KumiTheme.disabledGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the input field for typing messages
  Widget _buildInputField(BuildContext context, ChatState state) {
    final isLoading = state is ChatLoading || state is ChatStreaming;

    return Container(
      padding: const EdgeInsets.all(KumiTheme.spacingM),
      decoration: BoxDecoration(
        color: KumiTheme.cream,
        border: Border(
          top: BorderSide(
            color: KumiTheme.lightGray,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: KumiTheme.lightGray,
                  width: 1,
                ),
                borderRadius: KumiTheme.largeRadius,
              ),
              child: TextField(
                controller: _messageController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'Message Kumi...',
                  hintStyle: KumiTheme.bodyStyle.copyWith(
                    color: KumiTheme.disabledGray,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KumiTheme.spacingM,
                    vertical: KumiTheme.spacingM,
                  ),
                ),
                style: KumiTheme.bodyStyle,
                maxLines: null,
                minLines: 1,
              ),
            ),
          ),

          const SizedBox(width: KumiTheme.spacingS),

          // Send button
          GestureDetector(
            onTap: isLoading ? null : () => _sendMessage(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLoading ? KumiTheme.disabledGray : KumiTheme.orange,
                boxShadow: [if (!isLoading) KumiTheme.subtleShadow],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sends a message when the user taps send
  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    context.read<ChatCubit>().sendMessage(text);
  }

  /// Shows a confirmation dialog before clearing chat history
  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KumiTheme.cream,
        title: Text('Clear History?', style: KumiTheme.subtitleStyle),
        content: Text(
          'This will delete all messages. This action cannot be undone.',
          style: KumiTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: KumiTheme.buttonStyle.copyWith(color: KumiTheme.anthraciteGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: KumiTheme.buttonStyle),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ChatCubit>().clearHistory();
    }
  }

  /// Determines the mascot state based on chat state
  MascotState _getMascotState(ChatState state) {
    if (state is ChatLoading) return MascotState.listening;
    if (state is ChatStreaming) return MascotState.thinking;
    if (state is ChatSuccess) return MascotState.success;
    if (state is ChatError) return MascotState.error;
    return MascotState.idle;
  }
}
