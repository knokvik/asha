import { apiClient } from './client';

export type MapFacilityKind =
  | 'hospital'
  | 'phc'
  | 'chc'
  | 'subcentre'
  | 'lab'
  | 'pharmacy'
  | 'other';

export interface MapFacility {
  id: string;
  name: string;
  kind: MapFacilityKind | string;
  district?: string | null;
  block?: string | null;
  village?: string | null;
  lat: number;
  lon: number;
  phone?: string | null;
}

export interface MapSource {
  id: string;
  title: string;
  coverage: string;
  url: string;
  access: string;
  normalised_kinds: string[];
  status: string;
}

export interface DiseaseHotspot {
  ward_id: string;
  module_id: string;
  condition: string;
  cases: number;
  worker_count: number;
  active: boolean;
  last_reported_at: number;
  latitude: number | null;
  longitude: number | null;
}

export interface DiseaseHotspotContext {
  generated_at: number;
  as_of_month?: number;
  lookback_days: number;
  block_code?: string;
  counts: Array<{
    week_index: number;
    ward_id: string;
    condition: string;
    cases: number;
  }>;
  modules: Array<{
    id: string;
    condition: string;
    min_cases_per_week: number;
    lookback_weeks: number;
    seasonal_months: number[];
  }>;
  hotspots: DiseaseHotspot[];
  notifications?: Array<{
    id: string;
    ward_id: string;
    module_id: string;
    title: string;
    body: string;
    severity: string;
    created_at: number;
    expires_at: number;
  }>;
}

export async function getMapFacilities(filters?: {
  district?: string;
  facilityLevel?: string;
}): Promise<MapFacility[]> {
  const response = await apiClient.get<{ facilities?: MapFacility[] }>('/facilities', {
    params: {
      district: filters?.district,
      facility_level: filters?.facilityLevel,
    },
  });
  return Array.isArray(response.data?.facilities) ? response.data.facilities : [];
}

export async function getMapSources(): Promise<MapSource[]> {
  const response = await apiClient.get<{ sources?: MapSource[] }>('/map/sources');
  return Array.isArray(response.data?.sources) ? response.data.sources : [];
}

export async function getDiseaseHotspots(): Promise<DiseaseHotspotContext> {
  const response = await apiClient.get<DiseaseHotspotContext>('/sync/hotspots');
  return response.data;
}
