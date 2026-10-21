import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { apiClient } from '@/shared/api/client';

export interface TriageEvidence {
  index: number;
  type: 'image' | 'audio' | 'file';
  mimeType: string;
  originalBytes?: number;
  url: string;
}

export interface FrontlineSyncActivity {
  id: string;
  workerName: string;
  workerPhone: string;
  village: string;
  category: 'Maternal (ANC)' | 'Child (IMNCI)' | 'Postnatal (PNC)' | 'NCD Screening' | 'Immunization';
  details: string;
  clinicalPayload: string;
  vitalsSummary?: string;
  syncTime: string;
  timestamp: number;
  channel: 'ABDM Online Gateway' | 'SMS Emergency Gateway' | 'Subcentre Mesh';
  status: 'Verified & Synced' | 'Triage Priority' | 'Processed';
  severity?: 'RED' | 'YELLOW' | 'GREEN';
  patientName?: string;
  abhaId?: string;
  ticketId?: string;
  attachments?: TriageEvidence[];
}

export interface SyncToastItem {
  id: string;
  title: string;
  workerName: string;
  village: string;
  category: string;
  details: string;
  syncTime: string;
  type: 'sync_received' | 'urgent_triage' | 'outcome_pushed';
  link?: string;
}

interface SyncContextType {
  lastSyncTime: string;
  isSyncing: boolean;
  toasts: SyncToastItem[];
  syncActivities: FrontlineSyncActivity[];
  triggerManualSync: (customPayload?: Partial<FrontlineSyncActivity>) => void;
  dismissToast: (id: string) => void;
  recordDoctorOutcomeSync: (patientName: string, ashaName: string, actionText: string) => void;
}

const SyncContext = createContext<SyncContextType | undefined>(undefined);

function relativeTime(timestamp: number): string {
  const minutes = Math.max(0, Math.round((Date.now() - timestamp) / 60000));
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} min${minutes === 1 ? '' : 's'} ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours} hr${hours === 1 ? '' : 's'} ago`;
}

function mapPacket(packet: any): FrontlineSyncActivity {
  const timestamp = Number(packet.received_at || packet.device_timestamp || Date.now());
  const table = String(packet.table || 'sync packet');
  const category = table.includes('encounter') || table.includes('triage')
    ? 'NCD Screening'
    : table.includes('member') || table.includes('household')
      ? 'Child (IMNCI)'
      : 'Immunization';
  const ticket = packet.ticket;
  const attachments: TriageEvidence[] = Array.isArray(ticket?.attachments)
    ? ticket.attachments.map((attachment: any) => ({
        index: Number(attachment.index),
        type: attachment.type === 'image' || attachment.type === 'audio' ? attachment.type : 'file',
        mimeType: String(attachment.mime_type || 'application/octet-stream'),
        originalBytes: typeof attachment.original_bytes === 'number' ? attachment.original_bytes : undefined,
        url: String(attachment.url),
      }))
    : [];
  return {
    id: String(packet.id),
    workerName: String(packet.worker_id || 'Field worker'),
    workerPhone: '',
    village: String(ticket?.location || packet.device_id || 'Field device'),
    category,
    details: ticket
      ? `TRIAGE ${String(ticket.flag || 'SUBMITTED')} · ${String(ticket.id || packet.record_id)}`
      : `${String(packet.operation || 'update').toUpperCase()} ${table} · ${packet.record_id}`,
    clinicalPayload: ticket?.details
      ? String(ticket.details)
      : ticket
        ? `Ward ${String(ticket.ward_id || 'not recorded')} · ticket received from the field.`
        : 'Packet metadata available in the source record.',
    syncTime: relativeTime(timestamp),
    timestamp,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: ticket?.flag === 'RED' || ticket?.flag === 'YELLOW' || ticket?.flag === 'GREEN'
      ? ticket.flag
      : undefined,
    patientName: ticket?.patient_name ? String(ticket.patient_name) : undefined,
    ticketId: ticket?.id ? String(ticket.id) : undefined,
    attachments,
  };
}

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const [lastSyncTime, setLastSyncTime] = useState('Not synced yet');
  const [isSyncing, setIsSyncing] = useState(false);
  const [toasts, setToasts] = useState<SyncToastItem[]>([]);
  const [syncActivities, setSyncActivities] = useState<FrontlineSyncActivity[]>([]);

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  const loadActivity = useCallback(async () => {
    if (!localStorage.getItem('asha_auth_token')) {
      setSyncActivities([]);
      setLastSyncTime('Not synced yet');
      return;
    }
    setIsSyncing(true);
    try {
      const response = await apiClient.get('/sync/activity?limit=100');
      const packets = Array.isArray(response.data?.packets) ? response.data.packets : [];
      const next = packets.map(mapPacket);
      setSyncActivities(next);
      setLastSyncTime(next.length > 0 ? relativeTime(next[0].timestamp) : 'No packets yet');
    } catch {
      // The activity panel is optional; do not surface polling failures as
      // uncaught errors or interrupt the rest of the dashboard.
    } finally {
      setIsSyncing(false);
    }
  }, []);

  useEffect(() => {
    void loadActivity();
    const timer = window.setInterval(() => void loadActivity(), 10000);
    return () => window.clearInterval(timer);
  }, [loadActivity]);

  const triggerManualSync = useCallback(() => {
    void loadActivity();
  }, [loadActivity]);

  const recordDoctorOutcomeSync = useCallback(() => {
    void loadActivity();
  }, [loadActivity]);

  return (
    <SyncContext.Provider value={{ lastSyncTime, isSyncing, toasts, syncActivities, triggerManualSync, dismissToast, recordDoctorOutcomeSync }}>
      {children}
    </SyncContext.Provider>
  );
}

export function useSync() {
  const context = useContext(SyncContext);
  return context ?? {
    lastSyncTime: 'Not synced yet',
    isSyncing: false,
    toasts: [],
    syncActivities: [],
    triggerManualSync: () => undefined,
    dismissToast: () => undefined,
    recordDoctorOutcomeSync: () => undefined,
  };
}
