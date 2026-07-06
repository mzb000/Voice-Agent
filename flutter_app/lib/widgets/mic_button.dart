import 'package:flutter/material.dart';

import '../state/agent_controller.dart';
import '../theme/app_theme.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.state,
    required this.mode,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onTapToggle,
    required this.onCancel,
  });

  final AgentState state;
  final InteractionMode mode;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onTapToggle;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isListening = state == AgentState.listening;
    final isBusy = state == AgentState.thinking || state == AgentState.speaking;

    IconData icon;
    String label;
    Color bg;

    if (isBusy) {
      icon = Icons.stop_rounded;
      label = state == AgentState.thinking ? 'Thinking…' : 'Speaking…';
      bg = AppColors.accent2;
    } else if (isListening) {
      icon = Icons.stop_rounded;
      label = mode == InteractionMode.pushToTalk ? 'Release to send' : 'Tap to send';
      bg = AppColors.danger;
    } else {
      icon = Icons.mic_rounded;
      label = mode == InteractionMode.pushToTalk ? 'Hold to speak' : 'Tap to talk';
      bg = AppColors.accent;
    }

    Widget btn = GestureDetector(
      onLongPressStart: mode == InteractionMode.pushToTalk && !isBusy
          ? (_) => onPressStart()
          : null,
      onLongPressEnd: mode == InteractionMode.pushToTalk && !isBusy
          ? (_) => onPressEnd()
          : null,
      onTap: () {
        if (isBusy) {
          onCancel();
        } else {
          onTapToggle();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [bg, bg.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.55),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn,
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
