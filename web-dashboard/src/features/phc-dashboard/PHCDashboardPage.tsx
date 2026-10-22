import React, { useState, useMemo, useEffect, useRef, Fragment } from 'react';
import { NavLink, useSearchParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getReferralQueue,
  recordReferralOutcome,
  sendDoctorFeedback,
  acknowledgeReferral,
  fetchAbdmHiuRecords,
  startConsult,
} from '@/shared/api/referralApi';
import { HOTSPOT_REFERRAL_TICKET } from '@/shared/api/mockData';
import { useSync } from '@/shared/context/SyncContext';
import { slaLabel, unseenRedIds } from '@/features/clinical-desk/logic';
import { ReferralItem } from '@/types';
import {
  Activity,
  AlertTriangle,
  Phone,
  CheckCircle2,
  Clock,
  Send,
  Calendar,
  Layers,
  Search,
  Check,
  X,
  Stethoscope,
  Heart,
  Droplet,
  Radio,
  FileText,
  Bed,
  CheckCircle,
  Copy,
  Volume2,
  RefreshCw,
  Pill,
  MapPin,
  Maximize2,
  LayoutList,
  LayoutGrid,
  ChevronDown,
  ChevronUp,
  Sparkles,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardTitle, CardDescription, CardContent } from '@/components/ui/card';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { OsmAndMapPage } from '@/features/map/OsmAndMapPage';

