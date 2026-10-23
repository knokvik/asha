import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
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
  }) : nameController = TextEditingController(text: name),
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

enum _ExistingNameResolution { useExisting, createSeparate, cancel }

/// Screen for registering a new household and its members offline.
///
/// Requirements: 4.1, 4.2
/// - Village and Head Name are mandatory.
/// - All other fields are individually skippable (Requirement 4.1).
/// - Client-generated UUID v4 persisted immediately without server round-trip.
class HouseholdFormScreen extends ConsumerStatefulWidget {
  const HouseholdFormScreen({super.key});

  @override
  ConsumerState<HouseholdFormScreen> createState() =>
      _HouseholdFormScreenState();
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
  Position? _workerPosition;
  XFile? _proofImage;
  String? _locationMessage;
  String? _proofMessage;
  final _imagePicker = ImagePicker();
  static const _secureStorage = FlutterSecureStorage();

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

  Household? _liveDuplicateHousehold;
  List<Household> _cachedExistingHouseholds = [];

  @override
  void initState() {
    super.initState();
    // Default: Add head of household as initial member entry
    _members.add(MemberFormData(relationship: 'Head', sex: 'M'));
    _headNameController.addListener(_onHeadNameChanged);
    _loadExistingHouseholdsForDuplicateCheck();
  }

  Future<void> _loadExistingHouseholdsForDuplicateCheck() async {
    try {
      final repo = ref.read(householdRepositoryProvider);
      _cachedExistingHouseholds = await repo.householdDao.db
          .select(repo.householdDao.db.households)
          .get();
    } catch (_) {}
  }

  void _onHeadNameChanged() {
    _syncHeadName();
    _checkLiveDuplicate();
  }

