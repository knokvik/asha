import { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getAshaPerformanceCards,
  submitSupervisionChecklist,
  sendAshaRecognition,
} from '@/shared/api/supervisionApi';
import { useSync, type TriageEvidence } from '@/shared/context/SyncContext';
import { apiClient } from '@/shared/api/client';
import { AshaPerformanceCard, SupervisionChecklist } from '@/types';
import {
  Users,
  Award,
  ClipboardCheck,
  AlertCircle,
  CheckCircle2,
  BookOpen,
  Sparkles,
  Phone,
  Search,
  X,
  Star,
  RefreshCw,
  Activity,
  Layers,
  Clock,
  Radio,
  ShieldCheck,
  ArrowRight,
  Filter,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ImciAshaTable } from '@/features/af-supervision/ImciAshaTable';

export function AFSupervisionPage() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const urlSearch = searchParams.get('search') || searchParams.get('worker') || '';
  const urlTab = searchParams.get('tab');
  const [searchTerm, setSearchTerm] = useState(urlSearch);
  const [activeTab, setActiveTab] = useState<'supervision' | 'sync_feed'>(urlTab === 'sync' ? 'sync_feed' : 'supervision');

  const { syncActivities, triggerManualSync, isSyncing, lastSyncTime } = useSync();
  const [syncSearch, setSyncSearch] = useState('');
  const [syncCategoryFilter, setSyncCategoryFilter] = useState<string>('ALL');
  const [syncSeverityFilter, setSyncSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'GREEN'>('ALL');

  useEffect(() => {
    if (urlSearch) {
      setSearchTerm(urlSearch);
    }
    if (urlTab === 'sync') {
      setActiveTab('sync_feed');
    }
  }, [urlSearch, urlTab]);
  const [selectedAsha, setSelectedAsha] = useState<AshaPerformanceCard | null>(null);
  const [checklistOpen, setChecklistOpen] = useState(false);
  const [badgeModalOpen, setBadgeModalOpen] = useState(false);
  const [selectedBadge, setSelectedBadge] = useState<
    'star_performer' | 'care_champion' | 'prompt_referrer' | 'learning_master'
  >('star_performer');
  const [badgeNote, setBadgeNote] = useState('');
  const [badgeSent, setBadgeSent] = useState(false);

  // Supervision checklist form state
  const [visitType, setVisitType] = useState<SupervisionChecklist['visitType']>('household_visit');
  const [checklistScore, setChecklistScore] = useState(90);
  const [checklistNotes, setChecklistNotes] = useState('');
  const [recommendations, setRecommendations] = useState('');
  const [followUpRequired, setFollowUpRequired] = useState(false);
  const [followUpDate, setFollowUpDate] = useState('');

  const { data: ashas = [], isLoading } = useQuery({
    queryKey: ['af-supervision', 'ashas'],
    queryFn: () => getAshaPerformanceCards('af-01'),
  });

  const checklistMutation = useMutation({
    mutationFn: (data: SupervisionChecklist) => submitSupervisionChecklist(data),
    onSuccess: () => {
      setChecklistOpen(false);
      setChecklistNotes('');
      setRecommendations('');
      queryClient.invalidateQueries({ queryKey: ['af-supervision'] });
    },
  });

  const badgeMutation = useMutation({
    mutationFn: ({ ashaId, badge, msg }: { ashaId: string; badge: any; msg: string }) =>
      sendAshaRecognition(ashaId, badge, msg),
    onSuccess: () => {
      setBadgeSent(true);
      setTimeout(() => {
        setBadgeSent(false);
        setBadgeModalOpen(false);
        setBadgeNote('');
      }, 2000);
    },
  });

  const filteredAshas = ashas.filter(
    (a) =>
      a.ashaName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.village.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredSyncActivities = syncActivities.filter((act) => {
    if (syncCategoryFilter !== 'ALL' && act.category !== syncCategoryFilter) return false;
    if (syncSeverityFilter !== 'ALL') {
      if (syncSeverityFilter === 'RED' && act.severity !== 'RED') return false;
      if (syncSeverityFilter === 'YELLOW' && act.severity !== 'YELLOW') return false;
      if (syncSeverityFilter === 'GREEN' && act.severity !== 'GREEN') return false;
    }
    if (syncSearch.trim()) {
      const q = syncSearch.toLowerCase();
      const matchWorker = act.workerName.toLowerCase().includes(q);
      const matchVillage = act.village.toLowerCase().includes(q);
      const matchDetails = act.details.toLowerCase().includes(q);
      const matchPatient = act.patientName?.toLowerCase().includes(q);
      const matchPayload = act.clinicalPayload.toLowerCase().includes(q);
      if (!matchWorker && !matchVillage && !matchDetails && !matchPatient && !matchPayload) return false;
    }
    return true;
  });

  const urgentCount = syncActivities.filter((s) => s.severity === 'RED').length;

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* 1. Header Row */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
            ASHA Facilitator (AF) Supportive Supervision & Field Sync
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Facilitator: Sarita Singh • Sector: Shahpur Central • ABDM Gateway Live Sync Feed & Performance
          </p>
        </div>

        {/* Global Stats & Manual Sync Trigger */}
        <div className="flex flex-wrap items-center gap-2.5">
          <div className="flex items-center gap-2 bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] rounded-xl px-3 py-1.5 shadow-xs">
            <div className="flex flex-col">
              <span className="text-[10px] text-amber-600 dark:text-amber-400 font-semibold uppercase tracking-wider">Supervised ASHAs</span>
              <span className="text-xs font-bold text-slate-900 dark:text-white">{ashas.length} Active Workers</span>
            </div>
          </div>

          <div className="flex items-center gap-2 bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] rounded-xl px-3 py-1.5 shadow-xs">
            <div className="flex flex-col">
              <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold uppercase tracking-wider">Last Sync</span>
              <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>{lastSyncTime}</span>
              </span>
            </div>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={() => triggerManualSync()}
            disabled={isSyncing}
            className="bg-white dark:bg-[#1E1E1E] border-emerald-300 dark:border-emerald-500/40 text-[#0C5A3E] dark:text-[#34D399] hover:bg-emerald-50 dark:hover:bg-emerald-950/40 gap-1.5 shadow-xs"
            title="Trigger simulated live field synchronization packet"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
            <span>{isSyncing ? 'Syncing...' : 'Trigger Frontline Sync'}</span>
          </Button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 dark:border-[#26262A] pb-1">
        <button
          onClick={() => setActiveTab('supervision')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'supervision'
              ? 'bg-[#0C5A3E] text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-[#222226]'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>ASHA Team Supervision & Performance ({ashas.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('sync_feed')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'sync_feed'
              ? 'bg-[#0C5A3E] text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-[#222226]'
          }`}
        >
          <div className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
          </div>
          <Activity className="w-4 h-4 text-emerald-500" />
          <span>Live Frontline Data Sync Feed ({syncActivities.length})</span>
          {urgentCount > 0 && (
            <span className="px-1.5 py-0.2 rounded-full text-[10px] bg-rose-500 text-white font-bold">
              {urgentCount} RED
            </span>
          )}
        </button>
      </div>

      {activeTab === 'supervision' ? (
        /* TAB 1: ASHA Team Supervision & Performance */
        <div className="space-y-6">
          <ImciAshaTable />

          {/* Search Bar */}
          <div className="relative max-w-md">
            <Search className="w-4 h-4 text-[#71717A] absolute left-3.5 top-3" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search ASHA by name or village..."
              className="w-full pl-10 pr-4 py-2 rounded-xl bg-white dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A] focus:outline-none focus:ring-1 focus:ring-amber-500 transition-colors"
            />
          </div>

          {/* ASHA Performance Cards Grid (Req 39.1) */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {filteredAshas.map((asha) => {
              return (
                <Card
                  key={asha.ashaId}
                  className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-300 dark:hover:border-[#404040] transition-all space-y-4 shadow-xs"
                >
                  {/* Card Top: Name, Village, Sync Time */}
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center space-x-2">
                        <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">{asha.ashaName}</h2>
                        <span className="text-xs px-2 py-0.5 rounded-full bg-slate-100 dark:bg-[#2E2E2E] text-[#525252] dark:text-[#94A3B8] font-mono border border-slate-200 dark:border-[#404040]">
                          {asha.village}
                        </span>
                      </div>
                      <div className="text-xs text-[#525252] dark:text-[#94A3B8] flex items-center space-x-2 pt-0.5">
                        <span>{asha.totalAssignedHouseholds} HHs</span>
                        <span>•</span>
                        <span>{asha.hamletsCount} Hamlets</span>
                        <span>•</span>
                        <span className="text-emerald-600 dark:text-emerald-400">Synced {new Date(asha.lastSyncAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                      </div>
                    </div>

                    <a
                      href={`tel:${asha.phone}`}
                      className="p-2 rounded-xl bg-slate-100 dark:bg-[#2A2A2A] hover:bg-slate-200 dark:hover:bg-[#383838] text-[#0F172A] dark:text-[#F8FAFC] text-xs flex items-center space-x-1.5 transition-colors"
                    >
                      <Phone className="w-3.5 h-3.5 text-slate-500" />
                      <span className="hidden sm:inline font-mono">{asha.phone}</span>
                    </a>
                  </div>

                  {/* 4 Core Metrics Grid */}
                  <div className="grid grid-cols-4 gap-2 pt-1">
                    <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                      <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Coverage</div>
                      <div className={`text-base font-bold ${asha.coveragePct >= 90 ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400'}`}>
                        {asha.coveragePct}%
                      </div>
                    </div>
                    <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                      <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Overdue</div>
                      <div className={`text-base font-bold ${asha.overdueVisitsCount > 4 ? 'text-rose-600 dark:text-rose-400' : 'text-[#0F172A] dark:text-[#F8FAFC]'}`}>
                        {asha.overdueVisitsCount}
                      </div>
                    </div>
                    <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                      <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Data Quality</div>
                      <div className="text-base font-bold text-indigo-600 dark:text-indigo-400">
                        {asha.dataQualityScorePct}%
                      </div>
                    </div>
                    <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                      <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Learning</div>
                      <div className="text-base font-bold text-amber-600 dark:text-amber-400">
                        {asha.learningModulesCompleted} / 16
                      </div>
                    </div>
                  </div>

                  {/* Mentoring Pattern Detection Callout (Req 39.3) */}
                  {asha.mentoringFlags && asha.mentoringFlags.length > 0 && (
                    <div className="space-y-2">
                      {asha.mentoringFlags.map((flag, idx) => (
                        <div
                          key={idx}
                          className={`p-3 rounded-xl border text-xs flex items-start space-x-2.5 ${
                            flag.type === 'positive'
                              ? 'bg-emerald-50 dark:bg-emerald-950/20 border-emerald-200 dark:border-emerald-500/30 text-emerald-800 dark:text-emerald-300'
                              : flag.type === 'warning'
                              ? 'bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-500/30 text-amber-800 dark:text-amber-300'
                              : 'bg-indigo-50 dark:bg-indigo-950/20 border-indigo-200 dark:border-indigo-500/30 text-indigo-800 dark:text-indigo-300'
                          }`}
                        >
                          <Sparkles className="w-4 h-4 shrink-0 mt-0.5" />
                          <div>
                            <div className="font-semibold">{flag.message}</div>
                            {flag.suggestedModule && (
                              <div className="text-[11px] text-[#525252] dark:text-[#94A3B8] pt-0.5 flex items-center gap-1">
                                <BookOpen className="w-3 h-3 text-amber-600 dark:text-amber-400" />
                                <span>Recommended Micro-Lesson: <span className="font-mono font-medium text-amber-700 dark:text-amber-300">{flag.suggestedModule}</span></span>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Card Actions: Checklist & Recognition */}
                  <div className="flex items-center gap-2 pt-2 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        setSelectedAsha(asha);
                        setChecklistOpen(true);
                      }}
                      className="flex-1 gap-1.5"
                    >
                      <ClipboardCheck className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
                      <span>Digital Supervision Checklist (Req 39.2)</span>
                    </Button>
                    <Button
                      size="sm"
                      onClick={() => {
                        setSelectedAsha(asha);
                        setBadgeModalOpen(true);
                      }}
                      className="bg-amber-500/10 hover:bg-amber-500/20 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-500/30 gap-1.5 shadow-none"
                    >
                      <Award className="w-3.5 h-3.5" />
                      <span>Give Recognition (Req 39.5)</span>
                    </Button>
                  </div>
                </Card>
              );
            })}
          </div>
        </div>
      ) : (
        /* TAB 2: Live Frontline Data Sync Feed (What Was Received & When) */
        <div className="space-y-4">
          {/* Real-time Ingest Status Strip */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
            <div className="p-3.5 rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs">
              <span className="text-[11px] text-slate-500 font-medium">Frontline Records Synced</span>
              <div className="text-xl font-black text-slate-900 dark:text-white mt-0.5">
                {syncActivities.length} Records
              </div>
              <span className="text-[10px] text-emerald-600 dark:text-emerald-400 flex items-center gap-1 mt-0.5">
                <CheckCircle2 className="h-3 w-3" />
                <span>Auto-ingested via ABDM Gateway</span>
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs">
              <span className="text-[11px] text-slate-500 font-medium">Emergency Triage Referrals</span>
              <div className="text-xl font-black text-[#DC2626] mt-0.5">
                {urgentCount} High-Risk
              </div>
              <span className="text-[10px] text-slate-500 mt-0.5">
                Auto-routed to PHC Doctor Triage Desk
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs">
              <span className="text-[11px] text-slate-500 font-medium">Frontline ASHAs Active</span>
              <div className="text-xl font-black text-[#0C5A3E] dark:text-[#34D399] mt-0.5">
                42 / 44 Online
              </div>
              <span className="text-[10px] text-slate-500 mt-0.5">
                2 devices on SMS fallback queue
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-[11px] text-slate-500 font-medium">ABDM Gateway Link</span>
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              </div>
              <div className="text-sm font-bold text-slate-900 dark:text-white mt-1">
                Last sync: {lastSyncTime}
              </div>
              <Button
                size="xs"
                variant="outline"
                onClick={() => triggerManualSync()}
                disabled={isSyncing}
                className="mt-1 w-full text-xs text-[#0C5A3E] dark:text-[#34D399] border-emerald-300 dark:border-emerald-700"
              >
                <RefreshCw className={`w-3 h-3 mr-1 ${isSyncing ? 'animate-spin' : ''}`} />
                <span>Simulate Inbound Sync Now</span>
              </Button>
            </div>
          </div>

          {/* Sync Search & Category Filters */}
          <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3 p-3.5 rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs">
            {/* Search Input */}
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Search what was synced, ASHA name, patient, village..."
                value={syncSearch}
                onChange={(e) => setSyncSearch(e.target.value)}
                className="w-full pl-9 pr-8 h-9 rounded-lg bg-slate-50 dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:border-[#0C5A3E]"
              />
              {syncSearch && (
                <button
                  onClick={() => setSyncSearch('')}
                  className="absolute right-2.5 top-2.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            {/* Filter Pills */}
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-[11px] font-semibold text-slate-500 mr-1 flex items-center gap-1">
                <Filter className="w-3 h-3" />
                <span>Category:</span>
              </span>
              {[
                'ALL',
                'Maternal (ANC)',
                'Child (IMNCI)',
                'Postnatal (PNC)',
                'NCD Screening',
                'Immunization',
              ].map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSyncCategoryFilter(cat)}
                  className={`px-2.5 py-1 rounded-lg text-[11px] font-medium transition-colors cursor-pointer ${
                    syncCategoryFilter === cat
                      ? 'bg-[#0C5A3E] text-white shadow-xs'
                      : 'bg-slate-100 dark:bg-[#222226] text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-[#2A2A2E]'
                  }`}
                >
                  {cat}
                </button>
              ))}

              <span className="text-slate-300 dark:text-slate-700 mx-1">|</span>

              {/* Severity Pills */}
              {(['ALL', 'RED', 'YELLOW', 'GREEN'] as const).map((sev) => (
                <button
                  key={sev}
                  onClick={() => setSyncSeverityFilter(sev)}
                  className={`px-2 py-0.5 rounded-md text-[10px] font-bold transition-colors cursor-pointer ${
                    syncSeverityFilter === sev
                      ? sev === 'RED'
                        ? 'bg-rose-600 text-white'
                        : sev === 'YELLOW'
                        ? 'bg-amber-500 text-white'
                        : sev === 'GREEN'
                        ? 'bg-emerald-600 text-white'
                        : 'bg-slate-800 dark:bg-white text-white dark:text-slate-900'
                      : 'bg-slate-100 dark:bg-[#222226] text-slate-500 dark:text-slate-400 hover:bg-slate-200'
                  }`}
                >
                  {sev === 'ALL' ? 'All Risks' : sev}
                </button>
              ))}
            </div>
          </div>

          {/* Synced Inflow Stream (What Was Received & When) */}
          <div className="space-y-3">
            {filteredSyncActivities.length === 0 ? (
              <div className="py-12 text-center rounded-xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] text-slate-500 text-xs">
                No synced frontline records match your filter.
              </div>
            ) : (
              filteredSyncActivities.map((act) => {
                const isRed = act.severity === 'RED';
                const isYellow = act.severity === 'YELLOW';

                return (
                  <div
                    key={act.id}
                    className={`p-4 rounded-xl border bg-white dark:bg-[#18181B] transition-all shadow-xs ${
                      isRed
                        ? 'border-l-4 border-l-rose-500 border-slate-200 dark:border-[#26262A]'
                        : isYellow
                        ? 'border-l-4 border-l-amber-500 border-slate-200 dark:border-[#26262A]'
                        : 'border-l-4 border-l-emerald-500 border-slate-200 dark:border-[#26262A]'
                    }`}
                  >
                    <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4">
                      {/* Left: When, Who, What Was Received */}
                      <div className="flex-1 space-y-2">
                        {/* Row 1: Timestamp (When) + ASHA Worker + Program Category */}
                        <div className="flex flex-wrap items-center gap-2">
                          {/* When received */}
                          <div className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-slate-100 dark:bg-[#222226] text-slate-700 dark:text-slate-300 text-[11px] font-mono">
                            <Clock className="w-3 h-3 text-slate-400" />
                            <span className="font-bold">{act.syncTime}</span>
                          </div>

                          {/* Who sent it */}
                          <div className="flex items-center gap-1.5 text-xs font-bold text-slate-900 dark:text-white">
                            <Users className="w-3.5 h-3.5 text-[#0C5A3E] dark:text-[#34D399]" />
                            <span>ASHA {act.workerName}</span>
                            <span className="text-slate-400 font-normal">({act.village})</span>
                          </div>

                          <a
                            href={`tel:${act.workerPhone}`}
                            className="text-[11px] text-slate-500 hover:text-[#0C5A3E] dark:hover:text-[#34D399] flex items-center gap-1 ml-1"
                          >
                            <Phone className="w-3 h-3" />
                            <span className="font-mono">{act.workerPhone}</span>
                          </a>

                          {/* Category Badge */}
                          <span
                            className={`ml-auto text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                              isRed
                                ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-800'
                                : isYellow
                                ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-800'
                                : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800'
                            }`}
                          >
                            {act.category}
                          </span>
                        </div>

                        {/* Row 2: Headline / What was done */}
                        <div className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-2">
                          <span>{act.details}</span>
                          {act.patientName && (
                            <span className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-[#222226] px-2 py-0.5 rounded">
                              Beneficiary: {act.patientName}
                            </span>
                          )}
                          {act.abhaId && (
                            <span className="text-[10px] font-mono text-slate-500 bg-slate-50 dark:bg-[#202024] px-1.5 py-0.2 rounded border border-slate-200 dark:border-[#2E2E34]">
                              ABHA: {act.abhaId}
                            </span>
                          )}
                        </div>

                        {/* Row 3: What Was Received (Clinical Data Payload) */}
                        <div className="text-xs text-slate-600 dark:text-slate-300 bg-slate-50 dark:bg-[#202024] p-2.5 rounded-lg border border-slate-100 dark:border-[#26262A] leading-relaxed">
                          <strong className="text-slate-800 dark:text-slate-200">Clinical Observations & Field Ingest: </strong>
                          {act.clinicalPayload}
                        </div>

                        {act.attachments && act.attachments.length > 0 && (
                          <TriageEvidencePanel attachments={act.attachments} />
                        )}

                        {/* Row 4: Vitals Summary Pills */}
                        {act.vitalsSummary && (
                          <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
                            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wide mr-1">
                              Vitals Ingested:
                            </span>
                            <span className="px-2 py-0.5 rounded text-[11px] font-mono font-bold bg-slate-100 dark:bg-[#222226] text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-[#2E2E34]">
                              {act.vitalsSummary}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Right: Channel, Status & Quick Action */}
                      <div className="lg:w-64 lg:border-l lg:border-slate-100 dark:lg:border-[#26262A] lg:pl-4 flex flex-col justify-between space-y-3 shrink-0">
                        <div className="space-y-1.5">
                          <div className="text-[10px] uppercase font-bold text-slate-400">
                            Ingest Channel
                          </div>
                          <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300">
                            <Radio className="w-3.5 h-3.5 text-slate-400" />
                            <span>{act.channel}</span>
                          </div>
                          <div className="flex items-center gap-1.5 text-[11px]">
                            <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                            <span className="text-emerald-700 dark:text-emerald-400 font-medium">
                              Verified on ABDM Gateway
                            </span>
                          </div>
                        </div>

                        <div className="pt-2">
                          {isRed ? (
                            <button
                              onClick={() => navigate('/phc')}
                              className="w-full py-1.5 px-3 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer shadow-xs"
                            >
                              <Activity className="w-3.5 h-3.5" />
                              <span>Review in Triage Desk</span>
                              <ArrowRight className="w-3 h-3" />
                            </button>
                          ) : (
                            <button
                              onClick={() => {
                                setSearchTerm(act.workerName);
                                setActiveTab('supervision');
                              }}
                              className="w-full py-1.5 px-3 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 font-semibold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                            >
                              <span>View ASHA Performance</span>
                              <ArrowRight className="w-3 h-3" />
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}

      {/* Digital Field Supervision Checklist Modal (Req 39.2) */}
      {checklistOpen && selectedAsha && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-lg p-6 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <h3 className="font-bold text-base flex items-center gap-2">
                <ClipboardCheck className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                Supervision Checklist: {selectedAsha.ashaName}
              </h3>
              <button
                onClick={() => setChecklistOpen(false)}
                className="p-1 rounded-lg text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Checklist Type</label>
                <select
                  value={visitType}
                  onChange={(e) => setVisitType(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC]"
                >
                  <option value="household_visit">Observing Beneficiary Home Visit (HBNC / ANC)</option>
                  <option value="record_audit">Checking Registers & Digital Entries</option>
                  <option value="kit_inspection">Reviewing Equipment, BLE Devices & Medicine Kit</option>
                  <option value="vhsnd_session">Observing VHSND Clinic Session Mobilisation</option>
                </select>
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">
                  Overall Competency Score: <span className="font-bold text-amber-600 dark:text-amber-400">{checklistScore}%</span>
                </label>
                <input
                  type="range"
                  min="50"
                  max="100"
                  value={checklistScore}
                  onChange={(e) => setChecklistScore(Number(e.target.value))}
                  className="w-full accent-amber-500"
                />
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Observation Notes</label>
                <textarea
                  rows={3}
                  value={checklistNotes}
                  onChange={(e) => setChecklistNotes(e.target.value)}
                  placeholder="e.g. Demonstrated proper hand hygiene and thermometer sanitization. Clear communication with mother on danger signs."
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A]"
                />
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Supportive Recommendations / Action Items</label>
                <textarea
                  rows={2}
                  value={recommendations}
                  onChange={(e) => setRecommendations(e.target.value)}
                  placeholder="e.g. Advised to practice neonatal respiratory tap counter timer during quiet hours."
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A]"
                />
              </div>

              <div className="flex items-center space-x-2 pt-1">
                <input
                  type="checkbox"
                  id="chk-followup"
                  checked={followUpRequired}
                  onChange={(e) => setFollowUpRequired(e.target.checked)}
                  className="rounded border-[#E5E7EB] dark:border-[#2E2E2E] text-amber-500 focus:ring-0"
                />
                <label htmlFor="chk-followup" className="font-semibold cursor-pointer text-[#0F172A] dark:text-[#F8FAFC]">
                  Schedule follow-up supervision check
                </label>
              </div>

              {followUpRequired && (
                <div>
                  <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Follow-up Date</label>
                  <input
                    type="date"
                    value={followUpDate}
                    onChange={(e) => setFollowUpDate(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC]"
                  />
                </div>
              )}
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setChecklistOpen(false)}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                disabled={checklistMutation.isPending}
                onClick={() =>
                  checklistMutation.mutate({
                    afId: 'af-01',
                    ashaId: selectedAsha.ashaId,
                    visitDate: new Date().toISOString(),
                    visitType,
                    score: checklistScore,
                    notes: checklistNotes || 'Observation checklist completed in the field.',
                    recommendations: recommendations || 'Continue regular home visit protocol.',
                    followUpRequired,
                    followUpDate: followUpRequired ? followUpDate : undefined,
                  })
                }
                className="bg-amber-600 hover:bg-amber-700 text-white"
              >
                {checklistMutation.isPending ? 'Saving...' : 'Save & Sync Offline'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Recognition & Badge Modal (Req 39.5) */}
      {badgeModalOpen && selectedAsha && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md p-6 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <h3 className="font-bold text-base flex items-center gap-2">
                <Award className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                Send Recognition to {selectedAsha.ashaName}
              </h3>
              <button
                onClick={() => setBadgeModalOpen(false)}
                className="p-1 rounded-lg text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-semibold">Select Recognition Badge</label>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'star_performer', label: 'Star Performer', icon: Star, color: 'text-amber-600 dark:text-amber-400 border-amber-300 dark:border-amber-500/40 bg-amber-50 dark:bg-amber-500/10' },
                  { id: 'care_champion', label: 'Care Champion', icon: Sparkles, color: 'text-rose-600 dark:text-rose-400 border-rose-300 dark:border-rose-500/40 bg-rose-50 dark:bg-rose-500/10' },
                  { id: 'prompt_referrer', label: 'Prompt Referrer', icon: AlertCircle, color: 'text-indigo-600 dark:text-indigo-400 border-indigo-300 dark:border-indigo-500/40 bg-indigo-50 dark:bg-indigo-500/10' },
                  { id: 'learning_master', label: 'Learning Master', icon: BookOpen, color: 'text-emerald-600 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/40 bg-emerald-50 dark:bg-emerald-500/10' },
                ].map((b) => (
                  <button
                    key={b.id}
                    onClick={() => setSelectedBadge(b.id as any)}
                    className={`p-3 rounded-xl border text-left flex items-center space-x-2 transition-all cursor-pointer ${
                      selectedBadge === b.id
                        ? `${b.color} ring-2 ring-amber-500 font-bold`
                        : 'border-[#E5E7EB] dark:border-[#2E2E2E] bg-slate-50 dark:bg-[#181818] text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
                    }`}
                  >
                    <b.icon className="w-4 h-4 shrink-0" />
                    <span className="text-xs">{b.label}</span>
                  </button>
                ))}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1">
                  Congratulatory Note (Pushed to ASHA Home Screen)
                </label>
                <textarea
                  rows={2}
                  value={badgeNote}
                  onChange={(e) => setBadgeNote(e.target.value)}
                  placeholder="e.g. Great dedication on completing all high-risk pregnancy visits this week!"
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A] focus:outline-none focus:ring-1 focus:ring-amber-500"
                />
              </div>

              {badgeSent && (
                <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-500/40 text-emerald-800 dark:text-emerald-300 text-xs flex items-center space-x-2">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Recognition badge sent to {selectedAsha.ashaName}'s mobile app!</span>
                </div>
              )}
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setBadgeModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                disabled={badgeMutation.isPending}
                onClick={() =>
                  badgeMutation.mutate({
                    ashaId: selectedAsha.ashaId,
                    badge: selectedBadge,
                    msg: badgeNote || 'Thank you for your dedicated community healthcare service!',
                  })
                }
                className="bg-amber-600 hover:bg-amber-700 text-white"
              >
                {badgeMutation.isPending ? 'Sending...' : 'Award Badge'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function TriageEvidencePanel({ attachments }: { attachments: TriageEvidence[] }) {
  const [urls, setUrls] = useState<Record<number, string>>({});

  useEffect(() => {
    let active = true;
    const createdUrls: string[] = [];
    void Promise.all(
      attachments.map(async (attachment) => {
        const response = await apiClient.get(attachment.url, { responseType: 'blob' });
        const url = URL.createObjectURL(response.data);
        createdUrls.push(url);
        return [attachment.index, url] as const;
      })
    ).then((items) => {
      if (active) setUrls(Object.fromEntries(items));
    }).catch(() => {
      // Keep the ticket readable when a particular evidence file is unavailable.
    });
    return () => {
      active = false;
      createdUrls.forEach((url) => URL.revokeObjectURL(url));
    };
  }, [attachments]);

  return (
    <div className="rounded-lg border border-slate-200 dark:border-[#26262A] bg-white dark:bg-[#1B1B1F] p-2.5">
      <div className="mb-2 text-[11px] font-bold text-slate-700 dark:text-slate-200">Triage evidence</div>
      <div className="flex flex-wrap gap-3">
        {attachments.map((attachment) => {
          const url = urls[attachment.index];
          const label = `${attachment.type === 'image' ? 'Photo' : 'Voice note'}${attachment.originalBytes ? ` · ${attachment.originalBytes} bytes` : ''}`;
          if (attachment.type === 'image') {
            return (
              <div key={attachment.index} className="w-40 text-[10px] text-slate-500">
                {url ? (
                  <img src={url} alt="Triage evidence" className="h-28 w-40 rounded-md object-cover border border-slate-200" />
                ) : (
                  <div className="h-28 w-40 rounded-md bg-slate-100 animate-pulse" />
                )}
                <div className="mt-1">{label}</div>
              </div>
            );
          }
          return (
            <div key={attachment.index} className="min-w-52 text-[10px] text-slate-500">
              <div className="mb-1 font-medium text-slate-700 dark:text-slate-200">{label}</div>
              {url ? <audio controls className="h-8 w-52" src={url} /> : <div>Loading audio…</div>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
