import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';

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

const INITIAL_SYNC_ACTIVITIES: FrontlineSyncActivity[] = [
  {
    id: 'sync-001',
    workerName: 'Sunita Devi',
    workerPhone: '+91 98765 43210',
    village: 'Ward 7, Shahpur',
    category: 'Maternal (ANC)',
    details: 'High-Risk ANC 3rd Trimester evaluation for Patient S.D. (26/F)',
    clinicalPayload: 'Severe frontal headache, blurred vision, bilateral pedal edema (+++). Urgently referred to PHC triage.',
    vitalsSummary: 'BP: 165/105 mmHg • SpO2: 97% • Pulse: 98 bpm • Hb: 9.4 g/dL',
    syncTime: '2 mins ago',
    timestamp: Date.now() - 2 * 60 * 1000,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Patient S.D.',
    abhaId: '91-8765-4321-0987',
  },
  {
    id: 'sync-002',
    workerName: 'Poonam Devi',
    workerPhone: '+91 98765 11223',
    village: 'Kalyanpur',
    category: 'Child (IMNCI)',
    details: 'Day 3 PSBI Follow-up for Baby of Kavita (3 days, M)',
    clinicalPayload: 'Respiratory rate 68 breaths/min (confirmed by 60s tap). Severe chest indrawing. Lethargic, unable to suckle.',
    vitalsSummary: 'Resp: 68/min • SpO2: 91% • Temp: 99.8°F • Pulse: 155 bpm',
    syncTime: '8 mins ago',
    timestamp: Date.now() - 8 * 60 * 1000,
    channel: 'SMS Emergency Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Baby of Kavita',
    abhaId: '91-1122-3344-5566',
  },
  {
    id: 'sync-003',
    workerName: 'Rekha Devi',
    workerPhone: '+91 98765 22334',
    village: 'Dindaspur',
    category: 'Maternal (ANC)',
    details: 'Prolonged labour intrapartum monitor for Patient M.D. (28/F)',
    clinicalPayload: 'Active labour > 14 hours. Severe exhaustion. 108 Ambulance dispatch requested from Sub-centre.',
    vitalsSummary: 'BP: 138/88 mmHg • Fetal Heart: 148 bpm • Temp: 98.6°F',
    syncTime: '19 mins ago',
    timestamp: Date.now() - 19 * 60 * 1000,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Patient M.D.',
    abhaId: '91-2233-4455-6677',
  },
  {
    id: 'sync-004',
    workerName: 'Meena Kumari',
    workerPhone: '+91 98765 33445',
    village: 'Bhadwar',
    category: 'Child (IMNCI)',
    details: 'Follow-up MAM malnutrition screening for Patient R.K. (4/M)',
    clinicalPayload: 'Severe undernutrition assessment. MUAC 11.2 cm, visible wasting. Mother given nutritional counselling.',
    vitalsSummary: 'Weight: 11.4 kg • MUAC: 11.2 cm • Height: 92 cm',
    syncTime: '32 mins ago',
    timestamp: Date.now() - 32 * 60 * 1000,
    channel: 'Subcentre Mesh',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Patient R.K.',
    abhaId: '91-3344-5566-7788',
  },
  {
    id: 'sync-005',
    workerName: 'Rekha Sharma',
    workerPhone: '+91 98765 55667',
    village: 'Shahpur Ward 1',
    category: 'Postnatal (PNC)',
    details: 'Day 3 Postnatal Home Visit for Smt. Geeta & Newborn',
    clinicalPayload: 'Maternal BP normal, lochia normal. Baby latching well, cord clean and dry. No danger signs.',
    vitalsSummary: 'Maternal BP: 118/76 mmHg • Infant Weight: 2.85 kg • Temp: 36.8°C',
    syncTime: '48 mins ago',
    timestamp: Date.now() - 48 * 60 * 1000,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Geeta & Baby',
  },
  {
    id: 'sync-006',
    workerName: 'Kamla Thakur',
    workerPhone: '+91 94180 55443',
    village: 'Kotla Forest',
    category: 'NCD Screening',
    details: 'Hypertensive Emergency SMS fallback ingest for Ramesh Chand (58/M)',
    clinicalPayload: 'Relayed via SMS Gateway Phone from dead-zone. Severe chest pressure. Subcentre administered aspirin.',
    vitalsSummary: 'BP: 190/125 mmHg • Pulse: 112 bpm • SpO2: 93% • Resp: 26/min',
    syncTime: '1 hr ago',
    timestamp: Date.now() - 65 * 60 * 1000,
    channel: 'SMS Emergency Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Ramesh Chand',
    abhaId: '91-4455-6677-8899',
  },
  {
    id: 'sync-007',
    workerName: 'Sunita Devi',
    workerPhone: '+91 98765 43210',
    village: 'Shahpur Ward 7',
    category: 'Immunization',
    details: 'Mission Indradhanush mop-up session batch sync',
    clinicalPayload: '12 infants immunized with Pentavalent-3 and OPV-3. Cold chain temperature verified at 4.2°C.',
    vitalsSummary: '12 Beneficiaries • Zero AEFIs reported',
    syncTime: '1.5 hrs ago',
    timestamp: Date.now() - 95 * 60 * 1000,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
  },
];

