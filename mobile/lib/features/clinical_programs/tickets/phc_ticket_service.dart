import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'phc_review_ticket.dart';

/// Firestore-backed service for creating and observing PHC review tickets.
///
/// Collection path: `phc_review_tickets`
/// Index required:  (ashaId ASC, submittedAt DESC)
class PhcTicketService {
  final FirebaseFirestore _fs;
  static const _collection = 'phc_review_tickets';
  static const _uuid = Uuid();

  PhcTicketService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs.collection(_collection);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new review ticket in Firestore.
  ///
  /// Returns the created [PhcReviewTicket].
  Future<PhcReviewTicket> createTicket({
    required String programCode,
    required String encounterId,
    required String memberId,
    required String memberName,
    required String ashaId,
    required String ashaName,
    required Map<String, String> formDataSummary,
  }) async {
    final meta = ClinicalProgramMeta.fromCode(programCode);
    final ticketId = _uuid.v4();
    final now = DateTime.now();

    final ticket = PhcReviewTicket(
      ticketId: ticketId,
      programCode: programCode,
      programDisplayName: meta?.displayName ?? programCode.toUpperCase(),
      encounterId: encounterId,
      memberId: memberId,
      memberName: memberName,
      ashaId: ashaId,
      ashaName: ashaName,
      submittedAt: now,
      status: TicketStatus.pending,
      formDataSummary: formDataSummary,
    );

    await _col.doc(ticketId).set(ticket.toFirestore());
    return ticket;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches a single ticket by ID.
  Future<PhcReviewTicket?> getTicket(String ticketId) async {
    final snap = await _col.doc(ticketId).get();
    if (!snap.exists) return null;
    return PhcReviewTicket.fromFirestore(snap);
  }

  /// Returns the most recent ticket for each program code for a given ASHA worker.
  ///
  /// This drives the per-card status badges on the programs hub.
  Future<Map<String, PhcReviewTicket>> getLatestTicketsPerProgram(
      String ashaId) async {
    final snap = await _col
        .where('ashaId', isEqualTo: ashaId)
        .orderBy('submittedAt', descending: true)
        .limit(50)
        .get();

    final result = <String, PhcReviewTicket>{};
    for (final doc in snap.docs) {
      final ticket = PhcReviewTicket.fromFirestore(doc);
      // Only keep the most recent per program
      result.putIfAbsent(ticket.programCode, () => ticket);
    }
    return result;
  }

  /// Streams all tickets for a given ASHA worker, ordered by submission time.
  Stream<List<PhcReviewTicket>> watchTicketsForAsha(String ashaId) {
    return _col
        .where('ashaId', isEqualTo: ashaId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PhcReviewTicket.fromFirestore(d))
              .toList(),
        );
  }

  /// Watches a single ticket document — used to receive real-time review
  /// status updates from the PHC officer web dashboard.
  Stream<PhcReviewTicket?> watchTicket(String ticketId) {
    return _col.doc(ticketId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PhcReviewTicket.fromFirestore(snap);
    });
  }
}

// ── Riverpod providers ──────────────────────────────────────────────────────

final phcTicketServiceProvider = Provider<PhcTicketService>((ref) {
  return PhcTicketService();
});

/// Streams all tickets for the given ASHA ID.
final ashaTicketsProvider =
    StreamProvider.family<List<PhcReviewTicket>, String>((ref, ashaId) {
  final service = ref.watch(phcTicketServiceProvider);
  return service.watchTicketsForAsha(ashaId);
});

/// Streams a single ticket — used in TicketDetailScreen and notification
/// watch for real-time status updates.
final singleTicketProvider =
    StreamProvider.family<PhcReviewTicket?, String>((ref, ticketId) {
  final service = ref.watch(phcTicketServiceProvider);
  return service.watchTicket(ticketId);
});

/// Fires a one-shot future that loads the latest ticket per program.
final latestTicketsPerProgramProvider =
    FutureProvider.family<Map<String, PhcReviewTicket>, String>(
        (ref, ashaId) async {
  final service = ref.watch(phcTicketServiceProvider);
  return service.getLatestTicketsPerProgram(ashaId);
});
