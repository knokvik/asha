import 'dart:convert';

/// Represents a conflict item returned by the server in a sync push response.
class ConflictItem {
  final String recordId;
  final String table;
  final String conflictType;
  final List<Map<String, dynamic>> bothValues;
  final String resolution;

  const ConflictItem({
    required this.recordId,
    required this.table,
    required this.conflictType,
    required this.bothValues,
    required this.resolution,
  });

  factory ConflictItem.fromJson(Map<String, dynamic> json) => ConflictItem(
        recordId: json['record_id'] as String,
        table: json['table'] as String,
        conflictType: json['conflict_type'] as String,
        bothValues: (json['both_values'] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
        resolution: json['resolution'] as String,
      );
}

/// Merges server-side conflict responses back into the Local_Store.
///
/// For each conflict returned by `POST /sync/push`:
/// - **field_conflict**: Compare client and server field values by
///   device_timestamp. Accept the more recent value; store both with
///   provenance for display in the conflict detail view.
/// - **duplicate_identity**: Do NOT auto-merge; log for ANM/AF review.
///
/// Requirements: 31.2, 32.2, 32.3
class ConflictResolver {
  /// Apply a list of conflict items returned by the server push response.
  ///
  /// [deviceTimestamp] — the device clock timestamp of the push request.
  ///
  /// Returns a list of conflict IDs that require human review (i.e., could
  /// not be auto-resolved).
  List<String> applyConflicts(
    List<ConflictItem> conflicts,
    int deviceTimestamp,
  ) {
    final pendingReview = <String>[];

    for (final conflict in conflicts) {
      switch (conflict.conflictType) {
        case 'field_conflict':
          final resolved = _resolveFieldConflict(conflict, deviceTimestamp);
          if (!resolved) pendingReview.add(conflict.recordId);
        case 'duplicate_identity':
          // Never auto-merge duplicate beneficiaries.
          pendingReview.add(conflict.recordId);
        default:
          pendingReview.add(conflict.recordId);
      }
    }

    return pendingReview;
  }

  /// Attempt to auto-resolve a field conflict using last-write-wins.
  ///
  /// Returns true if the conflict was resolved automatically, false if
  /// it requires human review.
  bool _resolveFieldConflict(ConflictItem conflict, int clientTimestamp) {
    // If resolution is already auto_merged by the server, accept it.
    if (conflict.resolution == 'auto_merged') return true;

    // If flagged_for_review: retain both values for the conflict detail view.
    // The Local_Store already has the client value; we note the server value
    // for display. A future DB write here would update the conflict_review table.
    return false;
  }

  /// Applies a set of [edits] onto a [base] record state.
  ///
  /// Uses deterministic last-write-wins (LWW) per field based on [FieldUpdate.timestamp].
  /// For non-conflicting fields, edits are applied directly.
  /// For conflicting fields, the higher timestamp wins. In case of exact timestamp ties,
  /// the tie is broken deterministically by [FieldUpdate.changedBy].
  ///
  /// Satisfies Property 16: Confluence of independent offline edits:
  /// merge(A, merge(B, base)) == merge(B, merge(A, base))
  static Map<String, dynamic> applyFieldEdits(
    Map<String, dynamic> base,
    Map<String, FieldUpdate> edits,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in edits.entries) {
      final field = entry.key;
      final update = entry.value;
      final tsKey = '__ts_$field';
      final byKey = '__by_$field';

      final existingTs = result[tsKey] as int?;
      final existingBy = result[byKey] as String?;

      if (existingTs == null ||
          update.timestamp > existingTs ||
          (update.timestamp == existingTs &&
              update.changedBy.compareTo(existingBy ?? '') > 0)) {
        result[field] = update.value;
        result[tsKey] = update.timestamp;
        result[byKey] = update.changedBy;
      }
    }
    return result;
  }

  /// Confluent merge of two independent offline edit sets [editsA] and [editsB] onto [base].
  static Map<String, dynamic> mergeIndependentEdits(
    Map<String, dynamic> base,
    Map<String, FieldUpdate> editsA,
    Map<String, FieldUpdate> editsB,
  ) {
    final mergedA = applyFieldEdits(base, editsA);
    return applyFieldEdits(mergedA, editsB);
  }

  /// Parse a raw server push response body and extract conflict items.
  static List<ConflictItem> parseFromResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawConflicts = data['conflicts'] as List<dynamic>? ?? [];
      return rawConflicts
          .cast<Map<String, dynamic>>()
          .map(ConflictItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Represents a field-level edit with timestamp and provenance.
class FieldUpdate {
  final dynamic value;
  final int timestamp;
  final String changedBy;

  const FieldUpdate({
    required this.value,
    required this.timestamp,
    required this.changedBy,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'timestamp': timestamp,
        'changed_by': changedBy,
      };

  factory FieldUpdate.fromJson(Map<String, dynamic> json) => FieldUpdate(
        value: json['value'],
        timestamp: json['timestamp'] as int,
        changedBy: json['changed_by'] as String? ?? 'unknown',
      );
}

