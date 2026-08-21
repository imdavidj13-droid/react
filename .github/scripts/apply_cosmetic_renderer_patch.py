from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_react_run() -> None:
    path = Path('lib/features/gameplay/presentation/react_run_screen.dart')
    text = path.read_text()
    text = replace_once(
        text,
        "import '../../results/presentation/results_screen.dart';\n",
        "import '../../results/presentation/results_screen.dart';\nimport '../../season/presentation/season_gameplay_style.dart';\n",
        'react import',
    )
    old_helpers = """Color _themeArenaSurfaceColor() => switch (ReactCosmetics.currentTheme) {
  ReactVisualTheme.core => const Color(0xFF050A13),
  ReactVisualTheme.redline => const Color(0xFF100609),
  ReactVisualTheme.synthwave => const Color(0xFF090718),
  ReactVisualTheme.mono => const Color(0xFF050505),
};

Color _themeBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF243A57)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _themeInnerBorderColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF153B65)
    : ReactCosmetics.palette.primary.withValues(alpha: .44);

Color _themeRingBaseColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF122038)
    : ReactCosmetics.palette.primary.withValues(alpha: .16);

Color _themeTimerTrackColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF10243D)
    : ReactCosmetics.palette.primary.withValues(alpha: .20);
"""
    new_helpers = """Color _themeArenaSurfaceColor() {
  final base = switch (ReactCosmetics.currentTheme) {
    ReactVisualTheme.core => const Color(0xFF050A13),
    ReactVisualTheme.redline => const Color(0xFF100609),
    ReactVisualTheme.synthwave => const Color(0xFF090718),
    ReactVisualTheme.mono => const Color(0xFF050505),
  };
  return SeasonGameplayStyle.arenaSurface(base);
}

Color _themeBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF243A57)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _themeInnerBorderColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF153B65)
      : ReactCosmetics.palette.primary.withValues(alpha: .44);
  return SeasonGameplayStyle.arenaInnerBorder(base);
}

Color _themeRingBaseColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF122038)
      : ReactCosmetics.palette.primary.withValues(alpha: .16);
  return SeasonGameplayStyle.arenaRingBase(base);
}

Color _themeTimerTrackColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF10243D)
      : ReactCosmetics.palette.primary.withValues(alpha: .20);
  return SeasonGameplayStyle.arenaTimerTrack(base);
}
"""
    text = replace_once(text, old_helpers, new_helpers, 'react arena helpers')
    old_hud = """      decoration: BoxDecoration(
        color: _themePanelColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _themeBorderColor()),
      ),
"""
    new_hud = """      decoration: BoxDecoration(
        color: SeasonGameplayStyle.hudPanel(_themePanelColor()),
        borderRadius: BorderRadius.circular(SeasonGameplayStyle.hudRadius),
        border: Border.all(
          color: SeasonGameplayStyle.hudBorder(_themeBorderColor()),
        ),
        boxShadow: SeasonGameplayStyle.hudShadow,
      ),
"""
    text = replace_once(text, old_hud, new_hud, 'react hud card')
    arena_start = text.index('class _Arena extends StatelessWidget')
    ring_start = text.index('class _RingPainter extends CustomPainter')
    arena = text[arena_start:ring_start]
    arena = replace_once(
        arena,
        "    final seconds = (commandDurationMs * progress / 1000).clamp(0, 9.9);\n",
        "    final seconds = (commandDurationMs * progress / 1000).clamp(0, 9.9);\n    final arenaAccent = SeasonGameplayStyle.arenaPrimary(accent);\n",
        'react arena accent declaration',
    )
    arena = arena.replace('color: accent,\n                  size:', 'color: arenaAccent,\n                  size:', 1)
    arena = arena.replace('color: progress < .2 ? palette.failure : accent,', "color: progress < .2\n                          ? SeasonGameplayStyle.arenaFailure(palette.failure)\n                          : arenaAccent,", 1)
    text = text[:arena_start] + arena + text[ring_start:]
    text = replace_once(
        text,
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = _themeRingBaseColor();
""",
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke
      ..color = _themeRingBaseColor();
""",
        'react arena base ring',
    )
    text = replace_once(
        text,
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    deco.color = palette.primary.withValues(alpha: .72);
""",
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke - 1
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap;
    deco.color = SeasonGameplayStyle.arenaPrimary(
      palette.primary,
    ).withValues(alpha: .72);
""",
        'react arena deco primary',
    )
    text = replace_once(text, "    deco.color = palette.secondary.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaSecondary(\n      palette.secondary,\n    ).withValues(alpha: .72);\n", 'react arena deco secondary')
    text = replace_once(text, "    deco.color = palette.failure.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaFailure(\n      palette.failure,\n    ).withValues(alpha: .72);\n", 'react arena deco failure')
    text = replace_once(
        text,
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _themeTimerTrackColor();
""",
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..color = _themeTimerTrackColor();
""",
        'react timer track',
    )
    text = replace_once(
        text,
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = progress < .18 ? palette.failure : accent;
""",
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap
      ..color = progress < .18
          ? SeasonGameplayStyle.arenaFailure(palette.failure)
          : SeasonGameplayStyle.arenaPrimary(accent);
""",
        'react timer arc',
    )
    path.write_text(text)


