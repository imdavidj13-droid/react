import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SeasonProgressEvent {
  const SeasonProgressEvent({
    required this.eventId,
    required this.score,
    required this.successfulCommands,
    required this.isPersonalBest,
    required this.isDaily,
    required this.completedAt,
  });

  final String eventId;
  final int score;
  final int successfulCommands;
  final bool isPersonalBest;
  final bool isDaily;
  final DateTime completedAt;

  String encode() => jsonEncode(<String, dynamic>{
        'event_id': eventId,
        'score': score,
        'successful_commands': successfulCommands,
        'is_personal_best': isPersonalBest,
        'is_daily': isDaily,
        'completed_at': completedAt.toUtc().toIso8601String(),
      });

  static SeasonProgressEvent? tryDecode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final eventId = '${json['event_id'] ?? ''}'.trim();
      final completedAt = DateTime.tryParse('${json['completed_at'] ?? ''}');
      if (eventId.length < 8 || completedAt == null) return null;
      return SeasonProgressEvent(
        eventId: eventId,
        score: (json['score'] as num?)?.round() ?? 0,
        successfulCommands:
            (json['successful_commands'] as num?)?.round() ?? 0,
        isPersonalBest: json['is_personal_best'] == true,
        isDaily: json['is_daily'] == true,
        completedAt: completedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}

abstract final class LocalSeasonProgressQueue {
  static const _pendingKey = 'season_pending_progress_events';
  static const _limit = 200;

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
    return (prefs.getStringList(_pendingKey) ?? const <String>[])
        .map(SeasonProgressEvent.tryDecode)
        .whereType<SeasonProgressEvent>()
        .toList(growable: false);
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
