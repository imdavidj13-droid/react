from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_profile() -> None:
    path = Path('lib/features/player/presentation/player_profile_screen.dart')
    text = path.read_text()

    text = replace_once(
        text,
        """            _SeasonIdentityPill(
              icon: Icons.workspace_premium_rounded,
              label: badge.name,
              color: badgeAccent,
            ),
""",
        """            _SeasonIdentityPill(
              icon: _badgeIcon(badge.rewardKey),
              label: badge.name,
              color: badgeAccent,
              rewardKey: badge.rewardKey,
            ),
""",
        'badge call',
    )

    text = replace_once(
        text,
        """class _SeasonIdentityPill extends StatelessWidget {
  const _SeasonIdentityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
""",
        """class _SeasonIdentityPill extends StatelessWidget {
  const _SeasonIdentityPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.rewardKey,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String rewardKey;

  @override
  Widget build(BuildContext context) {
    final angular = rewardKey.contains('charge') || rewardKey.contains('pressure');
    final strong = rewardKey.contains('reflex') || rewardKey.contains('overdrive');
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: EdgeInsets.symmetric(
        horizontal: angular ? 11 : 9,
        vertical: strong ? 6 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? .13 : .08),
        borderRadius: BorderRadius.circular(angular ? 7 : 99),
        border: Border.all(
          color: color.withValues(alpha: strong ? .68 : .42),
          width: strong ? 1.5 : 1,
        ),
        boxShadow: strong
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .16),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
""",
        'badge component',
    )

    anchor = "IconData _emblemIcon(String rewardKey) {"
    if text.count(anchor) != 1:
        raise RuntimeError(f"emblem helper anchor: expected exactly one match, found {text.count(anchor)}")
    badge_helper = """IconData _badgeIcon(String rewardKey) {
  if (rewardKey.contains('ignition')) return Icons.local_fire_department_rounded;
  if (rewardKey.contains('live_wire')) return Icons.electric_bolt_rounded;
  if (rewardKey.contains('reflex')) return Icons.visibility_rounded;
  if (rewardKey.contains('charge')) return Icons.battery_charging_full_rounded;
  if (rewardKey.contains('pressure')) return Icons.speed_rounded;
  return Icons.workspace_premium_rounded;
}

"""
    text = text.replace(anchor, badge_helper + anchor, 1)
    path.write_text(text)


