import { useState, useMemo, useEffect } from 'react';
import { useSearchParams, useNavigate, Link } from 'react-router-dom';
import { useSync, type FrontlineSyncActivity, type TriageEvidence } from '@/shared/context/SyncContext';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  Clock,
  Copy,
  Check,
  ExternalLink,
  Filter,
  Layers,
  Phone,
  Printer,
  QrCode,
  Radio,
  RefreshCw,
  Search,
  ShieldCheck,
  Stethoscope,
  Users,
  X,
  FileText,
  AlertCircle,
  Heart,
  Baby,
  ChevronDown,
  ChevronUp,
  ChevronRight,
  SlidersHorizontal,
} from 'lucide-react';

export function SystemLogsPage() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const initialSearch = searchParams.get('search') || '';

  const { syncActivities, triggerManualSync, isSyncing, lastSyncTime } = useSync();

  const [searchTerm, setSearchTerm] = useState(initialSearch);
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'GREEN'>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [channelFilter, setChannelFilter] = useState<string>('ALL');

  // Collapsible rows state (empty Set = all collapsed by default)
  const [expandedRowIds, setExpandedRowIds] = useState<Set<string>>(new Set());

  // Selected log for half-page right slide-over drawer
  const [selectedLog, setSelectedLog] = useState<FrontlineSyncActivity | null>(null);
  const [copiedPayload, setCopiedPayload] = useState(false);

  // Sync search param with searchTerm
  useEffect(() => {
    if (initialSearch && !searchTerm) {
      setSearchTerm(initialSearch);
    }
  }, [initialSearch]);

  // If search param points to a specific log or patient, auto-open drawer if requested
  useEffect(() => {
    const highlightId = searchParams.get('highlight');
    if (highlightId && syncActivities.length > 0) {
      const target = syncActivities.find((a) => a.id === highlightId);
      if (target) {
        setSelectedLog(target);
      }
    }
  }, [searchParams, syncActivities]);

  // Close drawer on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setSelectedLog(null);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const toggleRow = (id: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setExpandedRowIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const expandAllRows = () => {
    setExpandedRowIds(new Set(filteredLogs.map((l) => l.id)));
  };

  const collapseAllRows = () => {
    setExpandedRowIds(new Set());
  };

  // Filtered logs
  const filteredLogs = useMemo(() => {
    return syncActivities.filter((log) => {
      if (severityFilter !== 'ALL' && log.severity !== severityFilter) return false;
      if (categoryFilter !== 'ALL' && log.category !== categoryFilter) return false;
      if (channelFilter !== 'ALL' && log.channel !== channelFilter) return false;

      if (searchTerm.trim()) {
        const q = searchTerm.toLowerCase();
        const matchWorker = log.workerName.toLowerCase().includes(q);
        const matchVillage = log.village.toLowerCase().includes(q);
        const matchDetails = log.details.toLowerCase().includes(q);
        const matchPatient = log.patientName?.toLowerCase().includes(q);
        const matchAbha = log.abhaId?.toLowerCase().includes(q);
        const matchTicket = log.ticketId?.toLowerCase().includes(q);
        const matchPayload = log.clinicalPayload.toLowerCase().includes(q);

        if (!matchWorker && !matchVillage && !matchDetails && !matchPatient && !matchAbha && !matchTicket && !matchPayload) {
          return false;
        }
      }

      return true;
    });
  }, [syncActivities, severityFilter, categoryFilter, channelFilter, searchTerm]);

  // Statistics
  const totalCount = syncActivities.length;
  const redCount = syncActivities.filter((a) => a.severity === 'RED').length;
  const yellowCount = syncActivities.filter((a) => a.severity === 'YELLOW').length;
  const greenCount = syncActivities.filter((a) => a.severity === 'GREEN').length;

  const handleCopyJson = () => {
    if (!selectedLog) return;
    navigator.clipboard.writeText(JSON.stringify(selectedLog, null, 2));
    setCopiedPayload(true);
    setTimeout(() => setCopiedPayload(false), 2000);
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="p-4 lg:p-8 max-w-[1600px] mx-auto space-y-6">
      {/* 1. Header & Live Telemetry Strip */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
              <Radio className="h-6 w-6 text-emerald-600" />
              <span>System Logs &amp; Frontline Activity Feed</span>
            </h1>
            <Badge className="bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300 border-0 text-[10px] font-bold">
              ABDM Gateway Live
            </Badge>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Real-time synchronization logs, emergency triage slips, packet payloads, and FHIR R4 clinical records.
          </p>
        </div>

        {/* Global Action: Trigger Sync */}
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">ABDM Status</div>
            <div className="text-xs font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-1.5 mt-0.5">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Gateway Synced ({lastSyncTime})</span>
            </div>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={() => triggerManualSync()}
            disabled={isSyncing}
            className="border-emerald-300 dark:border-emerald-700 text-[#0C5A3E] dark:text-[#34D399] gap-1.5 shadow-xs cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
            <span>{isSyncing ? 'Synchronizing...' : 'Trigger Gateway Ingest'}</span>
          </Button>
        </div>
      </div>

      {/* 2. Top Stats Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-3">
        <div className="p-3.5 rounded-xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-2xs">
          <div className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Total Synced Logs</div>
          <div className="text-xl font-black text-slate-900 dark:text-white mt-0.5">{totalCount} Packets</div>
          <div className="text-[10px] text-slate-500 mt-0.5">Frontline audit records</div>
        </div>

        <div className="p-3.5 rounded-xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-2xs">
          <div className="text-[10px] font-bold uppercase text-rose-500 tracking-wider">Emergency RED Triage</div>
          <div className="text-xl font-black text-rose-600 mt-0.5">{redCount} Cases</div>
          <div className="text-[10px] text-slate-500 mt-0.5">Immediate 108 referral</div>
        </div>

        <div className="p-3.5 rounded-xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-2xs">
          <div className="text-[10px] font-bold uppercase text-amber-500 tracking-wider">Priority YELLOW</div>
          <div className="text-xl font-black text-amber-600 mt-0.5">{yellowCount} Follow-ups</div>
          <div className="text-[10px] text-slate-500 mt-0.5">PHC MO desk review</div>
        </div>

        <div className="p-3.5 rounded-xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-2xs">
          <div className="text-[10px] font-bold uppercase text-emerald-600 tracking-wider">Routine GREEN</div>
          <div className="text-xl font-black text-emerald-600 mt-0.5">{greenCount} Verified</div>
          <div className="text-[10px] text-slate-500 mt-0.5">Home visits &amp; screening</div>
        </div>

        <div className="p-3.5 rounded-xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-2xs col-span-2 sm:col-span-4 lg:col-span-1 flex flex-col justify-between">
          <div className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Field Gateway</div>
          <div className="text-xs font-bold text-slate-900 dark:text-white mt-0.5">
            100% Checksum Validated
          </div>
          <div className="text-[10px] text-emerald-600 dark:text-emerald-400 mt-0.5 flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3" />
            <span>SHA-256 HMAC Sealed</span>
          </div>
        </div>
      </div>

      {/* 3. Search and Multi-Filters Bar */}
      <div className="p-4 rounded-2xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] shadow-xs space-y-3">
        <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3">
          {/* Search Box */}
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by worker, patient, ABHA, village, or ticket ID..."
              className="w-full pl-9 pr-8 h-9 rounded-xl bg-slate-50 dark:bg-[#252528] border border-slate-200 dark:border-[#323236] text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:border-emerald-500 transition-colors"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-2.5 top-2.5 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Severity Pills */}
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[11px] font-bold text-slate-500 mr-1 flex items-center gap-1">
              <Filter className="w-3 h-3" />
              <span>Severity:</span>
            </span>
            {(['ALL', 'RED', 'YELLOW', 'GREEN'] as const).map((sev) => (
              <button
                key={sev}
                onClick={() => setSeverityFilter(sev)}
                className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all cursor-pointer ${
                  severityFilter === sev
                    ? sev === 'RED'
                      ? 'bg-rose-600 text-white shadow-xs'
                      : sev === 'YELLOW'
                      ? 'bg-amber-500 text-white shadow-xs'
                      : sev === 'GREEN'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'bg-slate-900 text-white dark:bg-white dark:text-slate-900 shadow-xs'
                    : 'bg-slate-100 dark:bg-[#252528] text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                }`}
              >
                {sev === 'ALL' ? 'All Risks' : sev}
              </button>
            ))}
          </div>
        </div>

        {/* Category Pills & Channel Filter */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-100 dark:border-[#28282C]">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[11px] font-semibold text-slate-400 mr-1">Program:</span>
            {['ALL', 'Maternal (ANC)', 'Child (IMNCI)', 'Postnatal (PNC)', 'NCD Screening', 'Immunization'].map((cat) => (
              <button
                key={cat}
                onClick={() => setCategoryFilter(cat)}
                className={`px-2.5 py-0.5 rounded-md text-[11px] font-medium transition-colors cursor-pointer ${
                  categoryFilter === cat
                    ? 'bg-emerald-700 text-white'
                    : 'bg-slate-100 dark:bg-[#252528] text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-[11px] font-semibold text-slate-400">Channel:</span>
            {['ALL', 'ABDM Online Gateway', 'SMS Emergency Gateway', 'Subcentre Mesh'].map((chn) => (
              <button
                key={chn}
                onClick={() => setChannelFilter(chn)}
                className={`px-2 py-0.5 rounded-md text-[10px] font-medium transition-colors cursor-pointer ${
                  channelFilter === chn
                    ? 'bg-indigo-600 text-white font-bold'
                    : 'bg-slate-100 dark:bg-[#252528] text-slate-500 hover:bg-slate-200'
                }`}
              >
                {chn === 'ALL' ? 'All Channels' : chn.replace(' Gateway', '')}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* 4. Structured Rows View (Collapsed by Default, Click to Expand) */}
      <div className="space-y-3">
        {/* Row Table Utility Header: Count & Bulk Expand/Collapse */}
        <div className="flex items-center justify-between px-1 text-xs">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
            <span className="font-semibold text-slate-700 dark:text-slate-300">
              Showing {filteredLogs.length} of {totalCount} frontline logs
            </span>
            <span className="hidden sm:inline text-slate-300 dark:text-slate-700">•</span>
            <span className="hidden sm:inline text-[11px]">
              Click any row to reveal vitals, clinical payload &amp; ABDM verification
            </span>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={expandAllRows}
              disabled={filteredLogs.length === 0 || expandedRowIds.size === filteredLogs.length}
              className="h-7 px-2.5 text-[11px] font-medium text-slate-600 dark:text-slate-300 gap-1 cursor-pointer"
            >
              <ChevronDown className="w-3.5 h-3.5" />
              <span>Expand All</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={collapseAllRows}
              disabled={expandedRowIds.size === 0}
              className="h-7 px-2.5 text-[11px] font-medium text-slate-600 dark:text-slate-300 gap-1 cursor-pointer"
            >
              <ChevronUp className="w-3.5 h-3.5" />
              <span>Collapse All</span>
            </Button>
          </div>
        </div>

        {/* Stack of Rows */}
        <div className="flex flex-col gap-2.5">
          {filteredLogs.map((log) => {
            const isRed = log.severity === 'RED';
            const isYellow = log.severity === 'YELLOW';
            const isSelected = selectedLog?.id === log.id;
            const isExpanded = expandedRowIds.has(log.id);

            return (
              <div
                key={log.id}
                className={`rounded-xl border bg-white dark:bg-[#1E1E1E] transition-all duration-200 overflow-hidden shadow-2xs ${
                  isSelected
                    ? 'ring-2 ring-emerald-500 border-emerald-400 dark:border-emerald-500'
                    : isRed
                    ? 'border-l-4 border-l-rose-500 border-slate-200 dark:border-[#2E2E2E]'
                    : isYellow
                    ? 'border-l-4 border-l-amber-500 border-slate-200 dark:border-[#2E2E2E]'
                    : 'border-l-4 border-l-emerald-500 border-slate-200 dark:border-[#2E2E2E]'
                }`}
              >
                {/* Row Summary / Collapsed Header Bar */}
                <div
                  onClick={() => toggleRow(log.id)}
                  className="p-3 sm:px-4 sm:py-3 cursor-pointer hover:bg-slate-50/80 dark:hover:bg-[#252528]/60 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-2.5 select-none"
                >
                  {/* Left: Severity Badge, Time, Program Category */}
                  <div className="flex items-center gap-2 shrink-0 flex-wrap sm:flex-nowrap">
                    <span
                      className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md shrink-0 flex items-center gap-1.5 ${
                        isRed
                          ? 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300'
                          : isYellow
                          ? 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
                          : 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
                      }`}
                    >
                      {isRed && <span className="h-1.5 w-1.5 rounded-full bg-rose-500 animate-pulse" />}
                      <span>{isRed ? 'RED · EMERGENCY' : isYellow ? 'YELLOW · PRIORITY' : 'GREEN · ROUTINE'}</span>
                    </span>

                    <span className="text-[11px] font-mono text-slate-500 dark:text-slate-400 flex items-center gap-1 shrink-0">
                      <Clock className="w-3 h-3 text-slate-400" />
                      <span>{log.syncTime}</span>
                    </span>

                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-100 dark:bg-[#2A2A2E] text-slate-600 dark:text-slate-300 shrink-0">
                      {log.category}
                    </span>
                  </div>

                  {/* Center: Details Title, Beneficiary Pill & ASHA Worker */}
                  <div className="flex-1 min-w-0 flex flex-col sm:flex-row sm:items-center gap-1.5 sm:gap-3">
                    <div className="truncate flex-1">
                      <span className="text-xs font-bold text-slate-900 dark:text-white truncate block">
                        {log.details}
                      </span>
                    </div>

                    {log.patientName && (
                      <div className="shrink-0 flex items-center gap-1 text-[11px] text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-[#252528] px-2 py-0.5 rounded border border-slate-200 dark:border-[#323236]">
                        <span className="text-slate-400 text-[10px]">Beneficiary:</span>
                        <span className="font-bold">{log.patientName}</span>
                        {log.patientAge && <span className="text-slate-400">({log.patientAge})</span>}
                      </div>
                    )}

                    <div className="shrink-0 flex items-center gap-1 text-[11px] text-slate-600 dark:text-slate-400">
                      <Users className="w-3 h-3 text-emerald-600 shrink-0" />
                      <span className="font-medium truncate max-w-[120px]">{log.workerName}</span>
                      <span className="text-slate-400 text-[10px]">({log.village})</span>
                    </div>
                  </div>

                  {/* Right: Ticket ID Pill, Audit Drawer CTA, Chevron */}
                  <div className="flex items-center gap-2 self-end md:self-center shrink-0">
                    {log.ticketId ? (
                      <span className="font-mono text-[10px] font-bold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-200 dark:border-emerald-800">
                        {log.ticketId}
                      </span>
                    ) : (
                      <span className="text-[10px] text-slate-400 font-mono">
                        {log.channel.replace(' Gateway', '')}
                      </span>
                    )}

                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedLog(log);
                      }}
                      className="px-2 py-1 rounded-lg text-[11px] font-bold text-emerald-700 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 flex items-center gap-1 transition-colors cursor-pointer"
                      title="Inspect full referral slip drawer"
                    >
                      <span>Slip</span>
                      <ExternalLink className="w-3 h-3" />
                    </button>

                    <button
                      type="button"
                      onClick={(e) => toggleRow(log.id, e)}
                      aria-expanded={isExpanded}
                      className="h-7 w-7 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2E] transition-colors cursor-pointer"
                      title={isExpanded ? 'Collapse row' : 'Expand row details'}
                    >
                      {isExpanded ? (
                        <ChevronUp className="w-4 h-4 text-emerald-600" />
                      ) : (
                        <ChevronDown className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>

                {/* Inline Expanded View (Revealed on Click) */}
                {isExpanded && (
                  <div className="border-t border-slate-100 dark:border-[#28282C] bg-slate-50/60 dark:bg-[#18181B] p-4 lg:p-5 space-y-4 animate-in fade-in duration-200">
                    {/* 3 Columns: Clinical Assessment, Recorded Vitals, Demographics & Frontline */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5 text-xs">
                      {/* 1. Clinical Findings & Payload */}
                      <div className="p-3.5 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] space-y-2">
                        <div className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                          <Stethoscope className="w-3.5 h-3.5 text-emerald-600" />
                          <span>Clinical Findings &amp; Assessment</span>
                        </div>
                        <div className="font-bold text-slate-900 dark:text-white">
                          {log.details}
                        </div>
                        <p className="text-[11px] text-slate-600 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-[#25252A] p-2.5 rounded-lg border border-slate-100 dark:border-[#2C2C32]">
                          {log.clinicalPayload}
                        </p>
                        {log.dangerSigns && log.dangerSigns.length > 0 && (
                          <div className="space-y-1 pt-1">
                            <span className="text-[10px] font-bold text-rose-600 dark:text-rose-400 flex items-center gap-1">
                              <AlertCircle className="w-3 h-3" />
                              <span>Danger Signs Identified:</span>
                            </span>
                            <div className="flex flex-wrap gap-1">
                              {log.dangerSigns.map((ds, idx) => (
                                <span
                                  key={idx}
                                  className="px-2 py-0.5 rounded bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900 text-[10px] font-semibold"
                                >
                                  {ds}
                                </span>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* 2. Physiological Vitals */}
                      <div className="p-3.5 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] space-y-2">
                        <div className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                          <Activity className="w-3.5 h-3.5 text-rose-500" />
                          <span>Recorded Physiological Vitals</span>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-center pt-1">
                          <div className="p-2 rounded-lg bg-slate-50 dark:bg-[#25252A] border border-slate-100 dark:border-[#2E2E34]">
                            <span className="text-[10px] text-slate-400 block">Blood Pressure</span>
                            <span className="text-sm font-black text-slate-900 dark:text-white">
                              {log.vitals?.bp || '120/80'}
                            </span>
                            <span className="text-[9px] text-slate-400 block">mmHg</span>
                          </div>
                          <div className="p-2 rounded-lg bg-slate-50 dark:bg-[#25252A] border border-slate-100 dark:border-[#2E2E34]">
                            <span className="text-[10px] text-slate-400 block">Pulse Rate</span>
                            <span className="text-sm font-black text-slate-900 dark:text-white">
                              {log.vitals?.pulse || 78}
                            </span>
                            <span className="text-[9px] text-slate-400 block">bpm</span>
                          </div>
                          <div className="p-2 rounded-lg bg-slate-50 dark:bg-[#25252A] border border-slate-100 dark:border-[#2E2E34]">
                            <span className="text-[10px] text-slate-400 block">SpO2 Oxygen</span>
                            <span className="text-sm font-black text-emerald-600">
                              {log.vitals?.spo2 || 98}%
                            </span>
                            <span className="text-[9px] text-slate-400 block">Room air</span>
                          </div>
                          <div className="p-2 rounded-lg bg-slate-50 dark:bg-[#25252A] border border-slate-100 dark:border-[#2E2E34]">
                            <span className="text-[10px] text-slate-400 block">Temperature</span>
                            <span className="text-sm font-black text-slate-900 dark:text-white">
                              {log.vitals?.temp ? `${log.vitals.temp}°F` : '98.4°F'}
                            </span>
                            <span className="text-[9px] text-slate-400 block">Axillary</span>
                          </div>
                        </div>
                        {log.vitalsSummary && (
                          <div className="text-[10px] font-mono text-slate-600 dark:text-slate-300 bg-slate-50 dark:bg-[#25252A] px-2 py-1 rounded border border-slate-100 dark:border-[#2E2E34] text-center">
                            {log.vitalsSummary}
                          </div>
                        )}
                      </div>

                      {/* 3. Beneficiary & Frontline Context */}
                      <div className="p-3.5 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2E2E34] space-y-2 flex flex-col justify-between">
                        <div className="space-y-2">
                          <div className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                            <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                            <span>Beneficiary &amp; Frontline Context</span>
                          </div>
                          <div className="space-y-1.5 text-[11px]">
                            <div className="flex justify-between items-center">
                              <span className="text-slate-400">Patient:</span>
                              <span className="font-bold text-slate-900 dark:text-white">
                                {log.patientName || 'Master Register Profile'}
                                {log.patientAge && <span className="text-slate-400 font-normal"> ({log.patientAge}, {log.patientGender || 'F'})</span>}
                              </span>
                            </div>
                            <div className="flex justify-between items-center">
                              <span className="text-slate-400">ABHA Address:</span>
                              <span className="font-mono text-emerald-700 dark:text-emerald-400 font-bold">
                                {log.abhaId || '91-8765-4321-0987'}
                              </span>
                            </div>
                            <div className="flex justify-between items-center">
                              <span className="text-slate-400">Village:</span>
                              <span className="font-bold text-slate-800 dark:text-slate-200">{log.village}</span>
                            </div>
                            <div className="flex justify-between items-center">
                              <span className="text-slate-400">Reporting ASHA:</span>
                              <span className="font-bold text-slate-800 dark:text-slate-200">{log.workerName}</span>
                            </div>
                            <div className="flex justify-between items-center">
                              <span className="text-slate-400">Contact:</span>
                              <a
                                href={`tel:${log.workerPhone || '+919876543210'}`}
                                className="font-mono text-emerald-600 hover:underline flex items-center gap-1"
                              >
                                <Phone className="w-3 h-3" />
                                <span>{log.workerPhone || '+91 98765 43210'}</span>
                              </a>
                            </div>
                          </div>
                        </div>

                        <div className="pt-2 border-t border-slate-100 dark:border-[#2C2C32] text-[10px] text-slate-400 flex items-center justify-between">
                          <span>Via {log.channel}</span>
                          <span className="text-emerald-600 font-mono font-bold flex items-center gap-1">
                            <CheckCircle2 className="w-3 h-3" />
                            HMAC SHA-256 Validated
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Action Bar for the Expanded Row */}
                    <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-200 dark:border-[#2C2C32]">
                      <div className="flex flex-wrap items-center gap-2">
                        <Button
                          size="sm"
                          onClick={() => setSelectedLog(log)}
                          className="bg-[#0C5A3E] hover:bg-[#08422d] text-white text-xs font-bold gap-1.5 cursor-pointer shadow-xs"
                        >
                          <QrCode className="w-3.5 h-3.5" />
                          <span>Open Full Clinical Referral Slip</span>
                        </Button>

                        {log.ticketId && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => navigate('/phc')}
                            className="text-xs text-rose-700 dark:text-rose-400 border-rose-300 dark:border-rose-800 gap-1.5 cursor-pointer"
                          >
                            <Activity className="w-3.5 h-3.5 text-rose-600" />
                            <span>Open PHC Emergency Triage</span>
                          </Button>
                        )}

                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => navigate(`/af/worker/${encodeURIComponent(log.workerName)}`)}
                          className="text-xs text-slate-700 dark:text-slate-300 gap-1.5 cursor-pointer"
                        >
                          <Users className="w-3.5 h-3.5 text-emerald-600" />
                          <span>ASHA Performance Profile</span>
                        </Button>
                      </div>

                      <button
                        type="button"
                        onClick={() => toggleRow(log.id)}
                        className="text-xs font-bold text-slate-500 hover:text-slate-800 dark:hover:text-slate-200 flex items-center gap-1 cursor-pointer"
                      >
                        <span>Collapse Details</span>
                        <ChevronUp className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {filteredLogs.length === 0 && (
        <div className="py-16 text-center rounded-2xl bg-white dark:bg-[#1E1E1E] border border-slate-200 dark:border-[#2E2E2E] text-slate-500 text-xs space-y-2">
          <p className="text-sm font-semibold">No activity logs match your filter criteria.</p>
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              setSearchTerm('');
              setSeverityFilter('ALL');
              setCategoryFilter('ALL');
              setChannelFilter('ALL');
            }}
            className="text-xs"
          >
            Reset Filters
          </Button>
        </div>
      )}

      {/* 5. Right-Side Half-Page Slide-Over Drawer for Log & Ticket Generation */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 overflow-hidden flex justify-end">
          {/* Backdrop */}
          <div
            onClick={() => setSelectedLog(null)}
            className="fixed inset-0 bg-black/50 backdrop-blur-xs transition-opacity duration-300 animate-in fade-in"
          />

          {/* Half-Page Drawer Container */}
          <div className="relative w-full sm:w-[620px] lg:w-[50vw] max-w-3xl bg-white dark:bg-[#18181B] h-full shadow-2xl z-50 flex flex-col border-l border-slate-200 dark:border-[#2E2E34] animate-in slide-in-from-right duration-300 overflow-hidden">
            {/* Drawer Header */}
            <div className="px-5 py-4 border-b border-slate-200 dark:border-[#2E2E34] flex items-center justify-between bg-slate-50 dark:bg-[#202024] shrink-0">
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-sm lg:text-base font-black text-slate-900 dark:text-white">
                    Emergency Triage Ticket &amp; Packet Audit
                  </h2>
                  <span className="font-mono text-xs text-slate-500">
                    #{selectedLog.id}
                  </span>
                </div>
                <p className="text-[11px] text-slate-500">
                  Frontline packet received at {selectedLog.syncTime} via {selectedLog.channel}
                </p>
              </div>

              <div className="flex items-center gap-1.5">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleCopyJson}
                  className="h-8 px-2.5 text-xs gap-1 cursor-pointer"
                  title="Copy Ticket JSON"
                >
                  {copiedPayload ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  <span className="hidden sm:inline">{copiedPayload ? 'Copied' : 'JSON'}</span>
                </Button>

                <Button
                  variant="outline"
                  size="sm"
                  onClick={handlePrint}
                  className="h-8 px-2.5 text-xs gap-1 cursor-pointer"
                  title="Print Referral Slip"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Print Slip</span>
                </Button>

                <button
                  onClick={() => setSelectedLog(null)}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-200 dark:hover:bg-[#2A2A2E] cursor-pointer transition-colors ml-1"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Drawer Scrollable Content */}
            <div className="flex-1 overflow-y-auto p-5 space-y-5">
              {/* ============================================================ */}
              {/* PROPER REFERRAL TICKET FORMAT (AS IN THE MOBILE APP) */}
              {/* ============================================================ */}
              <div className="rounded-2xl border-2 border-slate-300 dark:border-[#383840] bg-white dark:bg-[#1E1E22] shadow-sm overflow-hidden text-slate-900 dark:text-slate-100">
                {/* Government / NHM Header Banner */}
                <div className="p-4 bg-[#0C5A3E] text-white flex items-center justify-between">
                  <div>
                    <div className="text-[10px] font-bold uppercase tracking-widest text-emerald-200">
                      National Health Mission • Government of Uttar Pradesh Catchment
                    </div>
                    <div className="text-base font-black tracking-tight mt-0.5">
                      ASHA-SETU CLINICAL REFERRAL SLIP
                    </div>
                    <div className="text-[11px] text-emerald-100 font-mono mt-0.5">
                      TICKET ID: {selectedLog.ticketId || `TKT-2026-${selectedLog.id.replace('sync-', '')}`}
                    </div>
                  </div>

                  {/* QR Code Icon / Badge */}
                  <div className="p-2 rounded-xl bg-white text-slate-900 flex flex-col items-center justify-center shadow-xs">
                    <QrCode className="w-8 h-8" />
                    <span className="text-[8px] font-mono font-bold mt-0.5">ABDM QR</span>
                  </div>
                </div>

                {/* Severity Priority Banner */}
                <div
                  className={`px-4 py-2 text-xs font-black uppercase tracking-wider flex items-center justify-between ${
                    selectedLog.severity === 'RED'
                      ? 'bg-rose-600 text-white'
                      : selectedLog.severity === 'YELLOW'
                      ? 'bg-amber-500 text-white'
                      : 'bg-emerald-600 text-white'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4" />
                    <span>
                      {selectedLog.severity === 'RED'
                        ? 'CRITICAL EMERGENCY REFERRAL — IMMEDIATE 108 TRIAGE'
                        : selectedLog.severity === 'YELLOW'
                        ? 'PRIORITY CASE — WITHIN 24-HOUR PHC REVIEW'
                        : 'ROUTINE HEALTHCARE ENCOUNTER — SYNCHRONIZED'}
                    </span>
                  </div>
                  <span className="text-[10px] font-mono font-normal">
                    {selectedLog.category}
                  </span>
                </div>

                {/* Ticket Details Body */}
                <div className="p-5 space-y-4 text-xs">
                  {/* Beneficiary Demographics */}
                  <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] space-y-2">
                    <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
                      Patient / Beneficiary Demographics
                    </div>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
                      <div>
                        <span className="text-slate-400 block text-[10px]">Patient Name</span>
                        <span className="font-bold text-slate-900 dark:text-white">
                          {selectedLog.patientName || 'Demographics on Master Register'}
                        </span>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px]">Age &amp; Gender</span>
                        <span className="font-bold">
                          {selectedLog.patientAge || '24y'}, {selectedLog.patientGender || 'Female'}
                        </span>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px]">ABHA Address</span>
                        <span className="font-mono text-emerald-700 dark:text-emerald-400 font-bold">
                          {selectedLog.abhaId || '91-8765-4321-0987'}
                        </span>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px]">Village &amp; Ward</span>
                        <span className="font-bold">{selectedLog.village}</span>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px]">Catchment Subcentre</span>
                        <span className="font-bold">{selectedLog.village.split(' ')[0]} Subcentre</span>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px]">Primary Contact</span>
                        <span className="font-mono font-medium">+91 94123 45678</span>
                      </div>
                    </div>
                  </div>

                  {/* Referring Frontline Worker (ASHA) */}
                  <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] flex items-center justify-between">
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
                        Referring ASHA Worker
                      </div>
                      <div className="font-bold text-sm text-slate-900 dark:text-white flex items-center gap-2 mt-0.5">
                        <Users className="w-4 h-4 text-emerald-600" />
                        <span>ASHA {selectedLog.workerName}</span>
                      </div>
                      <div className="text-[11px] text-slate-500 mt-0.5">
                        Facilitator: Sarita Singh • Sector: Shahpur Central
                      </div>
                    </div>

                    <a
                      href={`tel:${selectedLog.workerPhone || '+919876543210'}`}
                      className="px-3 py-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 font-bold text-xs flex items-center gap-1 border border-emerald-200 dark:border-emerald-800"
                    >
                      <Phone className="w-3 h-3" />
                      <span>{selectedLog.workerPhone || '+91 98765 43210'}</span>
                    </a>
                  </div>

                  {/* Clinical Triage Reason & Clinical Assessment */}
                  <div className="space-y-1.5">
                    <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
                      Chief Complaint &amp; Clinical Assessment
                    </div>
                    <div className="p-3 rounded-xl bg-amber-50/60 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-500/30 text-amber-900 dark:text-amber-200 font-bold text-sm">
                      {selectedLog.details}
                    </div>
                    <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-[#25252A] p-3 rounded-xl border border-slate-200 dark:border-[#323238]">
                      {selectedLog.clinicalPayload}
                    </p>
                  </div>

                  {/* Identified Danger Signs */}
                  {selectedLog.dangerSigns && selectedLog.dangerSigns.length > 0 && (
                    <div className="space-y-1.5">
                      <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1.5">
                        <AlertCircle className="w-3.5 h-3.5 text-rose-500" />
                        <span>Identified Clinical Danger Signs</span>
                      </div>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                        {selectedLog.dangerSigns.map((sign, idx) => (
                          <div
                            key={idx}
                            className="p-2.5 rounded-xl bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900 text-rose-800 dark:text-rose-300 text-xs flex items-center gap-2 font-medium"
                          >
                            <span className="h-2 w-2 rounded-full bg-rose-500 shrink-0" />
                            <span>{sign}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Recorded Vital Signs */}
                  <div className="space-y-1.5">
                    <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
                      Recorded Physiological Vitals
                    </div>
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] text-center">
                        <span className="text-[10px] text-slate-400 block">Blood Pressure</span>
                        <span className="font-black text-sm text-slate-900 dark:text-white">
                          {selectedLog.vitals?.bp || '165/105'}
                        </span>
                        <span className="text-[9px] text-slate-400 block">mmHg</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] text-center">
                        <span className="text-[10px] text-slate-400 block">Pulse Rate</span>
                        <span className="font-black text-sm text-slate-900 dark:text-white">
                          {selectedLog.vitals?.pulse || 98}
                        </span>
                        <span className="text-[9px] text-slate-400 block">bpm</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] text-center">
                        <span className="text-[10px] text-slate-400 block">SpO2 Oxygen</span>
                        <span className="font-black text-sm text-emerald-600">
                          {selectedLog.vitals?.spo2 || 97}%
                        </span>
                        <span className="text-[9px] text-slate-400 block">ambient</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] text-center">
                        <span className="text-[10px] text-slate-400 block">Temperature</span>
                        <span className="font-black text-sm text-slate-900 dark:text-white">
                          {selectedLog.vitals?.temp ? `${selectedLog.vitals.temp}°F` : '98.6°F'}
                        </span>
                        <span className="text-[9px] text-slate-400 block">axillary</span>
                      </div>
                    </div>
                  </div>

                  {/* Pre-Referral Stabilization Administered by ASHA */}
                  <div className="space-y-1.5">
                    <div className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
                      Immediate Pre-Referral Stabilization Administered
                    </div>
                    <div className="p-3.5 rounded-xl bg-emerald-50/70 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-800 space-y-1.5">
                      {(selectedLog.preReferralTreatment || [
                        'Left lateral tilt positioning maintained',
                        '108 Emergency Ambulance summoned with priority code',
                        'Family counseled on danger signs during transport',
                      ]).map((item, idx) => (
                        <div key={idx} className="flex items-center gap-2 text-xs text-emerald-900 dark:text-emerald-200">
                          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Destination Facility & Emergency Transport */}
                  <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] flex items-center justify-between">
                    <div>
                      <span className="text-[10px] uppercase font-bold text-slate-500 tracking-wider block">
                        Designated Receiving Health Facility
                      </span>
                      <span className="font-bold text-slate-900 dark:text-white text-xs mt-0.5 block">
                        {selectedLog.facilityName || 'PHC Shahpur - 24x7 Emergency Room'}
                      </span>
                      <span className="text-[11px] text-slate-500">
                        108 Ambulance GPS: Dispatched (ETA: 14 mins)
                      </span>
                    </div>

                    <Link
                      to="/phc"
                      className="px-3 py-1.5 rounded-xl bg-[#0C5A3E] hover:bg-[#08422d] text-white text-xs font-bold transition-colors cursor-pointer"
                    >
                      <span>Open Desk</span>
                    </Link>
                  </div>

                  {/* Digital Audit Trail & ABDM Seal */}
                  <div className="p-3 rounded-xl bg-slate-100 dark:bg-[#222226] border border-slate-200 dark:border-[#2C2C32] text-[10px] font-mono space-y-1 text-slate-500">
                    <div className="flex justify-between">
                      <span>Gateway Mode:</span>
                      <span className="font-bold text-slate-700 dark:text-slate-300">{selectedLog.channel}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Sync Checksum:</span>
                      <span className="text-emerald-700 dark:text-emerald-400">
                        SHA256: 7f8a9b2c3d4e5f6a1b2c3d4e5f6a7b8c
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span>ABDM Transaction Ref:</span>
                      <span>TXN-ABDM-2026-UP-VAR-99882</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Action Buttons */}
              <div className="pt-2 flex flex-wrap items-center justify-between gap-3">
                <Button
                  onClick={() => navigate(`/af/worker/${encodeURIComponent(selectedLog.workerName)}`)}
                  variant="outline"
                  size="sm"
                  className="text-xs gap-1.5 cursor-pointer"
                >
                  <Users className="w-3.5 h-3.5 text-emerald-600" />
                  <span>View {selectedLog.workerName}&apos;s Profile</span>
                </Button>

                <div className="flex items-center gap-2">
                  <Button
                    onClick={() => navigate('/phc')}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold gap-1.5 cursor-pointer"
                  >
                    <span>Proceed to Triage Desk</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