def patch_daily() -> None:
    path = Path('lib/features/daily/presentation/daily_run_screen.dart')
    text = path.read_text()
    text = replace_once(
        text,
        "import '../../results/presentation/results_screen.dart';\n",
        "import '../../results/presentation/results_screen.dart';\nimport '../../season/presentation/season_gameplay_style.dart';\n",
        'daily import',
    )
    old_helpers = """Color _dailyArenaSurfaceColor() => switch (ReactCosmetics.currentTheme) {
  ReactVisualTheme.core => const Color(0xFF050A13),
  ReactVisualTheme.redline => const Color(0xFF100609),
  ReactVisualTheme.synthwave => const Color(0xFF090718),
  ReactVisualTheme.mono => const Color(0xFF050505),
};

Color _dailyBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF243A57)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _dailyInnerBorderColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF153B65)
    : ReactCosmetics.palette.primary.withValues(alpha: .44);

Color _dailyRingBaseColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF122038)
    : ReactCosmetics.palette.primary.withValues(alpha: .16);

Color _dailyTimerTrackColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF10243D)
    : ReactCosmetics.palette.primary.withValues(alpha: .20);
"""
    new_helpers = """Color _dailyArenaSurfaceColor() {
  final base = switch (ReactCosmetics.currentTheme) {
    ReactVisualTheme.core => const Color(0xFF050A13),
    ReactVisualTheme.redline => const Color(0xFF100609),
    ReactVisualTheme.synthwave => const Color(0xFF090718),
    ReactVisualTheme.mono => const Color(0xFF050505),
  };
  return SeasonGameplayStyle.arenaSurface(base);
}

Color _dailyBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF243A57)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _dailyInnerBorderColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF153B65)
      : ReactCosmetics.palette.primary.withValues(alpha: .44);
  return SeasonGameplayStyle.arenaInnerBorder(base);
}

Color _dailyRingBaseColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF122038)
      : ReactCosmetics.palette.primary.withValues(alpha: .16);
  return SeasonGameplayStyle.arenaRingBase(base);
}

Color _dailyTimerTrackColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF10243D)
      : ReactCosmetics.palette.primary.withValues(alpha: .20);
  return SeasonGameplayStyle.arenaTimerTrack(base);
}
"""
    text = replace_once(text, old_helpers, new_helpers, 'daily arena helpers')
    old_hud = """      decoration: BoxDecoration(
        color: _dailyPanelColor(),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _dailyBorderColor()),
      ),
"""
    new_hud = """      decoration: BoxDecoration(
        color: SeasonGameplayStyle.hudPanel(_dailyPanelColor()),
        borderRadius: BorderRadius.circular(SeasonGameplayStyle.hudRadius),
        border: Border.all(
          color: SeasonGameplayStyle.hudBorder(_dailyBorderColor()),
        ),
        boxShadow: SeasonGameplayStyle.hudShadow,
      ),
"""
    text = replace_once(text, old_hud, new_hud, 'daily hud card')
    arena_start = text.index('class _DailyArena extends StatelessWidget')
    ring_start = text.index('class _DailyRingPainter extends CustomPainter')
    arena = text[arena_start:ring_start]
    arena = replace_once(
        arena,
        "    final accent = redline ? palette.failure : palette.primary;\n",
        "    final accent = redline\n        ? palette.failure\n        : SeasonGameplayStyle.arenaPrimary(palette.primary);\n",
        'daily arena accent',
    )
    text = text[:arena_start] + arena + text[ring_start:]
    text = replace_once(
        text,
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = _dailyRingBaseColor();
""",
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke
      ..color = _dailyRingBaseColor();
""",
        'daily base ring',
    )
    text = replace_once(
        text,
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    deco.color = palette.primary.withValues(alpha: .72);
""",
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke - 1
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap;
    deco.color = SeasonGameplayStyle.arenaPrimary(
      palette.primary,
    ).withValues(alpha: .72);
""",
        'daily deco primary',
    )
    text = replace_once(text, "    deco.color = palette.secondary.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaSecondary(\n      palette.secondary,\n    ).withValues(alpha: .72);\n", 'daily deco secondary')
    text = replace_once(text, "    deco.color = palette.failure.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaFailure(\n      palette.failure,\n    ).withValues(alpha: .72);\n", 'daily deco failure')
    text = replace_once(
        text,
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _dailyTimerTrackColor();
""",
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..color = _dailyTimerTrackColor();
""",
        'daily timer track',
    )
    text = replace_once(
        text,
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = progress < .18 ? palette.failure : accent;
""",
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap
      ..color = progress < .18
          ? palette.failure
          : SeasonGameplayStyle.arenaPrimary(accent);
""",
        'daily timer arc',
    )
    path.write_text(text)


