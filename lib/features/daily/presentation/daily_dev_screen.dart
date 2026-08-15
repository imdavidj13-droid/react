import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../domain/daily_challenge.dart';

class DailyDevScreen extends StatefulWidget {
  const DailyDevScreen({super.key});

  @override
  State<DailyDevScreen> createState() => _DailyDevScreenState();
}

class _DailyDevScreenState extends State<DailyDevScreen> {
  late bool _enabled;
  late DailyModifier _modifier;

  @override
  void initState() {
    super.initState();
    _enabled = ReactSettings.dailyDevOverrideEnabled;
    _modifier = DailyModifier.values.firstWhere(
      (value) => value.name == ReactSettings.dailyDevModifier,
      orElse: () => DailyModifier.lightsOut,
    );
  }

  @override
  void dispose() {
    ReactSettings.dailyDevRunActive = false;
    super.dispose();
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await ReactSettings.setDailyDevOverrideEnabled(value);
  }

  Future<void> _select(DailyModifier modifier) async {
    setState(() => _modifier = modifier);
    await ReactSettings.setDailyDevModifier(modifier.name);
  }

  Future<void> _launch() async {
    if (!_enabled || !mounted) return;

    // Keep the dev identity alive for the whole tester flow. The launch screen
    // replaces itself with Daily gameplay, so clearing this in a try/finally
    // here would clear it as soon as that replacement happens, before the run
    // reaches Results.
    ReactSettings.dailyDevRunActive = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReactRunLaunchScreen(
          mode: ReactGameMode.daily,
          consumeDailyAttempt: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      appBar: AppBar(
        backgroundColor: ReactColors.background,
        foregroundColor: ReactColors.textPrimary,
        title: const Text('DAILY DEV TEST'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            SwitchListTile(
              value: _enabled,
              onChanged: _setEnabled,
              activeThumbColor: ReactColors.electricBlueBright,
              title: const Text(
                'ENABLE DEV MODIFIER RUNS',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: const Text(
                'Developer runs only. Normal Daily always keeps its calendar modifier.',
                style: TextStyle(color: ReactColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            ...DailyModifier.values.map(
              (modifier) {
                final selected = modifier == _modifier;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _select(modifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07111D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? ReactColors.electricBlueBright
                              : const Color(0xFF263851),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? ReactColors.electricBlueBright
                                : ReactColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modifier.label,
                                  style: const TextStyle(
                                    color: ReactColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  modifier.shortRule,
                                  style: const TextStyle(
                                    color: ReactColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _enabled ? _launch : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF168CFF),
                  disabledBackgroundColor: const Color(0xFF0C243B),
                  disabledForegroundColor: ReactColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.science_rounded),
                label: Text(
                  _enabled ? 'TEST ${_modifier.label}' : 'ENABLE DEV RUNS TO TEST',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'DEV TEST RUNS DO NOT CHANGE NORMAL DAILY HISTORY, STREAKS OR RECORDS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
