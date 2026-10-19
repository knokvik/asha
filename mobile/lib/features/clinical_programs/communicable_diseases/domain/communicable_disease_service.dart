import 'communicable_disease_models.dart';

class CommunicableDiseaseService {
  CommunicableDiseaseService();

  /// Records Malaria RDT test and determines species-specific NVBDCP treatment regimen (Requirement 21.1).
  MalariaRdtRecord evaluateMalariaRdt({
    required String memberId,
    required MalariaSpecies species,
    required bool isEndemicArea,
  }) {
    final now = DateTime.now();
    String treatment;
    bool needsFacilityReferral;
    String urgency;

    switch (species) {
      case MalariaSpecies.plasmodiumFalciparum:
        treatment = 'Artemisinin-based Combination Therapy (ACT-AL) 3-day course + single dose Primaquine on Day 2 under supervision.';
        needsFacilityReferral = true;
        urgency = 'URGENT_REFERRAL (Within 24 hours to PHC/CHO)';
        break;
      case MalariaSpecies.plasmodiumVivax:
        treatment = 'Chloroquine tablets (3 days: 25 mg/kg total) followed by Primaquine (0.25 mg/kg daily for 14 days under MO prescription).';
        needsFacilityReferral = true;
        urgency = 'REFERRAL (To PHC for MO prescription & G6PD review)';
        break;
      case MalariaSpecies.mixed:
        treatment = 'Full course ACT-AL + Primaquine for 14 days per NVBDCP mixed-species protocol.';
        needsFacilityReferral = true;
        urgency = 'URGENT_REFERRAL (Within 24 hours to PHC/CHC)';
        break;
      case MalariaSpecies.negative:
        treatment = 'Symptomatic fever care (Paracetamol). Re-test if high fever persists > 48 hours or other symptoms develop.';
        needsFacilityReferral = false;
        urgency = 'ROUTINE';
        break;
    }

    return MalariaRdtRecord(
      id: 'malaria_rdt_${now.millisecondsSinceEpoch}',
      memberId: memberId,
      testDate: now,
      resultSpecies: species,
      isEndemicArea: isEndemicArea,
      treatmentRegimen: treatment,
      requiresFacilityReferral: needsFacilityReferral,
      referralUrgency: urgency,
    );
  }

