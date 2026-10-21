import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../household/data/member_search_repository.dart';
import '../data/offline_search_index.dart';

/// Unified offline search for beneficiaries and the ASHA field knowledge cards.
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

  static const _categories = <(String?, String, IconData)>[
    (null, 'All', Icons.grid_view_rounded),
    ('medicine', 'Medicine', Icons.medication_outlined),
    ('guide', 'Guides', Icons.menu_book_outlined),
    ('measure', 'Measurements', Icons.speed_outlined),
    ('danger_sign', 'Danger signs', Icons.emergency_outlined),
    ('program', 'Programmes', Icons.account_balance_outlined),
    ('warning', 'Warnings', Icons.shield_outlined),
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
      appBar: AppBar(
        titleSpacing: 8,
        backgroundColor: Colors.white,
        foregroundColor: AshaColors.textPrimary,
        title: TextField(
          key: const Key('offline_assistant_search_field'),
          controller: _controller,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value.trim()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search fever, ORS, person, guide…',
            border: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    key: const Key('offline_assistant_clear_button'),
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          _categoryBar(),
          Expanded(
            child: _query.isEmpty
                ? _emptyState()
                : indexAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _errorState(error),
                    data: (index) => _results(index, peopleAsync),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
            onSelected: (_) => setState(() => _category = category.$1),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Icon(
          Icons.manage_search_rounded,
          size: 68,
          color: AshaColors.primary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Offline ASHA search assistant',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Search local beneficiaries plus medicines, measurements, guides, danger signs, programmes, and safety warnings. Tap any result for the full card.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AshaColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 22),
        _hint('fever', Icons.thermostat_outlined),
        _hint('ORS diarrhoea', Icons.water_drop_outlined),
        _hint('blood pressure', Icons.favorite_border_rounded),
        _hint('pregnancy danger signs', Icons.emergency_outlined),
        const SizedBox(height: 12),
        const Text(
          'Reference support only. Always use the triage engine and refer when unsure.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AshaColors.textMuted),
        ),
      ],
    );
  }

  Widget _hint(String text, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AshaColors.primary),
      title: Text(text),
      trailing: const Icon(Icons.north_west_rounded, size: 16),
      onTap: () {
        _controller.text = text;
        setState(() => _query = text);
      },
    );
  }

  Widget _results(
    OfflineSearchIndex index,
    AsyncValue<List<BeneficiarySearchResult>> peopleAsync,
  ) {
    final knowledge = _category == 'person'
        ? const <SearchKnowledgeEntry>[]
        : index.search(_query, category: _category);
    final showPeople = _category == null || _category == 'person';
    final people =
        peopleAsync.asData?.value ?? const <BeneficiarySearchResult>[];
    final hasPeople = people.isNotEmpty;
    final isLoadingPeople = peopleAsync.isLoading;

    if (knowledge.isEmpty && !hasPeople && !isLoadingPeople) {
      return _noResults();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const _SafetyBanner(),
        if (showPeople && (hasPeople || isLoadingPeople)) ...[
          _sectionTitle('People', Icons.people_alt_outlined),
          if (isLoadingPeople)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            )
          else
            for (final person in people) _personCard(person),
        ],
        if (knowledge.isNotEmpty) ...[
          _sectionTitle('Offline knowledge cards', Icons.auto_awesome_outlined),
          for (final entry in knowledge) _knowledgeCard(entry),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AshaColors.primary),
          const SizedBox(width: 7),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _personCard(BeneficiarySearchResult result) {
    final member = result.member;
    return Card(
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

  Widget _knowledgeCard(SearchKnowledgeEntry entry) {
    return Card(
      key: Key('offline_search_result_${entry.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryIcon(entry.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AshaColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${entry.categoryLabel} • Tap for details',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AshaColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AshaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(String category) {
    final (icon, color) = switch (category) {
      'medicine' => (Icons.medication_outlined, const Color(0xFF176B87)),
      'danger_sign' => (Icons.emergency_outlined, const Color(0xFFB42318)),
      'warning' => (Icons.shield_outlined, const Color(0xFFB45309)),
      'measure' => (Icons.speed_outlined, const Color(0xFF6B4F9B)),
      'program' => (Icons.account_balance_outlined, AshaColors.primary),
      _ => (Icons.menu_book_outlined, AshaColors.primary),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
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
              'Try a symptom, medicine, programme name, danger sign, person name, phone number, or ABHA ID.',
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

  void _showDetails(SearchKnowledgeEntry entry) {
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _categoryIcon(entry.category),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.categoryLabel,
                style: const TextStyle(
                  color: AshaColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _detailSection('Purpose', entry.purpose),
              _detailSection('Dose / protocol', entry.doseOrProtocol),
              _detailSection('How to use', entry.howToUse),
              _detailSection('When to refer', entry.whenToRefer),
              _detailSection('Danger signs', entry.dangerSigns),
              if (entry.approxPrice.isNotEmpty)
                _detailSection('Approx. price / supply', entry.approxPrice),
              _detailSection('Source', entry.sourceRef),
              const SizedBox(height: 8),
              const Text(
                'Use this as an offline reference card. It does not replace clinical classification, local protocol, or PHC referral.',
                style: TextStyle(
                  color: AshaColors.textSecondary,
                  height: 1.35,
                  fontSize: 12,
                ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              height: 1.4,
              color: AshaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2D38A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reference cards are offline support. Run triage before treatment and refer immediately for danger signs.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF6B4A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
