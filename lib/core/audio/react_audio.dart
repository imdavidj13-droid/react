import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../cosmetics/react_cosmetics.dart';
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
/// Both built-in sound packs are generated as PCM WAV clips. On native
/// platforms those clips are persisted to temporary files and played with
/// [DeviceFileSource]. The equipped sound pack is selected independently from
/// the visual theme, so players can mix cosmetics.
abstract final class ReactAudio {
  static const int _sampleRate = 22050;
  static const int _playerCount = 6;
  static const int _rapidSuccessCooldownMs = 170;

  static final List<AudioPlayer> _players = List<AudioPlayer>.generate(
    _playerCount,
    (_) => AudioPlayer(),
  );

  static final Map<ReactSoundPack, Map<ReactSoundCue, Uint8List>> _clipSets = {
    ReactSoundPack.core: _buildCoreClips(),
    ReactSoundPack.arcade: _buildArcadeClips(),
  };

  static final Map<ReactSoundPack, Map<ReactSoundCue, String?>> _nativeClipPaths = {};

  static int _nextPlayer = 0;
  static bool _initialized = false;
  static Future<void>? _initialization;
  static ReactSoundCue? _lastRequestedCue;
  static int _lastRequestedCueMs = -1000000;

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

    for (final packEntry in _clipSets.entries) {
      final paths = <ReactSoundCue, String?>{};
      for (final cueEntry in packEntry.value.entries) {
        paths[cueEntry.key] = await persistReactAudioClip(
          'react_${packEntry.key.name}_${cueEntry.key.name}',
          cueEntry.value,
        );
      }
      _nativeClipPaths[packEntry.key] = paths;
    }

    for (final player in _players) {
      await player.setReleaseMode(ReleaseMode.stop);
    }

    ReactSettings.soundPreview = () => play(ReactSoundCue.success);
    _initialized = true;
  }

  static Future<void> play(ReactSoundCue cue) async {
    if (!enabled) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (cue == ReactSoundCue.success &&
        _lastRequestedCue == ReactSoundCue.success &&
        nowMs - _lastRequestedCueMs < _rapidSuccessCooldownMs) {
      _lastRequestedCueMs = nowMs;
      return;
    }
    _lastRequestedCue = cue;
    _lastRequestedCueMs = nowMs;

    try {
      await initialize();
    } catch (_) {
      // Audio initialization must never block gameplay. A later cue can retry.
      _initialization = null;
      return;
    }

    final pack = ReactCosmetics.currentSoundPack;
    final bytes = _clipSets[pack]?[cue] ?? _clipSets[ReactSoundPack.core]?[cue];
    if (bytes == null) return;

    final player = _players[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _players.length;

    final nativePath =
        _nativeClipPaths[pack]?[cue] ?? _nativeClipPaths[ReactSoundPack.core]?[cue];

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

  static Map<ReactSoundCue, Uint8List> _buildCoreClips() => {
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

  /// Brighter, more stepped cues inspired by compact arcade bleeps. The pack
  /// remains intentionally short and non-musical so it does not alter timing.
  static Map<ReactSoundCue, Uint8List> _buildArcadeClips() => {
    ReactSoundCue.countdownTick: _wav([
      const _Tone(1280, 34, .60),
      const _Tone(960, 34, .48),
    ]),
    ReactSoundCue.countdownGo: _wav([
      const _Tone(880, 38, .52),
      const _Tone(1320, 42, .62),
      const _Tone(1760, 78, .72),
    ]),
    ReactSoundCue.command: _wav([
      const _Tone(1540, 24, .38),
      const _Tone(1180, 24, .28),
    ]),
    ReactSoundCue.success: _wav([
      const _Tone(1040, 34, .48),
      const _Tone(1320, 36, .58),
      const _Tone(1760, 62, .72),
    ]),
    ReactSoundCue.miss: _wav([
      const _Tone(520, 46, .68),
      const _Tone(390, 52, .74),
      const _Tone(260, 82, .78),
    ]),
    ReactSoundCue.lifeLost: _wav([
      const _Tone(620, 46, .68),
      const _Tone(465, 52, .72),
      const _Tone(310, 58, .78),
      const _Tone(155, 92, .84),
    ]),
    ReactSoundCue.blitzWarning: _wav([
      const _Tone(1480, 42, .72),
      const _Tone(0, 38, 0),
      const _Tone(1480, 42, .72),
      const _Tone(0, 38, 0),
      const _Tone(1760, 55, .78),
    ]),
    ReactSoundCue.handoff: _wav([
      const _Tone(780, 34, .46),
      const _Tone(1040, 34, .52),
      const _Tone(1320, 34, .60),
      const _Tone(1560, 50, .68),
    ]),
    ReactSoundCue.completed: _wav([
      const _Tone(880, 40, .48),
      const _Tone(1175, 42, .56),
      const _Tone(1480, 44, .64),
      const _Tone(1975, 92, .76),
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
