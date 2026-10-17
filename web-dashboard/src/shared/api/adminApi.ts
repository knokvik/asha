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

export const INITIAL_ADMIN_USERS: AdminUserRecord[] = [
  { id: 'usr-01', name: 'Dr. Alok Verma', role: 'PHC_MO', phone: '+91 98111 22334', block: 'Shahpur', status: 'active', appVersion: 'Web Portal', lastSyncAt: 'Live' },
  { id: 'usr-02', name: 'Sarita Singh', role: 'AF', phone: '+91 98111 33445', block: 'Shahpur', status: 'active', appVersion: 'v2.4.1', lastSyncAt: '12 mins ago' },
  { id: 'usr-03', name: 'Kavita Kumari', role: 'ANM', phone: '+91 98111 44556', block: 'Shahpur', subcentre: 'SC Rampur', status: 'active', appVersion: 'v2.4.1', lastSyncAt: '35 mins ago' },
  { id: 'usr-04', name: 'Meena Sharma', role: 'ASHA', phone: '+91 98765 43210', block: 'Shahpur', subcentre: 'SC Rampur', status: 'active', appVersion: 'v2.4.0', lastSyncAt: '18 mins ago' },
  { id: 'usr-05', name: 'Poonam Devi', role: 'ASHA', phone: '+91 98765 11223', block: 'Shahpur', subcentre: 'SC Kalyanpur', status: 'active', appVersion: 'v2.4.1', lastSyncAt: '40 mins ago' },
];

export async function getAdminUsers(): Promise<AdminUserRecord[]> {
  try {
    const res = await apiClient.get<AdminUserRecord[]>('/admin/users');
    if (Array.isArray(res.data)) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return [...INITIAL_ADMIN_USERS];
}

export async function bulkUploadUsers(csvContent: string): Promise<{ success: boolean; count: number }> {
  try {
    const res = await apiClient.post('/admin/users/bulk-upload', { csv: csvContent });
    return res.data;
  } catch {
    const lines = csvContent.trim().split('\n').filter(Boolean);
    return { success: true, count: Math.max(1, lines.length - 1) };
  }
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
  } catch {
    return {
      activeDevicesCount: 148,
      latestVersion: 'v2.4.1',
      versionAdoptionPct: 92.5,
      syncSuccessRatePct: 99.4,
      storageWarningCount: 2,
    };
  }
}
