import { useMemo } from 'react';
import { Users, RefreshCw, LockKeyhole } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { useSync, type FrontlineSyncActivity } from '@/shared/context/SyncContext';

type HouseholdRow = { key: string; household: FrontlineSyncActivity; members: FrontlineSyncActivity[]; timestamp: number };

function ageOf(member: FrontlineSyncActivity): string {
  const value = member.record?.age_years ?? member.record?.ageYears ?? member.patientAge;
  return value == null || value === '' ? '—' : String(value);
}

export function HouseholdsPage() {
  const { syncActivities, lastSyncTime, isSyncing, triggerManualSync } = useSync();
  const households = useMemo<HouseholdRow[]>(() => {
    const groups = new Map<string, HouseholdRow>();
    for (const packet of syncActivities.filter((item) => item.recordTable === 'households' || item.recordTable === 'members').sort((a, b) => b.timestamp - a.timestamp)) {
      const key = packet.recordTable === 'households' ? packet.recordId! : packet.householdId || packet.householdHead || packet.id;
      const row = groups.get(key) || { key, household: packet, members: [], timestamp: packet.timestamp };
      row.timestamp = Math.max(row.timestamp, packet.timestamp);
      if (packet.recordTable === 'households') row.household = packet;
      else if (!row.members.some((member) => member.recordId === packet.recordId)) row.members.push(packet);
      groups.set(key, row);
    }
    return [...groups.values()].sort((a, b) => b.timestamp - a.timestamp);
  }, [syncActivities]);

  return <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
    <div className="flex flex-wrap items-start justify-between gap-3"><div><h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">Household Registry</h1><p className="text-xs text-slate-500 mt-1">All authenticated household and member records received from the server.</p></div><button onClick={() => triggerManualSync()} className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50"><RefreshCw className={`h-3.5 w-3.5 ${isSyncing ? 'animate-spin' : ''}`} /> Refresh</button></div>
    <Card className="p-4 text-xs text-slate-500">Last server sync: {lastSyncTime || 'Not synced yet'}</Card>
    {households.length === 0 ? <Card className="p-10 text-center text-sm text-slate-500"><Users className="mx-auto mb-3 h-8 w-8 text-slate-300" />No household records have been synced yet.</Card> : <div className="space-y-4">{households.map(({ key, household, members, timestamp }) => <Card key={key} className="p-5"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="text-base font-black text-slate-900 dark:text-white">{String(household.record?.head_name || household.householdHead || household.patientName || 'Household')}</h2><p className="text-xs text-slate-500">{String(household.record?.village || household.village || 'Village not provided')} · {members.length} member{members.length === 1 ? '' : 's'}</p></div><span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold text-slate-600"><LockKeyhole className="h-3 w-3" /> Read-only</span></div><dl className="mt-4 grid grid-cols-2 gap-3 text-xs sm:grid-cols-4"><div><dt className="text-slate-400">Household ID</dt><dd className="truncate font-semibold">{household.recordId || key}</dd></div><div><dt className="text-slate-400">ASHA worker</dt><dd className="font-semibold">{household.workerName}</dd></div><div><dt className="text-slate-400">Last synced</dt><dd className="font-semibold">{household.syncTime}</dd></div><div><dt className="text-slate-400">Sync status</dt><dd className="font-semibold text-emerald-700">Synced</dd></div></dl><div className="mt-4 overflow-x-auto rounded-lg border border-slate-100 dark:border-slate-800"><table className="w-full min-w-[620px] text-left text-xs"><thead className="bg-slate-50 text-slate-400 dark:bg-slate-900/40"><tr><th className="px-3 py-2">Member</th><th className="px-3 py-2">Relation</th><th className="px-3 py-2">Age</th><th className="px-3 py-2">Sex</th><th className="px-3 py-2">Last synced</th></tr></thead><tbody>{members.length === 0 ? <tr><td colSpan={5} className="px-3 py-4 text-slate-500">Household synced; member packets have not arrived yet.</td></tr> : members.map((member) => <tr key={member.recordId || member.id} className="border-t border-slate-100 dark:border-slate-800"><td className="px-3 py-2 font-semibold">{String(member.record?.name || member.patientName || 'Unnamed member')}</td><td className="px-3 py-2">{String(member.record?.relationship_to_head || '—')}</td><td className="px-3 py-2">{ageOf(member)}</td><td className="px-3 py-2">{String(member.record?.sex || member.patientGender || '—')}</td><td className="px-3 py-2 text-slate-500">{member.syncTime}</td></tr>)}</tbody></table></div><p className="mt-3 text-[11px] text-slate-400">Updated {new Date(timestamp).toLocaleString()}</p></Card>)}</div>}
  </div>;
}
