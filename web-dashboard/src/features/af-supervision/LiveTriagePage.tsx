import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Activity, ArrowLeft, Clock, FileAudio, Image as ImageIcon, Search, ShieldAlert } from 'lucide-react';
import { useSync } from '@/shared/context/SyncContext';
import { Button } from '@/components/ui/button';

export function LiveTriagePage() {
  const navigate = useNavigate();
  const { syncActivities, lastSyncTime, triggerManualSync, isSyncing } = useSync();
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const triage = useMemo(() => syncActivities
    .filter((item) => item.severity != null)
    .filter((item) => {
      const q = query.toLowerCase().trim();
      if (!q) return true;
      return [item.workerName, item.patientName, item.village, item.details, item.ticketId]
        .filter(Boolean).some((value) => String(value).toLowerCase().includes(q));
    }), [syncActivities, query]);

  const selected = triage.find((item) => item.id === selectedId) ?? triage[0];

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <button onClick={() => navigate('/af')} className="text-xs text-slate-500 hover:text-emerald-700 flex items-center gap-1 mb-3">
            <ArrowLeft className="w-3.5 h-3.5" /> Back to ASHA Team
          </button>
          <h1 className="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-2"><Activity className="w-6 h-6 text-rose-600" /> Live triage</h1>
          <p className="text-xs text-slate-500 mt-1">Authenticated packets received from ASHA workers · Last sync {lastSyncTime}</p>
        </div>
        <Button variant="outline" size="sm" onClick={() => triggerManualSync()} disabled={isSyncing} className="gap-1.5 text-xs">
          <Activity className="w-3.5 h-3.5" /> {isSyncing ? 'Refreshing…' : 'Refresh live feed'}
        </Button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
        <Stat label="Open triage packets" value={triage.length} tone="text-rose-700 bg-rose-50 border-rose-200" />
        <Stat label="Red / urgent" value={triage.filter((item) => item.severity === 'RED').length} tone="text-red-700 bg-red-50 border-red-200" />
        <Stat label="Reporting workers" value={new Set(triage.map((item) => item.workerName)).size} tone="text-emerald-700 bg-emerald-50 border-emerald-200" />
      </div>

      <div className="relative max-w-xl">
        <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search patient, ASHA worker, village, or ticket ID" className="w-full h-9 pl-9 pr-3 rounded-lg border border-slate-200 bg-white text-xs focus:outline-none focus:ring-1 focus:ring-rose-500" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] gap-4">
        <div className="space-y-2">
          {triage.length === 0 ? <div className="p-8 text-center text-xs text-slate-500 rounded-xl border border-dashed">No live triage packets match this search.</div> : triage.map((item) => (
            <button key={item.id} onClick={() => setSelectedId(item.id)} className={`w-full text-left p-4 rounded-xl border bg-white dark:bg-[#1E1E1E] ${selected?.id === item.id ? 'ring-2 ring-rose-500' : 'border-slate-200 dark:border-[#2E2E2E]'}`}>
              <div className="flex items-center justify-between gap-2"><span className={`text-[10px] font-black px-2 py-1 rounded ${item.severity === 'RED' ? 'bg-rose-100 text-rose-700' : 'bg-amber-100 text-amber-700'}`}>{item.severity} TRIAGE</span><span className="text-[10px] text-slate-400 flex items-center gap-1"><Clock className="w-3 h-3" />{item.syncTime}</span></div>
              <div className="mt-2 text-sm font-bold text-slate-900 dark:text-white">{item.patientName || 'Unnamed beneficiary'}</div>
              <div className="text-xs text-slate-500 mt-1">Reported by <span className="font-semibold">{item.workerName}</span> · {item.village}</div>
              <div className="text-xs text-slate-700 dark:text-slate-300 mt-2 line-clamp-2">{item.details}</div>
            </button>
          ))}
        </div>

        {selected && <div className="rounded-2xl border border-slate-200 dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] p-5 space-y-5 h-fit">
          <div className="flex items-start justify-between gap-3"><div><div className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Triage packet</div><h2 className="text-lg font-black text-slate-900 dark:text-white mt-1">{selected.patientName || 'Unnamed beneficiary'}</h2></div><span className={`px-2 py-1 rounded text-[10px] font-black ${selected.severity === 'RED' ? 'bg-rose-100 text-rose-700' : 'bg-amber-100 text-amber-700'}`}>{selected.severity}</span></div>
          <div className="grid grid-cols-2 gap-3 text-xs"><Detail label="Reported by" value={selected.workerName} /><Detail label="Worker contact" value={selected.workerPhone || 'Not supplied'} /><Detail label="Location" value={selected.village} /><Detail label="Ticket ID" value={selected.ticketId || selected.id} /><Detail label="Patient age" value={String(selected.patientAge || 'Not supplied')} /><Detail label="Gender" value={selected.patientGender || 'Not supplied'} /></div>
          <section><h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">Clinical details</h3><p className="text-sm text-slate-800 dark:text-slate-200 mt-2">{selected.details}</p><p className="text-xs text-slate-500 mt-2">{selected.clinicalPayload}</p></section>
          {selected.vitalsSummary && <section><h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">Vitals</h3><p className="font-mono text-xs mt-2">{selected.vitalsSummary}</p></section>}
          {selected.dangerSigns && selected.dangerSigns.length > 0 && <section><h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider flex items-center gap-1"><ShieldAlert className="w-3.5 h-3.5 text-rose-600" /> Danger signs</h3><ul className="mt-2 list-disc list-inside text-xs text-rose-700">{selected.dangerSigns.map((sign) => <li key={sign}>{sign}</li>)}</ul></section>}
          {selected.attachments && selected.attachments.length > 0 && <section><h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">Attachments</h3><div className="flex gap-2 mt-2">{selected.attachments.map((attachment) => attachment.type === 'image' ? <a key={attachment.index} href={attachment.url} target="_blank" rel="noreferrer" className="p-2 rounded-lg bg-slate-100 text-xs flex items-center gap-1"><ImageIcon className="w-3.5 h-3.5" /> Image</a> : <a key={attachment.index} href={attachment.url} target="_blank" rel="noreferrer" className="p-2 rounded-lg bg-slate-100 text-xs flex items-center gap-1"><FileAudio className="w-3.5 h-3.5" /> Audio</a>)}</div></section>}
        </div>}
      </div>
    </div>
  );
}

function Stat({ label, value, tone }: { label: string; value: number; tone: string }) {
  return <div className={`rounded-xl border px-4 py-3 ${tone}`}><div className="text-[10px] uppercase tracking-wider font-bold">{label}</div><div className="text-2xl font-black mt-1">{value}</div></div>;
}

function Detail({ label, value }: { label: string; value: string }) {
  return <div className="rounded-lg bg-slate-50 dark:bg-[#252528] p-3"><div className="text-[10px] uppercase text-slate-400 font-bold">{label}</div><div className="text-xs font-semibold text-slate-800 dark:text-slate-200 mt-1 break-words">{value}</div></div>;
}
