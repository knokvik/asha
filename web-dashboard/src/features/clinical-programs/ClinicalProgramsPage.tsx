import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Activity, Baby, ClipboardList, HeartPulse, Syringe, Thermometer, ArrowRight } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { useSync } from '@/shared/context/SyncContext';

const PROGRAMS = [
  { code: 'ANC', title: 'Antenatal care', description: 'Pregnancy registration, risk screening and follow-up visits.', icon: HeartPulse, color: 'text-rose-600 bg-rose-50' },
  { code: 'PNC', title: 'Postnatal care', description: 'Mother and newborn checks after delivery.', icon: Baby, color: 'text-blue-600 bg-blue-50' },
  { code: 'IMMUNIZATION', title: 'Immunization', description: 'Due vaccines, session follow-up and missed-dose tracking.', icon: Syringe, color: 'text-amber-600 bg-amber-50' },
  { code: 'NCD', title: 'NCD screening', description: 'CBAC screening and hypertension/diabetes follow-up.', icon: Thermometer, color: 'text-violet-600 bg-violet-50' },
  { code: 'HBNC', title: 'HBNC / HBYC', description: 'Home-based newborn and young-child care visits.', icon: ClipboardList, color: 'text-emerald-600 bg-emerald-50' },
  { code: 'TB', title: 'TB support', description: 'Presumptive screening, referral and treatment support.', icon: Activity, color: 'text-orange-600 bg-orange-50' },
];

export function ClinicalProgramsPage() {
  const navigate = useNavigate();
  const { syncActivities } = useSync();
  const counts = useMemo(() => syncActivities.reduce<Record<string, number>>((result, item) => {
    const key = item.category.includes('Maternal') ? 'ANC' : item.category.includes('Postnatal') ? 'PNC' : item.category.includes('Immunization') ? 'IMMUNIZATION' : item.category.includes('NCD') ? 'NCD' : item.category.includes('Child') ? 'HBNC' : 'TB';
    result[key] = (result[key] || 0) + 1;
    return result;
  }, {}), [syncActivities]);

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      <div><h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">Clinical Programs</h1><p className="text-xs text-slate-500 mt-1">The same ANC, PNC, child, NCD, immunization and TB workflows available to ASHA workers in the mobile app.</p></div>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {PROGRAMS.map((program) => { const Icon = program.icon; return <Card key={program.code} className="p-5 bg-white dark:bg-[#222224] border-slate-200 dark:border-[#2E2E2E] hover:border-emerald-300 transition-colors"><div className="flex items-start justify-between gap-3"><div className={`h-10 w-10 rounded-xl flex items-center justify-center ${program.color}`}><Icon className="h-5 w-5" /></div><span className="text-xs font-bold text-slate-500">{counts[program.code] || 0} synced</span></div><h2 className="mt-4 text-sm font-black text-slate-900 dark:text-white">{program.title}</h2><p className="mt-1 text-xs leading-5 text-slate-500 dark:text-slate-400">{program.description}</p><button onClick={() => navigate(`/clinical-programs/${program.code.toLowerCase()}`)} className="mt-4 inline-flex items-center gap-1 text-xs font-bold text-emerald-700 hover:text-emerald-800">Open operation page <ArrowRight className="h-3.5 w-3.5" /></button></Card>; })}
      </div>
      <Card className="p-5 bg-white dark:bg-[#222224] border-slate-200 dark:border-[#2E2E2E]"><h2 className="text-sm font-black text-slate-900 dark:text-white">Recent program activity</h2><div className="mt-3 divide-y divide-slate-100 dark:divide-slate-800">{syncActivities.slice(0, 6).map((item) => <div key={item.id} className="py-2.5 flex items-center gap-3 text-xs"><span className="font-bold text-slate-700 dark:text-slate-200">{item.category}</span><span className="truncate text-slate-500">{item.details}</span><span className="ml-auto text-slate-400">{item.syncTime}</span></div>)}{syncActivities.length === 0 && <p className="py-3 text-xs text-slate-500">No authenticated program packets have arrived yet.</p>}</div></Card>
    </div>
  );
}