def patch_sequence() -> None:
    path = Path('lib/features/dot_sequence/presentation/dot_sequence_screen.dart')
    text = path.read_text()
    text = replace_once(
        text,
        "import '../../results/presentation/results_screen.dart';\n",
        "import '../../results/presentation/results_screen.dart';\nimport '../../season/presentation/season_gameplay_style.dart';\n",
        'sequence import',
    )
    old_helpers = """Color _themeArenaSurfaceColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF050A13),
      ReactVisualTheme.redline => const Color(0xFF100609),
      ReactVisualTheme.synthwave => const Color(0xFF090718),
      ReactVisualTheme.mono => const Color(0xFF050505),
    };

Color _themeDotSurfaceColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF06101D),
      ReactVisualTheme.redline => const Color(0xFF16090C),
      ReactVisualTheme.synthwave => const Color(0xFF100B24),
      ReactVisualTheme.mono => const Color(0xFF0C0C0C),
    };

Color _themeBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF254766)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _themeInnerBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF153B65)
    : ReactCosmetics.palette.primary.withValues(alpha: .44);

Color _themeRingBaseColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF122038)
    : ReactCosmetics.palette.primary.withValues(alpha: .16);

Color _themeTimerTrackColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF10243D)
    : ReactCosmetics.palette.primary.withValues(alpha: .20);
"""
    new_helpers = """Color _themeArenaSurfaceColor() {
  final base = switch (ReactCosmetics.currentTheme) {
    ReactVisualTheme.core => const Color(0xFF050A13),
    ReactVisualTheme.redline => const Color(0xFF100609),
    ReactVisualTheme.synthwave => const Color(0xFF090718),
    ReactVisualTheme.mono => const Color(0xFF050505),
  };
  return SeasonGameplayStyle.arenaSurface(base);
}

Color _themeDotSurfaceColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF06101D),
      ReactVisualTheme.redline => const Color(0xFF16090C),
      ReactVisualTheme.synthwave => const Color(0xFF100B24),
      ReactVisualTheme.mono => const Color(0xFF0C0C0C),
    };

Color _themeBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF254766)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _themeInnerBorderColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF153B65)
      : ReactCosmetics.palette.primary.withValues(alpha: .44);
  return SeasonGameplayStyle.arenaInnerBorder(base);
}

Color _themeRingBaseColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF122038)
      : ReactCosmetics.palette.primary.withValues(alpha: .16);
  return SeasonGameplayStyle.arenaRingBase(base);
}

Color _themeTimerTrackColor() {
  final base = ReactCosmetics.currentTheme == ReactVisualTheme.core
      ? const Color(0xFF10243D)
      : ReactCosmetics.palette.primary.withValues(alpha: .20);
  return SeasonGameplayStyle.arenaTimerTrack(base);
}
"""
    text = replace_once(text, old_helpers, new_helpers, 'sequence arena helpers')
    old_hud = """        decoration: BoxDecoration(
          color: _themePanelColor(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _themeBorderColor()),
        ),
"""
    new_hud = """        decoration: BoxDecoration(
          color: SeasonGameplayStyle.hudPanel(_themePanelColor()),
          borderRadius: BorderRadius.circular(SeasonGameplayStyle.hudRadius),
          border: Border.all(
            color: SeasonGameplayStyle.hudBorder(_themeBorderColor()),
          ),
          boxShadow: SeasonGameplayStyle.hudShadow,
        ),
"""
    text = replace_once(text, old_hud, new_hud, 'sequence hud card')
    text = replace_once(
        text,
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = _themeRingBaseColor();
""",
        """    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke
      ..color = _themeRingBaseColor();
""",
        'sequence base ring',
    )
    text = replace_once(
        text,
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    deco.color = palette.primary.withValues(alpha: .72);
""",
        """    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaRingStroke - 1
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap;
    deco.color = SeasonGameplayStyle.arenaPrimary(
      palette.primary,
    ).withValues(alpha: .72);
""",
        'sequence deco primary',
    )
    text = replace_once(text, "    deco.color = palette.secondary.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaSecondary(\n      palette.secondary,\n    ).withValues(alpha: .72);\n", 'sequence deco secondary')
    text = replace_once(text, "    deco.color = palette.failure.withValues(alpha: .72);\n", "    deco.color = SeasonGameplayStyle.arenaFailure(\n      palette.failure,\n    ).withValues(alpha: .72);\n", 'sequence deco failure')
    text = replace_once(
        text,
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _themeTimerTrackColor();
""",
        """    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..color = _themeTimerTrackColor();
""",
        'sequence timer track',
    )
    text = replace_once(
        text,
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = progress < .22 ? palette.failure : palette.primary;
""",
        """    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = SeasonGameplayStyle.arenaStrokeCap
      ..strokeWidth = SeasonGameplayStyle.arenaTimerStroke
      ..color = progress < .22
          ? SeasonGameplayStyle.arenaFailure(palette.failure)
          : SeasonGameplayStyle.arenaPrimary(palette.primary);
""",
        'sequence timer arc',
    )
    path.write_text(text)


patch_react_run()
patch_daily()
patch_sequence()
