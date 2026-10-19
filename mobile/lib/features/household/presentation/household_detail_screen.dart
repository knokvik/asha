import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/household_dao.dart';
import '../data/member_dao.dart';

/// Screen displaying household details, location, BPL status, and family members.
/// Allows direct drill-down into individual beneficiary health timelines (Requirement 4).
class HouseholdDetailScreen extends ConsumerStatefulWidget {
  final String householdId;

  const HouseholdDetailScreen({
    super.key,
    required this.householdId,
  });

  @override
  ConsumerState<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends ConsumerState<HouseholdDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Household? _household;
  List<Member> _members = [];

  @override
  void initState() {
    super.initState();
    _loadHouseholdData();
  }

  Future<void> _loadHouseholdData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final householdDao = HouseholdDao(db);
      final memberDao = MemberDao(db);

      final h = await householdDao.getById(widget.householdId);
      final m = await memberDao.getByHousehold(widget.householdId);

      if (mounted) {
        setState(() {
          _household = h;
          _members = m;
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

  Future<void> _showAddMemberDialog() async {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final abhaCtrl = TextEditingController();
    String sex = 'F';
    String relationship = 'Daughter';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Aarti Devi',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (Years) *',
                          hintText: '24',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sex,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => sex = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relationship,
                  decoration: const InputDecoration(labelText: 'Relation to Head'),
                  items: const [
                    DropdownMenuItem(value: 'Head', child: Text('Head of Household')),
                    DropdownMenuItem(value: 'Spouse', child: Text('Spouse / Wife / Husband')),
                    DropdownMenuItem(value: 'Son', child: Text('Son')),
                    DropdownMenuItem(value: 'Daughter', child: Text('Daughter')),
                    DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                    DropdownMenuItem(value: 'Father', child: Text('Father')),
                    DropdownMenuItem(value: 'Daughter-in-law', child: Text('Daughter-in-law')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => relationship = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: abhaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ABHA Number / Address',
                    hintText: '14 digits or name@abdm',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '10 digits',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save Member'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final db = ref.read(appDatabaseProvider);
      final memberDao = MemberDao(db);
      final householdDao = HouseholdDao(db);
      final memberId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageYears = int.tryParse(ageCtrl.text.trim()) ?? 20;
      final dobApprox = DateTime.now().subtract(Duration(days: ageYears * 365)).millisecondsSinceEpoch;

      await memberDao.insertMember(
        MembersCompanion(
          id: drift.Value(memberId),
          householdId: drift.Value(widget.householdId),
          name: drift.Value(nameCtrl.text.trim()),
          sex: drift.Value(sex),
          relationshipToHead: drift.Value(relationship),
          dobApprox: drift.Value(dobApprox),
          isDobApprox: const drift.Value(true),
          phone: drift.Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
          abhaId: drift.Value(abhaCtrl.text.trim().isEmpty ? null : abhaCtrl.text.trim()),
          lifecycleStatus: const drift.Value('active'),
          consentStatus: const drift.Value('pending'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          createdBy: const drift.Value('asha-01'),
          syncStatus: const drift.Value('pending'),
        ),
      );

      await householdDao.updateMemberCount(widget.householdId, _members.length + 1);
      _loadHouseholdData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Household Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _household == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Household Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Household not found'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadHouseholdData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final h = _household!;

    return Scaffold(
      appBar: AppBar(
        title: Text(h.headName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHouseholdData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHouseholdData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Household Overview Card ──────────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Icon(Icons.home, size: 30, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.headName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${h.hamlet ?? "Main Village"}, ${h.village}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: h.isBpl ? Colors.green.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: h.isBpl ? Colors.green.shade300 : Colors.blue.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      h.isBpl ? 'BPL Card' : 'General / APL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: h.isBpl ? Colors.green.shade800 : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  if (h.socialCategory != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        h.socialCategory!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Family Members', '${_members.length}', Icons.groups),
                        _buildStatColumn('Contact', h.contactPhone ?? 'No Phone', Icons.phone),
                        _buildStatColumn('Sync', h.syncStatus.toUpperCase(), Icons.cloud_done),
                      ],
                    ),
                    if (h.landmarkNotes != null && h.landmarkNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Landmark: ${h.landmarkNotes}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Section: Family Members ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Members (${_members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Member'),
                  onPressed: _showAddMemberDialog,
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_members.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No members registered for this household'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Register First Member'),
                        onPressed: _showAddMemberDialog,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._members.map((m) => _buildMemberCard(m)),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Member m) {
    final theme = Theme.of(context);
    final ageText = m.dobApprox != null
        ? '${DateTime.now().year - DateTime.fromMillisecondsSinceEpoch(m.dobApprox!).year} yrs'
        : 'Age N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Open the beneficiary's comprehensive health timeline screen
          context.push('/beneficiary/${m.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: m.sex == 'F' ? Colors.pink.shade50 : Colors.blue.shade50,
                child: Icon(
                  m.sex == 'F' ? Icons.woman : Icons.man,
                  color: m.sex == 'F' ? Colors.pink : Colors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (m.relationshipToHead != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.relationshipToHead!,
                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${m.sex == "F" ? "Female" : "Male"} • $ageText${m.phone != null ? " • ${m.phone}" : ""}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          m.abhaId != null ? Icons.verified_user : Icons.shield_outlined,
                          size: 13,
                          color: m.abhaId != null ? Colors.teal : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.abhaId != null ? 'ABHA: ${m.abhaId}' : 'No ABHA Linked',
                          style: TextStyle(
                            fontSize: 11,
                            color: m.abhaId != null ? Colors.teal.shade800 : Colors.grey.shade600,
                            fontWeight: m.abhaId != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    color: theme.colorScheme.primary,
                    onPressed: () => context.push('/beneficiary/${m.id}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