const SIMULATED_NEW_INCOMING = [
  {
    workerName: 'Sunita Devi',
    workerPhone: '+91 98765 43210',
    village: 'Ward 7, Shahpur',
    category: 'Maternal (ANC)' as const,
    details: 'ANC 2nd Trimester Home Visit for Anita Devi (23/F)',
    clinicalPayload: 'Fundal height 22 weeks. Fetal heart sounds distinct. Td-2 dose administered. BP within normal range.',
    vitalsSummary: 'BP: 116/74 mmHg • Pulse: 82 bpm • Weight: 54 kg • Hb: 11.2 g/dL',
    channel: 'ABDM Online Gateway' as const,
    status: 'Verified & Synced' as const,
    severity: 'GREEN' as const,
    patientName: 'Anita Devi',
  },
  {
    workerName: 'Meena Kumari',
    workerPhone: '+91 98765 33445',
    village: 'Bhadwar',
    category: 'Child (IMNCI)' as const,
    details: 'Acute Diarrhea with Moderate Dehydration in Child (18m, F)',
    clinicalPayload: 'Sunken eyes, thirsty, skin pinch goes back slowly. ORS and Zinc supplementation initiated at household.',
    vitalsSummary: 'Temp: 38.1°C • Resp: 34/min • Weight: 9.8 kg',
    channel: 'ABDM Online Gateway' as const,
    status: 'Triage Priority' as const,
    severity: 'YELLOW' as const,
    patientName: 'Baby of Priyanka',
  },
  {
    workerName: 'Rekha Sharma',
    workerPhone: '+91 98765 55667',
    village: 'Shahpur Ward 1',
    category: 'NCD Screening' as const,
    details: 'Community NCD Screening for Ram Prasad (62/M)',
    clinicalPayload: 'Random blood glucose elevated. Confirmed hypertensive history. Scheduled for PHC doctor review.',
    vitalsSummary: 'BP: 154/96 mmHg • RBS: 198 mg/dL • BMI: 27.2',
    channel: 'ABDM Online Gateway' as const,
    status: 'Verified & Synced' as const,
    severity: 'YELLOW' as const,
    patientName: 'Ram Prasad',
  },
  {
    workerName: 'Poonam Devi',
    workerPhone: '+91 98765 11223',
    village: 'Kalyanpur',
    category: 'Postnatal (PNC)' as const,
    details: 'Day 7 PNC Home Visit for Savita & Baby',
    clinicalPayload: 'Exclusive breastfeeding established. Neonatal jaundice resolved. Umbilical stump dry and clean.',
    vitalsSummary: 'Infant Weight: 2.92 kg • Maternal BP: 122/80 mmHg',
    channel: 'ABDM Online Gateway' as const,
    status: 'Verified & Synced' as const,
    severity: 'GREEN' as const,
    patientName: 'Savita & Baby',
  },
];

