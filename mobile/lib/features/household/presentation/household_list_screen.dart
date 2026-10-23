import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/widgets/app_drawer.dart';
import 'household_form_screen.dart';
import 'household_providers.dart';

/// Screen listing all registered households grouped by hamlet/pada with offline search.
///
/// Requirements: 4.1
/// - Hamlet grouping with section headers.
/// - Instant offline search by head name, hamlet, or phone.
/// - Direct navigation to register household screen.
class HouseholdListScreen extends ConsumerStatefulWidget {
  const HouseholdListScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<HouseholdListScreen> createState() =>
      _HouseholdListScreenState();
}

class _HouseholdListScreenState extends ConsumerState<HouseholdListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedHamletFilter;
  bool? _bplFilter;
  String? _syncFilter;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    _searchQuery = initialQuery.toLowerCase();
    _searchController.text = initialQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupedAsync = ref.watch(householdsGroupedByHamletProvider);

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          l10n?.households ?? 'Households',
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
          IconButton(
            key: const Key('household_list_language_button'),
            icon: const Icon(Icons.language_rounded),
            tooltip: l10n?.language ?? 'Language',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
          IconButton(
            key: const Key('household_list_refresh_button'),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(householdListProvider);
              ref.invalidate(householdsGroupedByHamletProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AshaColors.screenBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AshaColors.borderSubtle),
              ),
              child: TextField(
                key: const Key('household_search_field'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: AshaColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by head name, hamlet, phone...',
                  hintStyle: const TextStyle(
                    color: AshaColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AshaColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AshaColors.textSecondary,
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: groupedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AshaColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AshaColors.alertHighRisk,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load households: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AshaColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(householdListProvider);
                    ref.invalidate(householdsGroupedByHamletProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AshaColors.primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AshaShapes.buttonRadius,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (groupedMap) {
          if (groupedMap.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          // Compute summary stats
          final totalHouseholds = groupedMap.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );
          final totalMembers = groupedMap.values.fold<int>(
            0,
            (sum, list) => sum + list.fold<int>(0, (s, h) => s + h.memberCount),
          );
          final totalHamlets = groupedMap.keys.length;

          // Apply search query filter across all hamlets
          final Map<String, List<Household>> filteredMap = {};

          groupedMap.forEach((hamlet, households) {
            if (_selectedHamletFilter != null &&
                _selectedHamletFilter != hamlet) {
              return;
            }

            final matching = households.where((h) {
              if (_bplFilter != null && h.isBpl != _bplFilter) return false;
              if (_syncFilter != null && h.syncStatus != _syncFilter)
                return false;
              if (_searchQuery.isEmpty) return true;
              final head = h.headName.toLowerCase();
              final village = h.village.toLowerCase();
              final hamletText = (h.hamlet ?? '').toLowerCase();
              final phone = (h.contactPhone ?? '').toLowerCase();
              return head.contains(_searchQuery) ||
                  village.contains(_searchQuery) ||
                  hamletText.contains(_searchQuery) ||
                  phone.contains(_searchQuery);
            }).toList();

            if (matching.isNotEmpty) {
              filteredMap[hamlet] = matching;
            }
          });

          if (filteredMap.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AshaColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 32,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No households match "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AshaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try checking the spelling or clear the filter',
                      style: TextStyle(
                        fontSize: 13,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final hamletKeys = groupedMap.keys.toList();

          return RefreshIndicator(
            color: AshaColors.primary,
            onRefresh: () async {
              ref.invalidate(householdListProvider);
              ref.invalidate(householdsGroupedByHamletProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top KPI Summary Cards Row
                _buildSummaryKpiRow(
                  totalHouseholds: totalHouseholds,
                  totalHamlets: totalHamlets,
                  totalMembers: totalMembers,
                ),
                const SizedBox(height: 14),

                // Hamlet filter chips if more than 1 hamlet
                if (hamletKeys.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHamletFilterChip(
                          key: const Key('hamlet_filter_all'),
                          label: 'All Hamlets',
                          isSelected: _selectedHamletFilter == null,
                          onSelected: (_) {
                            setState(() => _selectedHamletFilter = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...hamletKeys.map((hamlet) {
                          final count = groupedMap[hamlet]?.length ?? 0;
                          final isSelected = _selectedHamletFilter == hamlet;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildHamletFilterChip(
                              key: Key('hamlet_filter_$hamlet'),
                              label: '$hamlet ($count)',
                              isSelected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedHamletFilter = selected
                                      ? hamlet
                                      : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('BPL'),
                      selected: _bplFilter == true,
                      onSelected: (v) =>
                          setState(() => _bplFilter = v ? true : null),
                    ),
                    FilterChip(
                      label: const Text('Pending sync'),
                      selected: _syncFilter == 'pending',
                      onSelected: (v) =>
                          setState(() => _syncFilter = v ? 'pending' : null),
                    ),
                    FilterChip(
                      label: const Text('Synced'),
                      selected: _syncFilter == 'synced',
                      onSelected: (v) =>
                          setState(() => _syncFilter = v ? 'synced' : null),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Grouped sections by hamlet
                ...filteredMap.entries.map((entry) {
                  final hamletName = entry.key;
                  final households = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AshaColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hamletName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AshaColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AshaColors.vitalNormal.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AshaColors.vitalNormal.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${households.length} ${households.length == 1 ? 'Household' : 'Households'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...households.map(
                        (household) => _buildHouseholdCard(household),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 72), // Spacing for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('register_household_fab'),
        backgroundColor: AshaColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: AshaShapes.buttonRadius,
        ),
        onPressed: () async {
          final result = await Navigator.of(context).push<Household?>(
            MaterialPageRoute(builder: (_) => const HouseholdFormScreen()),
          );
          if (result != null) {
            ref.invalidate(householdListProvider);
            ref.invalidate(householdsGroupedByHamletProvider);
          }
        },
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          l10n?.registerHousehold ?? 'Register Household',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryKpiRow({
    required int totalHouseholds,
    required int totalHamlets,
    required int totalMembers,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildKpiBlock(
            label: 'Households',
            count: '$totalHouseholds',
            color: AshaColors.primary,
            icon: Icons.holiday_village_outlined,
          ),
          Container(
            height: 36,
            width: 1,
            color: AshaColors.borderSubtle,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildKpiBlock(
            label: 'Hamlets',
            count: '$totalHamlets',
            color: const Color(0xFF2563EB),
            icon: Icons.map_outlined,
          ),
          Container(
            height: 36,
            width: 1,
            color: AshaColors.borderSubtle,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildKpiBlock(
            label: 'Beneficiaries',
            count: '$totalMembers',
            color: const Color(0xFF16A34A),
            icon: Icons.people_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBlock({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AshaColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHamletFilterChip({
    required Key key,
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      key: key,
      selected: isSelected,
      label: Text(label),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AshaColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: AshaColors.cardSurface,
      selectedColor: AshaColors.primary,
      side: BorderSide(
        color: isSelected ? AshaColors.primary : AshaColors.borderSubtle,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: onSelected,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AshaColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 40,
                color: AshaColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Households Registered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AshaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register households and their family members to build your offline community registry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AshaColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_state_register_button'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HouseholdFormScreen(),
                  ),
                );
                ref.invalidate(householdListProvider);
                ref.invalidate(householdsGroupedByHamletProvider);
              },
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(l10n?.registerHousehold ?? 'Register Household'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AshaColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AshaShapes.buttonRadius,
                ),
                minimumSize: const Size(220, 50),
                elevation: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdCard(Household household) {
    final hamletStr = household.hamlet?.isNotEmpty == true
        ? ' • ${household.hamlet}'
        : '';

    return Container(
      key: Key('household_card_${household.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshaColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/household/${household.id}');
          },
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
                        color: AshaColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        color: AshaColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            household.headName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AshaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            household.syncStatus == 'synced'
                                ? '✓ Synced'
                                : '● Saved on phone · pending sync',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: household.syncStatus == 'synced'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AshaColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${household.village}$hamletStr',
                                  style: const TextStyle(
                                    color: AshaColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AshaColors.screenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AshaColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Member count chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            size: 13,
                            color: AshaColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${household.memberCount} members',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AshaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BPL status badge
                    if (household.isBpl)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'BPL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),

                    // Social category badge
                    if (household.socialCategory != null &&
                        household.socialCategory!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Text(
                          household.socialCategory!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                      ),

                    // Phone chip if available
                    if (household.contactPhone != null &&
                        household.contactPhone!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AshaColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              household.contactPhone!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AshaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
