import { useMemo } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, RefreshCw, MessageSquare, Phone, Activity, FileImage, FileAudio, ExternalLink } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { useSync, type FrontlineSyncActivity } from '@/shared/context/SyncContext';
import { apiClient } from '@/shared/api/client';

const PROGRAMS: Record<string, { title: string; subtitle: string; actions: string[] }> = {
  anc: {
    title: 'Antenatal care (ANC)',
    subtitle: 'Maternal health, vitals, hemoglobin checks, and pregnancy follow-ups received from ASHA stream.',
    actions: ['Review BP, gestational age and haemoglobin', 'Escalate pre-eclampsia, bleeding or reduced fetal movement', 'Assign ANM/medical officer and confirm delivery plan'],
  },
  pnc: {
    title: 'Postnatal care (PNC)',
    subtitle: 'Postpartum mother and newborn checks received from the authenticated ASHA sync stream.',
    actions: ['Review maternal and newborn danger signs', 'Check fever, bleeding, breastfeeding, BP and mental health', 'Assign postnatal/newborn review and counselling'],
  },
  immunization: {
    title: 'Immunization Registry',
    subtitle: 'Vaccine due lists, dose completions, and session records received from ASHA frontline workers.',
    actions: ['Confirm child identity and vaccine dose', 'Approve/correct the record and schedule missed or next doses', 'Review AEFI and escalate serious reactions'],
  },
  ncd: {
    title: 'NCD Screening',
    subtitle: 'Hypertension, diabetes, CBAC risk scores, and chronic disease follow-ups synced from field surveys.',
    actions: ['Review BP, glucose, CBAC score and risk factors', 'Confirm screening result and refer suspected cases', 'Schedule chronic-care follow-up'],
  },
  hbnc: {
    title: 'HBNC / HBYC',
    subtitle: 'Home-based newborn and young child care visits, feeding, and growth monitoring records.',
    actions: ['Review feeding, breathing, temperature and growth', 'Arrange urgent SNCU/PHC referral for danger signs', 'Send KMC, breastfeeding, nutrition and follow-up guidance'],
  },
  tb: {
    title: 'TB Support & Screening',
    subtitle: 'Presumptive tuberculosis screenings, sputum transport status, and adherence records.',
    actions: ['Review symptoms and sputum/sample information', 'Assign sputum testing, CBNAAT or Truenat', 'Track treatment enrolment, adherence and household contact tracing'],
  },
};

function categoryForProgram(program: string): FrontlineSyncActivity['category'][] {
  if (program === 'anc') return ['Maternal (ANC)'];
  if (program === 'pnc') return ['Postnatal (PNC)'];
  if (program === 'immunization') return ['Immunization'];
  if (program === 'ncd') return ['NCD Screening'];
  if (program === 'hbnc') return ['HBNC', 'HBYC', 'Child (IMNCI)'];
  return ['TB'];
}

