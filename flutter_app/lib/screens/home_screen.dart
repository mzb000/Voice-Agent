import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/agent_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/voice_orb_blob.dart';
import '../widgets/voice_orb_bars.dart';
import '../widgets/voice_orb_particles.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.baseUrl, required this.onBaseUrlChanged});
  final String baseUrl;
  final ValueChanged<String> onBaseUrlChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Voice Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              final res = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => SettingsScreen(currentBaseUrl: baseUrl)),
              );
              if (res != null && res.isNotEmpty) onBaseUrlChanged(res);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: const SafeArea(child: _HomeBody()),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AgentController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ModeToggle(mode: ctrl.mode, onChanged: ctrl.setMode)
              .animate().fadeIn(duration: 400.ms).slideY(begin: -.2),
          const SizedBox(height: 12),
          _OrbStylePicker(style: ctrl.orbStyle, onChanged: ctrl.setOrbStyle)
              .animate().fadeIn(delay: 100.ms).slideY(begin: -.2),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _buildOrb(ctrl)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.85, 0.85)),
            ),
          ),
          _StatusText(state: ctrl.state, error: ctrl.lastError),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: _TranscriptList(ctrl: ctrl),
          ),
          const SizedBox(height: 12),
          MicButton(
            state: ctrl.state,
            mode: ctrl.mode,
            onPressStart: ctrl.startListening,
            onPressEnd: ctrl.stopAndSend,
            onTapToggle: () {
              if (ctrl.state == AgentState.idle) {
                ctrl.startListening();
              } else if (ctrl.state == AgentState.listening) {
                ctrl.stopAndSend();
              }
            },
            onCancel: ctrl.cancel,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: .3),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrb(AgentController ctrl) {
    final active = ctrl.state != AgentState.idle;
    final amp = ctrl.state == AgentState.speaking ? 0.55 : ctrl.amplitude;
    switch (ctrl.orbStyle) {
      case OrbStyle.blob:
        return VoiceOrbBlob(amplitude: amp, active: active);
      case OrbStyle.bars:
        return VoiceOrbBars(amplitude: amp, active: active);
      case OrbStyle.particles:
        return VoiceOrbParticles(amplitude: amp, active: active);
    }
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final InteractionMode mode;
  final ValueChanged<InteractionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _seg('Push-to-talk', mode == InteractionMode.pushToTalk,
              () => onChanged(InteractionMode.pushToTalk)),
          _seg('Auto (VAD)', mode == InteractionMode.vad,
              () => onChanged(InteractionMode.vad)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? AppColors.orbGradient : null,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _OrbStylePicker extends StatelessWidget {
  const _OrbStylePicker({required this.style, required this.onChanged});
  final OrbStyle style;
  final ValueChanged<OrbStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill('Blob', OrbStyle.blob),
        const SizedBox(width: 8),
        _pill('Bars', OrbStyle.bars),
        const SizedBox(width: 8),
        _pill('Particles', OrbStyle.particles),
      ],
    );
  }

  Widget _pill(String label, OrbStyle s) {
    final active = s == style;
    return GestureDetector(
      onTap: () => onChanged(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: active ? AppColors.accent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.state, this.error});
  final AgentState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    String text;
    Color color = AppColors.textSecondary;
    switch (state) {
      case AgentState.idle:
        text = 'Ready';
        break;
      case AgentState.listening:
        text = 'Listening…';
        color = AppColors.accent2;
        break;
      case AgentState.thinking:
        text = 'Thinking…';
        color = AppColors.accent;
        break;
      case AgentState.speaking:
        text = 'Speaking…';
        color = AppColors.accent3;
        break;
      case AgentState.error:
        text = error ?? 'Something went wrong';
        color = AppColors.danger;
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TranscriptList extends StatelessWidget {
  const _TranscriptList({required this.ctrl});
  final AgentController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.history.isEmpty) {
      return Center(
        child: Text(
          'Say hello to start the conversation.',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ctrl.history.length,
        itemBuilder: (_, i) {
          final m = ctrl.history[ctrl.history.length - 1 - i];
          final isUser = m.role == 'user';
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isUser
                    ? const LinearGradient(colors: [AppColors.accent, AppColors.accent3])
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.06),
              ),
              child: Text(
                m.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut);
        },
      ),
    );
  }
}
