import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_note/kumi_chat/view/theme/kumi_theme.dart';

/// Widget for displaying a single chat message.
///
/// Renders messages differently based on whether they're from the user or Kumi:
/// - User messages: Right-aligned with orange background
/// - Kumi messages: Left-aligned with cream background, with source notes below
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    super.key,
  });

  /// The chat message to display
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KumiTheme.spacingM,
        vertical: KumiTheme.spacingS,
      ),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Main message bubble
            Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? KumiTheme.orange : KumiTheme.cream,
                    border: !message.isUser
                        ? Border.all(color: KumiTheme.lightGray)
                        : null,
                    borderRadius: KumiTheme.mediumRadius,
                    boxShadow: const [KumiTheme.subtleShadow],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KumiTheme.spacingM,
                    vertical: KumiTheme.spacingS,
                  ),
                  child: Text(
                    message.text,
                    style: KumiTheme.chatMessageStyle.copyWith(
                      color: message.isUser
                          ? Colors.white
                          : KumiTheme.anthraciteGray,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideY(
                  begin: 0.2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),

            // Source note IDs indicator (for Kumi responses)
            // Note: Full source display with repository lookup would be
            // implemented when we have proper DI in place. For now,
            // showing that sources exist.
            if (!message.isUser && message.sourceNoteIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: KumiTheme.spacingS,
                  left: KumiTheme.spacingS,
                ),
                child: Text(
                  'Sources: ${message.sourceNoteIds.join(', ')}',
                  style: KumiTheme.smallStyle.copyWith(
                    color: KumiTheme.disabledGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: KumiTheme.spacingXS),
              child: Text(
                _formatTime(message.timestamp),
                style: KumiTheme.smallStyle.copyWith(
                  color: KumiTheme.disabledGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a timestamp into a short time string
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
