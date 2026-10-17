import { apiClient } from './client';
import { INITIAL_CLAIM_ITEMS } from './mockData';
import { IncentiveClaimLineItem } from '@/types';

let claimsCache = [...INITIAL_CLAIM_ITEMS];

export async function getIncentiveVerificationQueue(subcentreId: string = 'sc-shahpur'): Promise<IncentiveClaimLineItem[]> {
  try {
    const res = await apiClient.get<IncentiveClaimLineItem[]>(`/anm/subcentre/${subcentreId}/claims-review`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...claimsCache];
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
  } catch {
    const item = claimsCache.find((c) => c.id === lineItemId);
    if (item) {
      item.status = action;
      if (rejectionReason) item.rejectionReason = rejectionReason;
      return { ...item };
    }
    throw new Error('Claim line item not found');
  }
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
  } catch {
    return { id: `vhsnd-${Date.now()}`, success: true };
  }
}
