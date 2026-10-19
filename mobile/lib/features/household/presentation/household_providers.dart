import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/household_repository.dart';

/// Provider for loading all registered households.
final householdListProvider =
    FutureProvider.autoDispose<List<Household>>((ref) async {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.listHouseholds();
});

/// Provider for grouping households by hamlet/pada.
/// Requirements: 4.1
final householdsGroupedByHamletProvider =
    FutureProvider.autoDispose<Map<String, List<Household>>>((ref) async {
  final households = await ref.watch(householdListProvider.future);
  final Map<String, List<Household>> grouped = {};

  for (final h in households) {
    final hamletKey = (h.hamlet != null && h.hamlet!.trim().isNotEmpty)
        ? h.hamlet!.trim()
        : 'Main Village / General';
    grouped.putIfAbsent(hamletKey, () => []).add(h);
  }

  return grouped;
});

/// Provider for retrieving a single household with its members.
final householdDetailsProvider =
    FutureProvider.autoDispose.family<HouseholdWithMembers?, String>((ref, id) async {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.getHouseholdWithMembers(id);
});

/// Provider for retrieving a single member by id.
final memberDetailsProvider =
    FutureProvider.autoDispose.family<Member?, String>((ref, id) async {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.getMember(id);
});
