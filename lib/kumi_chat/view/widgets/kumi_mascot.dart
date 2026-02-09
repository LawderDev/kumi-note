import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';

/// Shiba mascot states
enum MascotState {
  idle,      // Resting/power save mode
  listening, // Receiving user input
  thinking,  // Consulting database/generating response
  success,   // Success state
  error,     // Error state
}

/// Animated Shiba mascot that changes expression based on AI state
/// 
/// For now uses emoji-based animations. Can be replaced with Lottie files:
/// - assets/animations/shiba_idle.json
/// - assets/animations/shiba_listening.json
/// - assets/animations/shiba_thinking.json
class KumiMascot extends StatefulWidget {
  const KumiMascot({
    required this.state,
    this.size = 64,
    super.key,
  });

  final MascotState state;
  final double size;

  @override
  State<KumiMascot> createState() => _KumiMascotState();
}

class _KumiMascotState extends State<KumiMascot> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: _buildMascotForState(widget.state),
    );
  }

  Widget _buildMascotForState(MascotState state) {
    switch (state) {
      case MascotState.idle:
        return _buildIdleMascot();
      case MascotState.listening:
        return _buildListeningMascot();
      case MascotState.thinking:
        return _buildThinkingMascot();
      case MascotState.success:
        return _buildSuccessMascot();
      case MascotState.error:
        return _buildErrorMascot();
    }
  }

  Widget _buildIdleMascot() {
    return Container(
      key: const ValueKey('idle'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: KumiColors.orangeAccent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '🐕',
          style: TextStyle(fontSize: widget.size * 0.6),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.05, 1.05),
          end: const Offset(1.0, 1.0),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildListeningMascot() {
    return Container(
      key: const ValueKey('listening'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: KumiColors.info.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '👂🐕',
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(
          begin: -0.02,
          end: 0.02,
          duration: 300.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .rotate(
          begin: 0.02,
          end: -0.02,
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildThinkingMascot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          key: const ValueKey('thinking'),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: KumiColors.sageGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '🤔🐕',
              style: TextStyle(fontSize: widget.size * 0.5),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Text(
            '✨',
            style: TextStyle(fontSize: widget.size * 0.3),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: 600.ms,
              )
              .fadeOut(duration: 400.ms),
        ),
      ],
    );
  }

  Widget _buildSuccessMascot() {
    return Container(
      key: const ValueKey('success'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: KumiColors.success.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '😊🐕',
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildErrorMascot() {
    return Container(
      key: const ValueKey('error'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: KumiColors.error.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '😰🐕',
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    );
  }
}
