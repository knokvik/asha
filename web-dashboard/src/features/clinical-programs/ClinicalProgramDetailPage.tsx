import { useMemo } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, CalendarClock, CheckCircle2, ExternalLink, FileAudio, FileImage, MapPin, MessageSquare, Phone, UserRound } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { useSync, type FrontlineSyncActivity } from '@/shared/context/SyncContext';

const PROGRAMS: Record<string, { title: string; actions: string[] }> = {
  anc: { title: 'Antenatal care (ANC)', actions: ['Review BP, gestational age and haemoglobin', 'Escalate pre-eclampsia, bleeding or reduced fetal movement', 'Assign ANM/medical officer and confirm delivery plan'] },
  pnc: { title: 'Postnatal care (PNC)', actions: ['Review maternal and newborn danger signs', 'Check fever, bleeding, breastfeeding, BP and mental health', 'Assign postnatal/newborn review and counselling'] },
  immunization: { title: 'Immunization', actions: ['Confirm child identity and vaccine dose', 'Approve/correct the record and schedule missed or next doses', 'Review AEFI and escalate serious reactions'] },
  ncd: { title: 'NCD screening', actions: ['Review BP, glucose, CBAC score and risk factors', 'Confirm screening result and refer suspected cases', 'Schedule chronic-care follow-up'] },
  hbnc: { title: 'HBNC / HBYC', actions: ['Review feeding, breathing, temperature and growth', 'Arrange urgent SNCU/PHC referral for danger signs', 'Send KMC, breastfeeding, nutrition and follow-up guidance'] },
  tb: { title: 'TB support', actions: ['Review symptoms and sputum/sample information', 'Assign sputum testing, CBNAAT or Truenat', 'Track treatment enrolment, adherence and household contact tracing'] },
};

function categoryForProgram(program: string): FrontlineSyncActivity['category'][] {
  if (program === 'anc') return ['Maternal (ANC)'];
  if (program === 'pnc') return ['Postnatal (PNC)'];
  if (program === 'immunization') return ['Immunization'];
  if (program === 'ncd') return ['NCD Screening'];
  if (program === 'hbnc') return ['HBNC', 'HBYC', 'Child (IMNCI)'];
  return ['TB'];
}

