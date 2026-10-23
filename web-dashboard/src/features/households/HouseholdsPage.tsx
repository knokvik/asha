import { useMemo } from 'react';
import { Users, RefreshCw } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { useSync } from '@/shared/context/SyncContext';

export function HouseholdsPage() {
  const { syncActivities, lastSyncTime, isSyncing, triggerManualSync } = useSync();
  const households = useMemo(() => {
    const seen = new Set<string>();
    return syncActivities.filter((item) => {
      const key = `${item.patientName || item.id}|${item.village}|${item.workerName}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return Boolean(item.patientName);
    });
  }, [syncActivities]);

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">Household Registry</h1>
          <p className="text-xs text-slate-500 mt-1">Household and member details received from the authenticated ASHA sync stream.</p>
        </div>
        <button onClick={() => triggerManualSync()} className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50">
          <RefreshCw className={`h-3.5 w-3.5 ${isSyncing ? 'animate-spin' : ''}`} /> Refresh
        </button>
      </div>
      <Card className="p-4 text-xs text-slate-500">Last server sync: {lastSyncTime || 'Not synced yet'}</Card>
      {households.length === 0 ? (
        <Card className="p-10 text-center text-sm text-slate-500"><Users className="mx-auto mb-3 h-8 w-8 text-slate-300" />No real household records have been synced yet.</Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {households.map((item) => (
            <Card key={`${item.id}-${item.workerName}`} className="p-5">
              <div className="flex items-start justify-between gap-3">
                <div><h2 className="text-sm font-black text-slate-900 dark:text-white">{item.patientName}</h2><p className="text-xs text-slate-500">{item.patientAge || 'Age not provided'} · {item.patientGender || 'Gender not provided'}</p></div>
              </div>
              <dl className="mt-4 grid grid-cols-2 gap-3 text-xs">
                <div><dt className="text-slate-400">Household Head</dt><dd className="font-semibold text-slate-700 dark:text-slate-200">{item.householdHead || item.patientName || '—'}</dd></div>
                <div><dt className="text-slate-400">Village</dt><dd className="font-semibold text-slate-700 dark:text-slate-200">{item.village}</dd></div>
                <div><dt className="text-slate-400">ASHA worker</dt><dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerName}</dd></div>
                <div><dt className="text-slate-400">Worker phone</dt><dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerPhone || '—'}</dd></div>
                <div><dt className="text-slate-400">Last update</dt><dd className="font-semibold text-slate-700 dark:text-slate-200">{item.syncTime}</dd></div>
              </dl>
              <p className="mt-4 border-t border-slate-100 pt-3 text-xs leading-5 text-slate-500">{item.details}</p>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
