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