  /// Evaluates syndromic clustering across hamlets to detect localized outbreaks (Requirement 21.2).
  List<OutbreakAlert> detectOutbreakClusters(
    List<SyndromicCase> cases, {
    int threshold = 3,
    int windowDays = 7,
  }) {
    final alerts = <OutbreakAlert>[];
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: windowDays));

    // Filter to cases within active window
    final recentCases = cases.where((c) => c.reportedAt.isAfter(cutoff)).toList();

    // Group by hamletId and syndrome
    final grouped = <String, List<SyndromicCase>>{};
    for (final c in recentCases) {
      final key = '${c.hamletId}::${c.syndrome.name}';
      grouped.putIfAbsent(key, () => []).add(c);
    }

    for (final entry in grouped.entries) {
      final clusterCases = entry.value;
      if (clusterCases.length >= threshold) {
        final hamletId = clusterCases.first.hamletId;
        final syndrome = clusterCases.first.syndrome;
        final isHigh = clusterCases.length >= (threshold * 2);

        final checklist = _generateSupervisorChecklist(syndrome);

        alerts.add(
          OutbreakAlert(
            alertId: 'alert_${hamletId}_${syndrome.name}_${now.millisecondsSinceEpoch}',
            hamletId: hamletId,
            syndrome: syndrome,
            caseCount: clusterCases.length,
            timeWindowDays: windowDays,
            alertLevel: isHigh ? 'OUTBREAK_CONFIRMED' : 'WARNING',
            supervisorResponseChecklist: checklist,
            syncPayload: {
              'hamlet_id': hamletId,
              'syndrome': syndrome.name,
              'case_count': clusterCases.length,
              'time_window_days': windowDays,
              'alert_level': isHigh ? 'OUTBREAK_CONFIRMED' : 'WARNING',
              'member_ids': clusterCases.map((c) => c.memberId).toList(),
              'detected_at': now.toIso8601String(),
              'target_recipients': ['ANM', 'AF', 'MO'],
            },
            triggeredAt: now,
          ),
        );
      }
    }

    return alerts;
  }

  List<String> _generateSupervisorChecklist(SyndromeType syndrome) {
    switch (syndrome) {
      case SyndromeType.acuteDiarrhoealDisease:
        return [
          'Superchlorinate all drinking water wells and overhead tanks in the hamlet.',
          'Distribute ORS packets and Zinc tablets to all households with children.',
          'Collect 3 stool/water samples for laboratory microbiological testing.',
          'Issue community advisory: boil drinking water and maintain hand hygiene.',
        ];
      case SyndromeType.feverWithRash:
        return [
          'Isolate affected children from anganwadi / school.',
          'Verify measles-rubella (MR) vaccination coverage in birth cohorts under 5.',
          'Organize urgent mop-up MR immunization drive with ANM within 48 hours.',
          'Provide Vitamin A supplement drops immediately to all suspect cases.',
        ];
      case SyndromeType.feverWithChills:
        return [
          'Conduct 100% active door-to-door fever search across hamlet.',
          'Perform Malaria RDT on all fever suspects; start immediate ACT/CQ for positive cases.',
          'Mobilize anti-larval measures and indoor residual spraying (IRS).',
          'Ensure distribution and usage of Long Lasting Insecticidal Nets (LLINs).',
        ];
      case SyndromeType.acuteFlaccidParalysis:
        return [
          'Notify District Surveillance Officer (DSO) immediately within 24 hours.',
          'Collect 2 stool specimens 24-48 hours apart within 14 days of paralysis onset.',
          'Maintain reverse cold chain for stool specimen transportation to designated lab.',
        ];
      default:
        return [
          'Notify ANM and Medical Officer In-Charge immediately.',
          'Initiate active daily symptom tracking across affected hamlet.',
          'Prepare emergency medication and hydration supplies at Sub-Centre.',
        ];
    }
  }

  /// Emergency First Aid and Immediate Referral protocol for Bites and Poisoning (Requirement 21.6).
  EmergencyBitePoisoningProtocol getEmergencyProtocol(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'snake_bite':
        return const EmergencyBitePoisoningProtocol(
          eventType: 'snake_bite',
          title: 'Suspected Snake Bite First Aid Protocol',
          mandatoryFirstAidSteps: [
            'Keep victim calm and completely still; reassure that most snake bites are non-fatal.',
            'Immobilize the bitten limb using a splint or bandage (like a fractured bone) at or below heart level.',
            'Remove rings, bangles, tight clothing, and footwear before swelling occurs.',
            'Arrange immediate 108 ambulance transport to nearest facility stocked with Anti-Snake Venom (ASV).',
          ],
          strictlyForbiddenActions: [
            'DO NOT apply a tight arterial tourniquet (causes tissue necrosis and gangrene).',
            'DO NOT cut, incise, or suck the bite wound.',
            'DO NOT apply ice packs, potassium permanganate, electric shocks, or herbal pastes.',
            'DO NOT waste time visiting traditional faith healers; every minute counts for ASV administration.',
          ],
          referralDestination: 'Sub-District Hospital / CHC with ASV & ventilator support',
          helplineNumber: '108',
        );

      case 'rabid_dog_bite':
        return const EmergencyBitePoisoningProtocol(
          eventType: 'rabid_dog_bite',
          title: 'Animal / Dog Bite Rabies Prevention Protocol',
          mandatoryFirstAidSteps: [
            'Immediately wash wound vigorously under running tap water with soap for at least 15 minutes.',
            'Apply povidone-iodine or alcohol-based antiseptic to destroy the rabies virus envelope.',
            'Refer immediately to PHC/CHC for Anti-Rabies Vaccine (ARV) and Rabies Immunoglobulin (RIG).',
          ],
          strictlyForbiddenActions: [
            'DO NOT suture or stitch the bite wound immediately.',
            'DO NOT apply chili powder, lime, cow dung, mustard oil, or plant juice to the wound.',
            'DO NOT delay post-exposure prophylaxis (PEP); clinical rabies is 100% fatal once symptoms appear.',
          ],
          referralDestination: 'Primary Health Centre (PHC) / CHC Anti-Rabies Clinic',
          helplineNumber: '108 / 104',
        );

      case 'poisoning':
      default:
        return const EmergencyBitePoisoningProtocol(
          eventType: 'poisoning',
          title: 'Suspected Pesticide / Chemical Poisoning Protocol',
          mandatoryFirstAidSteps: [
            'Remove patient from exposure source into fresh air.',
            'Strip contaminated clothing and wash skin with copious water and soap.',
            'Maintain open airway in recovery position (on side) to prevent aspiration if vomiting.',
            'Save pesticide container, label, or sample for doctor identification and specific antidote selection.',
            'Call 108 ambulance for urgent resuscitation and Atropine/Pralidoxime administration.',
          ],
          strictlyForbiddenActions: [
            'DO NOT induce vomiting if patient is unconscious, drowsy, or ingested petroleum/corrosive substance.',
            'DO NOT give milk, ghee, raw eggs, or salt water orally.',
          ],
          referralDestination: 'Community Health Centre (CHC) / District Hospital ICU',
          helplineNumber: '108',
        );
    }
  }

  /// Formats minimum surveillance data fields for IDSP Form S reporting (Requirement 21.3).
  Map<String, dynamic> formatIdspWeeklySForm({
    required String reportingWeek,
    required String hamletName,
    required String ashaWorkerId,
    required List<SyndromicCase> cases,
  }) {
    final counts = <String, int>{};
    for (final c in cases) {
      counts[c.syndrome.name] = (counts[c.syndrome.name] ?? 0) + 1;
    }

    return {
      'reporting_format': 'IDSP_FORM_S',
      'reporting_week': reportingWeek,
      'hamlet_name': hamletName,
      'asha_worker_id': ashaWorkerId,
      'syndrome_tallies': counts,
      'total_cases': cases.length,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}
