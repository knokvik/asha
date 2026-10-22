import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/vhsnd_models.dart';

/// Screen for managing a Village Health Sanitation and Nutrition Day (VHSND) session
/// including service-specific due lists, mobilisation checklists, attendance & service recording,
/// and session summaries (Requirements 27.1, 27.2).
class VhsndSessionScreen extends StatefulWidget {
  final VhsndSession initialSession;
  final Function(VhsndSession updatedSession)? onSessionCompleted;

  const VhsndSessionScreen({
    super.key,
    required this.initialSession,
    this.onSessionCompleted,
  });

  @override
  State<VhsndSessionScreen> createState() => _VhsndSessionScreenState();
}

class _VhsndSessionScreenState extends State<VhsndSessionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<VhsndDueBeneficiary> _beneficiaries;
  late List<MobilisationChecklistItem> _checklist;
  final TextEditingController _summaryNotesController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _beneficiaries = List.from(widget.initialSession.beneficiaries);
    _checklist = List.from(widget.initialSession.mobilisationChecklist);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _summaryNotesController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          'VHSND: ${widget.initialSession.village}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AshaColors.primary,
          labelColor: AshaColors.primary,
          unselectedLabelColor: AshaColors.textMuted,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded), text: 'Due List'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'Mobilisation'),
            Tab(icon: Icon(Icons.fact_check_rounded), text: 'Recording'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDueListTab(context),
          _buildChecklistTab(context),
          _buildRecordingTab(context),
        ],
      ),
    );
  }

  // ── Tab 1: Service-specific Due Beneficiary List (Requirement 27.1) ──────────
  Widget _buildDueListTab(BuildContext context) {
    if (_beneficiaries.isEmpty) {
      return const Center(child: Text('No due beneficiaries for this session.'));
    }

    final services = VhsndServiceType.values;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: services.map((service) {
        final serviceBeneficiaries = _beneficiaries.where((b) => b.serviceType == service).toList();
        if (serviceBeneficiaries.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Chip(
                      label: Text('${serviceBeneficiaries.length} due'),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: TextStyle(color: Colors.green.shade800, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                ...serviceBeneficiaries.map((b) {
                  final idx = _beneficiaries.indexOf(b);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(b.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${b.dueServiceDetails} • Hamlet: ${b.hamlet}'),
                    value: b.isMobilised,
                    onChanged: (val) {
                      setState(() {
                        _beneficiaries[idx] = b.copyWith(isMobilised: val ?? false);
                      });
                    },
                    secondary: Icon(
                      b.isMobilised ? Icons.campaign : Icons.campaign_outlined,
                      color: b.isMobilised ? Colors.green : Colors.grey,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Tab 2: Mobilisation Checklist (Requirement 27.1) ─────────────────────────
  Widget _buildChecklistTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklist.length,
      itemBuilder: (context, index) {
        final item = _checklist[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.description),
            value: item.isCompleted,
            activeColor: const Color(0xFF1B5E20),
            onChanged: (val) {
              setState(() {
                _checklist[index] = item.copyWith(
                  isCompleted: val ?? false,
                  completedAt: (val ?? false) ? DateTime.now() : null,
                );
              });
            },
          ),
        );
      },
    );
  }

  // ── Tab 3: Attendance, Services Delivered & Session Summary (Requirement 27.2)
  Widget _buildRecordingTab(BuildContext context) {
    final attendedCount = _beneficiaries.where((b) => b.hasAttended).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance summary card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Due', '${_beneficiaries.length}'),
                  _buildStatItem('Mobilised', '${_beneficiaries.where((b) => b.isMobilised).length}'),
                  _buildStatItem('Attended', '$attendedCount'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Record Attendance & Services Given',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ..._beneficiaries.map((b) {
            final idx = _beneficiaries.indexOf(b);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: b.hasAttended,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) {
                        setState(() {
                          final attended = val ?? false;
                          _beneficiaries[idx] = b.copyWith(
                            hasAttended: attended,
                            servicesDelivered: attended ? [b.dueServiceDetails] : const [],
                          );
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Service: ${b.dueServiceDetails}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                          if (b.hasAttended)
                            const Text(
                              'Status: Service Delivered (Timeline Updated)',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text('Session Summary & Community Feedback (Req 27.2, 27.6)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _summaryNotesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Session Summary Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Community Feedback / Health Concerns (Routed to AF & VHSNC)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              final updated = VhsndSession(
                id: widget.initialSession.id,
                village: widget.initialSession.village,
                anganwadiCenter: widget.initialSession.anganwadiCenter,
                sessionDate: widget.initialSession.sessionDate,
                status: VhsndSessionStatus.completed,
                anmName: widget.initialSession.anmName,
                ashaName: widget.initialSession.ashaName,
                anganwadiWorkerName: widget.initialSession.anganwadiWorkerName,
                beneficiaries: _beneficiaries,
                mobilisationChecklist: _checklist,
                sessionSummaryNotes: _summaryNotesController.text,
                communityFeedbackNotes: _feedbackController.text,
                completedAt: DateTime.now(),
              );
              widget.onSessionCompleted?.call(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('VHSND session successfully recorded and timelines updated!')),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete VHSND Session & Update Timelines'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
