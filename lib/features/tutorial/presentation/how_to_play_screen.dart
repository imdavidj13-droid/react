import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key, this.firstRun = false});

  final bool firstRun;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.touch_app_rounded,
      title: 'TAP',
      command: 'TAP',
      description: 'Tap once anywhere in the play area before the timer runs out.',
      accent: ReactColors.electricBlueBright,
    ),
    _TutorialStep(
      icon: Icons.ads_click_rounded,
      title: 'DOUBLE TAP',
      command: 'DOUBLE TAP',
      description: 'Tap twice quickly. A single tap will not complete this command.',
      accent: ReactColors.purple,
    ),
    _TutorialStep(
      icon: Icons.pan_tool_alt_rounded,
      title: 'HOLD',
      command: 'HOLD',
      description: 'Press and keep your finger down until the hold completes.',
      accent: ReactColors.lime,
    ),
    _TutorialStep(
      icon: Icons.swipe_rounded,
      title: 'SWIPE',
      command: 'SWIPE ←  →  ↑  ↓',
      description: 'Swipe in the exact direction shown. There are four swipe commands.',
      accent: ReactColors.electricBlueBright,
    ),
    _TutorialStep(
      icon: Icons.zoom_in_map_rounded,
      title: 'PINCH',
      command: 'PINCH',
      description: 'Use two fingers and move them together toward the centre.',
      accent: ReactColors.coral,
    ),
    _TutorialStep(
      icon: Icons.zoom_out_map_rounded,
      title: 'SPREAD',
      command: 'SPREAD',
      description: 'Use two fingers and move them apart from each other.',
      accent: ReactColors.purple,
    ),
    _TutorialStep(
      icon: Icons.bolt_rounded,
      title: 'THAT\'S IT',
      command: 'REACT FAST',
      description: 'Follow the command before time runs out. Different modes change the pressure, but the gestures stay the same.',
      accent: ReactColors.lime,
    ),
  ];

  Future<void> _finish() async {
    if (widget.firstRun) {
      await ReactSettings.setHowToPlayCompleted(true);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _next() async {
    if (_page == _steps.length - 1) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    final horizontalPad = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 20.0;

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 18),
          child: Column(
            children: [
              Row(
                children: [
                  if (!widget.firstRun)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF07101E),
                        foregroundColor: ReactColors.textPrimary,
                        side: const BorderSide(color: Color(0xFF1E3552)),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    )
                  else
                    const SizedBox(width: 48),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'HOW TO PLAY',
                        style: TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.7,
                        ),
                      ),
                    ),
                  ),
                  if (widget.firstRun)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('SKIP'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: compact ? 10 : 18),
              const Text(
                '9 COMMANDS. ONE SIMPLE RULE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.25,
                ),
              ),
              SizedBox(height: compact ? 10 : 18),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) => _StepCard(
                    step: _steps[index],
                    compact: compact,
                  ),
                ),
              ),
              SizedBox(height: compact ? 10 : 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? _steps[_page].accent
                          : const Color(0xFF263851),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 10 : 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: _steps[_page].accent,
                    foregroundColor: const Color(0xFF02060B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Text(
                    _page == _steps.length - 1 ? 'LET\'S PLAY' : 'NEXT',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.compact});

  final _TutorialStep step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: step.accent.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: step.accent.withValues(alpha: .08),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 86 : 108,
            height: compact ? 86 : 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF040A13),
              border: Border.all(color: step.accent.withValues(alpha: .7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: step.accent.withValues(alpha: .18),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(step.icon, color: step.accent, size: compact ? 42 : 52),
          ),
          SizedBox(height: compact ? 18 : 26),
          Text(
            step.title,
            style: TextStyle(
              color: step.accent,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              step.command,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: compact ? 30 : 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.command,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String command;
  final String description;
  final Color accent;
}
