import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/user_profile_provider.dart';
import 'phc_review_ticket.dart';
import 'phc_ticket_service.dart';

/// Wraps its [child] and listens to the Firestore ticket stream for the
/// current ASHA worker. When a ticket transitions to [TicketStatus.approved]
/// or [TicketStatus.rejected], it shows a Material SnackBar with a
/// "View Ticket" action that navigates to /ticket/:id.
///
/// Mount this once above the programs hub (or at app shell level).
class PhcTicketNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const PhcTicketNotificationListener({super.key, required this.child});

  @override
  ConsumerState<PhcTicketNotificationListener> createState() =>
      _PhcTicketNotificationListenerState();
}

class _PhcTicketNotificationListenerState
    extends ConsumerState<PhcTicketNotificationListener> {
  // Track the last-seen status per ticket so we only fire the toast
  // when status actually changes, not on every snapshot rebuild.
  final Map<String, TicketStatus> _seenStatuses = {};
  StreamSubscription<List<PhcReviewTicket>>? _sub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final profile = ref.read(userProfileProvider);
    final ashaId = profile.maybeWhen(data: (p) => p.ashaId, orElse: () => null);
    if (ashaId == null) return;

    final service = ref.read(phcTicketServiceProvider);
    _sub = service.watchTicketsForAsha(ashaId).listen(_onTickets);
  }

  void _onTickets(List<PhcReviewTicket> tickets) {
    for (final ticket in tickets) {
      final previous = _seenStatuses[ticket.ticketId];

      // First load — just record the status, don't show a toast.
      if (previous == null) {
        _seenStatuses[ticket.ticketId] = ticket.status;
        continue;
      }

      // Status changed to a terminal reviewed state.
      if (previous != ticket.status &&
          (ticket.status == TicketStatus.approved ||
              ticket.status == TicketStatus.rejected)) {
        _seenStatuses[ticket.ticketId] = ticket.status;
        _showReviewToast(ticket);
      } else {
        _seenStatuses[ticket.ticketId] = ticket.status;
      }
    }
  }

  void _showReviewToast(PhcReviewTicket ticket) {
    if (!mounted) return;
    final isApproved = ticket.status == TicketStatus.approved;
    final color = isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = isApproved ? '✅' : '🔴';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        content: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isApproved
                        ? '${ticket.programDisplayName} Approved'
                        : '${ticket.programDisplayName} Needs Correction',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ticket.memberName,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View Ticket',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) context.push('/ticket/${ticket.ticketId}');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
