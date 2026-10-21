import { apiClient } from './client';
import { IncentiveClaimLineItem } from '@/types';

export async function getIncentiveVerificationQueue(subcentreId: string = 'sc-shahpur'): Promise<IncentiveClaimLineItem[]> {
  try {
    const res = await apiClient.get<IncentiveClaimLineItem[]>(`/anm/subcentre/${subcentreId}/claims-review`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch { return []; }
  return [];
}

export async function verifyClaimLineItem(
  lineItemId: string,
  action: 'approved' | 'rejected' | 'correction_requested',
  rejectionReason?: string
): Promise<IncentiveClaimLineItem> {
  try {
    const res = await apiClient.post<IncentiveClaimLineItem>(`/anm/claims-review/${lineItemId}/verify`, {
      action,
      rejection_reason: rejectionReason,
      verified_at: new Date().toISOString(),
    });
    return res.data;
  } catch { throw new Error('Unable to verify claim on the server.'); }
}

export async function recordVhsndSession(sessionData: {
  subcentreId: string;
  village: string;
  sessionDate: string;
  attendeesCount: number;
  immunizationsGiven: number;
  ancServicesGiven: number;
  cbacScreenings: number;
  notes: string;
}): Promise<{ id: string; success: boolean }> {
  try {
    const res = await apiClient.post(`/anm/vhsnd/session`, sessionData);
    return res.data;
  } catch { return { id: '', success: false }; }
}
