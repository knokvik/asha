import { apiClient } from './client';
import { INITIAL_INDICATORS, INITIAL_OUTBREAK_ALERTS, INITIAL_SUPPLY_FORECASTS } from './mockData';
import { DistrictIndicator, OutbreakAlert, SupplyForecast } from '@/types';

export async function getDistrictIndicators(districtCode: string = 'DIST_01'): Promise<DistrictIndicator[]> {
  try {
    const res = await apiClient.get<DistrictIndicator[]>(`/analytics/district/${districtCode}/indicators`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...INITIAL_INDICATORS];
}

export async function getOutbreakAlerts(blockCode: string = 'BLOCK_A'): Promise<OutbreakAlert[]> {
  try {
    const res = await apiClient.get<OutbreakAlert[]>(`/analytics/block/${blockCode}/outbreak-alerts`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...INITIAL_OUTBREAK_ALERTS];
}

export async function getSupplyForecasts(facilityId: string = 'phc-shahpur'): Promise<SupplyForecast[]> {
  try {
    const res = await apiClient.get<SupplyForecast[]>(`/analytics/facility/${facilityId}/supplies`);
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...INITIAL_SUPPLY_FORECASTS];
}
