import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/member_search_repository.dart';

/// Offline Beneficiary Full-Text Search screen powered by SQLite FTS5.
///
/// Features:
/// - Real-time lookup by Name, Phonetic variants, ABHA ID, RCH ID, and Phone.
/// - Operates 100% offline without network round-trips.
/// - Scoped to ASHA's community area.
///
/// Requirements: 4.7
class BeneficiarySearchScreen extends ConsumerStatefulWidget {
  const BeneficiarySearchScreen({super.key});

  @override
  ConsumerState<BeneficiarySearchScreen> createState() =>
      _BeneficiarySearchScreenState();
}

class _BeneficiarySearchScreenState
    extends ConsumerState<BeneficiarySearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _query = val.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchAsync = ref.watch(beneficiarySearchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('beneficiary_search_text_field'),
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search name, ABHA, phone, hamlet...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    key: const Key('search_clear_button'),
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildEmptyPrompt(theme)
          : searchAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Search error: $err'),
                    ],
                  ),
                ),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No beneficiaries found for "$_query"',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try searching by first name, phonetic spelling, phone, or ABHA ID.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return _buildResultCard(item);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyPrompt(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search,
              size: 80,
              color: theme.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Offline Beneficiary Search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quickly find beneficiaries in your area without connectivity using SQLite FTS5.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSearchHint(
              icon: Icons.person,
              title: 'By Name or Phonetic Variant',
              subtitle: 'e.g., "Sunita", "Pooja" or "Puja"',
            ),
            const SizedBox(height: 12),
            _buildSearchHint(
              icon: Icons.credit_card,
              title: 'By ABHA or RCH ID',
              subtitle: 'e.g., 14-digit ABHA number',
            ),
            const SizedBox(height: 12),
            _buildSearchHint(
              icon: Icons.phone,
              title: 'By Phone Number',
              subtitle: 'e.g., 10-digit mobile number',
            ),
            const SizedBox(height: 12),
            _buildSearchHint(
              icon: Icons.location_on,
              title: 'By Village or Hamlet',
              subtitle: 'e.g., "Shivpur", "Purva"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHint({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BeneficiarySearchResult item) {
    final m = item.member;
    final hamletStr = item.hamlet?.isNotEmpty == true ? ' • ${item.hamlet}' : '';

    return Card(
      key: Key('search_result_${m.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/beneficiary/${m.id}');
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
                      m.sex == 'F' ? Icons.face_3 : Icons.face,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.village}$hamletStr • Head: ${item.headName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Relationship & Sex badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${m.sex} • ${m.relationshipToHead ?? "Member"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),

                  // Phone chip if available
                  if (m.phone != null && m.phone!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            m.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ABHA ID badge if available
                  if (m.abhaId != null && m.abhaId!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ABHA: ${m.abhaId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade800,
                        ),
                      ),
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
