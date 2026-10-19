import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'register_models.dart';

/// Service managing built-in and OTA-updated Government Register templates (Requirement 34.1, 34.3).
class TemplateManager {
  static final TemplateManager _instance = TemplateManager._internal();
  factory TemplateManager() => _instance;
  TemplateManager._internal() {
    _initializeDefaultTemplates();
  }

  final Map<RegisterType, RegisterTemplateConfig> _activeTemplates = {};

  /// Returns the currently active template config for a given [RegisterType].
  RegisterTemplateConfig getTemplate(RegisterType type) {
    return _activeTemplates[type] ?? _buildDefaultTemplate(type);
  }

  /// Applies a server-delivered OTA template configuration without APK update (Requirement 34.3).
  void applyOtaTemplateUpdate(RegisterTemplateConfig newConfig) {
    final existing = _activeTemplates[newConfig.type];
    if (existing == null || newConfig.version > existing.version) {
      _activeTemplates[newConfig.type] = newConfig;
      debugPrint(
        'TemplateManager: Applied OTA update for ${newConfig.type.displayName} (v${newConfig.version})',
      );
    }
  }

  /// Ingests an OTA update from a raw JSON string or payload received via background sync.
  bool ingestOtaJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = RegisterTemplateConfig.fromJson(map);
      applyOtaTemplateUpdate(config);
      return true;
    } catch (e) {
      debugPrint('TemplateManager: Failed to parse OTA template config JSON: $e');
      return false;
    }
  }

  /// Resets all register templates to standard National Health Mission defaults.
  void resetToDefaults() {
    _initializeDefaultTemplates();
  }

  // ── Default Official Register Layouts (National Health Mission) ─────────────

  void _initializeDefaultTemplates() {
    for (final type in RegisterType.values) {
      _activeTemplates[type] = _buildDefaultTemplate(type);
    }
  }

  RegisterTemplateConfig _buildDefaultTemplate(RegisterType type) {
    final now = DateTime(2026, 1, 1);
    switch (type) {
      case RegisterType.villageSurvey:
        return RegisterTemplateConfig(
          id: 'tpl_village_survey_v1',
          type: RegisterType.villageSurvey,
          version: 1,
          title: 'VILLAGE SURVEY & ENUMERATION REGISTER',
          subtitle: 'National Health Mission • Comprehensive Village Mapping Format',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'hh_head', header: 'Head of Family', flex: 2.0),
            RegisterColumnDef(key: 'hamlet', header: 'Hamlet / Tola', flex: 1.5),
            RegisterColumnDef(key: 'family_size', header: 'Members', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'eligible_couples', header: 'Elig. Couples', flex: 1.0, alignment: 'center'),
            RegisterColumnDef(key: 'pregnant_count', header: 'PW', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'child_under_1', header: 'Child <1y', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'child_1_to_5', header: 'Child 1-5y', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'sanitation', header: 'Toilet / Water', flex: 1.2),
          ],
        );

      case RegisterType.rch:
        return RegisterTemplateConfig(
          id: 'tpl_rch_v1',
          type: RegisterType.rch,
          version: 1,
          title: 'REPRODUCTIVE AND CHILD HEALTH (RCH) REGISTER',
          subtitle: 'Maternal Care Tracking & Institutional Delivery Enrolment',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'rch_id', header: 'RCH ID', flex: 1.4),
            RegisterColumnDef(key: 'woman_name', header: "Woman's Name", flex: 2.0),
            RegisterColumnDef(key: 'age_gravida', header: 'Age / G-P', flex: 1.0, alignment: 'center'),
            RegisterColumnDef(key: 'lmp_date', header: 'LMP Date', flex: 1.2, alignment: 'center'),
            RegisterColumnDef(key: 'edd_date', header: 'EDD Date', flex: 1.2, alignment: 'center'),
            RegisterColumnDef(key: 'anc_visits', header: 'ANC Visits (1-4)', flex: 1.5),
            RegisterColumnDef(key: 'tt_doses', header: 'Td Doses', flex: 1.0),
            RegisterColumnDef(key: 'ifa_given', header: 'IFA Tabs', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'hrp_status', header: 'HRP Flag', flex: 1.0, alignment: 'center'),
          ],
        );

      case RegisterType.hbnc:
        return RegisterTemplateConfig(
          id: 'tpl_hbnc_v1',
          type: RegisterType.hbnc,
          version: 1,
          title: 'HOME BASED NEWBORN CARE (HBNC) REGISTER',
          subtitle: 'Scheduled Home Visits (Day 1, 3, 7, 14, 21, 28, 42) & Danger Sign Monitoring',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'baby_details', header: 'Newborn / Mother', flex: 2.2),
            RegisterColumnDef(key: 'dob_weight', header: 'DOB / Wt (kg)', flex: 1.4),
            RegisterColumnDef(key: 'visits_done', header: 'HBNC Visits (D1-42)', flex: 2.4),
            RegisterColumnDef(key: 'breastfeeding', header: 'Excl. BF', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'danger_signs', header: 'Danger Signs', flex: 1.6),
            RegisterColumnDef(key: 'current_status', header: 'Outcome', flex: 1.0, alignment: 'center'),
          ],
        );

      case RegisterType.hbyc:
        return RegisterTemplateConfig(
          id: 'tpl_hbyc_v1',
          type: RegisterType.hbyc,
          version: 1,
          title: 'HOME BASED YOUNG CHILD CARE (HBYC) REGISTER',
          subtitle: 'Quarterly Home Visits (Month 3 to 24) • Growth, Nutrition, and Development',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'child_name', header: 'Child & Mother', flex: 2.2),
            RegisterColumnDef(key: 'dob_age', header: 'DOB / Age', flex: 1.2),
            RegisterColumnDef(key: 'quarterly_visits', header: 'Visits (3m-24m)', flex: 2.2),
            RegisterColumnDef(key: 'ors_zinc', header: 'ORS & Zinc', flex: 1.0),
            RegisterColumnDef(key: 'ifa_syrup', header: 'IFA Syrup', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'growth_muac', header: 'MUAC / Growth', flex: 1.2),
          ],
        );

      case RegisterType.pnc:
        return RegisterTemplateConfig(
          id: 'tpl_pnc_v1',
          type: RegisterType.pnc,
          version: 1,
          title: 'POSTNATAL CARE (PNC) REGISTER',
          subtitle: 'Maternal Postpartum Health & Postpartum Family Planning (PPFP)',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'mother_name', header: "Mother's Name", flex: 2.0),
            RegisterColumnDef(key: 'delivery_date', header: 'Delivery Date', flex: 1.2, alignment: 'center'),
            RegisterColumnDef(key: 'place_of_delivery', header: 'Delivery Place', flex: 1.6),
            RegisterColumnDef(key: 'mother_vitals', header: 'Vitals / BP', flex: 1.4),
            RegisterColumnDef(key: 'lochia_check', header: 'Lochia / Sepsis', flex: 1.4),
            RegisterColumnDef(key: 'ppfp_choice', header: 'PPFP Choice', flex: 1.4),
          ],
        );

      case RegisterType.highRiskPregnancy:
        return RegisterTemplateConfig(
          id: 'tpl_hrp_v1',
          type: RegisterType.highRiskPregnancy,
          version: 1,
          title: 'HIGH-RISK PREGNANCY (HRP) REGISTER',
          subtitle: 'Intensive Tracking, Specialised Medical Consultation & Institutional Delivery Planning',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'woman_name', header: 'Woman / Husband', flex: 2.0),
            RegisterColumnDef(key: 'edd_date', header: 'EDD', flex: 1.0, alignment: 'center'),
            RegisterColumnDef(key: 'risk_conditions', header: 'High-Risk Condition(s)', flex: 2.5),
            RegisterColumnDef(key: 'hb_level', header: 'Hb / BP', flex: 1.0),
            RegisterColumnDef(key: 'facility_planned', header: 'Planned FRU/DH', flex: 1.5),
            RegisterColumnDef(key: 'action_status', header: 'Transport & Escort Plan', flex: 1.6),
          ],
        );

      case RegisterType.cbac:
        return RegisterTemplateConfig(
          id: 'tpl_cbac_v1',
          type: RegisterType.cbac,
          version: 1,
          title: 'COMMUNITY BASED ASSESSMENT CHECKLIST (CBAC) REGISTER',
          subtitle: 'Ayushman Bharat HWC • Non-Communicable Diseases (NCD) & Common Cancers Screening',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'individual_name', header: 'Beneficiary Name', flex: 2.0),
            RegisterColumnDef(key: 'age_gender', header: 'Age / Sex', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'cbac_score', header: 'CBAC ( /10)', flex: 0.9, alignment: 'center'),
            RegisterColumnDef(key: 'risk_flag', header: 'Risk Tier', flex: 1.0, alignment: 'center'),
            RegisterColumnDef(key: 'symptoms_check', header: 'Symptoms (HTN/DM/Oral)', flex: 2.2),
            RegisterColumnDef(key: 'hwc_screening', header: 'HWC Screening Status', flex: 1.5),
          ],
        );

      case RegisterType.tbTreatment:
        return RegisterTemplateConfig(
          id: 'tpl_tb_treatment_v1',
          type: RegisterType.tbTreatment,
          version: 1,
          title: 'TB PRESUMPTIVE & TREATMENT REGISTER (NI-KSHAY)',
          subtitle: 'National Tuberculosis Elimination Programme (NTEP) • Presumptive Tracking & DOTS Adherence',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'nikshay_id', header: 'Ni-kshay ID', flex: 1.2),
            RegisterColumnDef(key: 'patient_name', header: 'Patient Name', flex: 2.0),
            RegisterColumnDef(key: 'presumptive_date', header: 'Symptom Date', flex: 1.2, alignment: 'center'),
            RegisterColumnDef(key: 'diagnostic_status', header: 'Sputum / CBNAAT Result', flex: 1.8),
            RegisterColumnDef(key: 'regimen', header: 'DOTS Regimen', flex: 1.2),
            RegisterColumnDef(key: 'treatment_adherence', header: 'Dose Adherence', flex: 1.2),
          ],
        );

      case RegisterType.immunization:
        return RegisterTemplateConfig(
          id: 'tpl_immunization_v1',
          type: RegisterType.immunization,
          version: 1,
          title: 'UNIVERSAL IMMUNIZATION PROGRAMME (UIP) REGISTER',
          subtitle: 'National Immunization Schedule • Birth to 24 Months Tracking',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'sl_no', header: 'Sl No', flex: 0.6, alignment: 'center'),
            RegisterColumnDef(key: 'child_name', header: 'Child & Mother', flex: 2.2),
            RegisterColumnDef(key: 'dob', header: 'DOB', flex: 1.1, alignment: 'center'),
            RegisterColumnDef(key: 'birth_doses', header: 'Birth (BCG, OPV0, HepB)', flex: 1.8),
            RegisterColumnDef(key: 'six_weeks', header: '6W (P1, OPV1, RV1, IPV1)', flex: 1.8),
            RegisterColumnDef(key: 'ten_weeks', header: '10W (P2, OPV2, RV2)', flex: 1.5),
            RegisterColumnDef(key: 'fourteen_weeks', header: '14W (P3, OPV3, RV3, IPV2)', flex: 1.8),
            RegisterColumnDef(key: 'nine_months', header: '9M (MR1, JE1, PCV-B)', flex: 1.6),
            RegisterColumnDef(key: 'full_status', header: 'FIC Status', flex: 0.9, alignment: 'center'),
          ],
        );

      case RegisterType.monthlyReport:
        return RegisterTemplateConfig(
          id: 'tpl_monthly_report_v1',
          type: RegisterType.monthlyReport,
          version: 1,
          title: 'MONTHLY ASHA PROGRESS REPORT (MPR)',
          subtitle: 'National Health Mission • Comprehensive Monthly Field Summary',
          stateCode: 'ALL',
          effectiveDate: now,
          columns: const [
            RegisterColumnDef(key: 'indicator_code', header: 'Code', flex: 0.8, alignment: 'center'),
            RegisterColumnDef(key: 'indicator_name', header: 'Performance Indicator', flex: 4.0),
            RegisterColumnDef(key: 'target_value', header: 'Target / Due', flex: 1.2, alignment: 'center'),
            RegisterColumnDef(key: 'achieved_value', header: 'Achieved This Month', flex: 1.5, alignment: 'center'),
            RegisterColumnDef(key: 'cumulative_year', header: 'Cumulative (FY)', flex: 1.2, alignment: 'center'),
          ],
        );
    }
  }
}
