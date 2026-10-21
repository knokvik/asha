import { apiClient } from './client';
import { ReferralItem } from '@/types';
import { validateOutcome, type OutcomeAction } from '@/features/clinical-desk/logic';

const confirmedByWard: Record<string, number> = {};

function sortQueue(items: ReferralItem[]): ReferralItem[] {
  const order: Record<string, number> = { RED: 0, YELLOW: 1, GREEN: 2 };
  return [...items].sort((a, b) => {
    const sevDiff = (order[a.severity] ?? 2) - (order[b.severity] ?? 2);
    if (sevDiff !== 0) return sevDiff;
    return new Date(a.referredAt).getTime() - new Date(b.referredAt).getTime();
  });
}

export function resetReferralCache(): void {
  for (const key of Object.keys(confirmedByWard)) delete confirmedByWard[key];
}

export function wardConfirmations(): Record<string, number> {
  return { ...confirmedByWard };
}

export async function getReferralQueue(facilityId: string = 'phc-shahpur'): Promise<ReferralItem[]> {
  const res = await apiClient.get<ReferralItem[]>(`/referrals/facility/${facilityId}`);
  return Array.isArray(res.data) ? sortQueue(res.data) : [];
}

export async function recordReferralOutcome(
  referralId: string,
  status: 'admitted' | 'treated' | 'discharged' | 'did_not_reach',
  outcomeNotes: string
): Promise<ReferralItem> {
  const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/outcome`, { status, outcome_notes: outcomeNotes, recorded_at: new Date().toISOString() });
  return res.data;
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
  return {
    ...updated,
    diagnosis: input.diagnosis,
    outcomeAction: input.action,
    noteForAsha: input.noteForAsha,
  };
}

export async function startConsult(referralId: string): Promise<ReferralItem> {
  const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/consult`, {});
  return res.data;
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
  try {
    await apiClient.post(`/referrals/${referralId}/feedback`, {
      asha_id: ashaId,
      message,
      sent_at: new Date().toISOString(),
    });
    return { success: true };
  } catch { return { success: false }; }
}

export async function acknowledgeReferral(
  referralId: string,
  notes?: string
): Promise<ReferralItem> {
  const res = await apiClient.post<ReferralItem>(`/referrals/${referralId}/acknowledge`, { acknowledgment_notes: notes });
  return res.data;
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
  const res = await apiClient.get(`/integrations/abdm/hiu/records/${abhaId}`);
  return res.data;
}

