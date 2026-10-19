import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  const HouseholdListScreen({super.key});

  @override
  ConsumerState<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends ConsumerState<HouseholdListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedHamletFilter;

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
    final theme = Theme.of(context);
    final groupedAsync = ref.watch(householdsGroupedByHamletProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n?.households ?? 'Households'),
        actions: [
          IconButton(
            key: const Key('household_list_language_button'),
            icon: const Icon(Icons.language),
            tooltip: l10n?.language ?? 'Language',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
          IconButton(
            key: const Key('household_list_refresh_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(householdListProvider);
              ref.invalidate(householdsGroupedByHamletProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const Key('household_search_field'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by head name, hamlet, phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load households: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(householdListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groupedMap) {
          if (groupedMap.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          // Apply search query filter across all hamlets
          final Map<String, List<Household>> filteredMap = {};

          groupedMap.forEach((hamlet, households) {
            if (_selectedHamletFilter != null &&
                _selectedHamletFilter != hamlet) {
              return;
            }

            final matching = households.where((h) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No households match "$_searchQuery"',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final hamletKeys = groupedMap.keys.toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(householdListProvider);
              ref.invalidate(householdsGroupedByHamletProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Hamlet filter chips if more than 1 hamlet
                if (hamletKeys.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          key: const Key('hamlet_filter_all'),
                          label: const Text('All Hamlets'),
                          selected: _selectedHamletFilter == null,
                          onSelected: (_) {
                            setState(() => _selectedHamletFilter = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...hamletKeys.map((hamlet) {
                          final count = groupedMap[hamlet]?.length ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              key: Key('hamlet_filter_$hamlet'),
                              label: Text('$hamlet ($count)'),
                              selected: _selectedHamletFilter == hamlet,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedHamletFilter =
                                      selected ? hamlet : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Grouped sections by hamlet
                ...filteredMap.entries.map((entry) {
                  final hamletName = entry.key;
                  final households = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hamletName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${households.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...households.map((household) => _buildHouseholdCard(household)),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('register_household_fab'),
        onPressed: () async {
          final result = await Navigator.of(context).push<Household?>(
            MaterialPageRoute(builder: (_) => const HouseholdFormScreen()),
          );
          if (result != null) {
            ref.invalidate(householdListProvider);
            ref.invalidate(householdsGroupedByHamletProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n?.registerHousehold ?? 'Register Household'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.house_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Households Registered',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register households and their family members to build your offline community registry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_state_register_button'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HouseholdFormScreen()),
                );
                ref.invalidate(householdListProvider);
                ref.invalidate(householdsGroupedByHamletProvider);
              },
              icon: const Icon(Icons.person_add),
              label: Text(l10n?.registerHousehold ?? 'Register Household'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
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

    return Card(
      key: Key('household_card_${household.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.home,
                      color: Theme.of(context).primaryColor,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${household.village}$hamletStr',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Member count chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${household.memberCount} members',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
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
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BPL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
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
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        household.socialCategory!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),

                  // Phone chip if available
                  if (household.contactPhone != null &&
                      household.contactPhone!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          household.contactPhone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