const SyncContext = createContext<SyncContextType | undefined>(undefined);

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const [lastSyncTime, setLastSyncTime] = useState<string>('Just now');
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [toasts, setToasts] = useState<SyncToastItem[]>([]);
  const [syncActivities, setSyncActivities] = useState<FrontlineSyncActivity[]>(INITIAL_SYNC_ACTIVITIES);
  const simIndexRef = useRef(0);

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback((toast: SyncToastItem) => {
    setToasts((prev) => [toast, ...prev.slice(0, 4)]); // Keep at most 5 active toasts

    // Auto dismiss after 7 seconds
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== toast.id));
    }, 7000);
  }, []);

  const triggerManualSync = useCallback((customPayload?: Partial<FrontlineSyncActivity>) => {
    setIsSyncing(true);

    setTimeout(() => {
      const template = SIMULATED_NEW_INCOMING[simIndexRef.current % SIMULATED_NEW_INCOMING.length];
      simIndexRef.current += 1;

      const newActivity: FrontlineSyncActivity = {
        id: `sync-live-${Date.now()}`,
        workerName: customPayload?.workerName || template.workerName,
        workerPhone: customPayload?.workerPhone || template.workerPhone,
        village: customPayload?.village || template.village,
        category: customPayload?.category || template.category,
        details: customPayload?.details || template.details,
        clinicalPayload: customPayload?.clinicalPayload || template.clinicalPayload,
        vitalsSummary: customPayload?.vitalsSummary || template.vitalsSummary,
        syncTime: 'Just now',
        timestamp: Date.now(),
        channel: customPayload?.channel || template.channel,
        status: customPayload?.status || template.status,
        severity: customPayload?.severity || template.severity,
        patientName: customPayload?.patientName || template.patientName,
        abhaId: customPayload?.abhaId || template.patientName ? `91-${Math.floor(1000 + Math.random() * 9000)}-${Math.floor(1000 + Math.random() * 9000)}-${Math.floor(1000 + Math.random() * 9000)}` : undefined,
      };

      setSyncActivities((prev) => [newActivity, ...prev]);
      setLastSyncTime('Just now');
      setIsSyncing(false);

      // Create Toast notification
      const toastId = `toast-${Date.now()}`;
      addToast({
        id: toastId,
        title: 'Frontline Data Synced',
        workerName: newActivity.workerName,
        village: newActivity.village,
        category: newActivity.category,
        details: newActivity.details,
        syncTime: 'Just now',
        type: newActivity.severity === 'RED' ? 'urgent_triage' : 'sync_received',
        link: newActivity.severity === 'RED' ? '/phc' : '/af',
      });
    }, 600);
  }, [addToast]);

  const recordDoctorOutcomeSync = useCallback((patientName: string, ashaName: string, actionText: string) => {
    const toastId = `outcome-toast-${Date.now()}`;
    addToast({
      id: toastId,
      title: 'Counter-Referral Synced to ASHA',
      workerName: ashaName,
      village: 'Varanasi Field Unit',
      category: 'Clinical Outcome',
      details: `${actionText} for ${patientName} pushed to frontline tablet via ABDM gateway.`,
      syncTime: 'Just now',
      type: 'outcome_pushed',
      link: '/phc',
    });
  }, [addToast]);

  // Initial live sync demonstration 1.2s after load
  useEffect(() => {
    const initialTimer = setTimeout(() => {
      addToast({
        id: `initial-sync-${Date.now()}`,
        title: 'Frontline Data Synced',
        workerName: 'Sunita Devi',
        village: 'Ward 7, Shahpur',
        category: 'Maternal (ANC)',
        details: 'High-Risk pre-eclampsia vitals & field observations synced via ABDM Gateway.',
        syncTime: 'Just now',
        type: 'urgent_triage',
        link: '/phc',
      });
    }, 1200);

    return () => clearTimeout(initialTimer);
  }, [addToast]);

  // Periodic automated background sync every 50 seconds to keep live hospital ambiance
  useEffect(() => {
    const timer = setInterval(() => {
      // Periodic automatic sync
      triggerManualSync();
    }, 50_000);

    return () => clearInterval(timer);
  }, [triggerManualSync]);

  // Update relative time strings every 30 seconds
  useEffect(() => {
    const relativeTimer = setInterval(() => {
      setSyncActivities((prev) =>
        prev.map((act) => {
          const diffMin = Math.round((Date.now() - act.timestamp) / (1000 * 60));
          let timeText = 'Just now';
          if (diffMin >= 60) {
            timeText = `${Math.floor(diffMin / 60)}h ago`;
          } else if (diffMin > 1) {
            timeText = `${diffMin} mins ago`;
          } else if (diffMin === 1) {
            timeText = '1 min ago';
          }
          return { ...act, syncTime: timeText };
        })
      );
    }, 30_000);

    return () => clearInterval(relativeTimer);
  }, []);

  return (
    <SyncContext.Provider
      value={{
        lastSyncTime,
        isSyncing,
        toasts,
        syncActivities,
        triggerManualSync,
        dismissToast,
        recordDoctorOutcomeSync,
      }}
    >
      {children}
    </SyncContext.Provider>
  );
}

export function useSync() {
  const context = useContext(SyncContext);
  if (!context) {
    return {
      lastSyncTime: '30s ago',
      isSyncing: false,
      toasts: [],
      syncActivities: INITIAL_SYNC_ACTIVITIES,
      triggerManualSync: () => {},
      dismissToast: () => {},
      recordDoctorOutcomeSync: () => {},
    };
  }
  return context;
}
