import { useState, useMemo, useEffect, useRef } from 'react';
import { NavLink } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getReferralQueue,
  recordReferralOutcome,
  sendDoctorFeedback,
  acknowledgeReferral,
  fetchAbdmHiuRecords,
  startConsult,
} from '@/shared/api/referralApi';
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
  const [activeTab, setActiveTab] = useState<'referrals' | 'area_lists' | 'planning' | 'ipd_ward' | 'sms_feed' | 'catchment_map'>('referrals');
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'SMS'>('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'pending' | 'arrived' | 'treated' | 'admitted'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  
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
        {/* Top Header Card */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 rounded-2xl bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] shadow-xs backdrop-blur-xl transition-colors">
          <div className="space-y-1">
            <div className="flex items-center space-x-3">
              <div className="p-2.5 rounded-xl bg-rose-50 dark:bg-rose-500/10 border border-rose-200 dark:border-rose-500/20 text-[#F43F5E]">
                <Activity className="w-6 h-6" />
              </div>
              <div>
                <h1 className="text-xl font-extrabold text-[#0F172A] dark:text-white flex items-center gap-2 tracking-tight">
                  PHC Shahpur Emergency Triage & Referral Queue
                  {isRefetching && (
                    <span className="text-[11px] text-[#10B981] font-normal animate-pulse">
                      (Syncing live...)
                    </span>
                  )}
                </h1>
                <p className="text-xs text-[#525252] dark:text-[#A3A3A3]">
                  Primary Health Centre Shahpur • Facility Code: PHC-SHP-04 • National Health Mission (NHM) • Polling live every 30s
                </p>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setSoundAlertEnabled(!soundAlertEnabled)}
              className={soundAlertEnabled ? 'text-emerald-700 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/30' : 'text-[#71717A]'}
              title="Audio alert chime on incoming emergency"
            >
              <Volume2 className="w-3.5 h-3.5 mr-1" />
              <span>Chime {soundAlertEnabled ? 'On' : 'Off'}</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveTab('catchment_map')}
              className="text-emerald-700 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/30 gap-1.5"
              title="Open Catchment Field Map"
            >
              <MapPin className="w-3.5 h-3.5" />
              <span>Field Map</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => refetch()}
              className="text-[#0F172A] dark:text-[#F8FAFC]"
            >
              <RefreshCw className={`w-3.5 h-3.5 mr-1 ${isRefetching ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </Button>
          </div>
        </div>

        {/* Urgent Alert Banner (Pops if any RED is waiting) */}
        {redCount > 0 && (
          <div className="flex items-center justify-between p-4 rounded-xl bg-white dark:bg-[#222224] border-l-4 border-l-rose-500 border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs shadow-xs">
            <div className="flex items-center space-x-3">
              <div className="relative flex h-2.5 w-2.5 shrink-0">
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
              </div>
              <div>
                <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC] text-sm">
                  CRITICAL TRIAGE ALERT: {redCount} High-Risk Beneficiar{redCount > 1 ? 'ies' : 'y'} Pending Immediate Doctor Attention!
                </span>
                <p className="text-[#525252] dark:text-[#94A3B8] text-[11px] mt-0.5">
                  Pre-eclampsia, neonatal chest indrawing, or hypertensive emergency detected in field. Standard clinical SLA: &lt; 30 minutes.
                </p>
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
              View Urgent Queue &rarr;
            </Button>
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
          <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 p-3 rounded-xl bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] shadow-xs">
            {/* Search Input */}
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-[#71717A] absolute left-3 top-2.5" />
              <Input
                type="text"
                placeholder="Search patient, ABHA ID, village, or ASHA..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 pr-4 h-9 bg-slate-50 dark:bg-[#1E1E1E]"
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

            {/* Severity Pill Filters */}
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-[11px] text-[#525252] dark:text-[#A3A3A3] font-semibold mr-1">Severity:</span>
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
                className="flex items-center gap-1 text-cyan-600 dark:text-cyan-300 border-cyan-300 dark:border-cyan-500/30"
              >
                <Radio className="w-3 h-3 text-cyan-500" />
                SMS Relayed ({referrals.filter((r) => r.isSmsRelayed).length})
              </Button>
            </div>
          </div>

          {/* Referral Cards Feed */}
          {filteredReferrals.length === 0 ? (
            <div className="py-16 text-center text-slate-500 space-y-2 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224]">
              <CheckCircle className="w-8 h-8 text-[#10B981] mx-auto" />
              <p className="font-semibold text-[#0F172A] dark:text-slate-200">No pending referrals match your filter.</p>
              <p className="text-xs text-[#71717A]">All emergency patients have been reviewed or discharged.</p>
            </div>
          ) : (
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
                        ? 'border-rose-600 ring-2 ring-rose-500 bg-rose-50 dark:bg-rose-950/40'
                        : isRed
                        ? 'border-l-4 border-l-rose-500 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs'
                        : 'border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224]'
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
                                  ? 'bg-rose-500/15 text-[#F43F5E] border-rose-500/40 pulse-urgent'
                                  : 'bg-amber-500/15 text-[#F59E0B] border-amber-500/40'
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
                              <span className="text-xs font-normal text-[#525252] dark:text-[#A3A3A3]">
                                ({ageLabel}, {item.patientGender}{item.wardId ? `, ${item.wardId}` : ''})
                              </span>
                            </h2>

                            <span className="text-xs px-2 py-0.5 rounded-md bg-slate-100 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#F8FAFC] font-medium border border-slate-200 dark:border-[#404040]">
                              {item.village} • {item.subcentreId}
                            </span>

                            {/* ABHA Badge with copy */}
                            {item.abhaId && (
                              <div
                                onClick={() => handleCopyAbha(item.abhaId!)}
                                className="group inline-flex items-center space-x-1.5 px-2 py-0.5 rounded bg-sky-50 dark:bg-sky-950/60 border border-sky-300 dark:border-sky-500/30 text-sky-800 dark:text-sky-300 text-[11px] font-mono cursor-pointer hover:bg-sky-100 dark:hover:bg-sky-900/60 transition-colors"
                                title="Click to copy ABHA ID"
                              >
                                <span className="font-semibold text-sky-600 dark:text-sky-400">ABHA:</span>
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
                          <div className="text-sm font-semibold text-rose-700 dark:text-rose-200">
                            {item.reason}
                          </div>
                          {item.firedRules && item.firedRules.length > 0 && (
                            <details className="text-xs text-slate-700 dark:text-slate-300">
                              <summary className="cursor-pointer font-semibold">Reasons</summary>
                              <ul className="mt-1 space-y-1">
                                {item.firedRules.map((rule) => (
                                  <li key={rule.ruleId}>
                                    {rule.ruleId}: {rule.reason}
                                  </li>
                                ))}
                              </ul>
                            </details>
                          )}
                          {item.sms && (
                            <p className="font-mono text-[11px] text-slate-600 dark:text-slate-300">{item.sms}</p>
                          )}
                          {item.outbreakContext && (
                            <p className="text-xs text-amber-700 dark:text-amber-300">{item.outbreakContext}</p>
                          )}

                          {/* ASHA Clinical Field Observation */}
                          <div className="text-xs text-slate-700 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-[#181818] p-3 rounded-xl border border-slate-200 dark:border-[#2E2E2E]">
                            <span className="font-bold text-[#0F172A] dark:text-white">ASHA Field Observation: </span>
                            {item.clinicalNote}
                          </div>

                          {/* Explicit Danger Signs Screened (Absent vs Present Matrix - §6a.3) */}
                          {item.screenedDangerSigns && item.screenedDangerSigns.length > 0 && (
                            <div className="p-2.5 rounded-xl bg-slate-50/80 dark:bg-[#1A1A1A] border border-slate-200 dark:border-[#2E2E2E] text-xs space-y-1.5">
                              <div className="text-[11px] font-bold uppercase tracking-wider text-[#71717A] flex items-center justify-between">
                                <span>IMNCI / Triage Danger Signs Screened</span>
                                <span className="text-[10px] text-slate-500 font-normal">Explicit negatives verified</span>
                              </div>
                              <div className="flex flex-wrap gap-2">
                                {item.screenedDangerSigns.map((ds, idx) => (
                                  <span
                                    key={idx}
                                    className={`px-2 py-0.5 rounded-md text-[11px] font-medium flex items-center gap-1 border ${
                                      ds.present
                                        ? 'bg-rose-50 dark:bg-rose-500/15 text-[#F43F5E] border-rose-200 dark:border-rose-500/30 font-bold'
                                        : 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-500/20'
                                    }`}
                                  >
                                    {ds.present ? (
                                      <AlertTriangle className="w-3 h-3 text-[#F43F5E]" />
                                    ) : (
                                      <Check className="w-3 h-3 text-[#10B981]" />
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
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  BP: <span className="font-bold text-[#F43F5E]">{item.vitals.bpSystolic}/{item.vitals.bpDiastolic}</span> mmHg
                                </span>
                              )}
                              {item.vitals.respRate && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  Resp Rate: <span className="font-bold text-[#F43F5E]">{item.vitals.respRate}</span>/min
                                </span>
                              )}
                              {item.vitals.spo2 && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  SpO2: <span className="font-bold text-[#F59E0B]">{item.vitals.spo2}%</span>
                                </span>
                              )}
                              {item.vitals.hemoglobin && (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  Hb: <span className="font-bold text-[#F43F5E]">{item.vitals.hemoglobin}</span> g/dL
                                </span>
                              )}
                              {item.tempC != null ? (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  Temp: {item.tempC} °C
                                </span>
                              ) : item.vitals.temp ? (
                                <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-slate-800 dark:text-slate-200 font-mono">
                                  Temp: {item.vitals.temp} °F
                                </span>
                              ) : null}
                            </div>
                          )}
                        </div>

                        {/* Right: ASHA details, Arrival state, Clinical Actions */}
                        <div className="lg:w-84 space-y-3 lg:border-l lg:border-[#E5E7EB] dark:lg:border-[#2E2E2E] lg:pl-5 flex flex-col justify-between">
                          {/* Originating ASHA Context */}
                          <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E] text-xs space-y-1.5">
                            <div className="text-[11px] font-bold uppercase tracking-wider text-[#71717A]">Referring Frontline Worker</div>
                            <div className="font-bold text-[#0F172A] dark:text-white flex items-center justify-between">
                              <span>{item.ashaName}</span>
                              <span className="text-[10px] px-1.5 py-0.2 rounded bg-slate-200 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#A3A3A3]">ASHA</span>
                            </div>
                            <div className="flex items-center justify-between text-[#525252] dark:text-[#A3A3A3] pt-1 border-t border-slate-200 dark:border-[#2E2E2E]">
                              <span className="font-mono text-[11px]">{item.ashaPhone}</span>
                              <a
                                href={`tel:${item.ashaPhone}`}
                                className="inline-flex items-center space-x-1 px-2.5 py-1 rounded-lg bg-emerald-50 dark:bg-emerald-600/20 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-100 dark:hover:bg-emerald-600/30 font-semibold text-xs transition-colors"
                              >
                                <Phone className="w-3 h-3" />
                                <span>Call ASHA</span>
                              </a>
                            </div>
                          </div>

                          {/* Status and Time Tracking */}
                          <div className="flex items-center justify-between text-xs p-2 rounded-lg bg-slate-50 dark:bg-[#181818] border border-slate-200 dark:border-[#2E2E2E]">
                            <div className="space-y-0.5">
                              <div className="text-[#71717A] text-[11px]">
                                Referred: {new Date(item.referredAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </div>
                              <div className={`text-[11px] font-semibold ${minutesWaiting > 30 && isRed ? 'text-[#F43F5E] font-bold' : 'text-[#71717A]'}`}>
                                Wait: {minutesWaiting} mins {minutesWaiting > 30 && isRed ? '(OVERDUE)' : ''}
                              </div>
                              {sla && (
                                <div data-testid={`sla-${item.id}`} className={`text-[11px] font-bold ${sla.overdue ? 'text-[#F43F5E]' : 'text-emerald-700'}`}>
                                  SLA {sla.text}
                                </div>
                              )}
                            </div>
                            <span
                              className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase border ${
                                item.status === 'pending'
                                  ? 'bg-amber-50 dark:bg-amber-500/15 text-[#F59E0B] border-amber-200 dark:border-amber-500/30'
                                  : item.status === 'arrived'
                                  ? 'bg-sky-50 dark:bg-sky-500/15 text-sky-700 dark:text-sky-300 border-sky-200 dark:border-sky-500/30'
                                  : item.status === 'treated' || item.status === 'admitted'
                                  ? 'bg-emerald-50 dark:bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-500/30'
                                  : 'bg-slate-100 dark:bg-[#2E2E2E] text-slate-700 dark:text-[#A3A3A3] border-slate-200 dark:border-[#404040]'
                              }`}
                            >
                              {item.status.replace('_', ' ')}
                            </span>
                          </div>

                          {/* Doctor Action Buttons */}
                          <div className="space-y-2 pt-1">
                            {/* Doctor Ack: Mark Patient Arrived */}
                            {item.status === 'pending' && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => acknowledgeMutation.mutate(item.id)}
                                disabled={acknowledgeMutation.isPending}
                                className="w-full text-emerald-700 dark:text-emerald-300 border-emerald-300 dark:border-emerald-500/30 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"
                              >
                                <CheckCircle2 className="w-3.5 h-3.5 mr-1 text-[#10B981]" />
                                <span>ACKNOWLEDGE</span>
                              </Button>
                            )}
                            {(item.status === 'pending' || item.status === 'arrived') && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => consultMutation.mutate(item.id)}
                                disabled={consultMutation.isPending}
                                className="w-full"
                              >
                                <span>START CONSULT</span>
                              </Button>
                            )}
                            <NavLink to={`/ticket/${item.id}`} className="block text-center text-xs font-semibold text-emerald-700 dark:text-emerald-300 underline">
                              Open ticket
                            </NavLink>

                            <div className="grid grid-cols-2 gap-2">
                              {/* ABDM Longitudinal HIU Button */}
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleOpenAbdmHiu(item)}
                                className="text-sky-700 dark:text-sky-300 border-sky-300 dark:border-sky-500/30 hover:bg-sky-50 dark:hover:bg-sky-950/40"
                              >
                                <FileText className="w-3.5 h-3.5 mr-1 text-sky-500" />
                                <span>ABDM HIU</span>
                              </Button>

                              {/* Record Clinical Outcome Button (Tested in vitest) */}
                              <Button
                                size="sm"
                                variant="default"
                                onClick={() => {
                                  setSelectedReferral(item);
                                  setOutcomeStatus('treated');
                                }}
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
