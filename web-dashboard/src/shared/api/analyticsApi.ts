import { apiClient } from './client';
import { DistrictIndicator, OutbreakAlert, SupplyForecast } from '@/types';

export async function getDistrictIndicators(districtCode: string = 'DIST_01'): Promise<DistrictIndicator[]> {
  try {
    const res = await apiClient.get<DistrictIndicator[]>(`/analytics/district/${districtCode}/indicators`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch { return []; }
  return [];
}

export async function getOutbreakAlerts(blockCode: string = 'BLOCK_A'): Promise<OutbreakAlert[]> {
  try {
    const res = await apiClient.get<OutbreakAlert[]>(`/analytics/block/${blockCode}/outbreak-alerts`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch { return []; }
  return [];
}

export async function getSupplyForecasts(facilityId: string = 'phc-shahpur'): Promise<SupplyForecast[]> {
  try {
    const res = await apiClient.get<SupplyForecast[]>(`/analytics/facility/${facilityId}/supplies`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch { return []; }
  return [];
}
