import { apiClient } from './client';
import { AshaPerformanceCard, SupervisionChecklist } from '@/types';
import { INITIAL_ASHA_CARDS } from './mockData';

export async function getAshaPerformanceCards(afId: string = 'af-01'): Promise<AshaPerformanceCard[]> {
  try {
    const res = await apiClient.get<AshaPerformanceCard[]>(`/supervision/af/${afId}/ashas`);
    if (Array.isArray(res.data) && res.data.length > 0) {
      return res.data;
    }
  } catch {
    return INITIAL_ASHA_CARDS;
  }
  return INITIAL_ASHA_CARDS;
}

export async function submitSupervisionChecklist(checklist: SupervisionChecklist): Promise<{ id: string; success: boolean }> {
  const checklistId = checklist.id || `chk-${Date.now()}`;
  const record = { ...checklist, id: checklistId };
  try {
    const res = await apiClient.post(`/supervision/checklists`, record);
    return res.data;
  } catch { throw new Error('Unable to save supervision checklist to the server.'); }
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
  } catch { return { success: false }; }
  return { success: false };
}
