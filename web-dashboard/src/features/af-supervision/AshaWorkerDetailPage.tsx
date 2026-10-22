import { useState, useMemo } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { useSync } from '@/shared/context/SyncContext';
import { INITIAL_ASHA_CARDS } from '@/shared/api/mockData';
import {
  ArrowLeft,
  Phone,
  Radio,
  Users,
  Award,
  ClipboardCheck,
  AlertCircle,
  CheckCircle2,
  BookOpen,
  Sparkles,
  Activity,
  Layers,
  Clock,
  ShieldCheck,
  Heart,
  Baby,
  FileText,
  Stethoscope,
  Search,
  ExternalLink,
} from 'lucide-react';

export function AshaWorkerDetailPage() {
  const navigate = useNavigate();
  const { name = '' } = useParams();
  const workerName = decodeURIComponent(name);
  const { syncActivities } = useSync();

  const [activitySearch, setActivitySearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');

  // Look up worker profile from cards or create rich synthesized profile
  const workerProfile = useMemo(() => {
    const found = INITIAL_ASHA_CARDS.find(
      (c) => c.ashaName.toLowerCase() === workerName.toLowerCase()
    );
    if (found) return found;

    return {
      ashaId: 'asha-frontline',
      ashaName: workerName || 'ASHA Worker',
      phone: '+91 98765 00000',
      village: 'Catchment Area',
      hamletsCount: 3,
      lastSyncAt: new Date().toISOString(),
      coveragePct: 91.5,
      overdueVisitsCount: 1,
      pendingReferralsCount: 1,
      recentRedFlagsCount: 1,
      dataQualityScorePct: 96,
      learningModulesCompleted: 12,
      totalAssignedHouseholds: 210,
      mentoringFlags: [
        {
          type: 'positive' as const,
          message: 'Consistent home visit coverage across all assigned hamlets.',
        },
      ],
    };
  }, [workerName]);

  // All activities by this worker
  const workerActivities = useMemo(() => {
    return syncActivities.filter(
      (item) => item.workerName.toLowerCase() === workerName.toLowerCase()
    );
  }, [syncActivities, workerName]);

  // Filtered activities
  const filteredActivities = useMemo(() => {
    return workerActivities.filter((act) => {
      if (selectedCategory !== 'ALL' && act.category !== selectedCategory) return false;
      if (activitySearch.trim()) {
        const q = activitySearch.toLowerCase();
        return (
          act.details.toLowerCase().includes(q) ||
          act.clinicalPayload.toLowerCase().includes(q) ||
          (act.patientName && act.patientName.toLowerCase().includes(q)) ||
          (act.abhaId && act.abhaId.toLowerCase().includes(q))
        );
      }
      return true;
    });
  }, [workerActivities, selectedCategory, activitySearch]);

  const urgentTasksCount = workerActivities.filter((a) => a.severity === 'RED').length;

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* 1. Top Navigation & Breadcrumbs */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/af')}
          className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 dark:text-slate-300 hover:text-emerald-700 dark:hover:text-emerald-400 cursor-pointer transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to ASHA Team List</span>
        </button>

        <div className="text-xs text-slate-400">
          Supervision &gt; <span className="text-slate-600 dark:text-slate-200 font-semibold">{workerProfile.ashaName}</span>
        </div>
      </div>

      {/* 2. Hero Header Worker Profile Card */}
      <Card className="p-6 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] shadow-xs">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          {/* Left: Avatar + Identification */}
          <div className="flex items-start sm:items-center gap-4">
            <div className="relative">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-600 to-teal-800 text-white flex items-center justify-center font-black text-xl shadow-md">
                {workerProfile.ashaName.split(' ').map((n) => n[0]).join('')}
              </div>
              <span className="absolute -bottom-1 -right-1 h-4 w-4 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#1E1E1E]" />
            </div>

            <div>
              <div className="flex flex-wrap items-center gap-2.5">
                <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">
                  {workerProfile.ashaName}
                </h1>
                <Badge variant="outline" className="font-mono text-xs bg-slate-50 dark:bg-[#252528]">
                  {workerProfile.ashaId}
                </Badge>
                <Badge className="bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300 border-0">
                  Active Frontline Worker
                </Badge>
              </div>

              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 flex flex-wrap items-center gap-2">
                <span className="font-semibold text-slate-700 dark:text-slate-200">{workerProfile.village}</span>
                <span>•</span>
                <span>{workerProfile.hamletsCount} Hamlets Assigned</span>
                <span>•</span>
                <span>Sector: Shahpur Central</span>
                <span>•</span>
                <span>Facilitator: Sarita Singh</span>
              </p>

              <div className="mt-2 flex items-center gap-2 text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                <Radio className="w-3.5 h-3.5 animate-pulse" />
                <span>Last Gateway Sync: {new Date(workerProfile.lastSyncAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                <span className="text-slate-300 dark:text-slate-600">|</span>
                <span className="text-slate-500 font-mono">Device: Samsung Tab A9 (ABDM-v2.4)</span>
              </div>
            </div>
          </div>

          {/* Right: Quick Action Buttons */}
          <div className="flex flex-wrap items-center gap-2.5">
            <a
              href={`tel:${workerProfile.phone}`}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 dark:bg-[#28282B] hover:bg-slate-200 dark:hover:bg-[#323236] text-slate-800 dark:text-slate-200 text-xs font-semibold transition-colors"
            >
              <Phone className="w-3.5 h-3.5 text-emerald-600" />
              <span>Call {workerProfile.phone}</span>
            </a>

            <Button
              onClick={() => navigate('/af')}
              variant="outline"
              size="sm"
              className="text-xs gap-1.5 cursor-pointer"
            >
              <ClipboardCheck className="w-3.5 h-3.5 text-amber-600" />
              <span>Supervision Checklist</span>
            </Button>

            <Button
              onClick={() => navigate('/af')}
              size="sm"
              className="bg-amber-500/10 hover:bg-amber-500/20 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-500/30 text-xs gap-1.5 shadow-none cursor-pointer"
            >
              <Award className="w-3.5 h-3.5 text-amber-600" />
              <span>Award Recognition</span>
            </Button>
          </div>
        </div>
      </Card>

      {/* 3. Key Performance Indicators (6 Cards Grid) */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {/* Coverage Rate */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Coverage Rate</div>
          <div className={`text-2xl font-black mt-1 ${workerProfile.coveragePct >= 90 ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600'}`}>
            {workerProfile.coveragePct}%
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">Target: &gt;= 90%</div>
        </Card>

        {/* Assigned Households */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Assigned HHs</div>
          <div className="text-2xl font-black mt-1 text-slate-900 dark:text-white">
            {workerProfile.totalAssignedHouseholds}
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">{workerProfile.hamletsCount} remote hamlets</div>
        </Card>

        {/* Overdue Visits */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Overdue Visits</div>
          <div className={`text-2xl font-black mt-1 ${workerProfile.overdueVisitsCount > 4 ? 'text-rose-600' : workerProfile.overdueVisitsCount > 0 ? 'text-amber-600' : 'text-emerald-600'}`}>
            {workerProfile.overdueVisitsCount}
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">Visits requiring follow-up</div>
        </Card>

        {/* Data Quality Score */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Data Quality</div>
          <div className="text-2xl font-black mt-1 text-indigo-600 dark:text-indigo-400">
            {workerProfile.dataQualityScorePct}%
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">GPS &amp; timestamp audit</div>
        </Card>

        {/* Learning Modules */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Learning Progress</div>
          <div className="text-2xl font-black mt-1 text-amber-600 dark:text-amber-400">
            {workerProfile.learningModulesCompleted} / 16
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">Micro-lessons completed</div>
        </Card>

        {/* Critical Triages */}
        <Card className="p-4 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E]">
          <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">High-Risk Triages</div>
          <div className="text-2xl font-black mt-1 text-rose-600 dark:text-rose-400">
            {urgentTasksCount}
          </div>
          <div className="text-[10px] text-slate-500 mt-0.5">Escalated to PHC Desk</div>
        </Card>
      </div>

      {/* 4. Clinical Programs Performance Breakdown */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <Stethoscope className="w-4 h-4 text-emerald-600" />
          <h2 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider">
            Clinical Programs Coverage &amp; Delivery Breakdown
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Maternal Health (ANC) */}
          <Card className="p-5 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Heart className="w-3.5 h-3.5 text-rose-500" />
                <span>Maternal Health (ANC)</span>
              </span>
              <Badge className="bg-rose-50 text-rose-700 dark:bg-rose-950/40 text-[10px]">RMNCH+A</Badge>
            </div>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Registered ANC Mothers</span>
                <span className="font-bold text-slate-900 dark:text-white">28</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>High-Risk Pregnancies Flagged</span>
                <span className="font-bold text-rose-600">4 cases</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>4+ ANC Checkup Completion</span>
                <span className="font-bold text-emerald-600">92.8%</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>IFA 180-Day Supply Dispensed</span>
                <span className="font-bold text-slate-900 dark:text-white">96.0%</span>
              </div>
            </div>
          </Card>

          {/* Child Health (IMNCI) */}
          <Card className="p-5 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Baby className="w-3.5 h-3.5 text-blue-500" />
                <span>Child Health (IMNCI)</span>
              </span>
              <Badge className="bg-blue-50 text-blue-700 dark:bg-blue-950/40 text-[10px]">Under-5</Badge>
            </div>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Under-5 Children Monitored</span>
                <span className="font-bold text-slate-900 dark:text-white">64</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>PSBI Fast Breathing Screened</span>
                <span className="font-bold text-slate-900 dark:text-white">8 infants</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Full Immunization (0-1y)</span>
                <span className="font-bold text-emerald-600">95.2%</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>ORS + Zinc Diarrhea Protocol</span>
                <span className="font-bold text-emerald-600">100% compliant</span>
              </div>
            </div>
          </Card>

          {/* Postnatal Care (HBNC) */}
          <Card className="p-5 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                <span>Postnatal Care (HBNC)</span>
              </span>
              <Badge className="bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 text-[10px]">HBNC</Badge>
            </div>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>HBNC Home Visits Due/Done</span>
                <span className="font-bold text-slate-900 dark:text-white">42 / 44 visits</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Exclusive Breastfeeding Support</span>
                <span className="font-bold text-emerald-600">97.0%</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Newborn Hypothermia Wrap</span>
                <span className="font-bold text-slate-900 dark:text-white">100% verified</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Maternal PPH Danger Signs Checked</span>
                <span className="font-bold text-emerald-600">100%</span>
              </div>
            </div>
          </Card>

          {/* NCD & Infectious Disease */}
          <Card className="p-5 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Activity className="w-3.5 h-3.5 text-indigo-500" />
                <span>NCD &amp; Communicable</span>
              </span>
              <Badge className="bg-indigo-50 text-indigo-700 dark:bg-indigo-950/40 text-[10px]">NP-NCD / NTEP</Badge>
            </div>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>CBAC Forms Completed (30+ yrs)</span>
                <span className="font-bold text-slate-900 dark:text-white">142</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Hypertension Screened</span>
                <span className="font-bold text-slate-900 dark:text-white">110 (8 flagged)</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>Diabetes RBS Screening</span>
                <span className="font-bold text-slate-900 dark:text-white">85 screened</span>
              </div>
              <div className="flex justify-between text-slate-600 dark:text-slate-300">
                <span>TB Presumptive Referrals</span>
                <span className="font-bold text-indigo-600">3 for CBNAAT</span>
              </div>
            </div>
          </Card>
        </div>
      </div>

      {/* 5. Mentoring Guidance & Supervisory Notes */}
      {workerProfile.mentoringFlags && workerProfile.mentoringFlags.length > 0 && (
        <Card className="p-5 bg-gradient-to-r from-amber-50/70 to-emerald-50/50 dark:from-amber-950/20 dark:to-emerald-950/10 border-amber-200/80 dark:border-amber-500/20">
          <div className="flex items-center gap-2 mb-3">
            <Sparkles className="w-4 h-4 text-amber-600" />
            <h3 className="text-xs font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Supportive Supervision &amp; Mentoring Feedback
            </h3>
          </div>

          <div className="space-y-2">
            {workerProfile.mentoringFlags.map((flag, idx) => (
              <div
                key={idx}
                className="p-3 rounded-xl bg-white/90 dark:bg-[#1E1E1E] border border-amber-200 dark:border-[#2E2E2E] text-xs flex items-start gap-2.5"
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div className="space-y-0.5">
                  <div className="font-semibold text-slate-800 dark:text-slate-200">{flag.message}</div>
                  {flag.suggestedModule && (
                    <div className="text-[11px] text-slate-500 flex items-center gap-1">
                      <BookOpen className="w-3 h-3 text-amber-600" />
                      <span>Recommended Refresher Module: <span className="font-mono text-amber-700 dark:text-amber-400 font-bold">{flag.suggestedModule}</span></span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* 6. Complete Activity Log for this Worker */}
      <Card className="p-5 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100 dark:border-[#28282C]">
          <div>
            <h2 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <Radio className="h-4 w-4 text-emerald-600" />
              <span>Complete Frontline Field Activity Records</span>
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Verified inbound packets submitted by {workerProfile.ashaName} and synced via ABDM Gateway.
            </p>
          </div>

          {/* Quick link to System Logs */}
          <Link
            to="/logs"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-700 dark:text-emerald-400 hover:underline"
          >
            <span>View in Global System Logs</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>
        </div>

        {/* Filters & Search */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={activitySearch}
              onChange={(e) => setActivitySearch(e.target.value)}
              placeholder="Search beneficiary, details, or ABHA..."
              className="w-full pl-9 pr-3 h-9 rounded-lg bg-slate-50 dark:bg-[#252528] border border-slate-200 dark:border-[#323236] text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div className="flex flex-wrap items-center gap-1.5">
            {['ALL', 'Maternal (ANC)', 'Child (IMNCI)', 'Postnatal (PNC)', 'NCD Screening', 'Immunization'].map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-semibold transition-colors cursor-pointer ${
                  selectedCategory === cat
                    ? 'bg-emerald-700 text-white shadow-xs'
                    : 'bg-slate-100 dark:bg-[#252528] text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Activity Items List */}
        <div className="divide-y divide-slate-100 dark:divide-[#28282C]">
          {filteredActivities.map((act) => (
            <div key={act.id} className="py-4 flex flex-col md:flex-row md:items-start justify-between gap-3 text-xs">
              <div className="flex items-start gap-3 flex-1">
                <span
                  className={`mt-1 h-2.5 w-2.5 rounded-full shrink-0 ${
                    act.severity === 'RED'
                      ? 'bg-rose-500 ring-4 ring-rose-100 dark:ring-rose-950/60'
                      : act.severity === 'YELLOW'
                      ? 'bg-amber-500 ring-4 ring-amber-100 dark:ring-amber-950/60'
                      : 'bg-emerald-500 ring-4 ring-emerald-100 dark:ring-emerald-950/60'
                  }`}
                />

                <div className="space-y-1 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-bold text-slate-900 dark:text-white text-sm">
                      {act.details}
                    </span>
                    <Badge variant="outline" className="text-[10px]">
                      {act.category}
                    </Badge>
                    {act.ticketId && (
                      <span className="font-mono text-[10px] bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 px-2 py-0.5 rounded border border-rose-200 dark:border-rose-900">
                        {act.ticketId}
                      </span>
                    )}
                  </div>

                  <p className="text-slate-600 dark:text-slate-300 text-xs">
                    {act.clinicalPayload}
                  </p>

                  <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 pt-1">
                    {act.patientName && (
                      <span>Beneficiary: <strong className="text-slate-700 dark:text-slate-200">{act.patientName} ({act.patientAge || 'Age N/A'}, {act.patientGender || 'Gender N/A'})</strong></span>
                    )}
                    {act.abhaId && (
                      <span className="font-mono">ABHA: {act.abhaId}</span>
                    )}
                    {act.vitalsSummary && (
                      <span className="font-mono bg-slate-50 dark:bg-[#252528] px-1.5 py-0.5 rounded border border-slate-200 dark:border-[#323236]">
                        {act.vitalsSummary}
                      </span>
                    )}
                    <span>Channel: {act.channel}</span>
                  </div>
                </div>
              </div>

              <div className="flex md:flex-col items-center md:items-end justify-between md:justify-start gap-2 shrink-0">
                <span className="text-slate-400 font-mono text-[11px] flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {act.syncTime}
                </span>

                <Link
                  to={`/logs?search=${encodeURIComponent(act.patientName || act.workerName)}`}
                  className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-600 hover:text-emerald-700"
                >
                  <span>Inspect Ticket</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          ))}

          {filteredActivities.length === 0 && (
            <div className="py-10 text-center text-slate-500 text-xs">
              No matching activity records found for this worker.
            </div>
          )}
        </div>
      </Card>
    </div>
  );
}
