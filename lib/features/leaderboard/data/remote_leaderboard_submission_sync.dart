import 'package:flutter/foundation.dart';

import '../../../core/backend/react_supabase.dart';
import '../domain/leaderboard_submission.dart';
import 'local_leaderboard_submission_store.dart';

class RemoteLeaderboardSubmissionSync {
  const RemoteLeaderboardSubmissionSync._();

  static Future<int> flushPending() async {
    final client = ReactSupabase.client;
    if (client == null || client.auth.currentSession == null) return 0;

    final pending = await LocalLeaderboardSubmissionStore.pending();
    if (pending.isEmpty) return 0;

    final submittedIds = <String>[];

    for (final submission in pending) {
      try {
        await client.rpc(
          'submit_leaderboard_score',
          params: _rpcParams(submission),
        );
        submittedIds.add(submission.clientSubmissionId);
      } catch (error) {
        // Keep failed submissions in the local queue. A later launch/network
        // recovery can retry them without losing the completed run.
        debugPrint(
          'RE△CT leaderboard submission ${submission.clientSubmissionId} '
          'failed; keeping queued: $error',
        );
      }
    }

    await LocalLeaderboardSubmissionStore.removeSubmitted(submittedIds);
    return submittedIds.length;
  }

  static Map<String, dynamic> _rpcParams(LeaderboardSubmission submission) {
    return <String, dynamic>{
      'p_client_submission_id': submission.clientSubmissionId,
      'p_schema_version': LeaderboardSubmission.schemaVersion,
      'p_mode': submission.mode.name,
      'p_score': submission.score,
      'p_successful_commands': submission.successfulCommands,
      'p_average_reaction_seconds': submission.averageReactionSeconds,
      'p_misses': submission.misses,
      'p_max_streak': submission.maxStreak,
      'p_outcome': submission.outcome.name,
      'p_completed_at': submission.completedAt.toUtc().toIso8601String(),
      'p_daily_date': submission.dailyDate == null
          ? null
          : _dateOnly(submission.dailyDate!),
      'p_daily_modifier_label': submission.dailyModifierLabel,
    };
  }

  static String _dateOnly(DateTime date) {
    final normalized = date.toLocal();
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}
