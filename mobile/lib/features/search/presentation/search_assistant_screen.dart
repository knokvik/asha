import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../household/data/member_search_repository.dart';
import '../data/clinical_dictionary.dart';
import '../data/offline_search_index.dart';

/// Unified offline search for beneficiaries and the ASHA field knowledge cards.
/// Features a bottom-docked search bar with integrated back button, 4-section
/// categorized search results, and a full clinical disease dictionary.
class SearchAssistantScreen extends ConsumerStatefulWidget {
  const SearchAssistantScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchAssistantScreen> createState() =>
      _SearchAssistantScreenState();
}

class _SearchAssistantScreenState extends ConsumerState<SearchAssistantScreen> {
  late final TextEditingController _controller;
  String _query = '';
  String? _category;
  String? _selectedQuickDisease;
  String? _selectedQuickDiseaseLabel;

  static const _categories = <(String?, String, IconData)>[
    (null, 'All', Icons.grid_view_rounded),
    ('disease', 'Diseases', Icons.health_and_safety_outlined),
    ('medicine', 'Medicine', Icons.medication_outlined),
    ('guide', 'Guides', Icons.menu_book_outlined),
    ('danger_sign', 'Danger signs', Icons.emergency_outlined),
    ('person', 'People', Icons.people_alt_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indexAsync = ref.watch(offlineSearchIndexProvider);
    final peopleAsync = _category == 'person'
        ? ref.watch(beneficiarySearchResultsProvider(_query))
        : (_query.isEmpty || _category != null)
        ? const AsyncValue.data(<BeneficiarySearchResult>[])
        : ref.watch(beneficiarySearchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topHeader(),
            _categoryBar(),
            Expanded(
              child: _query.isEmpty
                  ? _emptyDictionaryHome()
                  : indexAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _errorState(error),
                      data: (index) => _buildSearchResults(index, peopleAsync),
                    ),
            ),
            _bottomSearchBar(context),
          ],
        ),
      ),
    );
  }

  /// Top title strip with offline status badge
  Widget _topHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AshaColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AshaColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'ASHA Knowledge & Dictionary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AshaColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEF7EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF03543F),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Clinical dictionary, medicines, protocols & danger signs',
                  style: TextStyle(
                    fontSize: 11,
                    color: AshaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter category chips
  Widget _categoryBar() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _category == category.$1;
          return FilterChip(
            key: Key('search_category_${category.$2.toLowerCase()}'),
            selected: selected,
            avatar: Icon(category.$3, size: 16),
            label: Text(category.$2),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AshaColors.primaryDark
                  : AshaColors.textSecondary,
            ),
            selectedColor: AshaColors.primaryLight,
            checkmarkColor: AshaColors.primaryDark,
            onSelected: (_) => setState(() => _category = category.$1),
          );
        },
      ),
    );
  }

  /// Search results formatted into the 4 distinct clinical sections
  Widget _buildSearchResults(
    OfflineSearchIndex index,
    AsyncValue<List<BeneficiarySearchResult>> peopleAsync,
  ) {
    final sections = index.searchSections(_query);
    final people =
        peopleAsync.asData?.value ?? const <BeneficiarySearchResult>[];
    final hasPeople =
        (_category == null || _category == 'person') && people.isNotEmpty;
    final isLoadingPeople =
        (_category == null || _category == 'person') && peopleAsync.isLoading;

    // Filter by category if selected
    final showDiseases =
        (_category == null || _category == 'disease') &&
        sections.diseases.isNotEmpty;
    final showMedicines =
        (_category == null || _category == 'medicine') &&
        sections.medicines.isNotEmpty;
    final showGuides =
        (_category == null || _category == 'guide') &&
        sections.guides.isNotEmpty;
    final showDangerSigns =
        (_category == null || _category == 'danger_sign') &&
        sections.dangerSigns.isNotEmpty;

    if (!showDiseases &&
        !showMedicines &&
        !showGuides &&
        !showDangerSigns &&
        !hasPeople &&
        !isLoadingPeople) {
      return _noResults();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        const _SafetyBanner(),
        if (_selectedQuickDisease != null) ...[
          _diseaseTaskBar(),
          const SizedBox(height: 8),
        ],

        // 1. SECTION 1: Diseases & Clinical Conditions (Clinical Dictionary)
        if (showDiseases) ...[
          _sectionHeader(
            '1. Clinical Conditions & Diseases',
            '${sections.diseases.length} matching conditions',
            Icons.health_and_safety_outlined,
            const Color(0xFF047857),
          ),
          for (final disease in sections.diseases) _diseaseCard(disease),
          const SizedBox(height: 8),
        ],

        // 2. SECTION 2: Recommended Medicines & Dosages
        if (showMedicines) ...[
          _sectionHeader(
            '2. Medicines & Dosing Protocols',
            '${sections.medicines.length} verified pharmaceuticals',
            Icons.medication_outlined,
            const Color(0xFF1D4ED8),
          ),
          for (final med in sections.medicines) _medicineCard(med),
          const SizedBox(height: 8),
        ],

        // 3. SECTION 3: Field Action Guides & Protocols
        if (showGuides) ...[
          _sectionHeader(
            '3. Field Guides & Action Protocols',
            '${sections.guides.length} SOPs and measurement standards',
            Icons.menu_book_outlined,
            const Color(0xFF7C3AED),
          ),
          for (final guide in sections.guides) _guideCard(guide),
          const SizedBox(height: 8),
        ],

        // 4. SECTION 4: Danger Signs & Emergency Warnings
        if (showDangerSigns) ...[
          _sectionHeader(
            '4. Danger Signs & Red Flag Warnings',
            '${sections.dangerSigns.length} critical emergency signs',
            Icons.warning_amber_rounded,
            const Color(0xFFDC2626),
          ),
          for (final sign in sections.dangerSigns) _dangerSignCard(sign),
          const SizedBox(height: 8),
        ],

        // Optional 5th Section: Beneficiaries in Household Registry
        if (hasPeople || isLoadingPeople) ...[
          _sectionHeader(
            'Beneficiaries in Catchment',
            'Local registered individuals',
            Icons.people_alt_outlined,
            const Color(0xFF475569),
          ),
          if (isLoadingPeople)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            )
          else
            for (final person in people) _personCard(person),
        ],
      ],
    );
  }

  /// Section Header with title and count badge
  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AshaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Disease / Clinical Condition Card (Tapping opens the full Clinical Dictionary)
  Widget _diseaseCard(ClinicalDisease disease) {
    return Card(
      key: Key('disease_card_${disease.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: disease.badgeColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showClinicalDictionarySheet(disease),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: disease.badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: disease.badgeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease.nameEn,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AshaColors.textPrimary,
                          ),
                        ),
                        Text(
                          disease.nameLocal,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: disease.badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: disease.badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: disease.badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      disease.severityBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: disease.badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                disease.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AshaColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AshaColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: AshaColors.primaryDark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tap to view Clinical Dictionary, Counter-measures & Doses →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AshaColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Medicine card
  Widget _medicineCard(SearchKnowledgeEntry entry) {
    return Card(
      key: Key('offline_search_result_${entry.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDBEAFE)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: Color(0xFF1D4ED8),
            size: 20,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.purpose}\n${entry.doseOrProtocol}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AshaColors.textMuted,
        ),
        onTap: () => _showKnowledgeSheet(entry),
      ),
    );
  }

  /// Guide card
  Widget _guideCard(SearchKnowledgeEntry entry) {
    return Card(
      key: Key('offline_search_result_${entry.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF3E8FF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF7C3AED),
            size: 20,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          entry.purpose,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AshaColors.textMuted,
        ),
        onTap: () => _showKnowledgeSheet(entry),
      ),
    );
  }

  /// Danger sign card
  Widget _dangerSignCard(SearchKnowledgeEntry entry) {
    return Card(
      key: Key('offline_search_result_${entry.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFFFF1F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFECDD3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.emergency_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: Color(0xFF991B1B),
          ),
        ),
        subtitle: Text(
          entry.purpose,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFB91C1C),
        ),
        onTap: () => _showKnowledgeSheet(entry),
      ),
    );
  }

  /// Beneficiary person card
  Widget _personCard(BeneficiarySearchResult result) {
    final member = result.member;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AshaColors.primaryLight,
          child: Icon(Icons.person_outline, color: AshaColors.primary),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${result.village} • Head: ${result.headName}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/beneficiary/${member.id}'),
      ),
    );
  }

  /// Empty state showing clinical dictionary shelf and quick search tags
  Widget _emptyDictionaryHome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _quickLookupPanel(),
        const SizedBox(height: 20),

        // Clinical Disease Dictionary Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Clinical Condition Dictionary (12 Protocols)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AshaColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AshaColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'IMCI / NHM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AshaColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // List of all 12 diseases in the dictionary
        for (final disease in ClinicalDictionary.allDiseases)
          _diseaseCard(disease),
      ],
    );
  }

  Widget _quickChip(String query, String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AshaColors.primary),
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AshaColors.textPrimary,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      onPressed: () {
        _controller.text = query;
        setState(() {
          _query = query;
          _selectedQuickDisease = query;
          _selectedQuickDiseaseLabel = label;
          _category = null;
        });
      },
    );
  }

  Widget _quickLookupPanel() {
    return Card(
      key: const Key('quick_disease_lookup_panel'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (_) {},
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: const Icon(
          Icons.health_and_safety_outlined,
          color: AshaColors.primary,
        ),
        title: const Text(
          'Quick Disease & Symptom Lookups',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Tap to choose a disease and see its tasks'),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('fever', 'Fever (बुखार)', Icons.thermostat_rounded),
              _quickChip(
                'diarrhoea',
                'Diarrhoea (दस्त)',
                Icons.water_drop_rounded,
              ),
              _quickChip(
                'pneumonia',
                'Pneumonia (निमोनिया)',
                Icons.air_rounded,
              ),
              _quickChip(
                'malaria',
                'Malaria (मलेरिया)',
                Icons.pest_control_rounded,
              ),
              _quickChip(
                'dengue',
                'Dengue (डेंगू)',
                Icons.warning_amber_rounded,
              ),
              _quickChip(
                'malnutrition',
                'SAM Malnutrition',
                Icons.speed_rounded,
              ),
              _quickChip(
                'pregnancy',
                'High-Risk Pregnancy',
                Icons.pregnant_woman_rounded,
              ),
              _quickChip('newborn', 'Newborn Sepsis', Icons.child_care_rounded),
              _quickChip(
                'tuberculosis',
                'TB (क्षय रोग)',
                Icons.medical_services_rounded,
              ),
              _quickChip(
                'hypertension',
                'High BP (रक्तचाप)',
                Icons.favorite_rounded,
              ),
              _quickChip(
                'diabetes',
                'Diabetes (मधुमेह)',
                Icons.bloodtype_rounded,
              ),
              _quickChip(
                'anaemia',
                'Anaemia (खून की कमी)',
                Icons.monitor_heart_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diseaseTaskBar() {
    final label = _selectedQuickDiseaseLabel ?? _selectedQuickDisease!;
    return Container(
      key: const Key('quick_disease_task_bar'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AshaColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshaColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label tasks',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AshaColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/triage'),
                icon: const Icon(Icons.fact_check_outlined, size: 17),
                label: const Text('Start triage'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _category = 'medicine'),
                icon: const Icon(Icons.medication_outlined, size: 17),
                label: const Text('Medicines'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _category = 'danger_sign'),
                icon: const Icon(Icons.warning_amber_rounded, size: 17),
                label: const Text('Danger signs'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// BOTTOM SEARCH BAR with integrated back button
  Widget _bottomSearchBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        bottomInset > 0 ? 8 : (bottomPadding > 0 ? bottomPadding : 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AshaColors.cardSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // INTEGRATED BACK BUTTON INSIDE THE SEARCH BAR
            IconButton(
              key: const Key('search_assistant_back_button'),
              tooltip: 'Back to previous screen',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AshaColors.textPrimary,
                size: 22,
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).maybePop();
              },
            ),

            // Text search input
            Expanded(
              child: TextField(
                key: const Key('offline_assistant_search_field'),
                controller: _controller,
                autofocus: _query.isEmpty,
                onChanged: (value) => setState(() {
                  _query = value.trim();
                  _selectedQuickDisease = null;
                  _selectedQuickDiseaseLabel = null;
                }),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AshaColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search fever, medicines, guides, signs...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: AshaColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Clear button or Search icon
            if (_query.isNotEmpty)
              IconButton(
                key: const Key('offline_assistant_clear_button'),
                tooltip: 'Clear search',
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 20,
                  color: AshaColors.textSecondary,
                ),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _query = '';
                    _selectedQuickDisease = null;
                    _selectedQuickDiseaseLabel = null;
                  });
                },
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.search_rounded,
                  color: AshaColors.primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// FULL CLINICAL DICTIONARY MODAL SHEET FOR A SPECIFIC DISEASE
  void _showClinicalDictionarySheet(ClinicalDisease disease) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: disease.badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: disease.badgeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease.nameEn,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AshaColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          disease.nameLocal,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: disease.badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Severity Badge Strip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: disease.badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: disease.badgeColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      disease.severityBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: disease.badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Clinical Dictionary Protocol',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. INTRODUCTION & CLINICAL DEFINITION
              _dictionaryCard(
                title: '1. Introduction & Clinical Definition',
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF0D9488),
                content: Text(
                  disease.introduction,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AshaColors.textPrimary,
                  ),
                ),
              ),

              // 2. COUNTER MEASURES & FIRST AID STEPS
              _dictionaryCard(
                title: '2. Counter Measures & Action Steps',
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF2563EB),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < disease.counterMeasures.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                disease.counterMeasures[i],
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AshaColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 3. MEDICINES & PRECISE DOSAGES
              _dictionaryCard(
                title: '3. Recommended Medicines & Dosing Schedule',
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFF059669),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final med in disease.medicines) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14532D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Indication: ${med.indication}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDCFCE7),
                                ),
                              ),
                              child: Text(
                                med.dosage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'How to give: ${med.howToAdminister}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AshaColors.textSecondary,
                              ),
                            ),
                            if (med.cautionWarning.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        med.cautionWarning,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF991B1B),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 4. DANGER SIGNS & RED FLAGS
              _dictionaryCard(
                title: '4. Danger Signs & Red Flags (Immediate Referral)',
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFDC2626),
                isAlert: true,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final sign in disease.dangerSigns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🚨 ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(
                                sign,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 5. REFERRAL PROTOCOL
              _dictionaryCard(
                title: '5. Facility Referral & Ambulance Protocol',
                icon: Icons.local_hospital_rounded,
                iconColor: const Color(0xFF2563EB),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in disease.referralProtocol)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AshaColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 6. COMMUNITY COUNSELING & PREVENTION
              _dictionaryCard(
                title: '6. Community Counseling & Prevention',
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF047857),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in disease.preventionTips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 16,
                              color: Color(0xFF047857),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AshaColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Source Protocol: ${disease.sourceGuidelines}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AshaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Container card for each dictionary section
  Widget _dictionaryCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    bool isAlert = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isAlert
                        ? const Color(0xFF991B1B)
                        : AshaColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, thickness: 0.8),
          content,
        ],
      ),
    );
  }

  /// Existing knowledge sheet for medicines and guides
  void _showKnowledgeSheet(SearchKnowledgeEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.94,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AshaColors.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AshaColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.categoryLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AshaColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailSection('Purpose / Indication', entry.purpose),
              _detailSection('Dose / Protocol', entry.doseOrProtocol),
              _detailSection('How to Use / Administration', entry.howToUse),
              _detailSection('When to Refer', entry.whenToRefer),
              _detailSection('Danger Signs / Red Flags', entry.dangerSigns),
              if (entry.approxPrice.isNotEmpty)
                _detailSection('Supply / Cost', entry.approxPrice),
              _detailSection('Guideline Source', entry.sourceRef),
              const SizedBox(height: 8),
              const Text(
                'Offline ASHA reference protocol. Always verify danger signs and triage risk.',
                style: TextStyle(color: AshaColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, String value) {
    if (value.trim().isEmpty || value.trim() == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AshaColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AshaColors.textPrimary,
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 58,
              color: AshaColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No offline results for “$_query”',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a symptom (fever, diarrhoea, cough), medicine (paracetamol, ORS), danger sign, or person name.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AshaColors.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Offline search catalog could not load: $error'),
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AshaColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AshaColors.primary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '100% Offline Clinical Assistant. Displays Diseases, Medicines, Action Guides & Danger Signs.',
              style: TextStyle(
                fontSize: 11.5,
                color: AshaColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
