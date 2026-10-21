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
