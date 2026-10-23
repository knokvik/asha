import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firestore Database service for Asha-Setu.
///
/// Provides structured access to Firestore collections:
/// - `users`: ASHA worker profile and auth mappings
/// - `triage_tickets`: Urgent, priority, and standard triage assessments
/// - `households`: Registered household details and location coordinates
/// - `members`: Beneficiaries, demographics, and risk categories
/// - `clinical_encounters`: Anc, immunization, and NCD field visits
/// - `sync_packets`: Batched offline packets uploaded by field workers
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserPhone => _auth.currentUser?.phoneNumber;

  // ---------------------------------------------------------------------------
  // Worker Profiles
  // ---------------------------------------------------------------------------

  /// Syncs or updates worker profile in Firestore
  Future<void> syncUserProfile({
    required String ashaId,
    required String name,
    required String state,
    required String district,
    required String block,
    required String village,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final docRef = _firestore.collection('users').doc(uid);
    await docRef.set({
      'uid': uid,
      'asha_id': ashaId,
      'phone_number': currentUserPhone,
      'name': name,
      'state': state,
      'district': district,
      'block': block,
      'village': village,
      'last_active_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Triage Tickets
  // ---------------------------------------------------------------------------

  /// Saves a triage referral ticket to Firestore
  Future<void> saveTriageTicket({
    required String ticketId,
    required String patientName,
    required int ageMonths,
    required String sex,
    required String village,
    required String flag,
    required String summary,
    required Map<String, dynamic> findings,
    required String facilityName,
    String? audioUrl,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('triage_tickets').doc(ticketId).set({
        'ticket_id': ticketId,
        'asha_uid': currentUserId,
        'asha_phone': currentUserPhone,
        'patient_name': patientName,
        'age_months': ageMonths,
        'sex': sex,
        'village': village,
        'triage_flag': flag,
        'clinical_summary': summary,
        'findings': findings,
        'facility_name': facilityName,
        'audio_url': audioUrl,
        'image_url': imageUrl,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving triage ticket to Firestore: $e');
      rethrow;
    }
  }

  /// Real-time stream of triage tickets for current ASHA worker
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyTriageTickets() {
    return _firestore
        .collection('triage_tickets')
        .where('asha_phone', isEqualTo: currentUserPhone)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Households & Beneficiaries
  // ---------------------------------------------------------------------------

  /// Registers or updates household in Firestore
  Future<void> saveHousehold({
    required String householdId,
    required String headName,
    required String address,
    required double latitude,
    required double longitude,
    required int memberCount,
    required String socialCategory,
  }) async {
    try {
      await _firestore.collection('households').doc(householdId).set({
        'household_id': householdId,
        'asha_uid': currentUserId,
        'head_name': headName,
        'address': address,
        'location': GeoPoint(latitude, longitude),
        'member_count': memberCount,
        'social_category': socialCategory,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving household to Firestore: $e');
      rethrow;
    }
  }

  /// Real-time stream of households registered by current worker
  Stream<QuerySnapshot<Map<String, dynamic>>> streamHouseholds() {
    return _firestore
        .collection('households')
        .where('asha_uid', isEqualTo: currentUserId)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Sync Packets (Offline Packet Backup)
  // ---------------------------------------------------------------------------

  /// Uploads encrypted sync packet payload directly to Firestore
  Future<void> uploadSyncPacket({
    required String packetId,
    required String packetType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _firestore.collection('sync_packets').doc(packetId).set({
        'packet_id': packetId,
        'packet_type': packetType,
        'asha_uid': currentUserId,
        'asha_phone': currentUserPhone,
        'payload': payload,
        'synced_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error uploading sync packet to Firestore: $e');
      rethrow;
    }
  }
}
