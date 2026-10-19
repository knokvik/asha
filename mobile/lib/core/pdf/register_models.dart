
/// Types of official Government Health Registers and Formats (Requirement 34.1).
enum RegisterType {
  villageSurvey('village_survey', 'Village Survey Register', 'A-1'),
  rch('rch', 'Reproductive & Child Health (RCH) Register', 'RCH-1'),
  hbnc('hbnc', 'Home Based Newborn Care (HBNC) Register', 'HBNC-1'),
  hbyc('hbyc', 'Home Based Young Child Care (HBYC) Register', 'HBYC-1'),
  pnc('pnc', 'Postnatal Care (PNC) Register', 'PNC-1'),
  highRiskPregnancy('high_risk_pregnancy', 'High-Risk Pregnancy (HRP) Register', 'HRP-1'),
  cbac('cbac', 'Community Based Assessment Checklist (CBAC) Register', 'NCD-CBAC'),
  tbTreatment('tb_treatment', 'TB Presumptive & Treatment (Ni-kshay) Register', 'TB-1'),
  immunization('immunization', 'Universal Immunization Programme (UIP) Register', 'UIP-1'),
  monthlyReport('monthly_report', 'Monthly ASHA Progress Report (MPR)', 'NHM-MPR');

  final String code;
  final String displayName;
  final String formCode;

  const RegisterType(this.code, this.displayName, this.formCode);

  static RegisterType fromCode(String code) {
    return RegisterType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RegisterType.villageSurvey,
    );
  }
}

/// Column definition for dynamic, configurable register layouts (Requirements 34.1, 34.3).
class RegisterColumnDef {
  final String key;
  final String header;
  final double flex;
  final String alignment; // 'left', 'center', 'right'

  const RegisterColumnDef({
    required this.key,
    required this.header,
    this.flex = 1.0,
    this.alignment = 'left',
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'header': header,
        'flex': flex,
        'alignment': alignment,
      };

  factory RegisterColumnDef.fromJson(Map<String, dynamic> json) => RegisterColumnDef(
        key: json['key'] as String,
        header: json['header'] as String,
        flex: (json['flex'] as num?)?.toDouble() ?? 1.0,
        alignment: json['alignment'] as String? ?? 'left',
      );
}

/// OTA Server-delivered register template configuration (Requirement 34.3).
class RegisterTemplateConfig {
  final String id;
  final RegisterType type;
  final int version;
  final String title;
  final String subtitle;
  final String stateCode;
  final List<RegisterColumnDef> columns;
  final String footerDisclaimer;
  final DateTime effectiveDate;

  const RegisterTemplateConfig({
    required this.id,
    required this.type,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.stateCode,
    required this.columns,
    this.footerDisclaimer = 'Official Government Record • National Health Mission (Ayushman Bharat)',
    required this.effectiveDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.code,
        'version': version,
        'title': title,
        'subtitle': subtitle,
        'state_code': stateCode,
        'columns': columns.map((c) => c.toJson()).toList(),
        'footer_disclaimer': footerDisclaimer,
        'effective_date': effectiveDate.toIso8601String(),
      };

  factory RegisterTemplateConfig.fromJson(Map<String, dynamic> json) => RegisterTemplateConfig(
        id: json['id'] as String,
        type: RegisterType.fromCode(json['type'] as String),
        version: json['version'] as int? ?? 1,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        stateCode: json['state_code'] as String? ?? 'ALL',
        columns: (json['columns'] as List<dynamic>)
            .map((c) => RegisterColumnDef.fromJson(c as Map<String, dynamic>))
            .toList(),
        footerDisclaimer: json['footer_disclaimer'] as String? ??
            'Official Government Record • National Health Mission',
        effectiveDate: DateTime.parse(json['effective_date'] as String),
      );
}

/// Data payload for rendering an on-screen grid or generating print-ready PDF (Requirements 34.1, 34.4).
class RegisterPageData {
  final RegisterType type;
  final String stateName;
  final String districtName;
  final String blockName;
  final String phcName;
  final String subCentreName;
  final String villageName;
  final String ashaName;
  final String ashaId;
  final String reportingPeriod;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summaryTotals;

  const RegisterPageData({
    required this.type,
    this.stateName = 'State Health Mission',
    this.districtName = 'District Health Office',
    this.blockName = 'Block Health Unit',
    this.phcName = 'Primary Health Centre',
    this.subCentreName = 'Health & Wellness Centre',
    required this.villageName,
    required this.ashaName,
    required this.ashaId,
    required this.reportingPeriod,
    required this.rows,
    this.summaryTotals = const {},
  });
}

/// Card types for family-friendly health summaries (Requirement 34.5).
enum FamilyCardType {
  mcpCardUpdate('mcp_card', 'Mother & Child Protection (MCP) Update Card'),
  childVaccination('child_vaccination', 'Child Universal Immunization Card'),
  referralSlip('family_referral', 'Emergency Medical Referral Slip');

  final String code;
  final String title;
  const FamilyCardType(this.code, this.title);
}

/// Beneficiary-facing family friendly card data (Requirement 34.5).
class FamilyFriendlyCardData {
  final FamilyCardType cardType;
  final String beneficiaryName;
  final String? rchId;
  final String? abhaId;
  final String? dateOfBirth;
  final String? gender;
  final String? guardianName;
  final String? village;
  final String? contactPhone;
  final String languageCode;
  final Map<String, dynamic> clinicalSummary;
  final List<Map<String, String>> keyChecklist;
  final String? nextVisitDate;
  final String ashaContact;

  const FamilyFriendlyCardData({
    required this.cardType,
    required this.beneficiaryName,
    this.rchId,
    this.abhaId,
    this.dateOfBirth,
    this.gender,
    this.guardianName,
    this.village,
    this.contactPhone,
    this.languageCode = 'hi',
    required this.clinicalSummary,
    required this.keyChecklist,
    this.nextVisitDate,
    required this.ashaContact,
  });
}