def patch_results() -> None:
    path = Path('lib/features/results/presentation/results_screen.dart')
    text = path.read_text()

    text = replace_once(
        text,
        """    final scoreAccent = scoreEffect == null
        ? ReactColors.lime
        : SeasonCosmeticLayers.accentForReward(scoreEffect);

    return Column(
""",
        """    final scoreAccent = scoreEffect == null
        ? ReactColors.lime
        : SeasonCosmeticLayers.accentForReward(scoreEffect);
    final scoreKey = scoreEffect?.rewardKey ?? '';
    final scoreRadius = scoreKey.contains('arc')
        ? 8.0
        : scoreKey.contains('streak')
            ? 999.0
            : scoreKey.contains('overload')
                ? 4.0
                : 20.0;
    final scoreBorderWidth = scoreKey.contains('overload')
        ? 2.2
        : scoreKey.contains('arc')
            ? 1.7
            : 1.0;
    final scoreGlow = scoreKey.contains('overload')
        ? 34.0
        : scoreKey.contains('streak')
            ? 26.0
            : 22.0;

    return Column(
""",
        'score style vars',
    )

    text = replace_once(
        text,
        """                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      scoreAccent.withValues(alpha: .12),
                      scoreAccent.withValues(alpha: .025),
                    ],
                  ),
                  border: Border.all(color: scoreAccent.withValues(alpha: .42)),
                  boxShadow: [
                    BoxShadow(
                      color: scoreAccent.withValues(alpha: .18),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
""",
        """                  borderRadius: BorderRadius.circular(scoreRadius),
                  gradient: LinearGradient(
                    begin: scoreKey.contains('arc')
                        ? Alignment.centerLeft
                        : Alignment.topLeft,
                    end: scoreKey.contains('arc')
                        ? Alignment.centerRight
                        : Alignment.bottomRight,
                    colors: [
                      scoreAccent.withValues(
                        alpha: scoreKey.contains('overload') ? .20 : .12,
                      ),
                      scoreAccent.withValues(
                        alpha: scoreKey.contains('streak') ? .06 : .025,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: scoreAccent.withValues(
                      alpha: scoreKey.contains('overload') ? .78 : .42,
                    ),
                    width: scoreBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreAccent.withValues(
                        alpha: scoreKey.contains('overload') ? .30 : .18,
                      ),
                      blurRadius: scoreGlow,
                      spreadRadius: scoreKey.contains('overload') ? 3 : 1,
                    ),
                  ],
""",
        'score decoration',
    )

    text = replace_once(
        text,
        """    final accent = effect == null
        ? color
        : SeasonCosmeticLayers.accentForReward(effect);

    return Container(
""",
        """    final accent = effect == null
        ? color
        : SeasonCosmeticLayers.accentForReward(effect);
    final effectKey = effect?.rewardKey ?? '';
    final effectRadius = effectKey.contains('shatter')
        ? 6.0
        : effectKey.contains('blackout')
            ? 2.0
            : effectKey.contains('red_arc')
                ? 12.0
                : effectKey.contains('flash')
                    ? 28.0
                    : effectKey.contains('overdrive')
                        ? 8.0
                        : 18.0;
    final effectBorderWidth = effectKey.contains('blackout') ||
            effectKey.contains('overdrive')
        ? 2.0
        : effectKey.contains('shatter')
            ? 1.7
            : 1.5;
    final effectGlow = effectKey.contains('flash')
        ? 30.0
        : effectKey.contains('blackout')
            ? 8.0
            : effectKey.contains('overdrive')
                ? 26.0
                : 20.0;

    return Container(
""",
        'outcome style vars',
    )

    text = replace_once(
        text,
        """        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: effect == null ? .62 : .78),
          width: effect == null ? 1 : 1.5,
        ),
        boxShadow: effect == null
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: .14),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
""",
        """        borderRadius: BorderRadius.circular(effect == null ? 18 : effectRadius),
        border: Border.all(
          color: accent.withValues(
            alpha: effect == null
                ? .62
                : effectKey.contains('blackout')
                    ? .38
                    : .78,
          ),
          width: effect == null ? 1 : effectBorderWidth,
        ),
        boxShadow: effect == null
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(
                    alpha: effectKey.contains('blackout') ? .08 : .18,
                  ),
                  blurRadius: effectGlow,
                  spreadRadius: effectKey.contains('overdrive') ? 2 : 1,
                ),
              ],
""",
        'outcome outer decoration',
    )

    text = replace_once(
        text,
        """            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: .08),
              border: Border.all(color: accent.withValues(alpha: .32)),
""",
        """            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: effectKey.contains('blackout') ? .03 : .08,
              ),
              borderRadius: BorderRadius.circular(
                effect == null
                    ? 99
                    : effectKey.contains('shatter')
                        ? 5
                        : effectKey.contains('overdrive')
                            ? 9
                            : 99,
              ),
              border: Border.all(
                color: accent.withValues(
                  alpha: effectKey.contains('blackout') ? .18 : .32,
                ),
              ),
""",
        'outcome icon decoration',
    )
    path.write_text(text)


def patch_preview() -> None:
    path = Path('lib/features/season/presentation/season_reward_preview.dart')
    text = path.read_text()
    text = replace_once(
        text,
        """            fontWeight: FontWeight.w900,
            fontFamily: terminal ? 'monospace' : null,
            fontStyle: keyName.contains('glitch') ? FontStyle.italic : null,
            letterSpacing: terminal ? 1.5 : .8,
""",
        """            fontWeight: FontWeight.w900,
            letterSpacing: terminal ? 1.5 : .8,
""",
        'command preview typography',
    )
    path.write_text(text)


patch_profile()
patch_results()
patch_preview()
