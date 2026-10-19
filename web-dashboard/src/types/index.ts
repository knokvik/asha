export type UserRole = 
  | 'AF'               // ASHA Facilitator
  | 'ANM'              // Auxiliary Nurse Midwife / CHO
  | 'PHC_MO'           // Primary Health Centre Medical Officer
  | 'DISTRICT_OFFICER' // Block / District Health Officer
  | 'STATE_ADMIN';     // State / Platform Administrator

export interface AuthUser {
  id: string;
  name: string;
  role: UserRole;
  phone?: string;
  stateCode: string;
  districtCode?: string;
  blockCode?: string;
  phcId?: string;
  subcentreId?: string;
  token?: string;
}

export type TriageSeverity = 'RED' | 'YELLOW' | 'GREEN';

export interface ReferralItem {
  id: string;
  patientId: string;
  patientName: string;
  patientAge: number;
  patientGender: 'M' | 'F' | 'O';
  village: string;
  abhaId?: string;
  isSmsRelayed?: boolean;
  ashaId: string;
  ashaName: string;
  ashaPhone: string;
  subcentreId: string;
  facilityId: string;
  severity: TriageSeverity;
  reason: string;
  clinicalNote: string;
  vitals?: {
    bpSystolic?: number;
    bpDiastolic?: number;
    pulse?: number;
    spo2?: number;
    temp?: number;
    respRate?: number;
    hemoglobin?: number;
    bloodGlucose?: number;
  };
  redFlags: string[];
  screenedDangerSigns?: {
    sign: string;
    present: boolean;
  }[];
  referredAt: string; // ISO timestamp
  arrivedAt?: string;
  status: 'pending' | 'arrived' | 'admitted' | 'treated' | 'discharged' | 'did_not_reach';
  outcomeNotes?: string;
  outcomeRecordedAt?: string;
  /** Child IMCI fields from the phone pack. Absent on older maternal referrals. */
  wardId?: string;
  ageMonths?: number;
  sms?: string;
  firedRules?: { ruleId: string; reason: string; guidelineRef: string }[];
  outbreakContext?: string;
  followUpDays?: number | null;
  urgency?: string;
  facilityName?: string;
  preReferral?: string[];
  suspected?: string;
  tempC?: number;
  diagnosis?: string;
  outcomeAction?: 'treated' | 'referred_up' | 'sent_home';
  noteForAsha?: string;
}

export interface AshaPerformanceCard {
  ashaId: string;
  ashaName: string;
  phone: string;
  village: string;
  hamletsCount: number;
  lastSyncAt: string;
  coveragePct: number;
  overdueVisitsCount: number;
  pendingReferralsCount: number;
  recentRedFlagsCount: number;
  dataQualityScorePct: number; // 0 - 100
  learningModulesCompleted: number;
  totalAssignedHouseholds: number;
  mentoringFlags: {
    type: 'warning' | 'info' | 'positive';
    message: string;
    suggestedModule?: string;
  }[];
}

export interface SupervisionChecklist {
  id?: string;
  afId: string;
  ashaId: string;
  visitDate: string;
  visitType: 'household_visit' | 'vhsnd_session' | 'record_audit' | 'kit_inspection';
  score: number;
  notes: string;
  recommendations: string;
  followUpRequired: boolean;
  followUpDate?: string;
}

export interface IncentiveClaimLineItem {
  id: string;
  claimId: string;
  ashaId: string;
  ashaName: string;
  activityCode: string;
  activityDescription: string;
  memberCodedId: string;
  serviceDate: string;
  amount: number;
  evidenceRefId: string;
  status: 'submitted' | 'approved' | 'rejected' | 'correction_requested';
  rejectionReason?: string;
}

export interface DistrictIndicator {
  code: string;
  name: string;
  category: 'maternal' | 'child' | 'ncd' | 'tb' | 'supply';
  currentValue: number;
  targetValue: number;
  previousValue: number;
  unit: string;
  trend: 'up' | 'down' | 'stable';
  isPositive: boolean;
}

export interface OutbreakAlert {
  id: string;
  disease: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
  affectedVillage: string;
  block: string;
  caseCount: number;
  timeframeDays: number;
  flaggedAt: string;
  status: 'active' | 'investigating' | 'contained';
}

export interface SupplyForecast {
  itemCode: string;
  itemName: string;
  currentStock: number;
  dailyConsumptionRate: number;
  estimatedDaysRemaining: number;
  reorderLevel: number;
  status: 'adequate' | 'warning' | 'critical_stockout';
}
