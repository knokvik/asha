import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/security/auth_service.dart';
import 'core_providers.dart';

/// Real authenticated ASHA worker profile model with live statistics.
class UserProfile {
  final String id;
  final String ashaId;
  final String name;
  final String role;
  final String village;
  final String subcentre;
  final String phc;
  final String phone;
  final int completedVisits;
  final int pendingVisits;
  final int overdueVisits;
  final int totalVisits;
  final String apiBaseUrl;
  final bool isOnline;

  const UserProfile({
    required this.id,
    required this.ashaId,
    required this.name,
    required this.role,
    required this.village,
    required this.subcentre,
    required this.phc,
    this.phone = '+91 98765 43210',
    this.completedVisits = 0,
    this.pendingVisits = 0,
    this.overdueVisits = 0,
    this.totalVisits = 0,
    this.apiBaseUrl = defaultAshaApiBaseUrl,
    this.isOnline = true,
  });

  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'AS';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    }
    return 'AS';
  }

  String get facilityDisplay {
    if (phc.isNotEmpty && phc != 'null') {
      final clean = phc
          .replaceAll(RegExp(r'[-_]'), ' ')
          .replaceAll(RegExp(r'\bphc\b', caseSensitive: false), 'PHC')
          .trim();
      return '$role Worker • $clean';
    }
    if (subcentre.isNotEmpty && subcentre != 'null') {
      return '$role Worker • $subcentre';
    }
    return '$role Worker • Field Health Centre';
  }

  UserProfile copyWith({
    String? id,
    String? ashaId,
    String? name,
    String? role,
    String? village,
    String? subcentre,
    String? phc,
    String? phone,
    int? completedVisits,
    int? pendingVisits,
    int? overdueVisits,
    int? totalVisits,
    String? apiBaseUrl,
    bool? isOnline,
  }) {
    return UserProfile(
      id: id ?? this.id,
      ashaId: ashaId ?? this.ashaId,
      name: name ?? this.name,
      role: role ?? this.role,
      village: village ?? this.village,
      subcentre: subcentre ?? this.subcentre,
      phc: phc ?? this.phc,
      phone: phone ?? this.phone,
      completedVisits: completedVisits ?? this.completedVisits,
      pendingVisits: pendingVisits ?? this.pendingVisits,
      overdueVisits: overdueVisits ?? this.overdueVisits,
      totalVisits: totalVisits ?? this.totalVisits,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  final FlutterSecureStorage _storage;

  UserProfileNotifier([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<UserProfile> build() async {
    return _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    // 1. Read stored server identity
    final workerId = await _storage.read(key: 'worker_id') ?? '';
    final ashaId = await _storage.read(key: 'server_user_id') ?? 'ASHA-001';
    final name = await _storage.read(key: 'server_user_name') ?? 'Sunita Devi';
    final role = await _storage.read(key: 'server_user_role') ?? 'ASHA';
    final phc = await _storage.read(key: 'server_phc_id') ?? 'phc-shahpur';
    final subcentre = await _storage.read(key: 'server_subcentre_id') ?? 'sc-shahpur';
    final village = await _storage.read(key: 'server_village') ?? 'Shahpur';
    final apiBaseUrl = await _storage.read(key: 'sync_api_base_url') ?? defaultAshaApiBaseUrl;

    int completed = 0;
    int pending = 0;
    int overdue = 0;

    // 2. Query live database counts if database is unlocked
    try {
      final db = ref.read(appDatabaseProvider);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final schedules = await db.select(db.visitSchedules).get();
      completed = schedules.where((s) => s.status == 'completed').length;
      pending = schedules.where((s) => s.status == 'pending' || s.status == 'rescheduled').length;
      overdue = schedules.where((s) => s.status == 'pending' && s.dueDate < nowMs).length;

      final userRow = await (db.select(db.users)..where((u) => u.role.equals('ASHA'))).getSingleOrNull();
      if (userRow != null) {
        _triggerBackgroundServerFetch();
        return UserProfile(
          id: userRow.id,
          ashaId: userRow.ashaId,
          name: userRow.name,
          role: userRow.role,
          village: userRow.areaVillage ?? village,
          subcentre: userRow.areaSubcentre ?? subcentre,
          phc: userRow.areaPhc ?? phc,
          completedVisits: completed,
          pendingVisits: pending,
          overdueVisits: overdue,
          totalVisits: completed + pending,
          apiBaseUrl: apiBaseUrl,
        );
      }
    } catch (_) {
      // AppDatabase not yet unlocked; rely on secure storage
    }

    _triggerBackgroundServerFetch();
    return UserProfile(
      id: workerId.isNotEmpty ? workerId : 'asha-local-01',
      ashaId: ashaId,
      name: name,
      role: role,
      village: village,
      subcentre: subcentre,
      phc: phc,
      completedVisits: completed,
      pendingVisits: pending,
      overdueVisits: overdue,
      totalVisits: completed + pending,
      apiBaseUrl: apiBaseUrl,
    );
  }

  Future<void> loadProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadProfile());
  }

  void _triggerBackgroundServerFetch() {
    _fetchFromServer().catchError((_) {});
  }

  Future<void> _fetchFromServer() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.isEmpty) return;

    final apiBaseUrl = await _storage.read(key: 'sync_api_base_url') ?? defaultAshaApiBaseUrl;
    final meUri = Uri.parse('${apiBaseUrl.replaceFirst(RegExp(r"/+$"), "")}/api/v1/auth/me');

    try {
      final res = await http.get(
        meUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newName = data['name']?.toString();
        final newAshaId = data['username']?.toString() ?? data['asha_id']?.toString();
        final newRole = data['role']?.toString();
        final newPhc = data['phcId']?.toString() ?? data['facility']?.toString();
        final newSubcentre = data['subcentreId']?.toString();
        final newVillage = data['village']?.toString();

        if (newName != null && newName.isNotEmpty) {
          await _storage.write(key: 'server_user_name', value: newName);
        }
        if (newAshaId != null && newAshaId.isNotEmpty) {
          await _storage.write(key: 'server_user_id', value: newAshaId);
        }
        if (newRole != null && newRole.isNotEmpty) {
          await _storage.write(key: 'server_user_role', value: newRole);
        }
        if (newPhc != null && newPhc.isNotEmpty) {
          await _storage.write(key: 'server_phc_id', value: newPhc);
        }
        if (newSubcentre != null && newSubcentre.isNotEmpty) {
          await _storage.write(key: 'server_subcentre_id', value: newSubcentre);
        }
        if (newVillage != null && newVillage.isNotEmpty) {
          await _storage.write(key: 'server_village', value: newVillage);
        }

        final current = state.value;
        if (current != null) {
          state = AsyncData(
            current.copyWith(
              name: newName ?? current.name,
              ashaId: newAshaId ?? current.ashaId,
              role: newRole ?? current.role,
              phc: newPhc ?? current.phc,
              subcentre: newSubcentre ?? current.subcentre,
              village: newVillage ?? current.village,
              isOnline: true,
            ),
          );
        }
      }
    } catch (_) {
      // Offline fallback: keep existing profile data
    }
  }

  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'worker_id');
    await _storage.delete(key: 'server_user_name');
    await _storage.delete(key: 'server_user_id');
    await _storage.delete(key: 'asha_pin_hash_v1');

    ref.read(databaseKeyProvider.notifier).lock();
    state = const AsyncLoading();

    if (context.mounted) {
      context.go('/login');
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);
