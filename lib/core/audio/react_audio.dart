import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../settings/react_settings.dart';
import 'react_audio_storage.dart';

enum ReactSoundCue {
  countdownTick,
  countdownGo,
  command,
  success,
  miss,
  lifeLost,
  blitzWarning,
  handoff,
  completed,
}

/// Central sound-effect controller for RE△CT.
///
/// The temporary SFX are generated as small PCM WAV clips. On native
/// platforms those clips are persisted to temporary files and played with
/// [DeviceFileSource], which is substantially more reliable than feeding raw
/// in-memory bytes to the platform player. Non-IO platforms retain a bytes
/// fallback so the app can still compile and run there.
abstract final class ReactAudio {
  static const int _sampleRate = 22050;
  static const int _playerCount = 6;

  static final List<AudioPlayer> _players = List<AudioPlayer>.generate(
    _playerCount,
    (_) => AudioPlayer(),
  );
  static final Map<ReactSoundCue, Uint8List> _clips = _buildClips();
  static final Map<ReactSoundCue, String?> _nativeClipPaths = {};

  static int _nextPlayer = 0;
  static bool _initialized = false;
  static Future<void>? _initialization;

  static bool get enabled => ReactSettings.soundEnabled;

  static Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initialization ??= _initializeOnce();
  }

  static Future<void> _initializeOnce() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ),
    );

    for (final entry in _clips.entries) {
      _nativeClipPaths[entry.key] = await persistReactAudioClip(
        'react_${entry.key.name}',
        entry.value,
      );
    }

    for (final player in _players) {
      await player.setReleaseMode(ReleaseMode.stop);
    }

    ReactSettings.soundPreview = () => play(ReactSoundCue.success);
    _initialized = true;
  }

  static Future<void> play(ReactSoundCue cue) async {
    if (!enabled) return;

    try {
      await initialize();
    } catch (_) {
      // Audio initialization must never block gameplay. A later cue can retry.
      _initialization = null;
      return;
    }

    final bytes = _clips[cue];
    if (bytes == null) return;

    final player = _players[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _players.length;

    final nativePath = _nativeClipPaths[cue];

    try {
      await player.stop();
      if (nativePath != null) {
        await player.play(
          DeviceFileSource(nativePath),
          volume: _volumeFor(cue),
        );
      } else {
        await player.play(
          BytesSource(bytes, mimeType: 'audio/wav'),
          volume: _volumeFor(cue),
        );
      }
    } catch (_) {
      // Keep a final bytes fallback for platforms/player backends that reject
      // the native file source. Sound failure must never interrupt a run.
      try {
        await player.stop();
        await player.play(
          BytesSource(bytes, mimeType: 'audio/wav'),
          volume: _volumeFor(cue),
        );
      } catch (_) {}
    }
  }

  static double _volumeFor(ReactSoundCue cue) => switch (cue) {
    ReactSoundCue.command => .42,
    ReactSoundCue.countdownTick => .55,
    ReactSoundCue.handoff => .62,
    ReactSoundCue.success => .72,
    ReactSoundCue.countdownGo => .82,
    ReactSoundCue.miss => .85,
    ReactSoundCue.lifeLost => .90,
    ReactSoundCue.blitzWarning => .88,
    ReactSoundCue.completed => .90,
  };

  static Map<ReactSoundCue, Uint8List> _buildClips() => {
    ReactSoundCue.countdownTick: _wav([
      const _Tone(920, 70, .58),
    ]),
    ReactSoundCue.countdownGo: _wav([
      const _Tone(760, 55, .55),
      const _Tone(1220, 100, .72),
    ]),
    ReactSoundCue.command: _wav([
      const _Tone(1180, 38, .36),
    ]),
    ReactSoundCue.success: _wav([
      const _Tone(930, 48, .54),
      const _Tone(1420, 70, .68),
    ]),
    ReactSoundCue.miss: _wav([
      const _Tone(360, 85, .70),
      const _Tone(220, 110, .76),
    ]),
    ReactSoundCue.lifeLost: _wav([
      const _Tone(430, 70, .72),
      const _Tone(285, 90, .78),
      const _Tone(185, 120, .82),
    ]),
    ReactSoundCue.blitzWarning: _wav([
      const _Tone(980, 75, .72),
      const _Tone(0, 55, 0),
      const _Tone(980, 75, .72),
    ]),
    ReactSoundCue.handoff: _wav([
      const _Tone(620, 55, .48),
      const _Tone(820, 55, .54),
      const _Tone(1040, 65, .62),
    ]),
    ReactSoundCue.completed: _wav([
      const _Tone(720, 60, .56),
      const _Tone(980, 70, .64),
      const _Tone(1320, 110, .75),
    ]),
  };

  static Uint8List _wav(List<_Tone> tones) {
    final totalSamples = tones.fold<int>(
      0,
      (sum, tone) => sum + ((_sampleRate * tone.durationMs) / 1000).round(),
    );
    final dataLength = totalSamples * 2;
    final bytes = ByteData(44 + dataLength);

    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    var sampleIndex = 0;
    for (final tone in tones) {
      final samples = ((_sampleRate * tone.durationMs) / 1000).round();
      final edgeSamples = max(1, min(samples ~/ 3, (_sampleRate * .006).round()));

      for (var i = 0; i < samples; i++) {
        final attack = min(1.0, i / edgeSamples);
        final release = min(1.0, (samples - 1 - i) / edgeSamples);
        final envelope = min(attack, release).clamp(0.0, 1.0);
        final wave = tone.frequencyHz <= 0
            ? 0.0
            : sin(2 * pi * tone.frequencyHz * i / _sampleRate);
        final sample = (wave * envelope * tone.amplitude * 32767)
            .round()
            .clamp(-32768, 32767)
            .toInt();
        bytes.setInt16(44 + sampleIndex * 2, sample, Endian.little);
        sampleIndex += 1;
      }
    }

    return bytes.buffer.asUint8List();
  }
}

class _Tone {
  const _Tone(this.frequencyHz, this.durationMs, this.amplitude);

  final double frequencyHz;
  final int durationMs;
  final double amplitude;
}
