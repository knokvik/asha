import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/safety_and_compliance/ai_safety_service.dart';
import 'package:asha_platform/core/safety_and_compliance/dpdp_compliance_service.dart';
import 'package:asha_platform/core/safety_and_compliance/worker_privacy_service.dart';

void main() {
  late AiSafetyService aiSafetyService;
  late DpdpComplianceService dpdpService;
  late WorkerPrivacyService workerPrivacyService;

  setUp(() {
    aiSafetyService = AiSafetyService();
    dpdpService = DpdpComplianceService();
    workerPrivacyService = WorkerPrivacyService();
  });

  group('Task 15.4: AI Safety & Human Oversight (Requirement 46)', () {
    test('46.1, 46.8: CDSS suggestions labelled decision support with contributing observations', () {
      final wrapped = aiSafetyService.wrapCdssSuggestion(
        ruleId: 'rule_imnci_pneumonia',
        suggestedSeverity: TriageSeverity.yellow,
        rationale: 'Fast breathing (54 breaths/min in 11-month infant)',
        userEnteredObservations: ['Age: 11m', 'RespRate: 54/min', 'Chest indrawing: No'],
      );

      expect(wrapped.isDecisionSupport, isTrue);
      expect(wrapped.safetyDisclaimer, contains('Decision Support Only'));
      expect(wrapped.contributingObservations.length, 3);
      expect(wrapped.suggestedSeverity, TriageSeverity.yellow);
    });

    test('46.2: Reconsideration check triggered when system suggestion is lower than ASHA suspicion', () {
      // System suggests YELLOW, ASHA suspects RED
      final prompt = aiSafetyService.checkReconsiderationPrompt(
        systemSuggested: TriageSeverity.yellow,
        ashaSuspicion: TriageSeverity.red,
        patientCategory: 'child',
      );

      expect(prompt, isNotNull);
      expect(prompt, contains('Does the child look lethargic'));
      expect(prompt, contains('escalate to Emergency / Immediate Transfer'));

      // If ASHA agrees or de-escalates, no reconsideration prompt
      final noPrompt = aiSafetyService.checkReconsiderationPrompt(
        systemSuggested: TriageSeverity.yellow,
        ashaSuspicion: TriageSeverity.yellow,
      );
      expect(noPrompt, isNull);
    });

    test('46.7: Records structured override feedback with escalation/de-escalation metrics', () {
      final override = aiSafetyService.recordOverride(
        ruleId: 'rule_imnci_diarrhea',
        systemSuggestedSeverity: TriageSeverity.yellow,
        ashaConfirmedSeverity: TriageSeverity.red,
        overrideReasonCategory: 'maternal_reported_worsening',
        userFeedbackNotes: 'Mother reports infant has had zero urine output for 8 hours and sunken eyes.',
        languageCode: 'hi',
        ashaWorkerId: 'worker_sunita',
      );

      expect(override.isEscalation, isTrue);
      expect(override.isDeescalation, isFalse);
      expect(override.overrideReasonCategory, 'maternal_reported_worsening');
      expect(override.userFeedbackNotes, contains('zero urine output'));
    });

    test('46.5: Poor-performing component disable capability restricts component', () {
      expect(aiSafetyService.isComponentEnabled('voice_asr_hi'), isTrue);

      aiSafetyService.disableComponent('voice_asr_hi', reason: 'High dialect error rate in Bundelkhand');
      expect(aiSafetyService.isComponentEnabled('voice_asr_hi'), isFalse);
    });

    test('46.4: Safety incident workflow records structured investigation fields', () {
      final incident = aiSafetyService.createIncidentReport(
        reporterId: 'worker_sunita',
        reporterRole: 'ASHA',
        description: 'Triage suggestion misclassified severe dehydration as mild due to sensor glitch',
        contributingFactors: ['Bluetooth pulse oximeter intermittent disconnection'],
        immediateOutcome: 'ASHA recognized danger sign clinically and escorted patient to CHC',
        proposedCorrectiveAction: 'Enforce manual confirmation of vitals before triage run',
        followUpReviewDate: DateTime.now().add(const Duration(days: 7)),
        severity: 'CRITICAL_NEAR_MISS',
      );

      expect(incident.severity, 'CRITICAL_NEAR_MISS');
      expect(incident.contributingFactors.first, contains('Bluetooth'));
      expect(incident.reporterRole, 'ASHA');
    });
  });

  group('Task 15.4: DPDP Compliance & Patient Privacy (Requirement 44)', () {
    test('44.2: Purpose limitation metadata generated on record writes', () {
      final ancMeta = dpdpService.generatePurposeMetadata(programCategory: 'anc_pnc');
      expect(ancMeta.statedPurpose, 'MOHFW_MATERNAL_CHILD_HEALTHCARE');
      expect(ancMeta.retentionYears, 7);
      expect(ancMeta.legalBasis, contains('DPDP Act 2023'));

      final tbMeta = dpdpService.generatePurposeMetadata(programCategory: 'tb');
      expect(tbMeta.retentionYears, 10);
    });

    test('44.3: Tracked SAR request workflow from submission to fulfillment', () {
      final request = dpdpService.submitSarRequest(
        beneficiaryId: 'ben_pooja_001',
        requestType: SarRequestType.dataAccess,
        details: 'Beneficiary requested digital copy of complete ANC vaccination records',
      );

      expect(request.status, SarRequestStatus.submitted);

      final fulfilled = dpdpService.fulfillSarRequest(
        request.requestId,
        resolutionNotes: 'Generated FHIR DiagnosticReport bundle and transmitted via ABDM PHR app',
      );

      expect(fulfilled.status, SarRequestStatus.fulfilled);
      expect(fulfilled.fulfilledAt, isNotNull);
    });

    test('44.4: Data breach logging triggers CERT-In statutory notice workflow', () {
      final breach = dpdpService.logBreachIncident(
        anomalyType: 'UNAUTHORIZED_DEVICE_EXPORT',
        affectedRecordsCount: 12,
        immediateMitigationTaken: 'Revoked session JWT tokens and blocked device hardware ID',
      );

      expect(breach.notifiedCertIn, isTrue);
      expect(breach.affectedRecordsCount, 12);
    });

    test('44.6: Logs every access and detects anomalous query spikes', () {
      for (int i = 0; i < 55; i++) {
        dpdpService.logDataAccess(
          userId: 'user_malicious',
          userRole: 'surveyor',
          patientId: 'patient_$i',
          category: 'demographics',
          purpose: 'bulk_export_attempt',
        );
      }

      expect(dpdpService.isAccessAnomalous(userId: 'user_malicious'), isTrue);
      expect(dpdpService.isAccessAnomalous(userId: 'user_innocent'), isFalse);
    });

    test('44.9: Masking stigmatised conditions (TB, HIV, FP, MH) in shared views', () {
      final confidentialRecord = {
        'patient_name': 'Meena',
        'tb_status': 'Active Pulmonary TB (Smear 2+)',
        'hiv_status': 'Positive (on ART)',
        'mental_health_score': 'Severe Depression (PHQ-4: 11)',
        'contraceptive_method': 'Centchroman (Chhaya)',
      };

      final masked = dpdpService.maskStigmatisedConditions(
        record: confidentialRecord,
        viewerRole: 'village_volunteer',
      );

      expect(masked['tb_status'], 'Respiratory Care Follow-up');
      expect(masked['hiv_status'], 'Specialized Wellness Protocol');
      expect(masked['mental_health_score'], 'General Counselling');
      expect(masked['contraceptive_method'], 'Reproductive Health Protocol');
    });
  });

  group('Task 15.4: Worker Privacy, Anti-Surveillance & Device Integrity (Requirements 44.8, 45, 48.4)', () {
    test('45.1: Install notice explicitly declares no 24/7 GPS surveillance or geofencing', () {
      final notice = workerPrivacyService.getInstallNotice();
      expect(notice.prohibitedUses.any((u) => u.contains('NO 24/7 background GPS tracking')), isTrue);
      expect(notice.prohibitedUses.any((u) => u.contains('NO geofencing attendance')), isTrue);
      expect(notice.audioPromptAssetKey, 'audio_worker_privacy_notice_hi');
    });

    test('45.2: Rejects background GPS logging and unconsented location access', () {
      // Background request -> strictly rejected
      expect(
        workerPrivacyService.canAccessLocation(
          hasUserOptedInForFeature: true,
          isFeatureActivelyInForeground: true,
          isBackgroundLoggingRequested: true,
        ),
        isFalse,
      );

      // Foreground with opt-in -> allowed
      expect(
        workerPrivacyService.canAccessLocation(
          hasUserOptedInForFeature: true,
          isFeatureActivelyInForeground: true,
          isBackgroundLoggingRequested: false,
        ),
        isTrue,
      );
    });

    test('45.4: Worker grievance submission and resolution tracking', () {
      final grievance = workerPrivacyService.submitGrievance(
        ashaWorkerId: 'worker_sunita',
        category: 'INCENTIVE_PAYMENT',
        description: 'July 2026 JSY delivery incentive (₹600) unpaid despite institutional voucher',
      );

      expect(grievance.status, 'OPEN');
      expect(grievance.assignedOwner, contains('BPMU'));

      final resolved = workerPrivacyService.resolveGrievance(
        grievance.grievanceId,
        resolution: 'Voucher re-verified by MO. Disbursed via PFMS transaction #TX99823',
      );

      expect(resolved.status, 'RESOLVED');
      expect(resolved.resolutionOutcome, contains('PFMS transaction'));
    });

    test('44.8: Rooted device check restricts sensitive data access and displays hotline', () {
      final isCompromised = workerPrivacyService.isDeviceIntegrityCompromised(
        detectedRootBinaries: ['/system/bin/su', '/system/xbin/daemonsu'],
      );
      expect(isCompromised, isTrue);

      final warning = workerPrivacyService.getRootedDeviceWarning();
      expect(warning, contains('SECURITY ALERT: Device system integrity is modified'));
      expect(warning, contains('1800-180-1104'));
    });

    test('48.4, 44.2: Crash stack trace sanitizer strips phone numbers, ABHA IDs, and patient names', () {
      const rawCrashLog = '''
Exception: Null pointer dereference
At: EncounterProcessor.save()
Context: patientName: Anita Sharma, phone: +91 9876543210, abha: 12-3456-7890-1234
Stack: at lib/features/triage/triage_engine.dart:140
''';

      final sanitized = workerPrivacyService.sanitizeCrashStackTrace(rawCrashLog);

      expect(sanitized, isNot(contains('+91 9876543210')));
      expect(sanitized, isNot(contains('12-3456-7890-1234')));
      expect(sanitized, isNot(contains('Anita Sharma')));
      expect(sanitized, contains('[REDACTED_PHONE]'));
      expect(sanitized, contains('[REDACTED_ABHA]'));
      expect(sanitized, contains('[REDACTED_NAME]'));
    });
  });
}
