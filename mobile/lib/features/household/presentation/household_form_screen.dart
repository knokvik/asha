import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/duplicate_detector.dart';
import '../data/household_repository.dart';
import 'household_providers.dart';

/// Form data model representing a family member in the household form.
class MemberFormData {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController phoneController;
  final TextEditingController abhaController;
  String sex;
  String relationship;

  MemberFormData({
    String name = '',
    String age = '',
    String phone = '',
    String abha = '',
    this.sex = 'F',
    this.relationship = 'Spouse',
  })  : nameController = TextEditingController(text: name),
        ageController = TextEditingController(text: age),
        phoneController = TextEditingController(text: phone),
        abhaController = TextEditingController(text: abha);

  void dispose() {
    nameController.dispose;
    ageController.dispose;
    phoneController.dispose;
    abhaController.dispose;
  }
}

/// Screen for registering a new household and its members offline.
///
/// Requirements: 4.1, 4.2
/// - Village and Head Name are mandatory.
/// - All other fields are individually skippable (Requirement 4.1).
/// - Client-generated UUID v4 persisted immediately without server round-trip.
class HouseholdFormScreen extends ConsumerStatefulWidget {
  const HouseholdFormScreen({super.key});

  @override
  ConsumerState<HouseholdFormScreen> createState() => _HouseholdFormScreenState();
}

