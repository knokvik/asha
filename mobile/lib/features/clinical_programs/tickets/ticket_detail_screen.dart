import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import 'phc_review_ticket.dart';
import 'phc_ticket_service.dart';

/// Full ticket detail view — shown when ASHA taps the PHC review toast
/// or navigates via /ticket/:id.
class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(singleTicketProvider(ticketId));

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: const Text(
          'PHC Review Ticket',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load ticket: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
          ),
        ),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Ticket not found.'));
          }
          return _TicketDetailBody(ticket: ticket);
        },
      ),
    );
  }
}

class _TicketDetailBody extends StatelessWidget {
  final PhcReviewTicket ticket;

  const _TicketDetailBody({required this.ticket});

  static final _dtFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ── Status Banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(_statusIcon(ticket.status), color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Submitted ${_dtFmt.format(ticket.submittedAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AshaColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Program Info ───────────────────────────────────────────────────
        _InfoCard(
          title: 'Program',
          icon: Icons.medical_services_rounded,
          children: [
            _Row('Program', ticket.programDisplayName),
            _Row('Ticket ID', ticket.ticketId.substring(0, 8).toUpperCase()),
            _Row('Encounter ID', ticket.encounterId.substring(0, 8).toUpperCase()),
          ],
        ),
        const SizedBox(height: 12),

        // ── Beneficiary Info ───────────────────────────────────────────────
        _InfoCard(
          title: 'Beneficiary',
          icon: Icons.person_outline_rounded,
          children: [
            _Row('Name', ticket.memberName),
            _Row('Member ID', ticket.memberId.substring(0, 12)),
          ],
        ),
        const SizedBox(height: 12),

        // ── ASHA Info ──────────────────────────────────────────────────────
        _InfoCard(
          title: 'Submitted By',
          icon: Icons.badge_outlined,
          children: [
            _Row('ASHA Name', ticket.ashaName),
            _Row('ASHA ID', ticket.ashaId),
            _Row('Submitted At', _dtFmt.format(ticket.submittedAt)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Form Data Summary ──────────────────────────────────────────────
        if (ticket.formDataSummary.isNotEmpty)
          _InfoCard(
            title: 'Clinical Data Summary',
            icon: Icons.summarize_outlined,
            children: ticket.formDataSummary.entries
                .map((e) => _Row(e.key, e.value))
                .toList(),
          ),
        const SizedBox(height: 12),

        // ── PHC Reviewer Notes ─────────────────────────────────────────────
        _InfoCard(
          title: 'PHC Review',
          icon: Icons.rate_review_outlined,
          children: [
            if (ticket.reviewedAt != null)
              _Row('Reviewed At', _dtFmt.format(ticket.reviewedAt!)),
            if (ticket.reviewedBy != null)
              _Row('Reviewed By', ticket.reviewedBy!),
            _Row(
              'Reviewer Note',
              ticket.reviewerNote?.isNotEmpty == true
                  ? ticket.reviewerNote!
                  : 'No notes yet.',
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.approved:
        return const Color(0xFF16A34A);
      case TicketStatus.rejected:
        return const Color(0xFFDC2626);
      case TicketStatus.underReview:
        return const Color(0xFFF59E0B);
      case TicketStatus.pending:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(TicketStatus s) {
    switch (s) {
      case TicketStatus.approved:
        return Icons.check_circle_outline_rounded;
      case TicketStatus.rejected:
        return Icons.cancel_outlined;
      case TicketStatus.underReview:
        return Icons.hourglass_top_rounded;
      case TicketStatus.pending:
        return Icons.schedule_rounded;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AshaColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AshaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AshaColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AshaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
