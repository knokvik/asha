import { apiClient } from './client';
import { INITIAL_REFERRALS } from './mockData';
import { ReferralItem } from '@/types';
import { validateOutcome, type OutcomeAction } from '@/features/clinical-desk/logic';

// In-memory reactive state for demonstration/offline resilience
let referralsCache: ReferralItem[] = INITIAL_REFERRALS.map((item) => ({ ...item }));
const confirmedByWard: Record<string, number> = {};

/** Skip the network when the demo flag is on. Unset still uses mocks so a down server cannot block the desk. */
export function mocksEnabled(): boolean {
  return import.meta.env.VITE_USE_MOCKS !== 'false';
}

function sortQueue(items: ReferralItem[]): ReferralItem[] {
  const order: Record<string, number> = { RED: 0, YELLOW: 1, GREEN: 2 };
  return [...items].sort((a, b) => {
    const sevDiff = (order[a.severity] ?? 2) - (order[b.severity] ?? 2);
    if (sevDiff !== 0) return sevDiff;
    return new Date(a.referredAt).getTime() - new Date(b.referredAt).getTime();
  });
}

export function resetReferralCache(): void {
  referralsCache = INITIAL_REFERRALS.map((item) => ({ ...item, firedRules: item.firedRules?.map((rule) => ({ ...rule })) }));
  for (const key of Object.keys(confirmedByWard)) delete confirmedByWard[key];
}

export function wardConfirmations(): Record<string, number> {
  return { ...confirmedByWard };
}

export async function getReferralQueue(facilityId: string = 'phc-shahpur'): Promise<ReferralItem[]> {
  if (!mocksEnabled()) {
    try {
      const res = await apiClient.get<ReferralItem[]>(`/referrals/facility/${facilityId}`);
      if (Array.isArray(res.data)) {
        return sortQueue(res.data);
      }
    } catch {
      // fallback
    }
  }

  return sortQueue(referralsCache);
}

export async function recordReferralOutcome(
  referralId: string,
  status: 'admitted' | 'treated' | 'discharged' | 'did_not_reach',
  outcomeNotes: string
): Promise<ReferralItem> {
  if (!mocksEnabled()) {
    try {
      const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/outcome`, {
        status,
        outcome_notes: outcomeNotes,
        recorded_at: new Date().toISOString(),
      });
      return res.data;
    } catch {
      // Update local cache below
    }
  }
  const item = referralsCache.find((r) => r.id === referralId);
  if (item) {
    item.status = status;
    item.outcomeNotes = outcomeNotes;
    item.outcomeRecordedAt = new Date().toISOString();
    return { ...item };
  }
  throw new Error('Referral not found');
}

export async function recordClinicalOutcome(
  referralId: string,
  input: { diagnosis: string; action: OutcomeAction; noteForAsha: string },
): Promise<ReferralItem> {
  const problem = validateOutcome(input);
  if (problem) throw new Error(problem);
  const status = input.action === 'treated' ? 'treated' : input.action === 'sent_home' ? 'discharged' : 'admitted';
  const updated = await recordReferralOutcome(
    referralId,
    status,
    `${input.diagnosis}\n${input.noteForAsha}`,
  );
  const cached = referralsCache.find((item) => item.id === referralId);
  if (cached) {
    cached.diagnosis = input.diagnosis;
    cached.outcomeAction = input.action;
    cached.noteForAsha = input.noteForAsha;
    if (cached.wardId) {
      confirmedByWard[cached.wardId] = (confirmedByWard[cached.wardId] ?? 0) + 1;
    }
  }
  return {
    ...updated,
    diagnosis: input.diagnosis,
    outcomeAction: input.action,
    noteForAsha: input.noteForAsha,
  };
}

export async function startConsult(referralId: string): Promise<ReferralItem> {
  if (!mocksEnabled()) {
    try {
      const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/consult`, {});
      return res.data;
    } catch {
      // local fallback
    }
  }
  const item = referralsCache.find((row) => row.id === referralId);
  if (!item) throw new Error('Referral not found');
  item.status = 'admitted';
  return { ...item };
}

export async function getReferralById(referralId: string): Promise<ReferralItem> {
  const queue = await getReferralQueue();
  const found = queue.find((item) => item.id === referralId);
  if (!found) throw new Error('Referral not found');
  return found;
}

export async function sendDoctorFeedback(
  referralId: string,
  ashaId: string,
  message: string
): Promise<{ success: boolean }> {
  if (mocksEnabled()) {
    return { success: true };
  }
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
  if (!mocksEnabled()) {
    try {
      const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/acknowledge`, {
        acknowledgment_notes: notes,
      });
      return res.data;
    } catch {
      // local fallback
    }
  }
  const item = referralsCache.find((r) => r.id === referralId);
  if (item) {
    item.status = 'arrived';
    item.arrivedAt = new Date().toISOString();
    return { ...item };
  }
  throw new Error('Referral not found');
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
  if (!mocksEnabled()) {
    try {
      const res = await apiClient.get(`/integrations/abdm/hiu/records/${abhaId}`);
      return res.data;
    } catch {
      // local fallback
    }
  }
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

