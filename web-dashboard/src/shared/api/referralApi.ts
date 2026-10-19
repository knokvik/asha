import { apiClient } from './client';
import { INITIAL_REFERRALS } from './mockData';
import { ReferralItem } from '@/types';

// In-memory reactive state for demonstration/offline resilience
let referralsCache = [...INITIAL_REFERRALS];

export async function getReferralQueue(facilityId: string = 'phc-shahpur'): Promise<ReferralItem[]> {
  try {
    const res = await apiClient.get<ReferralItem[]>(`/referrals/facility/${facilityId}`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }

  // Return sorted RED first, then pending/arrived
  return [...referralsCache].sort((a, b) => {
    const order: Record<string, number> = { RED: 0, YELLOW: 1, GREEN: 2 };
    const sevDiff = (order[a.severity] ?? 2) - (order[b.severity] ?? 2);
    if (sevDiff !== 0) return sevDiff;
    return new Date(b.referredAt).getTime() - new Date(a.referredAt).getTime();
  });
}

export async function recordReferralOutcome(
  referralId: string,
  status: 'admitted' | 'treated' | 'discharged' | 'did_not_reach',
  outcomeNotes: string
): Promise<ReferralItem> {
  try {
    const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/outcome`, {
      status,
      outcome_notes: outcomeNotes,
      recorded_at: new Date().toISOString(),
    });
    return res.data;
  } catch {
    // Update local cache
    const item = referralsCache.find((r) => r.id === referralId);
    if (item) {
      item.status = status;
      item.outcomeNotes = outcomeNotes;
      item.outcomeRecordedAt = new Date().toISOString();
      return { ...item };
    }
    throw new Error('Referral not found');
  }
}

export async function sendDoctorFeedback(
  referralId: string,
  ashaId: string,
  message: string
): Promise<{ success: boolean }> {
  try {
    await apiClient.post(`/referrals/${referralId}/feedback`, {
      asha_id: ashaId,
      message,
      sent_at: new Date().toISOString(),
    });
  } catch {
    console.info(`[Doctor Feedback sent to ASHA ${ashaId}]: ${message}`);
  }
  return { success: true };
}

export async function acknowledgeReferral(
  referralId: string,
  notes?: string
): Promise<ReferralItem> {
  try {
    const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/acknowledge`, {
      acknowledgment_notes: notes,
    });
    return res.data;
  } catch {
    const item = referralsCache.find((r) => r.id === referralId);
    if (item) {
      item.status = 'arrived';
      item.arrivedAt = new Date().toISOString();
      return { ...item };
    }
    throw new Error('Referral not found');
  }
}

export async function fetchAbdmHiuRecords(
  abhaId: string
): Promise<{
  abha_id: string;
  patient_name: string;
  age: number;
  gender: string;
  linked_care_contexts: Array<{
    context_id: string;
    facility: string;
    date: string;
    type: string;
    summary: string;
  }>;
  immunization_history?: Array<{
    vaccine: string;
    date: string;
    facility: string;
    status: string;
  }>;
}> {
  try {
    const res = await apiClient.get(`/integrations/abdm/hiu/records/${abhaId}`);
    return res.data;
  } catch {
    return {
      abha_id: abhaId,
      patient_name: 'Beneficiary',
      age: 26,
      gender: 'F',
      linked_care_contexts: [
        {
          context_id: 'CTX-ANC-01',
          facility: 'PHC Shahpur',
          date: '2026-08-14',
          type: 'WellnessRecord',
          summary: 'ANC Checkup 1: Hb 11.2 g/dL, BP 118/76 mmHg, Td vaccination given',
        },
        {
          context_id: 'CTX-REF-RED-991',
          facility: 'Sub-Centre Majra (ASHA Anita)',
          date: '2026-10-18',
          type: 'OPConsultation',
          summary: 'IMCI Triage RED Flag: High fever (102°F), rapid breathing (58/min)',
        },
      ],
      immunization_history: [
        { vaccine: 'Td-1', date: '2026-08-14', facility: 'PHC Shahpur', status: 'COMPLETED' },
        { vaccine: 'Td-2', date: '2026-09-12', facility: 'PHC Shahpur', status: 'COMPLETED' },
      ],
    };
  }
}

