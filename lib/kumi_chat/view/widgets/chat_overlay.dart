import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/core/theme/kumi_text_styles.dart';
import 'package:kumi_note/journal/cubit/journal_cubit.dart';
import 'package:kumi_note/kumi_chat/bloc/chat_cubit.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// ChatOverlay - slides up from bottom when user opens chat
/// Displays Kumi's response with animations and action buttons
class ChatOverlay extends StatefulWidget {
  const ChatOverlay({
    required this.isVisible,
    required this.onClose,
    this.onNoteTap,
    super.key,
  });

  final bool isVisible;
  final VoidCallback onClose;
  final void Function(int noteId)? onNoteTap;

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        unawaited(_slideController.forward());
      } else {
        unawaited(_slideController.reverse());
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !widget.isVisible,
      child: SlideTransition(
        position: _slideAnimation,
        child: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, chatState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: KumiColors.orangeAccent.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: KumiColors.orangeAccent.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: KumiColors.orangeAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kumi Response',
                                  style: KumiTextStyles.labelL,
                                ),
                                Text(
                                  chatState is ChatStreaming
                                      ? 'Thinking...'
                                      : 'Done',
                                  style: KumiTextStyles.caption.copyWith(
                                    color: KumiColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              color: KumiColors.textPrimary,
                            ),
                            onPressed: widget.onClose,
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Response content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildResponseContent(chatState),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: chatState is ChatStreaming
                                  ? null
                                  : () => _copyResponse(chatState),
                              icon: const Icon(LucideIcons.copy),
                              label: const Text('Copy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: chatState is ChatStreaming
                                  ? null
                                  : () => _shareResponse(chatState),
                              icon: const Icon(LucideIcons.share2),
                              label: const Text('Share'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: chatState is ChatStreaming
                                  ? null
                                  : () => _saveAsNote(context, chatState),
                              icon: const Icon(LucideIcons.save),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KumiColors.orangeAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponseContent(ChatState chatState) {
    if (chatState is ChatLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: KumiColors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      KumiColors.orangeAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kumi is thinking...',
                  style: KumiTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      );
    } else if (chatState is ChatStreaming) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichTextResponse(
            chatState.partialResponse,
            chatState.sourceNoteIds,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: KumiColors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      KumiColors.orangeAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kumi is thinking...',
                  style: KumiTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      );
    } else if (chatState is ChatSuccess) {
      return _buildRichTextResponse(
        chatState.lastResponse,
        chatState.sourceNoteIds,
      );
    } else if (chatState is ChatError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KumiColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: KumiColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chatState.error,
                    style: KumiTextStyles.bodyS.copyWith(
                      color: KumiColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask me anything about your notes!',
            style: KumiTextStyles.bodyM.copyWith(
              color: KumiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the send button to get started',
            style: KumiTextStyles.bodyS.copyWith(
              color: KumiColors.textDisabled,
            ),
          ),
        ],
      );
    }
  }

  /// Builds rich text with clickable note references.
  Widget _buildRichTextResponse(String text, List<int> sourceNoteIds) {
    if (sourceNoteIds.isEmpty) {
      return Text(text, style: KumiTextStyles.bodyM);
    }

    // Parse the text to find [X] patterns and make them clickable
    final regex = RegExp(r'\[(\d+)\]');
    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, style: KumiTextStyles.bodyM);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: KumiTextStyles.bodyM,
          ),
        );
      }

      // Get the note ID from the match
      final noteIdStr = match.group(1);
      final noteId = int.tryParse(noteIdStr ?? '');

      // Check if this note ID is in our source list
      final isSourceNote = noteId != null && sourceNoteIds.contains(noteId);

      // Add clickable span for the reference
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: isSourceNote && widget.onNoteTap != null
                ? () => widget.onNoteTap!(noteId)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSourceNote
                    ? KumiColors.orangeAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                match.group(0) ?? '',
                style: KumiTextStyles.bodyM.copyWith(
                  color: isSourceNote
                      ? KumiColors.orangeAccent
                      : KumiColors.textSecondary,
                  fontWeight: isSourceNote
                      ? FontWeight.w600
                      : FontWeight.normal,
                  decoration: isSourceNote ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: KumiTextStyles.bodyM,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _copyResponse(ChatState chatState) {
    final text = chatState is ChatSuccess
        ? chatState.lastResponse
        : chatState is ChatStreaming
        ? chatState.partialResponse
        : '';

    if (text.isNotEmpty) {
      unawaited(Clipboard.setData(ClipboardData(text: text)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  void _shareResponse(ChatState chatState) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
    // TODO(developer): Implement sharing
  }

  Future<void> _saveAsNote(BuildContext context, ChatState chatState) async {
    final text = chatState is ChatSuccess
        ? chatState.lastResponse
        : chatState is ChatStreaming
        ? chatState.partialResponse
        : '';

    if (text.isNotEmpty) {
      try {
        await context.read<JournalCubit>().addNote(text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved as note')),
          );
        }
      } on Exception catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving note: $e')),
          );
        }
      }
    }
  }
}