class _HouseholdFormScreenState extends ConsumerState<HouseholdFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Household fields
  final _villageController = TextEditingController();
  final _hamletController = TextEditingController();
  final _headNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();

  String? _selectedSocialCategory;
  bool _isBpl = false;
  bool _isSaving = false;

  final List<String> _socialCategories = const ['General', 'OBC', 'SC', 'ST'];
  final List<String> _relationships = const [
    'Head',
    'Spouse',
    'Son',
    'Daughter',
    'Mother',
    'Father',
    'Brother',
    'Sister',
    'Daughter-in-law',
    'Grandchild',
    'Other',
  ];

  // Member list
  final List<MemberFormData> _members = [];

  @override
  void initState() {
    super.initState();
    // Default: Add head of household as initial member entry
    _members.add(MemberFormData(relationship: 'Head', sex: 'M'));
    _headNameController.addListener(_syncHeadName);
  }

  void _syncHeadName() {
    if (_members.isNotEmpty && _members.first.relationship == 'Head') {
      if (_members.first.nameController.text != _headNameController.text) {
        _members.first.nameController.text = _headNameController.text;
      }
    }
  }

  @override
  void dispose() {
    _headNameController.removeListener(_syncHeadName);
    _villageController.dispose();
    _hamletController.dispose();
    _headNameController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    setState(() {
      _members.add(MemberFormData(relationship: 'Son', sex: 'M'));
    });
  }

  void _removeMember(int index) {
    if (_members.length <= 1) return;
    setState(() {
      final removed = _members.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(householdRepositoryProvider);

      // Check for potential duplicate beneficiaries before proceeding
      const detector = DuplicateDetector();
      final existingMembers = await repo.memberDao.db.select(repo.memberDao.db.members).get();

      if (existingMembers.isNotEmpty) {
        for (final member in _members) {
          final memberName = member.nameController.text.trim();
          if (memberName.isEmpty) continue;

          int? approxDob;
          final ageText = member.ageController.text.trim();
          if (ageText.isNotEmpty) {
            final ageYears = int.tryParse(ageText);
            if (ageYears != null && ageYears > 0) {
              final now = DateTime.now();
              approxDob = DateTime(now.year - ageYears, 1, 1).millisecondsSinceEpoch;
            }
          }

          final candidatePhone = member.phoneController.text.trim().isNotEmpty
              ? member.phoneController.text.trim()
              : _phoneController.text.trim();

          final duplicates = detector.filterDuplicates(
            existingMembers: existingMembers,
            targetName: memberName,
            targetDobApprox: approxDob,
            targetPhone: candidatePhone.isEmpty ? null : candidatePhone,
          );

          if (duplicates.isNotEmpty && mounted) {
            final resolution = await showDialog<DuplicateResolution>(
              context: context,
              barrierDismissible: false,
              builder: (_) => DuplicateConfirmationDialog(candidates: duplicates),
            );

            if (resolution == DuplicateResolution.cancel || resolution == null) {
              setState(() => _isSaving = false);
              return;
            }
          }
        }
      }

      // 1. Create household offline with UUID v4
      final household = await repo.createHousehold(
        village: _villageController.text.trim(),
        hamlet: _hamletController.text.trim().isEmpty
            ? null
            : _hamletController.text.trim(),
        headName: _headNameController.text.trim(),
        socialCategory: _selectedSocialCategory,
        isBpl: _isBpl,
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        landmarkNotes: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
      );

      // 2. Add family members offline with UUID v4
      String? firstMemberId;
      for (final member in _members) {
        final memberName = member.nameController.text.trim();
        if (memberName.isEmpty) continue;

        int? approxDob;
        final ageText = member.ageController.text.trim();
        if (ageText.isNotEmpty) {
          final ageYears = int.tryParse(ageText);
          if (ageYears != null && ageYears > 0) {
            final now = DateTime.now();
            final approxBirthDate = DateTime(now.year - ageYears, 1, 1);
            approxDob = approxBirthDate.millisecondsSinceEpoch;
          }
        }

        final createdMember = await repo.addMember(
          householdId: household.id,
          name: memberName,
          sex: member.sex,
          relationshipToHead: member.relationship,
          dobApprox: approxDob,
          isDobApprox: approxDob != null,
          phone: member.phoneController.text.trim().isEmpty
              ? null
              : member.phoneController.text.trim(),
          abhaId: member.abhaController.text.trim().isEmpty
              ? null
              : member.abhaController.text.trim(),
          socialCategory: _selectedSocialCategory,
          isBpl: _isBpl,
        );
        firstMemberId ??= createdMember.id;
      }

      // Refresh household list cache
      ref.invalidate(householdListProvider);
      ref.invalidate(householdsGroupedByHamletProvider);

      if (mounted) {
        if (firstMemberId != null) {
          await context.push('/beneficiary/$firstMemberId/consent');
          if (!mounted) return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Household registered offline'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(household);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save household: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.registerHousehold ?? 'Register Household'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              key: const Key('household_form_save_button'),
              onPressed: _submit,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                l10n?.save ?? 'Save',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Location & Head ──────────────────────────────────
            _buildSectionHeader(
              icon: Icons.location_on,
              title: 'Location & Household Head',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('village_field'),
              controller: _villageController,
              decoration: const InputDecoration(
                labelText: 'Village *',
                hintText: 'Enter village name',
                prefixIcon: Icon(Icons.home_work),
                border: OutlineInputBorder(),
                helperText: 'Mandatory field',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Village name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('hamlet_field'),
              controller: _hamletController,
              decoration: InputDecoration(
                labelText: 'Hamlet / Pada (Optional)',
                hintText: 'e.g. Purva, Ward 3, Naya Basti',
                prefixIcon: const Icon(Icons.holiday_village),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear / Skip',
                  onPressed: () => _hamletController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('head_name_field'),
              controller: _headNameController,
              decoration: const InputDecoration(
                labelText: 'Head of Household Name *',
                hintText: 'Enter full name of family head',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                helperText: 'Mandatory field',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Head of household name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Section 2: Socio-Economic & Contact ─────────────────────────
            _buildSectionHeader(
              icon: Icons.badge,
              title: 'Socio-Economic & Contact (Optional)',
            ),
            const SizedBox(height: 12),
            Text(
              'Social Category (Skippable)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._socialCategories.map((category) {
                  final isSelected = _selectedSocialCategory == category;
                  return ChoiceChip(
                    key: Key('category_chip_$category'),
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSocialCategory = selected ? category : null;
                      });
                    },
                  );
                }),
                if (_selectedSocialCategory != null)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    onPressed: () => setState(() => _selectedSocialCategory = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                key: const Key('bpl_switch'),
                title: const Text(
                  'Below Poverty Line (BPL)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Ration card / economic qualification'),
                value: _isBpl,
                onChanged: (val) => setState(() => _isBpl = val),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('contact_phone_field'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone Number (Optional)',
                hintText: '10-digit mobile number',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear / Skip',
                  onPressed: () => _phoneController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('landmark_field'),
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark / Location Notes (Optional)',
                hintText: 'e.g. Near old banyan tree, red brick house',
                prefixIcon: Icon(Icons.landscape),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 3: Family Members ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  icon: Icons.people,
                  title: 'Family Members (${_members.length})',
                ),
                OutlinedButton.icon(
                  key: const Key('add_member_button'),
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_members.length, (index) {
              return _buildMemberCard(index);
            }),
            const SizedBox(height: 32),

            // ── Submit Button ───────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('submit_household_button'),
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving to Local Store...'
                      : (l10n?.registerHousehold ?? 'Register Household'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMemberCard(int index) {
    final member = _members[index];
    final isHead = index == 0 && member.relationship == 'Head';

    return Card(
      key: Key('member_card_$index'),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isHead ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isHead ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHead
                      ? 'Member 1: Household Head'
                      : 'Member ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHead ? Theme.of(context).primaryColor : null,
                  ),
                ),
                if (!isHead && _members.length > 1)
                  IconButton(
                    key: Key('remove_member_button_$index'),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove member',
                    onPressed: () => _removeMember(index),
                  ),
              ],
            ),
            const Divider(),
            TextFormField(
              key: Key('member_name_field_$index'),
              controller: member.nameController,
              decoration: InputDecoration(
                labelText: 'Member Name *',
                hintText: 'Enter member name',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Member name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: Key('member_age_field_$index'),
                    controller: member.ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (Years)',
                      hintText: 'e.g. 28',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    key: Key('member_relationship_field_$index'),
                    initialValue: member.relationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _relationships.map((rel) {
                      return DropdownMenuItem(value: rel, child: Text(rel));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => member.relationship = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Sex: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('F'),
                  selected: member.sex == 'F',
                  onSelected: (sel) {
                    if (sel) setState(() => member.sex = 'F');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('M'),
                  selected: member.sex == 'M',
                  onSelected: (sel) {
                    if (sel) setState(() => member.sex = 'M');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('O'),
                  selected: member.sex == 'Other',
                  onSelected: (sel) {
                    if (sel) setState(() => member.sex = 'Other');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('member_phone_field_$index'),
              controller: member.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                hintText: 'Member mobile number',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('member_abha_field_$index'),
              controller: member.abhaController,
              decoration: const InputDecoration(
                labelText: 'ABHA ID / Number (Optional)',
                hintText: 'e.g. 14-digit ABHA number',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
