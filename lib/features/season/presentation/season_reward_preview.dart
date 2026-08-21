import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_layers.dart';

/// Compact, asset-free preview used by both the pass and season locker.
///
/// Previews are derived from the reward kind/key so future seasons can keep
/// using backend configuration without requiring a bespoke image asset for
/// every reward.
class SeasonRewardPreview extends StatelessWidget {
  const SeasonRewardPreview({
    required this.reward,
    this.height = 64,
    this.compact = false,
    super.key,
  });

  final SeasonReward reward;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonCosmeticLayers.accentForReward(reward);
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF040A13),
        borderRadius: BorderRadius.circular(compact ? 10 : 13),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PreviewBackdrop(accent: accent, rewardKey: reward.rewardKey),
          Padding(
            padding: EdgeInsets.all(compact ? 6 : 8),
            child: _PreviewContent(reward: reward, accent: accent),
          ),
        ],
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.reward, required this.accent});

  final SeasonReward reward;
  final Color accent;

  @override
  Widget build(BuildContext context) => switch (reward.kind) {
        'reaction_pack' || 'gameplay_theme' => _ReactionPreview(accent: accent),
        'arena_theme' => _ArenaPreview(accent: accent, keyName: reward.rewardKey),
        'command_style' || 'command_pack' =>
          _CommandPreview(accent: accent, keyName: reward.rewardKey),
        'countdown_style' => _CountdownPreview(accent: accent),
        'sound_pack' => _SoundPreview(accent: accent),
        'input_reaction_pack' =>
          _InputReactionPreview(accent: accent, keyName: reward.rewardKey),
        'hud_style' => _HudPreview(accent: accent, keyName: reward.rewardKey),
        'particle_pack' => _ParticlePreview(accent: accent, keyName: reward.rewardKey),
        'share_style' || 'share_card' => _SharePreview(accent: accent),
        'profile_frame' => _ProfilePreview(accent: accent, frame: true),
        'profile_badge' => _BadgePreview(accent: accent, label: reward.name),
        'player_code_style' => _PlayerCodePreview(accent: accent),
        'home_theme' || 'home_background' => _HomePreview(accent: accent),
        'score_effect' || 'result_score_style' => _ScorePreview(accent: accent),
        'success_effect' || 'result_success_style' =>
          _FeedbackPreview(accent: accent, success: true),
        'failure_effect' || 'result_failure_style' =>
          _FeedbackPreview(accent: accent, success: false),
        'mode_card_skin' => _ModeCardPreview(accent: accent),
        'title' => _TitlePreview(accent: accent, label: reward.name),
        'emblem' => _EmblemPreview(accent: accent, keyName: reward.rewardKey),
        _ => Center(child: Icon(Icons.auto_awesome_rounded, color: accent, size: 28)),
      };
}

class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({required this.accent, required this.rewardKey});

  final Color accent;
  final String rewardKey;

  @override
  Widget build(BuildContext context) {
    final reverse = rewardKey.hashCode.isEven;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse ? Alignment.topRight : Alignment.topLeft,
          end: reverse ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: .13),
            const Color(0xFF07111D),
            accent.withValues(alpha: .025),
          ],
        ),
      ),
    );
  }
}

class _ReactionPreview extends StatelessWidget {
  const _ReactionPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 3),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .5), blurRadius: 14)],
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: .16),
              ),
            ),
          ),
        ),
      );
}

class _ArenaPreview extends StatelessWidget {
  const _ArenaPreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox.square(
          dimension: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent,
                    width: keyName.contains('thin') ? 2 : 4,
                  ),
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: .3), blurRadius: 10),
                  ],
                ),
              ),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .07),
                  border: Border.all(color: accent.withValues(alpha: .52)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _CommandPreview extends StatelessWidget {
  const _CommandPreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final terminal = keyName.contains('terminal');
    final impact = keyName.contains('impact');
    return Center(
      child: FittedBox(
        child: Text(
          terminal ? '> SWIPE' : impact ? 'TAP!' : 'SWIPE',
          style: TextStyle(
            color: accent,
            fontSize: impact ? 22 : 18,
            fontWeight: FontWeight.w900,
            fontFamily: terminal ? 'monospace' : null,
            fontStyle: keyName.contains('glitch') ? FontStyle.italic : null,
            letterSpacing: terminal ? 1.5 : .8,
            shadows: [Shadow(color: accent.withValues(alpha: .55), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _CountdownPreview extends StatelessWidget {
  const _CountdownPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final value in const ['3', '2', '1']) ...[
            Container(
              width: 24,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: .45)),
              ),
              child: Text(
                value,
                style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
            if (value != '1') const SizedBox(width: 5),
          ],
        ],
      );
}

class _SoundPreview extends StatelessWidget {
  const _SoundPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.volume_up_rounded, color: accent, size: 23),
          const SizedBox(width: 8),
          for (final height in const [10.0, 22.0, 15.0, 28.0, 18.0, 11.0]) ...[
            Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(width: 3),
          ],
        ],
      );
}

class _InputReactionPreview extends StatelessWidget {
  const _InputReactionPreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  @override
  Widget build(BuildContext context) => Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < (keyName.contains('echo') ? 3 : 2); i++)
              Container(
                width: 24.0 + i * 14,
                height: 24.0 + i * 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: .75 - i * .18),
                    width: 1.5,
                  ),
                ),
              ),
            Icon(Icons.touch_app_rounded, color: accent, size: 20),
          ],
        ),
      );
}