export function ClinicalProgramDetailPage() {
  const { program = '' } = useParams();
  const config = PROGRAMS[program.toLowerCase()];
  const navigate = useNavigate();
  const { syncActivities, lastSyncTime, isSyncing, triggerManualSync } = useSync();
  const takeAction = async (item: FrontlineSyncActivity) => {
    const encounterId = item.recordId;
    if (!encounterId) { window.alert('This record has no clinical encounter ID yet. Refresh after the next server sync.'); return; }
    const decision = window.prompt('PHC decision (Reviewed / Follow-up assigned / Referred):', 'Reviewed');
    if (!decision) return;
    const instructions = window.prompt('Instructions for ASHA:', 'Continue routine follow-up and counselling.');
    if (!instructions) return;
    await apiClient.post(`/referrals/clinical/${encodeURIComponent(encounterId)}/action`, { decision, instructions });
    window.alert('PHC action saved. It will appear in the ASHA app after sync.');
    await triggerManualSync();
  };

  const records = useMemo(() => {
    if (!config) return [];
    return syncActivities.filter((item) =>
      categoryForProgram(program.toLowerCase()).includes(item.category)
    );
  }, [config, program, syncActivities]);

  if (!config) {
    return (
      <div className="p-8 max-w-7xl mx-auto space-y-4">
        <p className="text-sm text-slate-600">Clinical program not found.</p>
        <Link to="/clinical-programs" className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-700 hover:underline">
          <ArrowLeft className="h-3.5 w-3.5" /> Back to clinical programs
        </Link>
      </div>
    );
  }

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Top Header matching HouseholdsPage */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <Link
            to="/clinical-programs"
            className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 hover:text-emerald-800 mb-2"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> All clinical programs
          </Link>
          <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">{config.title}</h1>
          <p className="text-xs text-slate-500 mt-1">{config.subtitle}</p>
        </div>
        <button
          onClick={() => triggerManualSync()}
          disabled={isSyncing}
          className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
          {isSyncing ? 'Syncing…' : 'Refresh'}
        </button>
      </div>

      {/* Sync Status Banner */}
      <Card className="p-4 text-xs text-slate-500 flex flex-wrap items-center justify-between gap-2">
        <span>Last server sync: <strong className="text-slate-700 dark:text-slate-300">{lastSyncTime || 'Not synced yet'}</strong></span>
        <span className="text-[11px] font-semibold text-slate-400">{records.length} records in this program</span>
      </Card>

      {/* Program Checklist / Overview Card */}
      <Card className="p-5 bg-white dark:bg-[#222224] border-slate-200 dark:border-[#2E2E2E]">
        <h2 className="text-sm font-black text-slate-900 dark:text-white">PHC Review & Action Guidelines</h2>
        <div className="mt-3 grid grid-cols-1 md:grid-cols-3 gap-2.5 text-xs text-slate-600 dark:text-slate-300">
          {config.actions.map((action, i) => (
            <div key={i} className="flex items-start gap-2 bg-slate-50 dark:bg-[#19191C] p-2.5 rounded-lg border border-slate-100 dark:border-slate-800">
              <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-[10px] font-black text-emerald-800">
                {i + 1}
              </span>
              <span className="leading-5">{action}</span>
            </div>
          ))}
        </div>
      </Card>

      {/* Record List Grid (matching HouseholdsPage 2-column cards layout) */}
      {records.length === 0 ? (
        <Card className="p-10 text-center text-sm text-slate-500">
          <Activity className="mx-auto mb-3 h-8 w-8 text-slate-300" />
          No authenticated {config.title} records have been synced yet.
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {records.map((item) => (
            <Card key={item.id} className="p-5 flex flex-col justify-between">
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 className="text-sm font-black text-slate-900 dark:text-white">
                      {item.patientName || 'Beneficiary Record'}
                    </h2>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {item.patientAge ? `${item.patientAge} yrs` : 'Age not provided'} · {item.patientGender || 'Gender not provided'}
                    </p>
                  </div>
                  <div className="flex items-center gap-1.5">
                    {item.severity && (
                      <span
                        className={`rounded-full px-2 py-0.5 text-[10px] font-black ${
                          item.severity === 'RED'
                            ? 'bg-rose-100 text-rose-700'
                            : item.severity === 'YELLOW'
                            ? 'bg-amber-100 text-amber-700'
                            : 'bg-emerald-100 text-emerald-700'
                        }`}
                      >
                        {item.severity}
                      </span>
                    )}
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-bold text-emerald-700">
                      {item.status || 'Synced'}
                    </span>
                  </div>
                </div>

                <dl className="mt-4 grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <dt className="text-slate-400">Village</dt>
                    <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.village || '—'}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-400">ASHA worker</dt>
                    <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerName}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-400">Worker phone</dt>
                    <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerPhone || '—'}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-400">Last update</dt>
                    <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.syncTime}</dd>
                  </div>
                  {item.vitalsSummary && (
                    <div className="col-span-2">
                      <dt className="text-slate-400">Vitals recorded</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.vitalsSummary}</dd>
                    </div>
                  )}
                </dl>

                {item.dangerSigns && item.dangerSigns.length > 0 && (
                  <div className="mt-3 rounded-lg bg-rose-50 p-2.5 text-xs text-rose-800 dark:bg-rose-950/30 dark:text-rose-300">
                    <span className="font-bold">Danger signs:</span> {item.dangerSigns.join(' · ')}
                  </div>
                )}

                <p className="mt-4 border-t border-slate-100 pt-3 text-xs leading-5 text-slate-500 dark:border-slate-800 dark:text-slate-400">
                  {item.details || item.clinicalPayload || 'Clinical packet synced from mobile app.'}
                </p>

                {item.attachments && item.attachments.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {item.attachments.map((attachment) => (
                      <a
                        key={`${item.id}-${attachment.index}`}
                        href={attachment.url}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800 px-2 py-1 text-[11px] font-semibold text-emerald-700 dark:text-emerald-400 hover:bg-slate-200"
                      >
                        {attachment.type === 'image' ? <FileImage className="h-3 w-3" /> : <FileAudio className="h-3 w-3" />}
                        {attachment.type} <ExternalLink className="h-2.5 w-2.5" />
                      </a>
                    ))}
                  </div>
                )}
              </div>

              <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-slate-100 pt-3 dark:border-slate-800">
                <button
                  onClick={() => takeAction(item)}
                  className="inline-flex items-center gap-1.5 rounded-lg bg-[#0C5A3E] px-3 py-1.5 text-xs font-bold text-white hover:bg-[#094832]"
                >
                  <MessageSquare className="h-3.5 w-3.5" /> PHC Action
                </button>
                {item.workerPhone && (
                  <a
                    href={`tel:${item.workerPhone}`}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                  >
                    <Phone className="h-3.5 w-3.5" /> Call ASHA
                  </a>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