export function PHCDashboardPage() {
  const queryClient = useQueryClient();
  const {
    triggerManualSync,
    isSyncing,
    lastSyncTime,
    recordDoctorOutcomeSync,
    activeHotspot,
    clearHotspot,
  } = useSync();
  const [activeTab, setActiveTab] = useState<'referrals' | 'area_lists' | 'planning' | 'ipd_ward' | 'sms_feed' | 'catchment_map'>('referrals');
  const [triageView, setTriageView] = useState<'table' | 'cards'>('table');
  const [expandedRowId, setExpandedRowId] = useState<string | null>(null);
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'SMS'>('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'pending' | 'arrived' | 'treated' | 'admitted'>('ALL');
  const [searchParams, setSearchParams] = useSearchParams();
  const urlSearch = searchParams.get('search') || '';
  const [searchQuery, setSearchQuery] = useState(urlSearch);

  useEffect(() => {
    if (urlSearch) {
      setSearchQuery(urlSearch);
      setActiveTab('referrals');
    }
  }, [urlSearch]);
  
  // Selection states for Modals
  const [selectedReferral, setSelectedReferral] = useState<ReferralItem | null>(null);
  const [outcomeStatus, setOutcomeStatus] = useState<'treated' | 'admitted' | 'discharged' | 'did_not_reach'>('treated');
  const [outcomeNotes, setOutcomeNotes] = useState('');
  const [selectedPrescriptions, setSelectedPrescriptions] = useState<string[]>([]);
  const [feedbackMessage, setFeedbackMessage] = useState('');
  const [feedbackSent, setFeedbackSent] = useState(false);

  // ABDM HIU Modal state
  const [selectedAbdmItem, setSelectedAbdmItem] = useState<ReferralItem | null>(null);
  const [abdmData, setAbdmData] = useState<any>(null);
  const [isLoadingAbdm, setIsLoadingAbdm] = useState(false);
  const [copiedAbha, setCopiedAbha] = useState<string | null>(null);

  // Sound chime toggle
  const [soundAlertEnabled, setSoundAlertEnabled] = useState(true);
  const [freshRedIds, setFreshRedIds] = useState<string[]>([]);
  const seenRedIds = useRef<string[] | null>(null);

  // Poll referral queue every 30 seconds for live triage (Req 41.1, Design 2.7)
  const { data: referrals = [], isLoading, isRefetching, refetch } = useQuery({
    queryKey: ['referrals', 'pending', 'phc-shahpur'],
    queryFn: () => getReferralQueue('phc-shahpur'),
    refetchInterval: 30_000,
  });

  const outcomeMutation = useMutation({
    mutationFn: ({ id, status, notes }: { id: string; status: any; notes: string }) =>
      recordReferralOutcome(id, status, notes),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referrals'] });
      if (selectedReferral) {
        recordDoctorOutcomeSync(
          selectedReferral.patientName,
          selectedReferral.ashaName,
          `Outcome (${outcomeStatus.toUpperCase()}): ${outcomeNotes ? outcomeNotes.slice(0, 45) + '...' : 'Clinical action saved'}`
        );
      }
      setSelectedReferral(null);
      setOutcomeNotes('');
      setSelectedPrescriptions([]);
    },
  });

  const acknowledgeMutation = useMutation({
    mutationFn: (id: string) => acknowledgeReferral(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referrals'] });
    },
  });

  const consultMutation = useMutation({
    mutationFn: (id: string) => startConsult(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referrals'] });
    },
  });

  useEffect(() => {
    if (isLoading) return;
    const redIds = referrals
      .filter((item) => item.severity === 'RED' && (item.status === 'pending' || item.status === 'arrived'))
      .map((item) => item.id);
    if (seenRedIds.current === null) {
      seenRedIds.current = redIds;
      return;
    }
    const fresh = unseenRedIds(seenRedIds.current, redIds);
    if (fresh.length > 0) {
      setFreshRedIds(fresh);
      window.alert(`New RED referral: ${fresh.join(', ')}`);
      seenRedIds.current = [...seenRedIds.current, ...fresh];
    }
  }, [referrals, isLoading]);

  const feedbackMutation = useMutation({
    mutationFn: ({ refId, ashaId, msg }: { refId: string; ashaId: string; msg: string }) =>
      sendDoctorFeedback(refId, ashaId, msg),
    onSuccess: () => {
      setFeedbackSent(true);
      setTimeout(() => {
        setFeedbackSent(false);
        setFeedbackMessage('');
      }, 2500);
    },
  });

  const handleOpenAbdmHiu = async (item: ReferralItem) => {
    setSelectedAbdmItem(item);
    setIsLoadingAbdm(true);
    try {
      const data = await fetchAbdmHiuRecords(item.abhaId || '91-8765-4321-0987');
      setAbdmData(data);
    } finally {
      setIsLoadingAbdm(false);
    }
  };

  const handleCopyAbha = (abha: string) => {
    navigator.clipboard?.writeText(abha);
    setCopiedAbha(abha);
    setTimeout(() => setCopiedAbha(null), 2000);
  };

  // Filter and search logic
  const filteredReferrals = useMemo(() => {
    return referrals.filter((r) => {
      // Severity filter
      if (severityFilter === 'RED' && r.severity !== 'RED') return false;
      if (severityFilter === 'YELLOW' && r.severity !== 'YELLOW') return false;
      if (severityFilter === 'SMS' && !r.isSmsRelayed) return false;

      // Status filter
      if (statusFilter !== 'ALL' && r.status !== statusFilter) return false;

      // Search query (name, abha, village, asha)
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchName = r.patientName.toLowerCase().includes(q);
        const matchAbha = r.abhaId?.toLowerCase().includes(q);
        const matchVillage = r.village.toLowerCase().includes(q);
        const matchAsha = r.ashaName.toLowerCase().includes(q);
        const matchReason = r.reason.toLowerCase().includes(q);
        if (!matchName && !matchAbha && !matchVillage && !matchAsha && !matchReason) {
          return false;
        }
      }

      return true;
    });
  }, [referrals, severityFilter, statusFilter, searchQuery]);

  const redCount = referrals.filter((r) => r.severity === 'RED' && r.status === 'pending').length;
  const arrivedCount = referrals.filter((r) => r.status === 'arrived').length;
  const treatedTodayCount = referrals.filter((r) => r.status === 'treated' || r.status === 'admitted').length;

  // Prescription tag helper
  const togglePrescriptionTag = (tag: string) => {
    setSelectedPrescriptions((prev) => {
      const next = prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag];
      const joined = next.join(', ');
      setOutcomeNotes((current) => {
        const withoutTags = current.replace(/Prescription \/ Treatment: [^\n]*/g, '').trim();
        return withoutTags
          ? `${withoutTags}\nPrescription / Treatment: ${joined}`
          : `Prescription / Treatment: ${joined}`;
      });
      return next;
    });
  };

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* 1. Emergency Triage Banner & Facility Stats Strip */}
      <div className="space-y-4">
        {/* Header Row */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
              PHC Shahpur Emergency Triage & Referral Queue
              {isRefetching && (
                <span className="text-[11px] text-[#10B981] font-normal animate-pulse">
                  (Syncing live...)
                </span>
              )}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Primary Health Centre Shahpur • Facility Code: PHC-SHP-04 • National Health Mission (NHM) • Polling live every 30s
            </p>
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setSoundAlertEnabled(!soundAlertEnabled)}
              className={`bg-white dark:bg-[#1E1E1E] shadow-xs ${soundAlertEnabled ? 'text-emerald-700 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/30' : 'text-[#71717A] border-slate-200 dark:border-[#2E2E2E]'}`}
              title="Audio alert chime on incoming emergency"
            >
              <Volume2 className="w-3.5 h-3.5 mr-1" />
              <span>Chime {soundAlertEnabled ? 'On' : 'Off'}</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveTab('catchment_map')}
              className="bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] text-emerald-700 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/30 gap-1.5 shadow-xs"
              title="Open Catchment Field Map"
            >
              <MapPin className="w-3.5 h-3.5" />
              <span>Field Map</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => refetch()}
              className="bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] shadow-xs"
            >
              <RefreshCw className={`w-3.5 h-3.5 mr-1 ${isRefetching ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </Button>
          </div>
        </div>

        {/* Live queue ticker: concise, dynamic and free of hardcoded clinical diagnoses. */}
        {redCount > 0 && (
          <div className="flex items-center gap-3 rounded-xl border border-rose-200 bg-rose-50/70 dark:bg-rose-950/20 dark:border-rose-900 px-3 py-2 text-xs shadow-xs overflow-hidden">
            <span className="h-2 w-2 shrink-0 rounded-full bg-rose-500 animate-pulse" />
            <div className="min-w-0 flex-1 overflow-hidden whitespace-nowrap">
              <div className="inline-block animate-[queue-marquee_20s_linear_infinite] font-semibold text-rose-800 dark:text-rose-200">
                Live clinical queue · {redCount} RED referral{redCount === 1 ? '' : 's'} awaiting review · updates are sent back to the originating ASHA device after PHC action
              </div>
            </div>
            <Button
              size="xs"
              variant="destructive"
              onClick={() => {
                setActiveTab('referrals');
                setSeverityFilter('RED');
              }}
              className="hidden sm:inline-flex"
            >
              Open RED queue &rarr;
            </Button>
          </div>
        )}

        {/* Active Hotspot Outbreak Surveillance Banner */}
        {activeHotspot && (
          <div className="relative overflow-hidden rounded-2xl border-2 border-red-500 bg-gradient-to-r from-red-500/10 via-rose-500/15 to-amber-500/10 p-4 shadow-md dark:border-red-500/60 dark:from-red-950/40 dark:to-rose-950/30">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-600 text-white shadow-lg ring-4 ring-red-500/20">
                  <AlertTriangle className="h-5 w-5 animate-bounce" />
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-red-600 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wider text-white">
                      <span className="h-1.5 w-1.5 rounded-full bg-white animate-ping" />
                      Active Hotspot Outbreak Mapped
                    </span>
                    <span className="text-xs font-bold text-red-700 dark:text-red-300">
                      Indira Airport, Delhi (28.5562° N, 77.1000° E)
                    </span>
                    <span className="rounded bg-red-100 dark:bg-red-900/50 px-2 py-0.5 text-[10px] font-bold text-red-800 dark:text-red-200">
                      Radius: 1.8 km · 14 Cases · Dengue / AFI
                    </span>
                  </div>
                  <p className="mt-1 text-xs text-slate-700 dark:text-slate-300">
                    <strong className="text-red-600 dark:text-red-400">Clinical Triage Rule Enforced:</strong> All acute fever cases presenting from Mahipalpur / Aerocity / Rangpuri catchment are auto-elevated to <strong>RED Emergency Triage</strong>. 4 nearby ASHA workers are live-synced to this beat.
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2 shrink-0 self-end lg:self-center">
                <Button
                  size="sm"
                  onClick={() => setActiveTab('catchment_map')}
                  className="bg-red-600 hover:bg-red-700 text-white font-bold text-xs gap-1.5 shadow-sm"
                >
                  <MapPin className="w-3.5 h-3.5" />
                  View on Field Map
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => clearHotspot()}
                  className="border-red-300 dark:border-red-800 text-red-700 dark:text-red-300 hover:bg-red-100/50 text-xs"
                >
                  Clear Hotspot
                </Button>
              </div>
            </div>
          </div>
        )}

        {/* Clinical KPI Metric Cards (User Palette Swatches) */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3.5">
          <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-4">
            <div className="flex items-center justify-between">
              <span className="text-xs text-[#F43F5E] font-semibold">Unreviewed RED</span>
              <div className="p-1.5 rounded-lg bg-slate-100 dark:bg-[#181818] text-[#F43F5E]">
                <AlertTriangle className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-2 text-2xl font-black text-[#0F172A] dark:text-white">{redCount}</div>
            <div className="text-[10px] text-[#F43F5E] font-bold mt-1">
              &lt; 30m response target
            </div>
          </Card>

          <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-4">
            <div className="flex items-center justify-between">
              <span className="text-xs text-[#10B981] font-semibold">Patient Arrivals in OPD</span>
              <div className="p-1.5 rounded-lg bg-slate-100 dark:bg-[#181818] text-[#10B981]">
                <Stethoscope className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-2 text-2xl font-black text-[#0F172A] dark:text-white">{arrivedCount} Waiting</div>
            <div className="text-[10px] text-[#525252] dark:text-[#A3A3A3] mt-1">
              Acked by nursing station
            </div>
          </Card>

          <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-4">
            <div className="flex items-center justify-between">
              <span className="text-xs text-[#525252] dark:text-[#A3A3A3] font-semibold">Treated & Discharged</span>
              <div className="p-1.5 rounded-lg bg-slate-100 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#F8FAFC]">
                <CheckCircle2 className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-2 text-2xl font-black text-[#0F172A] dark:text-white">{treatedTodayCount} Completed</div>
            <div className="text-[10px] text-[#71717A] mt-1">
              Counter-referrals pushed
            </div>
          </Card>

          <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-4">
            <div className="flex items-center justify-between">
              <span className="text-xs text-[#525252] dark:text-[#A3A3A3] font-semibold">Total Inflow Queue</span>
              <div className="p-1.5 rounded-lg bg-slate-100 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#F8FAFC]">
                <Clock className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-2 text-2xl font-black text-[#0F172A] dark:text-white">{referrals.length} Cases</div>
            <div className="text-[10px] text-[#71717A] mt-1">
              Across 6 linked sub-centres
            </div>
          </Card>
        </div>
      </div>

      {/* 2. Primary Navigation Tabs (Shadcn Tabs) */}
      <Tabs value={activeTab} onValueChange={(val: any) => setActiveTab(val)}>
        <TabsList className="w-full justify-start overflow-x-auto h-11 p-1">
          <TabsTrigger value="referrals" className="gap-2">
            <Activity className="w-4 h-4 text-[#F43F5E]" />
            <span>Emergency Referral Queue ({referrals.length})</span>
          </TabsTrigger>
          <TabsTrigger value="area_lists" className="gap-2">
            <Layers className="w-4 h-4 text-[#8B5CF6]" />
            <span>Active Area Health Lists</span>
          </TabsTrigger>
          <TabsTrigger value="planning" className="gap-2">
            <Calendar className="w-4 h-4 text-[#F59E0B]" />
            <span>Facility Planning & Stocks</span>
          </TabsTrigger>
          <TabsTrigger value="ipd_ward" className="gap-2">
            <Bed className="w-4 h-4 text-teal-500" />
            <span>Inpatient (IPD) Ward (12/16 Beds)</span>
          </TabsTrigger>
          <TabsTrigger value="sms_feed" className="gap-2">
            <Radio className="w-4 h-4 text-cyan-500" />
            <span>SMS Emergency Gateway</span>
          </TabsTrigger>
          <TabsTrigger value="catchment_map" className="gap-2">
            <MapPin className="w-4 h-4 text-emerald-500" />
            <span>Catchment Field Map</span>
          </TabsTrigger>
        </TabsList>

        {/* TAB 1: Live Emergency Referral Queue */}
        <TabsContent value="referrals" className="space-y-4">
          {/* Search & Filter Command Bar */}
          <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3 p-3.5 rounded-2xl bg-white dark:bg-[#18181B] border border-slate-200 dark:border-[#26262A] shadow-xs">
            {/* Search Input */}
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <Input
                type="text"
                placeholder="Search patient, ABHA ID, village, or ASHA..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 pr-8 h-9 bg-slate-50 dark:bg-[#202024] border-slate-200 dark:border-[#2E2E34] text-xs"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-2.5 top-2.5 text-slate-400 hover:text-black dark:hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            {/* Severity Pill Filters & View Mode Switcher */}
            <div className="flex flex-wrap items-center gap-2">
              <div className="flex items-center gap-1">
                <span className="text-[11px] text-slate-500 font-semibold mr-1">Severity:</span>
                <Button
                  size="xs"
                  variant={severityFilter === 'ALL' ? 'default' : 'outline'}
                  onClick={() => setSeverityFilter('ALL')}
                >
                  All ({referrals.length})
                </Button>
                <Button
                  size="xs"
                  variant={severityFilter === 'RED' ? 'destructive' : 'outline'}
                  onClick={() => setSeverityFilter('RED')}
                  className="flex items-center gap-1"
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-rose-400" />
                  RED ({referrals.filter((r) => r.severity === 'RED').length})
                </Button>
                <Button
                  size="xs"
                  variant={severityFilter === 'YELLOW' ? 'warning' : 'outline'}
                  onClick={() => setSeverityFilter('YELLOW')}
                  className="flex items-center gap-1"
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-400" />
                  YELLOW ({referrals.filter((r) => r.severity === 'YELLOW').length})
                </Button>
                <Button
                  size="xs"
                  variant={severityFilter === 'SMS' ? 'default' : 'outline'}
                  onClick={() => setSeverityFilter('SMS')}
                  className="flex items-center gap-1 text-cyan-700 dark:text-cyan-300 border-cyan-300 dark:border-cyan-500/30"
                >
                  <Radio className="w-3 h-3 text-cyan-500" />
                  SMS Relayed ({referrals.filter((r) => r.isSmsRelayed).length})
                </Button>
              </div>

              <div className="hidden sm:block h-4 w-px bg-slate-200 dark:bg-slate-700 mx-1" />

              {/* View Switcher: Table vs Cards */}
              <div className="flex items-center rounded-lg bg-slate-100 dark:bg-[#202024] p-0.5 border border-slate-200 dark:border-[#2E2E34]">
                <button
                  onClick={() => setTriageView('table')}
                  className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold transition-all cursor-pointer ${
                    triageView === 'table'
                      ? 'bg-white dark:bg-[#18181B] text-[#0C5A3E] dark:text-[#34D399] shadow-xs'
                      : 'text-slate-500 dark:text-slate-400 hover:text-slate-900'
                  }`}
                  title="Structured Triage Board Table View"
                >
                  <LayoutList className="w-3.5 h-3.5" />
                  <span>Table View</span>
                </button>
                <button
                  onClick={() => setTriageView('cards')}
                  className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold transition-all cursor-pointer ${
                    triageView === 'cards'
                      ? 'bg-white dark:bg-[#18181B] text-[#0C5A3E] dark:text-[#34D399] shadow-xs'
                      : 'text-slate-500 dark:text-slate-400 hover:text-slate-900'
                  }`}
                  title="Detailed Clinical Case Cards View"
                >
                  <LayoutGrid className="w-3.5 h-3.5" />
                  <span>Cards View</span>
                </button>
              </div>
            </div>
          </div>

          {/* Active Hotspot Triage Consideration Card */}
          {activeHotspot && (
            <div className="relative overflow-hidden rounded-2xl border-2 border-rose-500 bg-rose-50/60 dark:bg-rose-950/20 dark:border-rose-500/70 p-4 shadow-sm">
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-rose-600 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wider text-white">
                      <span className="h-1.5 w-1.5 rounded-full bg-white animate-ping" />
                      Priority Outbreak Triage Alert
                    </span>
                    <span className="text-xs font-black text-rose-700 dark:text-rose-300">
                      Nearby Case for Triage Consideration · Sunita Devi (29y F)
                    </span>
                    <span className="rounded-full bg-rose-200/80 dark:bg-rose-900/60 px-2 py-0.5 text-[10px] font-bold text-rose-800 dark:text-rose-200">
                      0.8 km from Indira Airport Epicentre
                    </span>
                    <span className="rounded-full bg-amber-100 dark:bg-amber-900/50 px-2 py-0.5 text-[10px] font-bold text-amber-800 dark:text-amber-200">
                      ABHA: 91-7710-0014-9921
                    </span>
                  </div>

                  <p className="text-xs text-slate-700 dark:text-slate-300 leading-relaxed">
                    <strong className="text-rose-700 dark:text-rose-400">Clinical Presentation:</strong> High fever 103.4°F (Day 4), severe petechial rash, persistent vomiting × 3, platelets ~42,000/μL. Rapid NS1 Ag positive at field level.
                    <span className="ml-1 text-slate-600 dark:text-slate-400">
                      Reported by ASHA <strong>Meena Sharma</strong> (+91 98765 43210) from Mahipalpur Extn beat.
                    </span>
                  </p>

                  <div className="flex items-center gap-3 text-[11px] font-medium text-slate-600 dark:text-slate-400 flex-wrap">
                    <span className="flex items-center gap-1">
                      <Heart className="w-3.5 h-3.5 text-rose-500" />
                      Pulse: 114 bpm
                    </span>
                    <span className="flex items-center gap-1">
                      <Activity className="w-3.5 h-3.5 text-blue-500" />
                      BP: 94/62 mmHg
                    </span>
                    <span className="flex items-center gap-1">
                      <Droplet className="w-3.5 h-3.5 text-rose-600" />
                      Platelets: 42,000/μL
                    </span>
                    <span className="flex items-center gap-1 text-rose-600 dark:text-rose-400 font-bold">
                      <AlertTriangle className="w-3.5 h-3.5" />
                      Triage rule: Outbreak proximity auto-escalated to RED
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2 shrink-0 flex-wrap">
                  <Button
                    size="sm"
                    onClick={() => setSelectedReferral(HOTSPOT_REFERRAL_TICKET)}
                    className="bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs gap-1.5 shadow-sm"
                  >
                    <Stethoscope className="w-3.5 h-3.5" />
                    Review & Triage Case
                  </Button>
                  <NavLink
                    to={`/ticket/${HOTSPOT_REFERRAL_TICKET.id}`}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 dark:border-rose-800 bg-white dark:bg-[#1E1E1E] px-3 py-1.5 text-xs font-bold text-rose-700 dark:text-rose-300 hover:bg-rose-50 dark:hover:bg-rose-950/40"
                  >
                    <FileText className="w-3.5 h-3.5" />
                    Open Ticket
                  </NavLink>
                  <a
                    href="tel:+919876543210"
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-[#1E1E1E] px-3 py-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-50"
                  >
                    <Phone className="w-3.5 h-3.5 text-emerald-600" />
                    Call ASHA
                  </a>
                </div>
              </div>
            </div>
          )}

          {/* Referral Queue View */}
          {filteredReferrals.length === 0 ? (
            <div className="py-16 text-center text-slate-500 space-y-2 rounded-2xl border border-slate-200 dark:border-[#26262A] bg-white dark:bg-[#18181B]">
              <CheckCircle className="w-8 h-8 text-[#10B981] mx-auto" />
              <p className="font-semibold text-slate-900 dark:text-slate-200">No pending referrals match your filter.</p>
              <p className="text-xs text-slate-500">All emergency patients have been reviewed or discharged.</p>
            </div>
          ) : triageView === 'table' ? (
            /* STRUCTURED TRIAGE MATRIX TABLE (Formal Clinical Hospital Format) */
            <div className="rounded-2xl border border-slate-200 dark:border-[#26262A] bg-white dark:bg-[#18181B] overflow-hidden shadow-xs">
              <div className="overflow-x-auto">
                <table className="w-full min-w-[1120px] text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-slate-200 dark:border-[#26262A] bg-slate-50/80 dark:bg-[#202024] text-slate-600 dark:text-slate-300 font-bold uppercase text-[10px] tracking-wider">
                      <th className="py-2.5 px-3 w-36">Priority / Triage</th>
                      <th className="py-2.5 px-3 w-44">Patient & ABHA</th>
                      <th className="py-2.5 px-3 min-w-[240px]">Clinical Complaint & Danger Signs</th>
                      <th className="py-2.5 px-3 w-36">Field Vitals</th>
                      <th className="py-2.5 px-3 w-40">Referring ASHA</th>
                      <th className="py-2.5 px-3 w-32 whitespace-nowrap">Wait & SLA</th>
                      <th className="py-2.5 px-3 text-right min-w-[260px]">Clinical Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-[#26262A]">
                    {filteredReferrals.map((item) => {
                      const isRed = item.severity === 'RED';
                      const minutesWaiting = Math.round(
                        (Date.now() - new Date(item.referredAt).getTime()) / (1000 * 60)
                      );
                      const sla = isRed ? slaLabel(item.referredAt, Date.now()) : null;
                      const ageLabel =
                        item.ageMonths != null
                          ? `${item.ageMonths} mo`
                          : item.patientAge < 1
                            ? `${Math.round(item.patientAge * 12)} months`
                            : `${item.patientAge} yrs`;
                      const isExpanded = expandedRowId === item.id;

                      return (
                        <React.Fragment key={item.id}>
                          <tr
                            data-fresh-red={freshRedIds.includes(item.id) ? 'true' : 'false'}
                            className={`transition-colors hover:bg-slate-50/90 dark:hover:bg-[#202024]/60 ${
                              isRed ? 'bg-rose-50/20 dark:bg-rose-950/10' : ''
                            }`}
                          >
                            {/* Priority / Triage Badge */}
                            <td className="py-3 px-3 align-top whitespace-nowrap">
                              <div className="flex flex-col gap-1 items-start">
                                <span
                                  className={`px-2.5 py-0.5 rounded-full text-[10px] font-black tracking-wide uppercase border flex items-center gap-1.5 ${
                                    isRed
                                      ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-300 dark:border-rose-800'
                                      : 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-300 dark:border-amber-800'
                                  }`}
                                >
                                  <AlertTriangle className="w-3 h-3 text-inherit" />
                                  <span>{item.severity} TRIAGE</span>
                                </span>

                                {item.isSmsRelayed && (
                                  <span className="inline-flex items-center gap-1 px-1.5 py-0.2 rounded text-[9px] font-bold bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-300 border border-cyan-200 dark:border-cyan-800">
                                    <Radio className="w-2.5 h-2.5 animate-pulse" />
                                    <span>SMS Relay</span>
                                  </span>
                                )}

                                <span
                                  className={`px-2 py-0.2 rounded-full text-[9px] font-bold uppercase mt-0.5 ${
                                    item.status === 'pending'
                                      ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                                      : item.status === 'arrived'
                                      ? 'bg-sky-100 text-sky-800 dark:bg-sky-900/40 dark:text-sky-300'
                                      : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                  }`}
                                >
                                  {item.status.replace('_', ' ')}
                                </span>
                              </div>
                            </td>

                            {/* Patient & ABHA */}
                            <td className="py-3 px-3 align-top">
                              <div className="space-y-1">
                                <div className="font-bold text-slate-900 dark:text-white text-sm leading-tight flex items-center gap-1.5">
                                  <span>{item.patientName}</span>
                                  <span className="text-[11px] font-normal text-slate-500">
                                    ({ageLabel}, {item.patientGender})
                                  </span>
                                </div>

                                <div className="text-[11px] text-slate-500 flex items-center gap-1">
                                  <span>{item.village}</span>
                                  <span>•</span>
                                  <span className="font-mono text-[10px] text-slate-400">{item.subcentreId}</span>
                                </div>

                                {item.abhaId && (
                                  <button
                                    onClick={() => handleCopyAbha(item.abhaId!)}
                                    className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-slate-100 dark:bg-[#26262A] hover:bg-slate-200 text-slate-700 dark:text-slate-300 text-[10px] font-mono border border-slate-200 dark:border-slate-700 transition-colors cursor-pointer"
                                    title="Click to copy ABHA ID"
                                  >
                                    <span className="font-bold">ABHA:</span>
                                    <span>{item.abhaId}</span>
                                    {copiedAbha === item.abhaId ? (
                                      <Check className="w-2.5 h-2.5 text-emerald-600" />
                                    ) : (
                                      <Copy className="w-2.5 h-2.5 text-slate-400" />
                                    )}
                                  </button>
                                )}
                              </div>
                            </td>

                            {/* Clinical Complaint & Danger Signs */}
                            <td className="py-3 px-3 align-top">
                              <div className="space-y-1.5">
                                <div className="font-semibold text-rose-700 dark:text-rose-300 text-xs leading-snug">
                                  {item.reason}
                                </div>

                                {/* Danger signs chips */}
                                {item.screenedDangerSigns && item.screenedDangerSigns.length > 0 && (
                                  <div className="flex flex-wrap gap-1">
                                    {item.screenedDangerSigns.slice(0, 3).map((ds, idx) => (
                                      <span
                                        key={idx}
                                        className={`px-1.5 py-0.2 rounded text-[10px] font-medium flex items-center gap-1 border ${
                                          ds.present
                                            ? 'bg-rose-100 dark:bg-rose-950/60 text-rose-800 dark:text-rose-200 border-rose-300 font-bold'
                                            : 'bg-slate-100 dark:bg-[#202024] text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700'
                                        }`}
                                      >
                                        <span>{ds.sign}</span>
                                        <strong className={ds.present ? 'text-rose-700 font-bold' : 'text-slate-400'}>
                                          {ds.present ? '✓' : '✗'}
                                        </strong>
                                      </span>
                                    ))}
                                    {item.screenedDangerSigns.length > 3 && (
                                      <button
                                        onClick={() => setExpandedRowId(isExpanded ? null : item.id)}
                                        className="text-[10px] text-[#0C5A3E] dark:text-[#34D399] font-bold hover:underline"
                                      >
                                        +{item.screenedDangerSigns.length - 3} more
                                      </button>
                                    )}
                                  </div>
                                )}
                              </div>
                            </td>

                            {/* Field Vitals */}
                            <td className="py-3 px-3 align-top whitespace-nowrap">
                              {item.vitals ? (
                                <div className="flex flex-col gap-1 text-[11px] font-mono">
                                  {item.vitals.bpSystolic && (
                                    <span className="px-1.5 py-0.5 rounded bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900 font-bold">
                                      BP: {item.vitals.bpSystolic}/{item.vitals.bpDiastolic}
                                    </span>
                                  )}
                                  {item.vitals.spo2 && (
                                    <span className="px-1.5 py-0.5 rounded bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900 font-bold">
                                      SpO2: {item.vitals.spo2}%
                                    </span>
                                  )}
                                  {item.vitals.respRate && (
                                    <span className="px-1.5 py-0.5 rounded bg-slate-100 dark:bg-[#222226] text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-[#2E2E34]">
                                      Resp: {item.vitals.respRate}/m
                                    </span>
                                  )}
                                  {item.vitals.hemoglobin && (
                                    <span className="px-1.5 py-0.5 rounded bg-slate-100 dark:bg-[#222226] text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-[#2E2E34]">
                                      Hb: {item.vitals.hemoglobin} g/dL
                                    </span>
                                  )}
                                </div>
                              ) : (
                                <span className="text-slate-400 text-[11px]">No vitals</span>
                              )}
                            </td>

                            {/* Referring ASHA */}
                            <td className="py-3 px-3 align-top whitespace-nowrap">
                              <div className="space-y-1">
                                <div className="font-bold text-slate-900 dark:text-white text-xs">
                                  {item.ashaName}
                                </div>
                                <div className="text-[10px] text-slate-400">
                                  ASHA Worker
                                </div>
                                <a
                                  href={`tel:${item.ashaPhone}`}
                                  className="inline-flex items-center gap-1 text-[11px] font-mono text-[#0C5A3E] dark:text-[#34D399] hover:underline"
                                >
                                  <Phone className="w-3 h-3" />
                                  <span>{item.ashaPhone}</span>
                                </a>
                              </div>
                            </td>

                            {/* Wait & SLA */}
                            <td className="py-3 px-3 align-top whitespace-nowrap">
                              <div className="space-y-1">
                                <div className={`text-[11px] font-bold ${minutesWaiting > 30 && isRed ? 'text-rose-600' : 'text-slate-700 dark:text-slate-300'}`}>
                                  Wait: {minutesWaiting} mins
                                </div>
                                {sla && (
                                  <div
                                    data-testid={`sla-${item.id}`}
                                    className={`px-2 py-0.5 rounded text-[10px] font-bold border inline-block ${
                                      sla.overdue
                                        ? 'bg-rose-100 text-rose-800 border-rose-300 dark:bg-rose-950/60 dark:text-rose-200'
                                        : 'bg-emerald-100 text-emerald-800 border-emerald-300 dark:bg-emerald-950/60 dark:text-emerald-200'
                                    }`}
                                  >
                                    SLA {sla.text}
                                  </div>
                                )}
                              </div>
                            </td>

                            {/* Clinical Actions */}
                            <td className="py-3 px-3 align-top text-right whitespace-nowrap min-w-[280px]">
                              <div className="flex flex-col gap-1.5 items-end">
                                <div className="flex flex-wrap justify-end gap-1.5 max-w-[280px]">
                                  {item.status === 'pending' && (
                                    <Button
                                      size="xs"
                                      variant="outline"
                                      onClick={() => acknowledgeMutation.mutate(item.id)}
                                      disabled={acknowledgeMutation.isPending}
                                      className="text-[10px] h-7 px-2"
                                    >
                                      <CheckCircle2 className="w-3 h-3 mr-1 text-slate-500" />
                                      <span>ACKNOWLEDGE</span>
                                    </Button>
                                  )}

                                  {(item.status === 'pending' || item.status === 'arrived') && (
                                    <Button
                                      size="xs"
                                      variant="outline"
                                      onClick={() => consultMutation.mutate(item.id)}
                                      disabled={consultMutation.isPending}
                                      className="text-[10px] h-7 px-2"
                                    >
                                      <span>START CONSULT</span>
                                    </Button>
                                  )}

                                  <Button
                                    size="xs"
                                    variant="outline"
                                    onClick={() => handleOpenAbdmHiu(item)}
                                    className="text-[10px] h-7 px-2"
                                  >
                                    <FileText className="w-3 h-3 mr-1 text-slate-500" />
                                    <span>ABDM HIU</span>
                                  </Button>

                                  <Button
                                    size="xs"
                                    variant="default"
                                    onClick={() => {
                                      setSelectedReferral(item);
                                      setOutcomeStatus('treated');
                                    }}
                                    className="text-[10px] h-7 px-2.5 bg-[#0C5A3E] hover:bg-[#08422E] text-white font-bold"
                                  >
                                    <Stethoscope className="w-3 h-3 mr-1" />
                                    <span>Record Outcome</span>
                                  </Button>
                                </div>

                                <div className="flex items-center gap-2 text-[11px]">
                                  <NavLink
                                    to={`/ticket/${item.id}`}
                                    className="text-slate-500 hover:text-slate-800 dark:hover:text-white underline"
                                  >
                                    Open ticket
                                  </NavLink>
                                  <button
                                    onClick={() => setExpandedRowId(isExpanded ? null : item.id)}
                                    className="text-[#0C5A3E] dark:text-[#34D399] font-semibold flex items-center gap-0.5 hover:underline cursor-pointer"
                                  >
                                    <span>{isExpanded ? 'Hide Details' : 'View Observation'}</span>
                                    {isExpanded ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                                  </button>
                                </div>
                              </div>
                            </td>
                          </tr>

                          {/* Expanded Observation Drawer */}
                          {isExpanded && (
                            <tr className="bg-slate-50/90 dark:bg-[#1A1A1E]">
                              <td colSpan={7} className="p-4 border-b border-slate-200 dark:border-[#26262A]">
                                <div className="space-y-3">
                                  <div className="p-3 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-xs">
                                    <strong className="text-slate-900 dark:text-white block mb-1">
                                      ASHA Clinical Field Observation:
                                    </strong>
                                    <p className="text-slate-700 dark:text-slate-300 leading-relaxed">
                                      {item.clinicalNote}
                                    </p>
                                  </div>

                                  {/* Danger Signs Screened Matrix */}
                                  {item.screenedDangerSigns && (
                                    <div className="p-3 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-xs space-y-1.5">
                                      <div className="text-[11px] font-bold text-slate-500 uppercase tracking-wide">
                                        Full Danger Signs Screened Matrix
                                      </div>
                                      <div className="flex flex-wrap gap-2">
                                        {item.screenedDangerSigns.map((ds, idx) => (
                                          <span
                                            key={idx}
                                            className={`px-2 py-0.5 rounded-md text-[11px] font-medium flex items-center gap-1 border ${
                                              ds.present
                                                ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-300 font-bold'
                                                : 'bg-slate-50 dark:bg-[#18181B] text-slate-600 dark:text-slate-400 border-slate-200 dark:border-[#26262A]'
                                            }`}
                                          >
                                            {ds.present ? (
                                              <AlertTriangle className="w-3 h-3 text-rose-600" />
                                            ) : (
                                              <Check className="w-3 h-3 text-emerald-600" />
                                            )}
                                            <span>{ds.sign}: {ds.present ? 'PRESENT' : 'ABSENT'}</span>
                                          </span>
                                        ))}
                                      </div>
                                    </div>
                                  )}

                                  {item.sms && (
                                    <div className="text-[11px] font-mono text-slate-600 dark:text-slate-400 bg-white dark:bg-[#202024] p-2 rounded border border-slate-200 dark:border-[#2E2E34]">
                                      <span className="font-bold text-slate-800 dark:text-slate-200">Raw Relayed Ingest: </span>
                                      {item.sms}
                                    </div>
                                  )}
                                </div>
                              </td>
                            </tr>
                          )}
                        </React.Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            /* DETAILED CLINICAL CASE CARDS */
            <div className="space-y-4">
              {filteredReferrals.map((item) => {
                const isRed = item.severity === 'RED';
                const minutesWaiting = Math.round(
                  (Date.now() - new Date(item.referredAt).getTime()) / (1000 * 60)
                );
                const sla = isRed ? slaLabel(item.referredAt, Date.now()) : null;
                const ageLabel =
                  item.ageMonths != null
                    ? `${item.ageMonths} mo`
                    : item.patientAge < 1
                      ? `${Math.round(item.patientAge * 12)} months`
                      : `${item.patientAge} yrs`;

                return (
                  <Card
                    key={item.id}
                    data-fresh-red={freshRedIds.includes(item.id) ? 'true' : 'false'}
                    className={`transition-all ${
                      freshRedIds.includes(item.id)
                        ? 'border-2 border-rose-500 bg-white dark:bg-[#18181B] shadow-xs'
                        : isRed
                        ? 'border-l-4 border-l-rose-500 border-slate-200 dark:border-[#26262A] bg-white dark:bg-[#18181B] shadow-xs'
                        : 'border-slate-200 dark:border-[#26262A] bg-white dark:bg-[#18181B]'
                    }`}
                  >
                    <CardContent className="p-5">
                      <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-5">
                        {/* Left: Patient clinical summary, danger signs, vitals */}
                        <div className="space-y-3 flex-1 min-w-0">
                          {/* Row 1: Triage Badge, Patient Name, ABHA ID */}
                          <div className="flex flex-wrap items-center gap-2.5">
                            <span
                              className={`px-2.5 py-0.5 rounded-full text-xs font-bold tracking-wide uppercase border flex items-center gap-1.5 ${
                                isRed
                                  ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-300 dark:border-rose-800'
                                  : 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-300 dark:border-amber-800'
                              }`}
                            >
                              <AlertTriangle className="w-3.5 h-3.5" />
                              {item.severity} TRIAGE
                            </span>

                            {item.isSmsRelayed && (
                              <Badge variant="sms" className="flex items-center gap-1">
                                <Radio className="w-3 h-3 text-cyan-500 animate-pulse" />
                                <span>SMS Gateway Relay</span>
                              </Badge>
                            )}

                            <h2 className="text-lg font-bold text-[#0F172A] dark:text-white flex items-center gap-2">
                              {item.patientName}
                              <span className="text-xs font-normal text-slate-500 dark:text-slate-400">
                                ({ageLabel}, {item.patientGender}{item.wardId ? `, ${item.wardId}` : ''})
                              </span>
                            </h2>

                            <span className="text-xs px-2 py-0.5 rounded-md bg-slate-100 dark:bg-[#202024] text-slate-700 dark:text-slate-300 font-medium border border-slate-200 dark:border-[#2E2E34]">
                              {item.village} • {item.subcentreId}
                            </span>

                            {/* ABHA Badge with copy */}
                            {item.abhaId && (
                              <div
                                onClick={() => handleCopyAbha(item.abhaId!)}
                                className="group inline-flex items-center space-x-1.5 px-2 py-0.5 rounded bg-slate-50 dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-slate-700 dark:text-slate-300 text-[11px] font-mono cursor-pointer hover:border-slate-400 transition-colors"
                                title="Click to copy ABHA ID"
                              >
                                <span className="font-semibold text-slate-900 dark:text-white">ABHA:</span>
                                <span>{item.abhaId}</span>
                                {copiedAbha === item.abhaId ? (
                                  <Check className="w-3 h-3 text-[#10B981]" />
                                ) : (
                                  <Copy className="w-3 h-3 text-slate-400 group-hover:text-black dark:group-hover:text-white" />
                                )}
                              </div>
                            )}
                          </div>

                          {/* Primary Referral Reason (Clinical Trigger) */}
                          <div className="text-sm font-semibold text-rose-700 dark:text-rose-300">
                            {item.reason}
                          </div>

                          {/* ASHA Clinical Field Observation */}
                          <div className="text-xs text-slate-700 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-[#202024] p-3 rounded-xl border border-slate-200 dark:border-[#2E2E34]">
                            <span className="font-bold text-slate-900 dark:text-white">ASHA Field Observation: </span>
                            {item.clinicalNote}
                          </div>

                          {/* Screened Danger Signs */}
                          {item.screenedDangerSigns && item.screenedDangerSigns.length > 0 && (
                            <div className="p-2.5 rounded-xl bg-slate-50/80 dark:bg-[#202024]/80 border border-slate-200 dark:border-[#2E2E34] text-xs space-y-1.5">
                              <div className="text-[11px] font-bold uppercase tracking-wider text-slate-500 flex items-center justify-between">
                                <span>IMNCI / Triage Danger Signs Screened</span>
                                <span className="text-[10px] text-slate-400 font-normal">Explicit negatives verified</span>
                              </div>
                              <div className="flex flex-wrap gap-2">
                                {item.screenedDangerSigns.map((ds, idx) => (
                                  <span
                                    key={idx}
                                    className={`px-2 py-0.5 rounded-md text-[11px] font-medium flex items-center gap-1 border ${
                                      ds.present
                                        ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-300 font-bold'
                                        : 'bg-white dark:bg-[#18181B] text-slate-600 dark:text-slate-400 border-slate-200 dark:border-[#26262A]'
                                    }`}
                                  >
                                    {ds.present ? (
                                      <AlertTriangle className="w-3 h-3 text-rose-600" />
                                    ) : (
                                      <Check className="w-3 h-3 text-emerald-600" />
                                    )}
                                    <span>
                                      {ds.sign}: {ds.present ? 'PRESENT' : 'ABSENT'}
                                    </span>
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {/* Vitals Pills Strip */}
                          {item.vitals && (
                            <div className="flex flex-wrap items-center gap-2 pt-0.5">
                              {item.vitals.bpSystolic && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900 text-rose-700 dark:text-rose-300 font-mono font-bold">
                                  BP: {item.vitals.bpSystolic}/{item.vitals.bpDiastolic} mmHg
                                </span>
                              )}
                              {item.vitals.respRate && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-slate-800 dark:text-slate-200 font-mono">
                                  Resp Rate: <span className="font-bold text-rose-600">{item.vitals.respRate}</span>/min
                                </span>
                              )}
                              {item.vitals.spo2 && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900 text-amber-800 dark:text-amber-200 font-mono font-bold">
                                  SpO2: {item.vitals.spo2}%
                                </span>
                              )}
                              {item.vitals.hemoglobin && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-slate-800 dark:text-slate-200 font-mono">
                                  Hb: {item.vitals.hemoglobin} g/dL
                                </span>
                              )}
                            </div>
                          )}
                        </div>

                        {/* Right: ASHA details, Arrival state, Clinical Actions */}
                        <div className="lg:w-84 space-y-3 lg:border-l lg:border-slate-200 dark:lg:border-[#26262A] lg:pl-5 flex flex-col justify-between shrink-0">
                          {/* Originating ASHA Context */}
                          <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] text-xs space-y-1.5">
                            <div className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Referring Frontline Worker</div>
                            <div className="font-bold text-slate-900 dark:text-white flex items-center justify-between">
                              <span>{item.ashaName}</span>
                              <span className="text-[10px] px-1.5 py-0.2 rounded bg-slate-200 dark:bg-[#26262A] text-slate-700 dark:text-slate-300 font-mono">ASHA</span>
                            </div>
                            <div className="flex items-center justify-between text-slate-600 dark:text-slate-400 pt-1 border-t border-slate-200 dark:border-[#2E2E34]">
                              <span className="font-mono text-[11px]">{item.ashaPhone}</span>
                              <a
                                href={`tel:${item.ashaPhone}`}
                                className="inline-flex items-center space-x-1 px-2.5 py-1 rounded-lg bg-white dark:bg-[#18181B] text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-slate-400 font-semibold text-xs transition-colors"
                              >
                                <Phone className="w-3 h-3 text-slate-500" />
                                <span>Call ASHA</span>
                              </a>
                            </div>
                          </div>

                          {/* Status and Time Tracking */}
                          <div className="flex items-center justify-between text-xs p-2.5 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34]">
                            <div className="space-y-0.5">
                              <div className="text-slate-500 text-[11px]">
                                Referred: {new Date(item.referredAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </div>
                              <div className={`text-[11px] font-semibold ${minutesWaiting > 30 && isRed ? 'text-rose-600 font-bold' : 'text-slate-500'}`}>
                                Wait: {minutesWaiting} mins {minutesWaiting > 30 && isRed ? '(OVERDUE)' : ''}
                              </div>
                              {sla && (
                                <div data-testid={`sla-${item.id}`} className={`text-[11px] font-bold ${sla.overdue ? 'text-rose-600' : 'text-emerald-700 dark:text-emerald-400'}`}>
                                  SLA {sla.text}
                                </div>
                              )}
                            </div>
                            <span
                              className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase border ${
                                item.status === 'pending'
                                  ? 'bg-amber-50 text-amber-800 border-amber-300 dark:bg-amber-950/40 dark:text-amber-300'
                                  : item.status === 'arrived'
                                  ? 'bg-sky-50 text-sky-800 border-sky-300 dark:bg-sky-950/40 dark:text-sky-300'
                                  : 'bg-emerald-50 text-emerald-800 border-emerald-300 dark:bg-emerald-950/40 dark:text-emerald-300'
                              }`}
                            >
                              {item.status.replace('_', ' ')}
                            </span>
                          </div>

                          {/* Doctor Action Buttons */}
                          <div className="space-y-2 pt-1">
                            {item.status === 'pending' && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => acknowledgeMutation.mutate(item.id)}
                                disabled={acknowledgeMutation.isPending}
                                className="w-full text-slate-800 dark:text-slate-200 border-slate-200 dark:border-slate-700"
                              >
                                <CheckCircle2 className="w-3.5 h-3.5 mr-1 text-slate-600 dark:text-slate-400" />
                                <span>ACKNOWLEDGE</span>
                              </Button>
                            )}
                            {(item.status === 'pending' || item.status === 'arrived') && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => consultMutation.mutate(item.id)}
                                disabled={consultMutation.isPending}
                                className="w-full border-slate-200 dark:border-slate-700"
                              >
                                <span>START CONSULT</span>
                              </Button>
                            )}
                            <NavLink to={`/ticket/${item.id}`} className="block text-center text-xs font-semibold text-slate-700 dark:text-slate-300 underline">
                              Open ticket
                            </NavLink>

                            <div className="grid grid-cols-2 gap-2">
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleOpenAbdmHiu(item)}
                                className="text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700"
                              >
                                <FileText className="w-3.5 h-3.5 mr-1 text-slate-500" />
                                <span>ABDM HIU</span>
                              </Button>

                              <Button
                                size="sm"
                                variant="default"
                                onClick={() => {
                                  setSelectedReferral(item);
                                  setOutcomeStatus('treated');
                                }}
                                className="bg-[#0C5A3E] hover:bg-[#08422E] text-white font-bold"
                              >
                                <Stethoscope className="w-3.5 h-3.5 mr-1" />
                                <span>Record Outcome</span>
                              </Button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </TabsContent>

        {/* TAB 2: Active Area Health Lists & Cohort Registries */}
        <TabsContent value="area_lists" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-5 space-y-3">
              <div className="flex items-center space-x-2 text-[#F43F5E]">
                <Heart className="w-5 h-5" />
                <CardTitle className="text-sm">High-Risk Pregnancies</CardTitle>
              </div>
              <div className="text-2xl font-black text-[#0F172A] dark:text-white">18 Identified</div>
              <CardDescription>
                Severe anaemia (6), Pre-eclampsia (4), Previous C-section (5), Gestational Diabetes (3).
              </CardDescription>
              <div className="text-[11px] text-[#10B981] font-semibold">
                ✓ All assigned to PHC MO weekly review queue.
              </div>
            </Card>

            <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-5 space-y-3">
              <div className="flex items-center space-x-2 text-[#F59E0B]">
                <AlertTriangle className="w-5 h-5" />
                <CardTitle className="text-sm">Sick Newborns (PSBI / IMNCI)</CardTitle>
              </div>
              <div className="text-2xl font-black text-[#0F172A] dark:text-white">7 Monitored</div>
              <CardDescription>
                Active HBNC home visit follow-ups. 2 referred for urgent paediatric assessment.
              </CardDescription>
              <div className="text-[11px] text-[#F59E0B] font-semibold">
                Daily ASHA 60s respiratory tap checks active.
              </div>
            </Card>

            <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-5 space-y-3">
              <div className="flex items-center space-x-2 text-[#8B5CF6]">
                <Activity className="w-5 h-5" />
                <CardTitle className="text-sm">TB Defaulters & Sputum</CardTitle>
              </div>
              <div className="text-2xl font-black text-[#0F172A] dark:text-white">12 on Regimen</div>
              <CardDescription>
                Nikshay synced daily. 1 treatment interruption flagged in Majra Khas; ASHA notified.
              </CardDescription>
              <div className="text-[11px] text-[#8B5CF6] font-semibold">
                Nikshay ID digital linking active.
              </div>
            </Card>

            <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-5 space-y-3">
              <div className="flex items-center space-x-2 text-[#10B981]">
                <Droplet className="w-5 h-5" />
                <CardTitle className="text-sm">NCD HTN / Diabetes Defaulters</CardTitle>
              </div>
              <div className="text-2xl font-black text-[#0F172A] dark:text-white">34 Overdue Meds</div>
              <CardDescription>
                Hypertension prescription renewals due this month. Sub-centre drug refill lists mapped.
              </CardDescription>
              <div className="text-[11px] text-[#10B981] font-semibold">
                Automated SMS reminder queued.
              </div>
            </Card>
          </div>
        </TabsContent>

        {/* TAB 3: Facility Planning & 4-Week Demand */}
        <TabsContent value="planning" className="space-y-4">
          <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-4">
            <div className="flex items-center space-x-2">
              <Calendar className="w-5 h-5 text-[#F59E0B]" />
              <CardTitle className="text-base">4-Week Facility Demand Forecast (Requirement 41.4)</CardTitle>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] space-y-2">
                <div className="text-xs text-[#525252] dark:text-[#A3A3A3] font-semibold">Expected Institutional Deliveries</div>
                <div className="text-2xl font-black text-[#F59E0B]">42 Mothers</div>
                <p className="text-xs text-[#71717A]">
                  12 high-risk pregnancies scheduled with advance 108 transport booking.
                </p>
              </div>

              <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] space-y-2">
                <div className="text-xs text-[#525252] dark:text-[#A3A3A3] font-semibold">VHSND Immunization Demand</div>
                <div className="text-2xl font-black text-[#10B981]">18 Sessions Planned</div>
                <p className="text-xs text-[#71717A]">
                  Target: 210 Pentavalent, 185 BCG, 140 MR doses required from cold-chain store.
                </p>
              </div>

              <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] space-y-2">
                <div className="text-xs text-[#525252] dark:text-[#A3A3A3] font-semibold">Commodity Stock Readiness</div>
                <div className="text-2xl font-black text-[#F43F5E]">1 Critical Stockout</div>
                <p className="text-xs text-[#71717A]">
                  Pregnancy test kits low (4 days left). Emergency indents raised to District CMSO.
                </p>
                <NavLink to="/resources" className="text-xs font-semibold text-rose-700 underline">
                  PCMC early warning: Ward W3 dengue NS1 stock
                </NavLink>
              </div>
            </div>
          </Card>
        </TabsContent>

        {/* TAB 4: Inpatient (IPD) / Stabilization Ward */}
        <TabsContent value="ipd_ward" className="space-y-4">
          <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-4">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <div>
                <CardTitle className="text-base flex items-center gap-2">
                  <Bed className="w-5 h-5 text-teal-500" />
                  PHC Observation & Maternity Stabilization Ward
                </CardTitle>
                <CardDescription>
                  16 Total Capacity • 12 Active Beds • Staff Nurse on Duty: Sister Anjali • Emergency Oxygen Cylinders: 4 Full
                </CardDescription>
              </div>
              <Badge variant="outline" className="text-teal-700 dark:text-teal-300 border-teal-300 dark:border-teal-500/30">
                75% Bed Occupancy
              </Badge>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-8 gap-3">
              {[
                { bed: 'Bed 01', patient: 'Sunita Devi', status: 'pre-eclampsia', borderAccent: 'border-l-4 border-l-rose-500' },
                { bed: 'Bed 02', patient: 'Baby of Kavita', status: 'PSBI Oxy', borderAccent: 'border-l-4 border-l-rose-500' },
                { bed: 'Bed 03', patient: 'Kamlesh W.', status: 'Post-delivery', borderAccent: 'border-l-4 border-l-emerald-500' },
                { bed: 'Bed 04', patient: 'Suman R.', status: 'Post-delivery', borderAccent: 'border-l-4 border-l-emerald-500' },
                { bed: 'Bed 05', patient: 'Pooja T.', status: 'IV Iron', borderAccent: 'border-l-4 border-l-amber-500' },
                { bed: 'Bed 06', patient: 'Kavita M.', status: 'Observation', borderAccent: 'border-l-4 border-l-teal-500' },
                { bed: 'Bed 07', patient: 'Rukhsana', status: 'Labour Room', borderAccent: 'border-l-4 border-l-rose-500' },
                { bed: 'Bed 08', patient: 'Meena P.', status: 'Post-delivery', borderAccent: 'border-l-4 border-l-emerald-500' },
                { bed: 'Bed 09', patient: 'Lata B.', status: 'Fever OBS', borderAccent: 'border-l-4 border-l-amber-500' },
                { bed: 'Bed 10', patient: 'Roshni G.', status: 'IV Fluids', borderAccent: 'border-l-4 border-l-teal-500' },
                { bed: 'Bed 11', patient: 'Reena S.', status: 'Maternity', borderAccent: 'border-l-4 border-l-emerald-500' },
                { bed: 'Bed 12', patient: 'Aarti D.', status: 'Post-Op', borderAccent: 'border-l-4 border-l-teal-500' },
                { bed: 'Bed 13', patient: 'AVAILABLE', status: 'Cleaned', borderAccent: 'border-l-4 border-l-slate-300 dark:border-l-[#404040]' },
                { bed: 'Bed 14', patient: 'AVAILABLE', status: 'Cleaned', borderAccent: 'border-l-4 border-l-slate-300 dark:border-l-[#404040]' },
                { bed: 'Bed 15', patient: 'AVAILABLE', status: 'Cleaned', borderAccent: 'border-l-4 border-l-slate-300 dark:border-l-[#404040]' },
                { bed: 'Bed 16', patient: 'AVAILABLE', status: 'Cleaned', borderAccent: 'border-l-4 border-l-slate-300 dark:border-l-[#404040]' },
              ].map((b, i) => (
                <div
                  key={i}
                  className={`p-3 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-xs space-y-1 ${b.borderAccent}`}
                >
                  <div className="font-bold text-[11px] text-[#0F172A] dark:text-[#F8FAFC] flex items-center justify-between">
                    <span>{b.bed}</span>
                    <Bed className="w-3.5 h-3.5 text-[#71717A]" />
                  </div>
                  <div className="font-semibold text-[#0F172A] dark:text-white truncate">{b.patient}</div>
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">{b.status}</div>
                </div>
              ))}
            </div>
          </Card>
        </TabsContent>

        {/* TAB 5: Emergency SMS Gateway Feed */}
        <TabsContent value="sms_feed" className="space-y-4">
          <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-4">
            <div className="flex items-center space-x-2 text-cyan-600 dark:text-cyan-400">
              <Radio className="w-5 h-5 animate-pulse" />
              <CardTitle className="text-base">Offline Dead-Zone SMS Triage Gateway (SMS-Relayed Inflow)</CardTitle>
            </div>
            <CardDescription>
              When an ASHA assesses a critical patient in a hamlet without cellular data (2G/voice only), the mobile app compiles an encrypted 140-char SMS triage ticket containing patient vitals, severity band, and danger signs, and transmits it directly to the PHC modem gateway.
            </CardDescription>

            <div className="space-y-3 pt-2">
              {referrals.filter((r) => r.isSmsRelayed).map((smsRef) => (
                <div key={smsRef.id} className="p-4 rounded-xl bg-slate-50 dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <Badge variant="sms">SMS Ingest</Badge>
                      <span className="font-bold text-[#0F172A] dark:text-white text-sm">{smsRef.patientName}</span>
                      <span className="text-xs text-[#525252] dark:text-[#A3A3A3]">({smsRef.village})</span>
                    </div>
                    <span className="text-xs font-mono text-cyan-700 dark:text-cyan-400">Gateway Mod: +91 94180 55443</span>
                  </div>
                  <p className="text-xs text-slate-800 dark:text-slate-300 font-mono bg-slate-50 dark:bg-[#181818] p-2.5 rounded-lg border border-slate-200 dark:border-[#2E2E2E]">
                    RAW SMS: [SETU_RED#BP190/125#PULSE112#RR26#SPO2:93#CRISIS_CHEST_PAIN#ASHA:KamlaThakur#TICKET_091]
                  </p>
                  <div className="flex justify-between items-center text-xs">
                    <span className="text-[#525252] dark:text-[#A3A3A3]">Decoded & Assigned to Doctor Triage Queue</span>
                    <Button
                      size="xs"
                      variant="destructive"
                      onClick={() => {
                        setSelectedReferral(smsRef);
                        setOutcomeStatus('treated');
                      }}
                    >
                      Record Outcome
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </TabsContent>

        {/* TAB 6: Live Catchment GIS Field Map */}
        <TabsContent value="catchment_map" className="space-y-4">
          <Card className="border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] overflow-hidden rounded-2xl shadow-sm">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-emerald-600" />
                  PHC Shahpur Catchment Map & Fleet Tracking
                </h3>
                <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
                  Live GPS positions of 108 ambulances, 6 linked sub-centres, 15m/30m catchment isochrones, and offline SMS hamlets
                </p>
              </div>
              <NavLink to="/map">
                <Button size="xs" variant="outline" className="text-xs gap-1">
                  <Maximize2 className="w-3.5 h-3.5" />
                  <span>Full Screen Map &rarr;</span>
                </Button>
              </NavLink>
            </div>
            <div className="h-[620px] w-full">
              <OsmAndMapPage />
            </div>
          </Card>
        </TabsContent>
      </Tabs>

      {/* 3. Record Clinical Outcome & Doctor Feedback Modal (Shadcn Dialog) */}
      <Dialog open={!!selectedReferral} onOpenChange={(open) => !open && setSelectedReferral(null)}>
        {selectedReferral && (
          <DialogContent onClose={() => setSelectedReferral(null)} className="max-w-xl">
            <DialogHeader>
              <DialogTitle>
                <Stethoscope className="w-5 h-5 text-[#10B981]" />
                Record Outcome: {selectedReferral.patientName}
              </DialogTitle>
              <DialogDescription>
                Primary Health Centre Shahpur • Triage Flag: {selectedReferral.severity} • Referring ASHA: {selectedReferral.ashaName}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-[#0F172A] dark:text-slate-200 mb-1.5">
                  Clinical Outcome & Care Disposition (Pushes Real-Time Notification to ASHA & ANM)
                </label>
                <select
                  value={outcomeStatus}
                  onChange={(e) => setOutcomeStatus(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-slate-100 text-xs focus:outline-none focus:border-[#10B981]"
                >
                  <option value="treated">Treated & Discharged (Outpatient Consultation)</option>
                  <option value="admitted">Admitted to PHC Inpatient Observation Ward</option>
                  <option value="discharged">Transferred to District Hospital via 108 Ambulance</option>
                  <option value="did_not_reach">Did Not Reach Facility (Defaulted / Not Arrived)</option>
                </select>
              </div>

              {/* Quick Clinical Prescription Tags */}
              <div>
                <label className="block text-xs font-semibold text-[#525252] dark:text-[#A3A3A3] mb-1 flex items-center justify-between">
                  <span>Quick Prescriptions & Clinical Orders:</span>
                  <span className="text-[10px] text-[#71717A]">Click to append</span>
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    'IV Labetalol 20mg stat',
                    'Inj Magnesium Sulphate 5g IM',
                    'Inj Ceftriaxone 500mg IV',
                    'Nebulization Salbutamol',
                    'Oral Amoxicillin 250mg TDS',
                    'Oral Iron Folic Acid (IFA)',
                    'ORS & Zinc Co-pack',
                    'IV Fluids Ringers Lactate 500ml',
                  ].map((drug) => (
                    <button
                      key={drug}
                      type="button"
                      onClick={() => togglePrescriptionTag(drug)}
                      className={`px-2 py-1 rounded-lg text-[11px] font-medium border transition-colors cursor-pointer ${
                        selectedPrescriptions.includes(drug)
                          ? 'bg-emerald-50 dark:bg-emerald-600/30 border-emerald-400 text-emerald-800 dark:text-emerald-200'
                          : 'bg-slate-100 dark:bg-[#1E1E1E] border-slate-200 dark:border-[#2E2E2E] text-slate-700 dark:text-[#F8FAFC] hover:bg-slate-200 dark:hover:bg-[#2A2A2A]'
                      }`}
                    >
                      <Pill className="w-3 h-3 inline mr-1 opacity-70" />
                      {drug}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                {/* Note: Label MUST contain "Clinical Outcome & Diagnosis Notes" for test 14.6 */}
                <label className="block text-xs font-semibold text-[#0F172A] dark:text-slate-200 mb-1.5">
                  Clinical Outcome & Diagnosis Notes
                </label>
                <Textarea
                  rows={3}
                  value={outcomeNotes}
                  onChange={(e) => setOutcomeNotes(e.target.value)}
                  placeholder="e.g. Administered IV labetalol; BP stabilized to 135/88 mmHg. Continue oral alpha-methyldopa."
                  className="bg-slate-50 dark:bg-[#181818] text-xs"
                />
              </div>

              {/* Feedback to Originating ASHA Worker */}
              <div className="pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
                <label className="block text-xs font-semibold text-[#0F172A] dark:text-slate-200 mb-1 flex items-center justify-between">
                  <span>Send Doctor Feedback to ASHA {selectedReferral.ashaName} (Req 41.5)</span>
                  {feedbackSent && (
                    <span className="text-[#10B981] text-xs flex items-center gap-1">
                      <Check className="w-3.5 h-3.5" /> Sent to ASHA app
                    </span>
                  )}
                </label>
                <div className="flex gap-2">
                  <Input
                    type="text"
                    value={feedbackMessage}
                    onChange={(e) => setFeedbackMessage(e.target.value)}
                    placeholder="e.g., Excellent triage detection. Patient is now stable."
                    className="flex-1 bg-slate-50 dark:bg-[#181818] text-xs h-9"
                  />
                  <Button
                    size="sm"
                    variant="success"
                    disabled={!feedbackMessage || feedbackMutation.isPending}
                    onClick={() =>
                      feedbackMutation.mutate({
                        refId: selectedReferral.id,
                        ashaId: selectedReferral.ashaId,
                        msg: feedbackMessage,
                      })
                    }
                  >
                    <Send className="w-3.5 h-3.5 mr-1" />
                    <span>Send</span>
                  </Button>
                </div>
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedReferral(null)}
              >
                Cancel
              </Button>
              <Button
                variant="default"
                size="sm"
                disabled={outcomeMutation.isPending}
                onClick={() =>
                  outcomeMutation.mutate({
                    id: selectedReferral.id,
                    status: outcomeStatus,
                    notes: outcomeNotes,
                  })
                }
              >
                {outcomeMutation.isPending ? 'Saving...' : 'Confirm & Push Notification'}
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>

      {/* 4. ABDM HIU Historical Records Modal (Shadcn Dialog) */}
      <Dialog open={!!selectedAbdmItem} onOpenChange={(open) => !open && setSelectedAbdmItem(null)}>
        {selectedAbdmItem && (
          <DialogContent onClose={() => setSelectedAbdmItem(null)} className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                <FileText className="w-5 h-5 text-sky-500" />
                ABDM HIU Historical Record: {selectedAbdmItem.patientName}
              </DialogTitle>
              <DialogDescription>
                Ayushman Bharat Health Account (ABHA):{' '}
                <span className="font-mono text-[#10B981] font-bold">
                  {selectedAbdmItem.abhaId || '91-8765-4321-0987'}
                </span>{' '}
                • Consent Artifact: AR-HIU-2026-9812
              </DialogDescription>
            </DialogHeader>

            {isLoadingAbdm ? (
              <div className="py-12 text-center text-slate-400 text-sm animate-pulse space-y-2">
                <Activity className="w-8 h-8 text-sky-500 animate-spin mx-auto" />
                <p>Querying ABDM Gateway via HIU Consent Artifact...</p>
              </div>
            ) : abdmData ? (
              <div className="space-y-4">
                <div className="p-3 rounded-xl bg-sky-50 dark:bg-sky-950/40 border border-sky-200 dark:border-sky-500/30 text-xs text-sky-900 dark:text-sky-200">
                  ✓ ABDM Health Information User (HIU) consent verified. Displaying longitudinal health records linked to this ABHA ID across all registered health facilities in the National Health Exchange.
                </div>

                <div>
                  <h4 className="text-xs font-bold text-[#0F172A] dark:text-slate-300 uppercase tracking-wider mb-2">
                    Linked Care Contexts ({abdmData.linked_care_contexts?.length || 0})
                  </h4>
                  <div className="space-y-2">
                    {abdmData.linked_care_contexts?.map((ctx: any, i: number) => (
                      <div key={i} className="p-3 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-xs space-y-1">
                        <div className="flex items-center justify-between text-slate-500">
                          <span className="font-bold text-[#0F172A] dark:text-slate-200">{ctx.facility}</span>
                          <span className="font-mono text-[10px] text-sky-600 dark:text-sky-400">{ctx.date}</span>
                        </div>
                        <div className="text-slate-700 dark:text-slate-300">{ctx.summary}</div>
                        <span className="inline-block text-[10px] px-2 py-0.5 rounded bg-slate-200 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#A3A3A3] font-mono border border-slate-200 dark:border-[#404040]">
                          {ctx.type} • {ctx.context_id}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {abdmData.immunization_history && (
                  <div>
                    <h4 className="text-xs font-bold text-[#0F172A] dark:text-slate-300 uppercase tracking-wider mb-2">
                      Digital Immunization Record (U-WIN Synced)
                    </h4>
                    <div className="grid grid-cols-2 gap-2">
                      {abdmData.immunization_history.map((imm: any, i: number) => (
                        <div key={i} className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-xs">
                          <div className="font-bold text-[#10B981]">{imm.vaccine}</div>
                          <div className="text-[11px] text-slate-500 dark:text-slate-400">{imm.facility} • {imm.date}</div>
                          <div className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold">Status: {imm.status}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ) : null}

            <DialogFooter>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedAbdmItem(null)}
              >
                Close Historical View
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}