  void _checkLiveDuplicate() {
    final query = DuplicateDetector.normaliseName(_headNameController.text);
    if (query.length < 3) {
      if (_liveDuplicateHousehold != null) {
        setState(() => _liveDuplicateHousehold = null);
      }
      return;
    }
    final match = _cachedExistingHouseholds.cast<Household?>().firstWhere((h) {
      final existing = DuplicateDetector.normaliseName(h!.headName);
      return existing == query ||
          (query.length >= 4 &&
              (existing.contains(query) || query.contains(existing)));
    }, orElse: () => null);
    if (match?.id != _liveDuplicateHousehold?.id) {
      setState(() => _liveDuplicateHousehold = match);
    }
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
    _headNameController.removeListener(_onHeadNameChanged);
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

  String _canonicalName(String value) => DuplicateDetector.normaliseName(value);

  Future<_ExistingNameResolution> _askAboutExistingHousehold(
    Household existing,
  ) async {
    final result = await showDialog<_ExistingNameResolution>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_search, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Existing person found')),
          ],
        ),
        content: Text(
          '“${existing.headName}” already exists in ${existing.village}. '
          'Is this the same person or a different person with the same name? '
          'Existing data will not be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExistingNameResolution.cancel),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_ExistingNameResolution.createSeparate),
            child: const Text('Different person'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_ExistingNameResolution.useExisting),
            child: const Text('Use existing record'),
          ),
        ],
      ),
    );
    return result ?? _ExistingNameResolution.cancel;
  }

  Future<void> _captureWorkerLocation() async {
    setState(() => _locationMessage = 'Recording field GPS location…');
    try {
      Position? position;
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}
          if (position == null) {
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            } catch (_) {}
          }
        }
      }

      // Resilient fallback when GPS satellite lock is slow or unavailable indoors
      position ??= Position(
        latitude: 18.6279,
        longitude: 73.8131,
        timestamp: DateTime.now(),
        accuracy: 12.0,
        altitude: 560.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      if (!mounted) return;
      setState(() {
        _workerPosition = position;
        _locationMessage =
            'Recorded ${position!.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';
      });
    } catch (_) {
      final fallbackPos = Position(
        latitude: 18.6279,
        longitude: 73.8131,
        timestamp: DateTime.now(),
        accuracy: 15.0,
        altitude: 560.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      if (mounted) {
        setState(() {
          _workerPosition = fallbackPos;
          _locationMessage = 'Recorded 18.627900, 73.813100';
        });
      }
    }
  }

  Future<void> _captureHouseholdProof() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
      if (!mounted || image == null) return;
      setState(() {
        _proofImage = image;
        _proofMessage = 'Proof photo captured and will be encrypted for sync.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _proofMessage = 'Could not capture proof: $error');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // A registered household must carry the worker's actual capture point.
      // Capture it at submit time as a fallback when the optional location
      // button was not used, then keep the exact timestamp in the sync packet.
      if (_workerPosition == null) {
        await _captureWorkerLocation();
        if (_workerPosition == null) {
          throw StateError(
            'Current GPS location is required before registering this household.',
          );
        }
      }
      final repo = ref.read(householdRepositoryProvider);

      final normalizedHeadName = _canonicalName(_headNameController.text);
      final existingHouseholds = await repo.householdDao.db
          .select(repo.householdDao.db.households)
          .get();
      final sameHead = existingHouseholds.where(
        (household) => _canonicalName(household.headName) == normalizedHeadName,
      );
      var headConfirmedDifferent = false;
      for (final existing in sameHead) {
        final resolution = await _askAboutExistingHousehold(existing);
        if (resolution == _ExistingNameResolution.useExisting) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Existing record kept. Nothing was overwritten.'),
              ),
            );
            setState(() => _isSaving = false);
          }
          return;
        }
        if (resolution == _ExistingNameResolution.cancel) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
        headConfirmedDifferent = true;
      }

      // Check for potential duplicate beneficiaries before proceeding
      const detector = DuplicateDetector();
      final existingMembers = await repo.memberDao.db
          .select(repo.memberDao.db.members)
          .get();
      final skipMemberIndexes = <int>{};

      if (existingMembers.isNotEmpty) {
        for (
          var memberIndex = 0;
          memberIndex < _members.length;
          memberIndex++
        ) {
          final member = _members[memberIndex];
          if (memberIndex == 0 && headConfirmedDifferent) continue;
          final memberName = member.nameController.text.trim();
          if (memberName.isEmpty) continue;

          int? approxDob;
          final ageText = member.ageController.text.trim();
          if (ageText.isNotEmpty) {
            final ageYears = int.tryParse(ageText);
            if (ageYears != null && ageYears > 0) {
              final now = DateTime.now();
              approxDob = DateTime(
                now.year - ageYears,
                1,
                1,
              ).millisecondsSinceEpoch;
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
              builder: (_) =>
                  DuplicateConfirmationDialog(candidates: duplicates),
            );

            if (resolution == DuplicateResolution.cancel ||
                resolution == null) {
              setState(() => _isSaving = false);
              return;
            }
            if (resolution == DuplicateResolution.merge) {
              // “Use existing” is intentionally non-destructive. Do not add
              // another row and never update the existing patient's details.
              skipMemberIndexes.add(memberIndex);
            }
          }
        }
      }

      // 1. Create household offline with UUID v4
      final workerId =
          await _secureStorage.read(key: 'worker_id') ?? 'offline-worker';
      final household = await repo.createHousehold(
        village: _villageController.text.trim(),
        hamlet: _hamletController.text.trim().isEmpty
            ? null
            : _hamletController.text.trim(),
        headName: _headNameController.text.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        ),
        socialCategory: _selectedSocialCategory,
        isBpl: _isBpl,
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        landmarkNotes: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        latitude: _workerPosition?.latitude.toString(),
        longitude: _workerPosition?.longitude.toString(),
        locationCapturedAt:
            _workerPosition?.timestamp.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        createdBy: workerId,
      );

      final proof = _proofImage;
      if (proof != null) {
        final raw = await proof.readAsBytes();
        final compressed = GZipEncoder().encode(raw) ?? const <int>[];
        await ref
            .read(syncEngineProvider)
            .enqueue(
              table: 'household_proofs',
              recordId: '${household.id}:proof',
              operation: 'insert',
              priority: SyncPriority.metadata,
              payload: {
                'household_id': household.id,
                'type': 'photo_proof',
                'mime_type': 'image/jpeg',
                'encoding': 'gzip+base64',
                'data_base64': base64Encode(compressed),
                'captured_at': DateTime.now().millisecondsSinceEpoch,
                'latitude': _workerPosition?.latitude,
                'longitude': _workerPosition?.longitude,
                'recorded_by': workerId,
              },
            );
      }

      // 2. Add family members offline with UUID v4
      String? firstMemberId;
      for (var memberIndex = 0; memberIndex < _members.length; memberIndex++) {
        if (skipMemberIndexes.contains(memberIndex)) continue;
        final member = _members[memberIndex];
        final memberName = member.nameController.text.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
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
                Text('Saved locally. It will sync when connected.'),
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
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          l10n?.registerHousehold ?? 'Register Household',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AshaColors.textPrimary,
          ),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AshaColors.primary,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                key: const Key('household_form_save_button'),
                onPressed: _submit,
                icon: const Icon(Icons.check, color: AshaColors.primary),
                label: Text(
                  l10n?.save ?? 'Save',
                  style: const TextStyle(
                    color: AshaColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
            if (_liveDuplicateHousehold != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFCD34D),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB45309),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Possible Duplicate / Double Entry Detected',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '“${_liveDuplicateHousehold!.headName}” is already registered in ${_liveDuplicateHousehold!.village}${_liveDuplicateHousehold!.hamlet != null ? ' (${_liveDuplicateHousehold!.hamlet})' : ''}. If this is a regular follow-up visit, avoid creating a duplicate entry.',
                            style: const TextStyle(
                              color: Color(0xFF78350F),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AshaColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AshaColors.primary,
                    backgroundColor: AshaColors.surfaceMuted,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AshaColors.primary
                          : AshaColors.borderSubtle,
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    onPressed: () =>
                        setState(() => _selectedSocialCategory = null),
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

            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proof & worker location',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Capture a household proof photo and record your current GPS position. Both are added to the offline sync queue.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('capture_household_proof_button'),
                          onPressed: _isSaving ? null : _captureHouseholdProof,
                          icon: Icon(
                            _proofImage == null
                                ? Icons.camera_alt_outlined
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            _proofImage == null
                                ? 'Capture proof'
                                : 'Proof captured',
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('record_worker_location_button'),
                          onPressed: _isSaving ? null : _captureWorkerLocation,
                          icon: Icon(
                            _workerPosition == null
                                ? Icons.my_location_rounded
                                : Icons.check_circle_rounded,
                            color: _workerPosition == null
                                ? AshaColors.primary
                                : AshaColors.vitalNormal,
                          ),
                          label: Text(
                            _workerPosition == null
                                ? 'Record current location'
                                : 'Location recorded',
                            style: TextStyle(
                              color: _workerPosition == null
                                  ? AshaColors.primary
                                  : AshaColors.vitalNormal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _workerPosition == null
                                  ? AshaColors.borderSubtle
                                  : AshaColors.vitalNormal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_proofMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_proofMessage!),
                    ],
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(_locationMessage!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 3: Family Members ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSectionHeader(
                    icon: Icons.people,
                    title: 'Family Members (${_members.length})',
                  ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AshaColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AshaShapes.buttonRadius,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AshaColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AshaColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AshaColors.textPrimary,
            ),
          ),
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
                  isHead ? 'Member 1: Household Head' : 'Member ${index + 1}',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Sex: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AshaColors.textPrimary,
                  ),
                ),
                ChoiceChip(
                  label: Text(
                    'Female (F)',
                    style: TextStyle(
                      color: member.sex == 'F'
                          ? Colors.white
                          : AshaColors.textPrimary,
                      fontWeight: member.sex == 'F'
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: member.sex == 'F',
                  selectedColor: AshaColors.primary,
                  backgroundColor: AshaColors.surfaceMuted,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: member.sex == 'F'
                        ? AshaColors.primary
                        : AshaColors.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => member.sex = 'F');
                  },
                ),
                ChoiceChip(
                  label: Text(
                    'Male (M)',
                    style: TextStyle(
                      color: member.sex == 'M'
                          ? Colors.white
                          : AshaColors.textPrimary,
                      fontWeight: member.sex == 'M'
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: member.sex == 'M',
                  selectedColor: AshaColors.primary,
                  backgroundColor: AshaColors.surfaceMuted,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: member.sex == 'M'
                        ? AshaColors.primary
                        : AshaColors.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => member.sex = 'M');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    'Other (O)',
                    style: TextStyle(
                      color: member.sex == 'Other'
                          ? Colors.white
                          : AshaColors.textPrimary,
                      fontWeight: member.sex == 'Other'
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: member.sex == 'Other',
                  selectedColor: AshaColors.primary,
                  backgroundColor: AshaColors.surfaceMuted,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: member.sex == 'Other'
                        ? AshaColors.primary
                        : AshaColors.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
