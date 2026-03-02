import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/kumi_chat/bloc/chat_cubit.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Bottom input bar for "Kumi Stage" - allows users to ask Kumi
/// or create quick notes
/// Features:
/// - Placeholder: "Ask Kumi..."
/// - Send button with orange accent color (#E67E22)
/// - Mic button for voice input (future)
/// - Flying note animation on submit
class BottomInputBar extends StatefulWidget {
  const BottomInputBar({
    super.key,
    this.onInputTap,
    this.onSubmit,
  });

  final VoidCallback? onInputTap;
  final VoidCallback? onSubmit;

  @override
  State<BottomInputBar> createState() => _BottomInputBarState();
}

class _BottomInputBarState extends State<BottomInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _showFlyingNote = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    // Haptic feedback
    unawaited(HapticFeedback.lightImpact());

    // Show flying note animation
    setState(() => _showFlyingNote = true);

    try {
      // Notify parent to open chat overlay
      widget.onSubmit?.call();

      // Send message to Chat only (note creation is handled by FAB)
      unawaited(context.read<ChatCubit>().askQuestion(content));

      if (mounted) {
        _controller.clear();
        _focusNode.unfocus();

        // Success feedback
        unawaited(HapticFeedback.mediumImpact());

        // Hide flying animation after it completes
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() => _showFlyingNote = false);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: KumiColors.error,
          ),
        );
        setState(() => _showFlyingNote = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _startVoiceInput() {
    // TODO(developer): Implement voice input with mic access
    unawaited(HapticFeedback.lightImpact());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: KumiColors.warmGray.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Mic button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _startVoiceInput,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.mic,
                          color: _isSubmitting
                              ? KumiColors.textDisabled
                              : KumiColors.orangeAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: KumiColors.creamBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? KumiColors.orangeAccent
                              : KumiColors.warmGray.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_isSubmitting,
                        onTap: () {
                          // Initialize ChatCubit when user taps input
                          // (lazy init)
                          final chatCubit = context.read<ChatCubit>();
                          if (chatCubit.state is ChatInitial) {
                            unawaited(chatCubit.initialize());
                          }
                          // Open chat overlay
                          widget.onInputTap?.call();
                        },
                        decoration: InputDecoration(
                          hintText: 'Demande à Kumi...',
                          hintStyle: TextStyle(
                            color: KumiColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submitMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send button
                  Material(
                    color: _controller.text.trim().isEmpty || _isSubmitting
                        ? KumiColors.textDisabled
                        : KumiColors.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                    elevation: _controller.text.trim().isEmpty ? 0 : 3,
                    child: InkWell(
                      onTap: _controller.text.trim().isEmpty || _isSubmitting
                          ? null
                          : _submitMessage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                LucideIcons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Flying note animation
        if (_showFlyingNote)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child:
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: KumiColors.sageGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: KumiColors.sageGreen.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Envol vers Kumi...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 200.ms,
                      )
                      .fadeIn(duration: 200.ms)
                      .then()
                      .moveY(
                        begin: 0,
                        end: -100,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(duration: 400.ms),
            ),
          ),
      ],
    );
  }
}
