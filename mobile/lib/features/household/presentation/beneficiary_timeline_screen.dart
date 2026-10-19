import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../data/timeline_repository.dart';
import 'household_providers.dart';

/// Screen presenting a live, reverse-chronological longitudinal health timeline for a beneficiary.
///
/// Sourced via reactive [StreamProvider] from Drift SQLite local tables.
/// Requirements: 4.4
class BeneficiaryTimelineScreen extends ConsumerStatefulWidget {
  final String memberId;

  const BeneficiaryTimelineScreen({
    super.key,
    required this.memberId,
  });

  @override
  ConsumerState<BeneficiaryTimelineScreen> createState() =>
      _BeneficiaryTimelineScreenState();
}

class _BeneficiaryTimelineScreenState
    extends ConsumerState<BeneficiaryTimelineScreen> {
  TimelineEventType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberAsync = ref.watch(memberDetailsProvider(widget.memberId));
    final timelineAsync =
        ref.watch(beneficiaryTimelineStreamProvider(widget.memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Timeline'),
        actions: [
          IconButton(
            key: const Key('timeline_refresh_button'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(memberDetailsProvider(widget.memberId));
              ref.invalidate(beneficiaryTimelineStreamProvider(widget.memberId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Beneficiary Profile Header ────────────────────────────────────
          memberAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Text('Error loading member: $err'),
            ),
            data: (member) {
              if (member == null) {
                return const SizedBox.shrink();
              }
              return _buildMemberHeader(context, member);
            },
          ),

          // ── Filter Chips ──────────────────────────────────────────────────
          _buildFilterChips(theme),

          // ── Timeline Stream List ──────────────────────────────────────────
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading timeline: $err'),
                    ],
                  ),
                ),
              ),
              data: (events) {
                final filtered = _selectedTypeFilter == null
                    ? events
                    : events.where((e) => e.type == _selectedTypeFilter).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  key: const Key('timeline_event_list'),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isLast = index == filtered.length - 1;
                    return _buildTimelineItem(context, item, isLast);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('record_visit_fab'),
        onPressed: () {
          context.push('/programs');
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Record Visit'),
      ),
    );
  }

  Widget _buildMemberHeader(BuildContext context, Member member) {
    final theme = Theme.of(context);
    final ageStr = member.dobApprox != null
        ? '${DateTime.now().year - DateTime.fromMillisecondsSinceEpoch(member.dobApprox!).year} yrs'
        : 'Age unrecorded';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                child: Icon(
                  member.sex == 'F' ? Icons.face_3 : Icons.face,
                  color: theme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.sex} • $ageStr • ${member.relationshipToHead ?? "Member"}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (member.abhaId != null && member.abhaId!.isNotEmpty)
                _buildChip(
                  label: 'ABHA: ${member.abhaId}',
                  color: Colors.purple.shade50,
                  textColor: Colors.purple.shade800,
                  icon: Icons.credit_card,
                ),
              if (member.phone != null && member.phone!.isNotEmpty)
                _buildChip(
                  label: member.phone!,
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade800,
                  icon: Icons.phone,
                ),
              _buildChip(
                label: 'Status: ${member.lifecycleStatus.toUpperCase()}',
                color: Colors.blue.shade50,
                textColor: Colors.blue.shade800,
                icon: Icons.verified_user,
              ),
              InkWell(
                key: const Key('timeline_consent_chip'),
                onTap: () => context.push('/beneficiary/${member.id}/consent'),
                borderRadius: BorderRadius.circular(6),
                child: _buildChip(
                  label: 'Consent: ${member.consentStatus.toUpperCase()}',
                  color: member.consentStatus == 'given'
                      ? Colors.teal.shade50
                      : member.consentStatus == 'declined'
                          ? Colors.orange.shade50
                          : Colors.amber.shade50,
                  textColor: member.consentStatus == 'given'
                      ? Colors.teal.shade800
                      : member.consentStatus == 'declined'
                          ? Colors.orange.shade900
                          : Colors.amber.shade900,
                  icon: member.consentStatus == 'given'
                      ? Icons.verified
                      : member.consentStatus == 'declined'
                          ? Icons.warning_amber
                          : Icons.pending_actions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              key: const Key('timeline_filter_all'),
              label: const Text('All Events'),
              selected: _selectedTypeFilter == null,
              onSelected: (_) => setState(() => _selectedTypeFilter = null),
            ),
            const SizedBox(width: 8),
            FilterChip(
              key: const Key('timeline_filter_encounters'),
              label: const Text('Visits'),
              selected: _selectedTypeFilter == TimelineEventType.encounter,
              onSelected: (sel) => setState(() {
                _selectedTypeFilter = sel ? TimelineEventType.encounter : null;
              }),
            ),
            const SizedBox(width: 8),
            FilterChip(
              key: const Key('timeline_filter_referrals'),
              label: const Text('Referrals'),
              selected: _selectedTypeFilter == TimelineEventType.referral,
              onSelected: (sel) => setState(() {
                _selectedTypeFilter = sel ? TimelineEventType.referral : null;
              }),
            ),
            const SizedBox(width: 8),
            FilterChip(
              key: const Key('timeline_filter_incentives'),
              label: const Text('Incentives'),
              selected: _selectedTypeFilter == TimelineEventType.incentive,
              onSelected: (sel) => setState(() {
                _selectedTypeFilter = sel ? TimelineEventType.incentive : null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEventItem item,
    bool isLast,
  ) {
    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    final dateFormatted = DateFormat('d MMM y, h:mm a').format(date);
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline Track & Node ─────────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (item.badgeColor ?? theme.primaryColor)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: item.badgeColor ?? theme.primaryColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Event Card ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                key: Key('timeline_card_${item.id}'),
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (item.badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (item.badgeColor ?? theme.primaryColor)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.badgeText!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.badgeColor ?? theme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Clinical Events Recorded',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'All clinical visits, triage observations, referrals, and incentives for this beneficiary will appear here chronologically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_timeline_record_button'),
              onPressed: () {
                context.push('/programs');
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Record First Visit'),
            ),
          ],
        ),
      ),
    );
  }
}
