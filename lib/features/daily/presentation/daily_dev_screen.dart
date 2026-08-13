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

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await ReactSettings.setDailyDevOverrideEnabled(value);
  }

  Future<void> _select(DailyModifier modifier) async {
    setState(() => _modifier = modifier);
    await ReactSettings.setDailyDevModifier(modifier.name);
  }

  Future<void> _launch() async {
    if (!_enabled) await _setEnabled(true);
    if (!mounted) return;
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
                'OVERRIDE TODAY\'S MODIFIER',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: const Text(
                'Developer only. Normal Daily rotation returns when disabled.',
                style: TextStyle(color: ReactColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            ...DailyModifier.values.map(
              (modifier) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<DailyModifier>(
                  value: modifier,
                  groupValue: _modifier,
                  onChanged: (value) {
                    if (value != null) _select(value);
                  },
                  activeColor: ReactColors.electricBlueBright,
                  tileColor: const Color(0xFF07111D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: modifier == _modifier
                          ? ReactColors.electricBlueBright
                          : const Color(0xFF263851),
                    ),
                  ),
                  title: Text(
                    modifier.label,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    modifier.shortRule,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _launch,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF168CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.science_rounded),
                label: Text(
                  'TEST ${_modifier.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'DEV TEST RUNS DO NOT CONSUME THE NORMAL DAILY ATTEMPT.',
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
