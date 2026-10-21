import { apiClient } from './client';

export interface AdminUserRecord {
  id: string;
  name: string;
  role: string;
  phone: string;
  block: string;
  subcentre?: string;
  status: 'active' | 'inactive';
  appVersion?: string;
  lastSyncAt?: string;
}

export async function getAdminUsers(): Promise<AdminUserRecord[]> {
  try {
    const res = await apiClient.get<AdminUserRecord[]>('/admin/users');
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch { return []; }
  return [];
}

export async function bulkUploadUsers(csvContent: string): Promise<{ success: boolean; count: number }> {
  try {
    const res = await apiClient.post('/admin/users/bulk-upload', { csv: csvContent });
    return res.data;
  } catch { return { success: false, count: 0 }; }
}

export async function getOtaDeploymentMetrics(): Promise<{
  activeDevicesCount: number;
  latestVersion: string;
  versionAdoptionPct: number;
  syncSuccessRatePct: number;
  storageWarningCount: number;
}> {
  try {
    const res = await apiClient.get('/admin/ota/metrics');
    return res.data;
  } catch { return { activeDevicesCount: 0, latestVersion: '', versionAdoptionPct: 0, syncSuccessRatePct: 0, storageWarningCount: 0 }; }
}
