import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../data/immunization_repository.dart';
import '../domain/immunization_models.dart';

/// Screen for planning, mobilizing beneficiaries, and recording attendance/services
/// during a Village Health, Sanitation and Nutrition Day (VHSND) (Requirement 16.4, 27).
class VhsndSessionScreen extends ConsumerStatefulWidget {
  final String villageName;
  final String? hamlet;
  final String anganwadiCenterName;
  final String ashaId;

  const VhsndSessionScreen({
    super.key,
    required this.villageName,
    this.hamlet,
    required this.anganwadiCenterName,
    required this.ashaId,
  });

  @override
  ConsumerState<VhsndSessionScreen> createState() => _VhsndSessionScreenState();
}

class _VhsndSessionScreenState extends ConsumerState<VhsndSessionScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  DateTime _sessionDate = DateTime.now();
  VhsndSession? _session;
  bool _isLoading = true;
  String? _errorMessage;

  // Local state for mobilisation and attendance tracking
  final Map<String, bool> _mobilizedMap = {};
  final Map<String, bool> _attendedMap = {};
  final Map<String, Set<String>> _deliveredServicesMap = {};

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(immunizationRepositoryProvider);
      final session = await repo.planVhsndSession(
        sessionDate: _sessionDate,
        villageName: widget.villageName,
        hamlet: widget.hamlet,
        anganwadiCenterName: widget.anganwadiCenterName,
        ashaId: widget.ashaId,
      );

      _mobilizedMap.clear();
      _attendedMap.clear();
      _deliveredServicesMap.clear();

      for (final b in session.beneficiariesDue) {
        _mobilizedMap[b.memberId] = b.isMobilized;
        _attendedMap[b.memberId] = b.attended;
        _deliveredServicesMap[b.memberId] = b.servicesDelivered.toSet();
      }

      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSessionOutcomes() async {
    if (_session == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedRoster = _session!.beneficiariesDue.map((b) {
        return b.copyWith(
          isMobilized: _mobilizedMap[b.memberId] ?? false,
          attended: _attendedMap[b.memberId] ?? false,
          servicesDelivered: _deliveredServicesMap[b.memberId]?.toList() ?? [],
        );
      }).toList();

      final repo = ref.read(immunizationRepositoryProvider);
      await repo.recordVhsndSessionOutcomes(
        sessionId: _session!.id,
        ashaId: widget.ashaId,
        completedRoster: updatedRoster,
        sessionDate: _sessionDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('VHSND session outcomes successfully recorded and saved.')),
        );
        _loadSessionData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving VHSND outcomes: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final beneficiaries = _session?.beneficiariesDue ?? [];
    final totalDue = beneficiaries.length;
    final totalMobilized = _mobilizedMap.values.where((v) => v).length;
    final totalAttended = _attendedMap.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: const Text('VHSND Session & Mobilisation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Text('Loading VHSND session data...'))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Header Session Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.villageName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_month, size: 16),
                                  label: Text(_dateFormat.format(_sessionDate), style: const TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _sessionDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now().add(const Duration(days: 60)),
                                    );
                                    if (picked != null) {
                                      setState(() => _sessionDate = picked);
                                      _loadSessionData();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Anganwadi: ${widget.anganwadiCenterName} ${widget.hamlet != null ? "• Hamlet: ${widget.hamlet}" : ""}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                            const Divider(height: 18),
                            // Metrics Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _metricTile('Total Due', '$totalDue', Colors.blue),
                                _metricTile('Mobilized', '$totalMobilized', Colors.orange),
                                _metricTile('Attended', '$totalAttended', Colors.green),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'Mobilisation & Service Delivery Roster',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    if (beneficiaries.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No beneficiaries due for vaccination or ANC during this session window.'),
                        ),
                      )
                    else
                      ...beneficiaries.map((b) => _buildBeneficiaryCard(b)),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save VHSND Outcomes & Update Cards'),
            onPressed: _saveSessionOutcomes,
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBeneficiaryCard(VhsndBeneficiaryDue b) {
    final isMobilized = _mobilizedMap[b.memberId] ?? false;
    final attended = _attendedMap[b.memberId] ?? false;
    final deliveredSet = _deliveredServicesMap[b.memberId] ?? <String>{};

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.beneficiaryName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${b.beneficiaryType} ${b.hamlet != null ? "• Hamlet: ${b.hamlet}" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: attended ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    attended ? 'Attended' : (isMobilized ? 'Mobilized' : 'Pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: attended ? Colors.green.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Due Services Chips
            if (b.dueVaccines.isNotEmpty) ...[
              const Text('Due Vaccines:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: b.dueVaccines.map((v) {
                  final isDelivered = deliveredSet.contains(v);
                  return FilterChip(
                    label: Text(v.split(':').first.trim(), style: const TextStyle(fontSize: 12)),
                    selected: isDelivered,
                    selectedColor: Colors.green.shade200,
                    onSelected: attended
                        ? (selected) {
                            setState(() {
                              if (selected) {
                                deliveredSet.add(v);
                              } else {
                                deliveredSet.remove(v);
                              }
                              _deliveredServicesMap[b.memberId] = deliveredSet;
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
            ],

            if (b.dueOtherServices.isNotEmpty) ...[
              const Text('Other Services Due:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
              Wrap(
                spacing: 6,
                children: b.dueOtherServices
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.indigo.shade50,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
            ],

            // Checkbox Actions
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Mobilized (Visited)', style: TextStyle(fontSize: 12)),
                    value: isMobilized,
                    onChanged: (val) {
                      setState(() => _mobilizedMap[b.memberId] = val ?? false);
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Attended Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: attended,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _attendedMap[b.memberId] = val ?? false;
                        if (val == true && isMobilized == false) {
                          _mobilizedMap[b.memberId] = true;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
