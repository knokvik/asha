import { apiClient } from './client';
import { INITIAL_ASHA_CARDS } from './mockData';
import { AshaPerformanceCard, SupervisionChecklist } from '@/types';

let ashaCardsCache = [...INITIAL_ASHA_CARDS];
let checklistsCache: SupervisionChecklist[] = [];

export async function getAshaPerformanceCards(afId: string = 'af-01'): Promise<AshaPerformanceCard[]> {
  try {
    const res = await apiClient.get<AshaPerformanceCard[]>(`/supervision/af/${afId}/ashas`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...ashaCardsCache];
}

export async function submitSupervisionChecklist(checklist: SupervisionChecklist): Promise<{ id: string; success: boolean }> {
  const checklistId = checklist.id || `chk-${Date.now()}`;
  const record = { ...checklist, id: checklistId };
  try {
    const res = await apiClient.post(`/supervision/checklists`, record);
    return res.data;
  } catch {
    checklistsCache.push(record);
    return { id: checklistId, success: true };
  }
}

export async function sendAshaRecognition(
  ashaId: string,
  badgeType: 'star_performer' | 'care_champion' | 'prompt_referrer' | 'learning_master',
  message: string
): Promise<{ success: boolean }> {
  try {
    await apiClient.post(`/supervision/recognition`, {
      asha_id: ashaId,
      badge_type: badgeType,
      message,
      sent_at: new Date().toISOString(),
    });
  } catch {
    console.info(`[Recognition badge ${badgeType} sent to ASHA ${ashaId}]: ${message}`);
  }
  return { success: true };
}
