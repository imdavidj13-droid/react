import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SeasonProgressEvent {
  const SeasonProgressEvent({
    required this.eventId,
    required this.mode,
    required this.score,
    required this.successfulCommands,
    required this.isPersonalBest,
    required this.dailyModifier,
    required this.completedAt,
  });

  final String eventId;
  final String mode;
  final int score;
  final int successfulCommands;
  final bool isPersonalBest;
  final String? dailyModifier;
  final DateTime completedAt;

  bool get isDaily => mode == 'daily';

  String encode() => jsonEncode(<String, dynamic>{
        'event_id': eventId,
        'mode': mode,
        'score': score,
        'successful_commands': successfulCommands,
        'is_personal_best': isPersonalBest,
        'daily_modifier': dailyModifier,
        'completed_at': completedAt.toUtc().toIso8601String(),
      });

  static SeasonProgressEvent? tryDecode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final eventId = '${json['event_id'] ?? ''}'.trim();
      final completedAt = DateTime.tryParse('${json['completed_at'] ?? ''}');
      final explicitMode = '${json['mode'] ?? ''}'.trim();
      final mode = explicitMode.isNotEmpty ? explicitMode : _modeFromEventId(eventId);
      if (eventId.length < 8 || completedAt == null || !_validModes.contains(mode)) {
        return null;
      }
      return SeasonProgressEvent(
        eventId: eventId,
        mode: mode,
        score: (json['score'] as num?)?.round() ?? 0,
        successfulCommands:
            (json['successful_commands'] as num?)?.round() ?? 0,
        isPersonalBest: json['is_personal_best'] == true,
        dailyModifier: json['daily_modifier'] == null
            ? null
            : '${json['daily_modifier']}'.trim(),
        completedAt: completedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static const _validModes = <String>{
    'classic',
    'blitz',
    'endless',
    'daily',
    'passIt',
    'sequence',
  };

  static String _modeFromEventId(String eventId) {
    for (final mode in _validModes) {
      if (eventId.startsWith('season-$mode-')) return mode;
    }
    return '';
  }
}

abstract final class LocalSeasonProgressQueue {
  static const _pendingKey = 'season_pending_progress_events';

  // 200 runs can be exceeded during a long offline stretch and silently lost
  // the oldest progression. Keep a bounded queue, but large enough for a full
  // 21-day season of heavy play.
  static const _limit = 2048;
  static const _serverRetention = Duration(days: 30);

  static Future<void> enqueue(SeasonProgressEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingKey) ?? const <String>[];
    if (current.any((raw) {
      return SeasonProgressEvent.tryDecode(raw)?.eventId == event.eventId;
    })) {
      return;
    }
    final next = <String>[event.encode(), ...current]
        .take(_limit)
        .toList(growable: false);
    await prefs.setStringList(_pendingKey, next);
  }

  static Future<List<SeasonProgressEvent>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_pendingKey) ?? const <String>[];
    final now = DateTime.now().toUtc();
    final validRaw = <String>[];
    final events = <SeasonProgressEvent>[];

    for (final encoded in raw) {
      final event = SeasonProgressEvent.tryDecode(encoded);
      if (event == null) continue;
      if (now.difference(event.completedAt) > _serverRetention) continue;
      validRaw.add(encoded);
      events.add(event);
    }

    // Remove corrupt and permanently expired rows instead of retrying them on
    // every launch forever.
    if (validRaw.length != raw.length) {
      await prefs.setStringList(_pendingKey, validRaw);
    }
    return events;
  }

  static Future<void> remove(Iterable<String> eventIds) async {
    final ids = eventIds.toSet();
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final remaining = (prefs.getStringList(_pendingKey) ?? const <String>[])
        .where((raw) {
          final event = SeasonProgressEvent.tryDecode(raw);
          return event == null || !ids.contains(event.eventId);
        })
        .toList(growable: false);
    await prefs.setStringList(_pendingKey, remaining);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }
}