class _HudPreview extends StatelessWidget {
  const _HudPreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final label in const ['SCORE', 'MODE', 'TIME']) ...[
            Container(
              width: 42,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(keyName.contains('rail') ? 4 : 9),
                border: Border.all(color: accent.withValues(alpha: .48)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 5.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (label != 'TIME') const SizedBox(width: 4),
          ],
        ],
      );
}

class _ParticlePreview extends StatelessWidget {
  const _ParticlePreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final count = keyName.contains('dense') || keyName.contains('storm') ? 16 : 9;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: 8 + ((i * 31) % math.max(12, constraints.maxWidth - 16)),
              top: 5 + ((i * 17) % math.max(10, constraints.maxHeight - 10)),
              child: Container(
                width: 2.5 + (i % 3),
                height: 2.5 + (i % 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .45 + (i % 4) * .1),
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: .28), blurRadius: 5),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 58,
          height: 45,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: .7)),
            gradient: LinearGradient(colors: [accent.withValues(alpha: .13), const Color(0xFF07111D)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RE△CT', style: TextStyle(color: accent, fontSize: 6, fontWeight: FontWeight.w900)),
              const Spacer(),
              const Text('42', style: TextStyle(color: ReactColors.textPrimary, fontSize: 18, height: .9, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.accent, required this.frame});
  final Color accent;
  final bool frame;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 78,
          height: 45,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF07111D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent, width: frame ? 2 : 1),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .2), blurRadius: 9)],
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent)),
                child: Icon(Icons.person_rounded, color: accent, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 4, width: 30, color: ReactColors.textPrimary.withValues(alpha: .8)),
                    const SizedBox(height: 4),
                    Container(height: 3, width: 21, color: accent.withValues(alpha: .8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: accent.withValues(alpha: .10),
            border: Border.all(color: accent.withValues(alpha: .6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, color: accent, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label.replaceAll(' BADGE', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accent, fontSize: 7, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
}

class _PlayerCodePreview extends StatelessWidget {
  const _PlayerCodePreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: accent.withValues(alpha: .08),
            border: Border.all(color: accent.withValues(alpha: .5)),
          ),
          child: Text(
            'RX-1A2B3C',
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: [Shadow(color: accent.withValues(alpha: .5), blurRadius: 7)],
            ),
          ),
        ),
      );
}

class _HomePreview extends StatelessWidget {
  const _HomePreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(painter: _MiniGridPainter(accent), size: const Size(double.infinity, double.infinity)),
          Container(
            width: 47,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: const Color(0xFF07111D),
              border: Border.all(color: accent.withValues(alpha: .65)),
            ),
            child: Text('PLAY', style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      );
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('42', style: TextStyle(color: ReactColors.textPrimary, fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            Text('+1', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w900, shadows: [Shadow(color: accent, blurRadius: 8)])),
          ],
        ),
      );
}

class _FeedbackPreview extends StatelessWidget {
  const _FeedbackPreview({required this.accent, required this.success});
  final Color accent;
  final bool success;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: .65), width: 2),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .28), blurRadius: 14, spreadRadius: 2)],
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            color: accent,
            size: 26,
          ),
        ),
      );
}

class _ModeCardPreview extends StatelessWidget {
  const _ModeCardPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 72,
          height: 46,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: .75)),
            gradient: LinearGradient(colors: [accent.withValues(alpha: .14), const Color(0xFF07111D)]),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: accent, size: 14),
              const Spacer(),
              const Text('CLASSIC', style: TextStyle(color: ReactColors.textPrimary, fontSize: 7, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}

class _TitlePreview extends StatelessWidget {
  const _TitlePreview({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PLAYER', style: TextStyle(color: ReactColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: .6)),
          ],
        ),
      );
}

class _EmblemPreview extends StatelessWidget {
  const _EmblemPreview({required this.accent, required this.keyName});
  final Color accent;
  final String keyName;

  IconData get _icon {
    if (keyName.contains('reactor')) return Icons.blur_circular_rounded;
    if (keyName.contains('peak_signal')) return Icons.cell_tower_rounded;
    if (keyName.contains('split_second')) return Icons.timer_outlined;
    if (keyName.contains('charge_cell')) return Icons.battery_charging_full_rounded;
    if (keyName.contains('elite')) return Icons.change_history_rounded;
    if (keyName.contains('overdrive')) return Icons.electric_bolt_rounded;
    return Icons.bolt_rounded;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .10),
            border: Border.all(color: accent.withValues(alpha: .65)),
          ),
          child: Icon(_icon, color: accent, size: 23),
        ),
      );
}

class _MiniGridPainter extends CustomPainter {
  const _MiniGridPainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: .12)
      ..strokeWidth = .7;
    const gap = 13.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: .16), Colors.transparent],
      ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: math.max(size.width, size.height) * .55));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter oldDelegate) => oldDelegate.accent != accent;
}