function ActivityRecord({ item }: { item: FrontlineSyncActivity }) {
  const navigate = useNavigate();
  return (
    <Card className="p-5 bg-white dark:bg-[#222224] border-slate-200 dark:border-[#2E2E2E]">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-sm font-black text-slate-900 dark:text-white">{item.patientName || 'Unnamed patient/member'}</h2>
            <span className={`rounded-full px-2 py-0.5 text-[10px] font-black ${item.severity === 'RED' ? 'bg-rose-100 text-rose-700' : item.severity === 'YELLOW' ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}>{item.severity || 'GREEN'}</span>
          </div>
          <p className="mt-1 text-xs text-slate-500">{item.details || item.clinicalPayload || 'Clinical packet received'}</p>
        </div>
        <span className="rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-bold text-emerald-700">{item.status}</span>
      </div>

      <div className="mt-4 grid gap-3 text-xs text-slate-600 dark:text-slate-300 sm:grid-cols-2 lg:grid-cols-4">
        <div className="flex gap-2"><UserRound className="h-4 w-4 text-slate-400" /><span><b>ASHA:</b> {item.workerName}<br />{item.workerPhone || 'Phone unavailable'}</span></div>
        <div className="flex gap-2"><MapPin className="h-4 w-4 text-slate-400" /><span><b>Village:</b> {item.village || 'Not recorded'}</span></div>
        <div className="flex gap-2"><CalendarClock className="h-4 w-4 text-slate-400" /><span><b>Submitted:</b> {item.syncTime}<br />{item.channel}</span></div>
        <div><b>Vitals:</b> {item.vitalsSummary || 'Not recorded'}</div>
      </div>

      {item.dangerSigns && item.dangerSigns.length > 0 && <div className="mt-4 rounded-lg bg-rose-50 p-3 text-xs text-rose-800"><b>Danger signs:</b> {item.dangerSigns.join(' · ')}</div>}
      <div className="mt-4 grid gap-3 lg:grid-cols-2">
        <div className="rounded-lg bg-slate-50 p-3 text-xs text-slate-700 dark:bg-[#19191C] dark:text-slate-300"><b>Clinical findings</b><p className="mt-1 whitespace-pre-wrap">{item.clinicalPayload || 'No clinical narrative received.'}</p></div>
        <div className="rounded-lg bg-slate-50 p-3 text-xs text-slate-700 dark:bg-[#19191C] dark:text-slate-300"><b>Attachments</b><div className="mt-2 flex flex-wrap gap-2">{item.attachments?.length ? item.attachments.map((attachment) => <a key={`${item.id}-${attachment.index}`} href={attachment.url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 rounded-md bg-white px-2 py-1 font-semibold text-emerald-700 shadow-sm"><>{attachment.type === 'image' ? <FileImage className="h-3.5 w-3.5" /> : <FileAudio className="h-3.5 w-3.5" />}</>{attachment.type} <ExternalLink className="h-3 w-3" /></a>) : <span>No image/audio/file attached</span>}</div></div>
      </div>

      <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-slate-100 pt-4 dark:border-slate-800">
        <button onClick={() => navigate(`/phc${item.ticketId ? `?ticket=${encodeURIComponent(item.ticketId)}` : ''}`)} className="inline-flex items-center gap-2 rounded-lg bg-[#0C5A3E] px-3 py-2 text-xs font-bold text-white hover:bg-[#094832]"><MessageSquare className="h-3.5 w-3.5" />Open PHC action queue</button>
        {item.workerPhone && <a href={`tel:${item.workerPhone}`} className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"><Phone className="h-3.5 w-3.5" />Call ASHA</a>}
      </div>
    </Card>
  );
}

export function ClinicalProgramDetailPage() {
  const { program = '' } = useParams();
  const config = PROGRAMS[program.toLowerCase()];
  const { syncActivities, lastSyncTime, isSyncing, triggerManualSync } = useSync();
  const records = useMemo(() => config ? syncActivities.filter((item) => categoryForProgram(program.toLowerCase()).includes(item.category)) : [], [config, program, syncActivities]);

  if (!config) return <div className="p-8"><p className="text-sm text-slate-600">Clinical program not found.</p><Link to="/clinical-programs" className="mt-3 inline-block text-sm font-bold text-emerald-700">Back to programs</Link></div>;

  return <div className="mx-auto max-w-7xl space-y-6 p-4 lg:p-8">
    <div className="flex flex-wrap items-start justify-between gap-4"><div><Link to="/clinical-programs" className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700"><ArrowLeft className="h-3.5 w-3.5" />All clinical programs</Link><h1 className="mt-3 text-xl font-black text-slate-900 dark:text-white">{config.title}</h1><p className="mt-1 text-xs text-slate-500">Live records received from the ASHA app through the server sync queue. Last sync: {lastSyncTime}.</p></div><button onClick={() => triggerManualSync()} disabled={isSyncing} className="rounded-lg border border-emerald-200 px-3 py-2 text-xs font-bold text-emerald-700 disabled:opacity-50">{isSyncing ? 'Syncing…' : 'Refresh live records'}</button></div>
    <Card className="p-5 bg-emerald-50 dark:bg-[#132A20] border-emerald-100 dark:border-[#1E4334]"><h2 className="text-sm font-black text-emerald-900 dark:text-emerald-100">PHC review checklist</h2><div className="mt-3 grid gap-2 text-xs text-emerald-900 dark:text-emerald-100 md:grid-cols-3">{config.actions.map((action) => <div key={action} className="flex gap-2"><CheckCircle2 className="h-4 w-4 shrink-0" />{action}</div>)}</div><p className="mt-4 text-xs text-emerald-800 dark:text-emerald-200">Use the PHC action queue on each record to assign priority, facility/person, follow-up and instructions back to ASHA. The response is timestamped and appears in the worker workflow when the next sync completes.</p></Card>
    <div className="space-y-4">{records.map((item) => <ActivityRecord key={item.id} item={item} />)}{records.length === 0 && <Card className="p-8 text-center text-xs text-slate-500">No authenticated {config.title} records have been synced yet.</Card>}</div>
  </div>;
}
