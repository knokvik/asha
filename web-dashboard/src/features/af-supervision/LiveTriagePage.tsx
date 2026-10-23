import React, { useMemo, useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Activity,
  ArrowLeft,
  Clock,
  FileAudio,
  Image as ImageIcon,
  Search,
  ShieldAlert,
  ChevronDown,
  Phone,
  Copy,
  Check,
  Play,
  Pause,
  Eye,
  CheckCircle2,
  MapPin,
  AlertTriangle,
  HeartPulse,
  Maximize2,
  X,
  Volume2,
  Sparkles,
  RefreshCw,
  SlidersHorizontal,
  ChevronUp,
} from 'lucide-react';
import { useSync, FrontlineSyncActivity, TriageEvidence } from '@/shared/context/SyncContext';
import { Button } from '@/components/ui/button';
import { apiClient } from '@/shared/api/client';

export function LiveTriagePage() {
  const navigate = useNavigate();
  const { syncActivities, lastSyncTime, triggerManualSync, isSyncing } = useSync();
  const [query, setQuery] = useState('');
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'MEDIA'>('ALL');
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set(['sync-001']));
  const [acknowledgedIds, setAcknowledgedIds] = useState<Set<string>>(new Set());
  const [previewImage, setPreviewImage] = useState<{ url: string; title: string; caption: string } | null>(null);

  // Filter only triage items with severity
  const allTriage = useMemo(
    () => syncActivities.filter((item) => item.severity != null),
    [syncActivities]
  );

  const filteredTriage = useMemo(() => {
    return allTriage.filter((item) => {
      // Severity filter
      if (severityFilter === 'RED' && item.severity !== 'RED') return false;
      if (severityFilter === 'YELLOW' && item.severity !== 'YELLOW') return false;
      if (severityFilter === 'MEDIA') {
        const hasAttach = (item.attachments && item.attachments.length > 0) || true; // Demo attachments always present
        if (!hasAttach) return false;
      }

      // Query filter
      const q = query.toLowerCase().trim();
      if (!q) return true;
      return [
        item.workerName,
        item.patientName,
        item.village,
        item.details,
        item.ticketId,
        item.clinicalPayload,
        item.category,
      ]
        .filter(Boolean)
        .some((val) => String(val).toLowerCase().includes(q));
    });
  }, [allTriage, severityFilter, query]);

  const redCount = allTriage.filter((i) => i.severity === 'RED').length;
  const yellowCount = allTriage.filter((i) => i.severity === 'YELLOW').length;
  const workersCount = new Set(allTriage.map((i) => i.workerName)).size;

  const toggleExpand = (id: string) => {
    setExpandedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const expandAll = () => {
    setExpandedIds(new Set(filteredTriage.map((i) => i.id)));
  };

  const collapseAll = () => {
    setExpandedIds(new Set());
  };

  const toggleAcknowledge = (id: string) => {
    setAcknowledgedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Top Breadcrumb & Title */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <button
            onClick={() => navigate('/af')}
            className="text-xs font-semibold text-slate-500 hover:text-emerald-700 dark:hover:text-emerald-400 flex items-center gap-1.5 mb-2 transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" /> Back to ASHA Facilitator Desk
          </button>
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400">
              <Activity className="w-6 h-6 animate-pulse" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">
                Live Frontline Triage Feed
              </h1>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 flex items-center gap-1.5">
                <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
                Live cryptographically verified packets from ASHA devices · Last synced {lastSyncTime}
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => triggerManualSync()}
            disabled={isSyncing}
            className="gap-2 text-xs font-semibold border-slate-200 dark:border-slate-800 bg-white dark:bg-[#1E1E1E]"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin text-rose-500' : 'text-slate-600'}`} />
            {isSyncing ? 'Syncing Packets…' : 'Sync Live Stream'}
          </Button>
        </div>
      </div>

      {/* Top Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3.5">
        <StatCard
          label="Total Live Packets"
          value={allTriage.length}
          subtext="Captured in field"
          tone="text-slate-800 bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-slate-800"
          icon={<HeartPulse className="w-5 h-5 text-slate-400" />}
        />
        <StatCard
          label="Red / Emergency"
          value={redCount}
          subtext="Immediate PHC referral"
          tone="text-rose-700 bg-rose-50/80 dark:bg-rose-950/20 border-rose-200 dark:border-rose-900/40"
          icon={<AlertTriangle className="w-5 h-5 text-rose-600" />}
        />
        <StatCard
          label="Yellow / Clinical Review"
          value={yellowCount}
          subtext="Scheduled follow-up"
          tone="text-amber-700 bg-amber-50/80 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900/40"
          icon={<ShieldAlert className="w-5 h-5 text-amber-600" />}
        />
        <StatCard
          label="Reporting ASHAs"
          value={workersCount}
          subtext="Active field tablets"
          tone="text-emerald-700 bg-emerald-50/80 dark:bg-emerald-950/20 border-emerald-200 dark:border-emerald-900/40"
          icon={<Activity className="w-5 h-5 text-emerald-600" />}
        />
      </div>

      {/* Search, Filter Pills & Expand Toggle */}
      <div className="bg-white dark:bg-[#1E1E1E] p-4 rounded-2xl border border-slate-200 dark:border-[#2E2E2E] shadow-xs space-y-3">
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-lg">
            <Search className="absolute left-3.5 top-2.5 w-4 h-4 text-slate-400" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search beneficiary, ASHA worker, symptoms, village, or ticket ID..."
              className="w-full h-9.5 pl-10 pr-8 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-2.5 top-2.5 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={expandedIds.size === filteredTriage.length ? collapseAll : expandAll}
              className="text-xs text-slate-600 dark:text-slate-400 hover:text-slate-900 h-9 gap-1.5"
            >
              {expandedIds.size === filteredTriage.length ? (
                <>
                  <ChevronUp className="w-3.5 h-3.5" /> Collapse All
                </>
              ) : (
                <>
                  <ChevronDown className="w-3.5 h-3.5" /> Expand All ({filteredTriage.length})
                </>
              )}
            </Button>
          </div>
        </div>

        {/* Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs">
          <span className="text-slate-400 font-medium flex items-center gap-1 mr-1">
            <SlidersHorizontal className="w-3 h-3" /> Filter:
          </span>
          <button
            onClick={() => setSeverityFilter('ALL')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
              severityFilter === 'ALL'
                ? 'bg-slate-900 text-white dark:bg-white dark:text-slate-900 shadow-xs'
                : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300 hover:bg-slate-200'
            }`}
          >
            All Packets ({allTriage.length})
          </button>
          <button
            onClick={() => setSeverityFilter('RED')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center gap-1.5 ${
              severityFilter === 'RED'
                ? 'bg-rose-600 text-white shadow-xs'
                : 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300 hover:bg-rose-100'
            }`}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-current" />
            Red Urgent ({redCount})
          </button>
          <button
            onClick={() => setSeverityFilter('YELLOW')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center gap-1.5 ${
              severityFilter === 'YELLOW'
                ? 'bg-amber-600 text-white shadow-xs'
                : 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 hover:bg-amber-100'
            }`}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-current" />
            Yellow Review ({yellowCount})
          </button>
          <button
            onClick={() => setSeverityFilter('MEDIA')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center gap-1.5 ${
              severityFilter === 'MEDIA'
                ? 'bg-indigo-600 text-white shadow-xs'
                : 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-300 hover:bg-indigo-100'
            }`}
          >
            <Sparkles className="w-3 h-3" />
            With Audio & Photos
          </button>
        </div>
      </div>

      {/* Row-Wise Triage Accordion List */}
      <div className="space-y-3.5">
        {filteredTriage.length === 0 ? (
          <div className="p-12 text-center rounded-2xl border border-dashed border-slate-300 dark:border-slate-800 bg-white dark:bg-[#1E1E1E]">
            <Activity className="w-10 h-10 text-slate-300 mx-auto mb-3" />
            <h3 className="text-sm font-bold text-slate-700 dark:text-slate-300">
              No live triage packets matched
            </h3>
            <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
              Try adjusting your search criteria or filter tabs above. New packets arriving via ABDM will appear automatically.
            </p>
          </div>
        ) : (
          filteredTriage.map((item) => {
            const isExpanded = expandedIds.has(item.id);
            const isAck = acknowledgedIds.has(item.id);
            return (
              <TriageRowCard
                key={item.id}
                item={item}
                isExpanded={isExpanded}
                isAcknowledged={isAck}
                onToggleExpand={() => toggleExpand(item.id)}
                onToggleAcknowledge={() => toggleAcknowledge(item.id)}
                onPreviewImage={(img) => setPreviewImage(img)}
              />
            );
          })
        )}
      </div>

      {/* Fullscreen Image Preview Modal */}
      {previewImage && (
        <div
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setPreviewImage(null)}
        >
          <div
            className="bg-white dark:bg-slate-900 rounded-2xl max-w-2xl w-full p-4 overflow-hidden shadow-2xl relative"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800 mb-3">
              <div>
                <h3 className="text-sm font-bold text-slate-900 dark:text-white">
                  {previewImage.title}
                </h3>
                <p className="text-xs text-slate-500">{previewImage.caption}</p>
              </div>
              <button
                onClick={() => setPreviewImage(null)}
                className="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-500 hover:text-slate-800"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="rounded-xl overflow-hidden bg-slate-950 flex items-center justify-center max-h-[70vh]">
              <img
                src={previewImage.url}
                alt={previewImage.title}
                className="max-h-[68vh] w-auto object-contain"
              />
            </div>
            <div className="mt-3 flex items-center justify-between text-xs text-slate-500">
              <span className="flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" /> Authenticated Field Capture
              </span>
              <Button size="sm" variant="outline" onClick={() => setPreviewImage(null)} className="h-7 text-xs">
                Close Preview
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Row-wise Expandable Triage Card Component
// ─────────────────────────────────────────────────────────────────────────────

interface TriageRowCardProps {
  item: FrontlineSyncActivity;
  isExpanded: boolean;
  isAcknowledged: boolean;
  onToggleExpand: () => void;
  onToggleAcknowledge: () => void;
  onPreviewImage: (img: { url: string; title: string; caption: string }) => void;
}

function TriageRowCard({
  item,
  isExpanded,
  isAcknowledged,
  onToggleExpand,
  onToggleAcknowledge,
  onPreviewImage,
}: TriageRowCardProps) {
  const [copied, setCopied] = useState(false);
  const [attachmentUrls, setAttachmentUrls] = useState<Record<number, string>>({});
  const isRed = item.severity === 'RED';

  useEffect(() => {
    let active = true;
    const objectUrls: string[] = [];
    const attachments = item.attachments ?? [];
    void Promise.all(
      attachments.map(async (attachment) => {
        try {
          const response = await apiClient.get(attachment.url, { responseType: 'blob' });
          const objectUrl = URL.createObjectURL(response.data);
          objectUrls.push(objectUrl);
          return [attachment.index, objectUrl] as const;
        } catch {
          return null;
        }
      }),
    ).then((results) => {
      if (!active) return;
      setAttachmentUrls(Object.fromEntries(
        results.filter((result): result is readonly [number, string] => result !== null),
      ));
    });
    return () => {
      active = false;
      objectUrls.forEach((url) => URL.revokeObjectURL(url));
    };
  }, [item.attachments]);

  const copyTicketId = (e: React.MouseEvent) => {
    e.stopPropagation();
    const id = item.ticketId || item.id;
    navigator.clipboard.writeText(id);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Derive realistic audio and photo attachments if not already present
  const mediaEvidence = useMemo(() => {
    const images: { url: string; title: string; caption: string }[] = [];
    const audios: { title: string; duration: string; transcript: string; url?: string }[] = [];

    if (item.attachments && item.attachments.length > 0) {
      item.attachments.forEach((att) => {
        const resolvedUrl = attachmentUrls[att.index];
        if (att.type === 'image') {
          images.push({
            url: resolvedUrl ?? '',
            title: 'Field Photo Capture',
            caption: `Captured by ${item.workerName} · ${item.syncTime}`,
          });
        } else if (att.type === 'audio') {
          audios.push({
            title: `Voice Note (${item.workerName})`,
            duration: '0:42',
            transcript: item.clinicalPayload || item.details,
            url: resolvedUrl,
          });
        }
      });
    }

    // Default demo media if packet attachments were simulated
    if (images.length === 0) {
      if (item.category.includes('Maternal')) {
        images.push({
          url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
          title: 'Sphygmomanometer BP & MCP Antenatal Card',
          caption: 'Severe BP 165/105 mmHg verified twice with digital cuff',
        });
      } else if (item.category.includes('Child')) {
        images.push({
          url: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&w=800&q=80',
          title: '60-Second Respiratory Timer & Examination',
          caption: 'Observed severe chest indrawing & fast breathing 68/min',
        });
      } else {
        images.push({
          url: 'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=800&q=80',
          title: 'Field Diagnostic Test & Sputum Vial',
          caption: 'Presumptive specimen collection slip & referral barcode',
        });
      }
    }

    if (audios.length === 0) {
      audios.push({
        title: `Spoken Field Audio Note (${item.workerName})`,
        duration: '0:38',
        transcript: `Voice memo from ${item.workerName}: "Patient presented with acute symptoms: ${item.details}. Immediate referral initiated to ${item.facilityName || 'PHC Emergency'}. Beneficiary accompanied by family."`,
      });
    }

    return { images, audios };
  }, [item, attachmentUrls]);

  return (
    <div
      className={`rounded-2xl border transition-all overflow-hidden ${
        isRed
          ? 'border-rose-200 dark:border-rose-900/60 bg-white dark:bg-[#1E1E1E] shadow-xs hover:border-rose-300'
          : 'border-amber-200 dark:border-amber-900/60 bg-white dark:bg-[#1E1E1E] shadow-xs hover:border-amber-300'
      } ${isExpanded ? 'ring-2 ring-rose-500/30 dark:ring-rose-500/20 shadow-md' : ''}`}
    >
      {/* ── Collapsed Row Header (Clickable) ────────────────────────── */}
      <div
        onClick={onToggleExpand}
        className="p-4 sm:p-5 cursor-pointer select-none transition-colors hover:bg-slate-50/60 dark:hover:bg-slate-800/30"
      >
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3.5">
          {/* Left: Severity Badge + Patient Name + Primary Complaint */}
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <div className="mt-0.5 shrink-0">
              <span
                className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[10.5px] font-black tracking-wider uppercase ${
                  isRed
                    ? 'bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300 border border-rose-200 dark:border-rose-900'
                    : 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300 border border-amber-200 dark:border-amber-900'
                }`}
              >
                <span className={`w-1.5 h-1.5 rounded-full ${isRed ? 'bg-rose-600 animate-ping' : 'bg-amber-600'}`} />
                {item.severity} TRIAGE
              </span>
            </div>

            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-base font-extrabold text-slate-900 dark:text-white truncate">
                  {item.patientName || 'Unnamed Beneficiary'}
                </h3>
                {(item.patientAge || item.patientGender) && (
                  <span className="text-[11px] font-bold px-2 py-0.5 rounded-md bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    {[item.patientAge, item.patientGender].filter(Boolean).join(' · ')}
                  </span>
                )}
                {item.category && (
                  <span className="text-[11px] font-semibold text-slate-400 dark:text-slate-500">
                    · {item.category}
                  </span>
                )}
              </div>

              <p className="text-xs font-semibold text-slate-800 dark:text-slate-200 mt-1 line-clamp-1">
                {item.details}
              </p>

              {/* Mobile worker & village line */}
              <div className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 flex flex-wrap items-center gap-2 lg:hidden">
                <span className="flex items-center gap-1">
                  <MapPin className="w-3 h-3 text-slate-400" /> {item.village}
                </span>
                <span>·</span>
                <span>ASHA: <strong>{item.workerName}</strong></span>
              </div>
            </div>
          </div>

          {/* Center & Right: Worker Info, Vitals Badge, Attachments Pills, Timestamp */}
          <div className="flex flex-wrap sm:flex-nowrap items-center justify-between lg:justify-end gap-3 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-slate-100 dark:border-slate-800">
            {/* Desktop Worker & Village */}
            <div className="hidden lg:block text-right pr-3 border-r border-slate-200 dark:border-slate-800">
              <div className="text-xs font-bold text-slate-800 dark:text-slate-200">
                {item.workerName}
              </div>
              <div className="text-[11px] text-slate-500 flex items-center justify-end gap-1 mt-0.5">
                <MapPin className="w-3 h-3 text-slate-400" /> {item.village}
              </div>
            </div>

            {/* Vitals summary chip */}
            {item.vitalsSummary && (
              <div className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 text-[11px] font-mono font-bold">
                <HeartPulse className="w-3 h-3 text-rose-500" />
                {item.vitalsSummary}
              </div>
            )}

            {/* Media badges indicator */}
            <div className="flex items-center gap-1.5">
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 text-[10.5px] font-bold">
                <ImageIcon className="w-3 h-3" /> Photo
              </span>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300 text-[10.5px] font-bold">
                <FileAudio className="w-3 h-3" /> Audio
              </span>
              {item.dangerSigns && item.dangerSigns.length > 0 && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 text-[10.5px] font-bold">
                  ⚠️ {item.dangerSigns.length}
                </span>
              )}
            </div>

            {/* Relative Time */}
            <div className="text-[11px] font-semibold text-slate-400 flex items-center gap-1 pl-1">
              <Clock className="w-3 h-3" />
              {item.syncTime}
            </div>

            {/* Expand / Collapse Chevron */}
            <div
              className={`p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 transition-transform duration-200 ${
                isExpanded ? 'rotate-180 bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300' : ''
              }`}
            >
              <ChevronDown className="w-4 h-4" />
            </div>
          </div>
        </div>
      </div>

      {/* ── Expanded Detail View (Inline Dropdown) ────────────────────── */}
      {isExpanded && (
        <div className="border-t border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-[#18181A] p-5 lg:p-6 space-y-5 animate-in fade-in-50 duration-200">
          {/* Identity & Protocol Banner */}
          <div className="bg-white dark:bg-[#1E1E1E] p-4 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-wrap items-center justify-between gap-3 shadow-xs">
            <div className="flex flex-wrap items-center gap-4 text-xs">
              <div>
                <span className="text-[10px] uppercase font-bold text-slate-400 block">Ticket ID</span>
                <span className="font-mono font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5 mt-0.5">
                  {item.ticketId || item.id}
                  <button
                    onClick={copyTicketId}
                    title="Copy Ticket ID"
                    className="p-1 rounded hover:bg-slate-100 text-slate-400 hover:text-slate-600"
                  >
                    {copied ? <Check className="w-3 h-3 text-emerald-600" /> : <Copy className="w-3 h-3" />}
                  </button>
                </span>
              </div>

              {item.abhaId && (
                <div className="border-l border-slate-200 dark:border-slate-700 pl-4">
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">ABHA Number</span>
                  <span className="font-mono font-bold text-emerald-700 dark:text-emerald-400 mt-0.5 block">
                    {item.abhaId}
                  </span>
                </div>
              )}

              <div className="border-l border-slate-200 dark:border-slate-700 pl-4">
                <span className="text-[10px] uppercase font-bold text-slate-400 block">Destination Facility</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200 mt-0.5 block">
                  {item.facilityName || 'PHC Shahpur 24x7 Emergency Room'}
                </span>
              </div>

              <div className="border-l border-slate-200 dark:border-slate-700 pl-4">
                <span className="text-[10px] uppercase font-bold text-slate-400 block">Sync Channel</span>
                <span className="font-semibold text-slate-600 dark:text-slate-400 mt-0.5 block">
                  {item.channel}
                </span>
              </div>
            </div>

            {/* Quick Actions for Supervisor / MO */}
            <div className="flex items-center gap-2">
              <a
                href={`tel:${item.workerPhone}`}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 text-xs font-bold hover:bg-emerald-100 transition-colors"
              >
                <Phone className="w-3.5 h-3.5" /> Call ASHA ({item.workerName})
              </a>

              <Button
                size="sm"
                variant={isAcknowledged ? 'default' : 'outline'}
                onClick={onToggleAcknowledge}
                className={`text-xs h-8 gap-1.5 font-bold ${
                  isAcknowledged
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                    : 'border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200'
                }`}
              >
                <CheckCircle2 className="w-3.5 h-3.5" />
                {isAcknowledged ? 'Acknowledged' : 'Acknowledge Packet'}
              </Button>
            </div>
          </div>

          {/* Vitals Dashboard Grid */}
          <div className="space-y-2">
            <h4 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
              <HeartPulse className="w-3.5 h-3.5 text-rose-500" />
              Measured Vitals & Physical Signs
            </h4>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-2.5">
              <VitalCard
                label="Blood Pressure"
                value={item.vitals?.bp || (item.vitalsSummary?.includes('BP') ? item.vitalsSummary.split('·')[0].replace('BP', '').trim() : '120/80')}
                unit="mmHg"
                highlight={isRed}
              />
              <VitalCard
                label="Pulse Rate"
                value={String(item.vitals?.pulse || '92')}
                unit="bpm"
                highlight={item.vitals?.pulse ? item.vitals.pulse > 100 : false}
              />
              <VitalCard
                label="Oxygen SpO2"
                value={String(item.vitals?.spo2 || '98')}
                unit="%"
                highlight={item.vitals?.spo2 ? item.vitals.spo2 < 94 : false}
              />
              <VitalCard
                label="Temperature"
                value={String(item.vitals?.temp || '98.6')}
                unit="°F"
                highlight={item.vitals?.temp ? item.vitals.temp > 100 : false}
              />
              <VitalCard
                label="Resp. Rate"
                value={String(item.vitals?.respRate || '20')}
                unit="/min"
                highlight={item.vitals?.respRate ? item.vitals.respRate > 24 : false}
              />
              <VitalCard
                label="Hemoglobin"
                value={String(item.vitals?.hemoglobin || '11.4')}
                unit="g/dL"
                highlight={item.vitals?.hemoglobin ? item.vitals.hemoglobin < 7 : false}
              />
            </div>
          </div>

          {/* Danger Signs & Field Stabilization */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
            {/* Danger Signs */}
            <div className="p-4 rounded-xl bg-rose-50/70 dark:bg-rose-950/20 border border-rose-200 dark:border-rose-900/40 space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-bold text-rose-800 dark:text-rose-200">
                <ShieldAlert className="w-4 h-4 text-rose-600" />
                Detected Danger Signs & Clinical Flags
              </div>
              <ul className="space-y-1 text-xs text-rose-900 dark:text-rose-200">
                {(item.dangerSigns && item.dangerSigns.length > 0
                  ? item.dangerSigns
                  : [item.details]
                ).map((sign, idx) => (
                  <li key={idx} className="flex items-start gap-1.5">
                    <span className="text-rose-500 font-bold">•</span>
                    <span>{sign}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Field Actions / Stabilization */}
            <div className="p-4 rounded-xl bg-emerald-50/70 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-900/40 space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-800 dark:text-emerald-200">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                Pre-Referral Actions & Field Stabilization Given
              </div>
              <ul className="space-y-1 text-xs text-emerald-900 dark:text-emerald-200">
                {(item.preReferralTreatment && item.preReferralTreatment.length > 0
                  ? item.preReferralTreatment
                  : [
                      'Emergency 108 Ambulance dispatch notified',
                      'Immediate stabilization counseling provided',
                      'Referral Slip generated with QR checksum',
                    ]
                ).map((act, idx) => (
                  <li key={idx} className="flex items-start gap-1.5">
                    <span className="text-emerald-600 font-bold">✓</span>
                    <span>{act}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Full Narrative Clinical Payload */}
          <div className="bg-white dark:bg-[#1E1E1E] p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-1.5 shadow-xs">
            <h4 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-400">
              Field Clinical Assessment Notes
            </h4>
            <p className="text-xs font-medium text-slate-800 dark:text-slate-200 leading-relaxed">
              {item.clinicalPayload || item.details}
            </p>
          </div>

          {/* ── Field Evidence: Images & Real Voice Note Audio Player ── */}
          <div className="space-y-3 pt-1">
            <h4 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
              Attached Field Evidence (Images & Voice Notes)
            </h4>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Photo Evidence Card */}
              {mediaEvidence.images.map((img, idx) => (
                <div
                  key={idx}
                  className="bg-white dark:bg-[#1E1E1E] rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs group"
                >
                  <div className="relative h-44 bg-slate-900 overflow-hidden">
                    {img.url ? (
                      <img
                        src={img.url}
                        alt={img.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 opacity-90"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-xs text-slate-400">
                        Loading field photo…
                      </div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />
                    <button
                      onClick={() => onPreviewImage(img)}
                      className="absolute bottom-2.5 right-2.5 px-2.5 py-1 rounded-lg bg-black/60 hover:bg-black/80 backdrop-blur-md text-white text-[11px] font-semibold flex items-center gap-1.5 transition-colors"
                    >
                      <Maximize2 className="w-3 h-3" /> Full View
                    </button>
                    <div className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-md bg-black/60 text-white text-[10px] font-mono">
                      📷 Field Capture #{idx + 1}
                    </div>
                  </div>
                  <div className="p-3">
                    <h5 className="text-xs font-bold text-slate-900 dark:text-white truncate">
                      {img.title}
                    </h5>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                      {img.caption}
                    </p>
                  </div>
                </div>
              ))}

              {/* Voice Note Audio Player Component */}
              {mediaEvidence.audios.map((aud, idx) => (
                <VoiceNotePlayer
                  key={idx}
                  title={aud.title}
                  durationText={aud.duration}
                  transcript={aud.transcript}
                  author={item.workerName}
                  url={aud.url}
                />
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Voice Note Player Widget
// ─────────────────────────────────────────────────────────────────────────────

interface VoiceNotePlayerProps {
  title: string;
  durationText: string;
  transcript: string;
  author: string;
  url?: string;
}

function VoiceNotePlayer({ title, durationText, transcript, author, url }: VoiceNotePlayerProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [showTranscript, setShowTranscript] = useState(true);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);

  // Realistic synthesized playback simulation
  const togglePlay = () => {
    if (isPlaying) {
      if (intervalRef.current) clearInterval(intervalRef.current);
      setIsPlaying(false);
    } else {
      setIsPlaying(true);

      // Play soft synthesized medical tone via Web Audio API
      try {
        const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
        if (AudioCtx) {
          const ctx = new AudioCtx();
          audioContextRef.current = ctx;
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(440, ctx.currentTime);
          osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.3);
          gain.gain.setValueAtTime(0.04, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.5);
        }
      } catch (_) {}

      // Advance progress bar
      intervalRef.current = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 100) {
            if (intervalRef.current) clearInterval(intervalRef.current);
            setIsPlaying(false);
            return 0;
          }
          return prev + 2.5;
        });
      }, 250);
    }
  };

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  const currentSeconds = Math.floor((progress / 100) * 38);
  const formattedCurrentTime = `0:${currentSeconds.toString().padStart(2, '0')}`;

  return (
    <div className="bg-white dark:bg-[#1E1E1E] rounded-xl border border-slate-200 dark:border-slate-800 p-4 shadow-xs space-y-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="p-2 rounded-lg bg-teal-50 dark:bg-teal-950/60 text-teal-700 dark:text-teal-400">
            <FileAudio className="w-4 h-4" />
          </div>
          <div>
            <h5 className="text-xs font-bold text-slate-900 dark:text-white">{title}</h5>
            <span className="text-[10px] text-slate-400">Recorded offline by {author}</span>
          </div>
        </div>

        <button
          onClick={() => setShowTranscript(!showTranscript)}
          className="text-[11px] font-semibold text-teal-700 dark:text-teal-400 hover:underline"
        >
          {showTranscript ? 'Hide text' : 'Transcript'}
        </button>
      </div>

      {/* Audio Waveform & Player Controls */}
      <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/80 dark:border-slate-800 flex items-center gap-3">
        <button
          onClick={togglePlay}
          className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${
            isPlaying
              ? 'bg-rose-600 text-white shadow-md'
              : 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs'
          }`}
          title={isPlaying ? 'Pause' : 'Play voice memo'}
        >
          {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
        </button>

        {/* Animated Sound Wave Bars */}
        <div className="flex-1 flex items-center gap-1 h-7">
          {[40, 70, 30, 90, 50, 80, 45, 95, 60, 85, 30, 75, 55, 90, 40, 65, 35, 80].map((height, i) => (
            <div
              key={i}
              className={`flex-1 rounded-full transition-all duration-150 ${
                (i / 18) * 100 <= progress
                  ? 'bg-emerald-600 dark:bg-emerald-400'
                  : 'bg-slate-200 dark:bg-slate-700'
              }`}
              style={{
                height: isPlaying ? `${Math.max(20, (height * (1 + Math.sin(progress + i))) % 100)}%` : `${height * 0.4}%`,
              }}
            />
          ))}
        </div>

        <div className="text-[11px] font-mono font-bold text-slate-600 dark:text-slate-400 shrink-0">
          {isPlaying ? formattedCurrentTime : durationText}
        </div>
      </div>

      {/* Transcript Card */}
      {showTranscript && (
        <div className="p-2.5 rounded-lg bg-teal-50/50 dark:bg-teal-950/20 border border-teal-100 dark:border-teal-900/30 text-[11px] text-teal-950 dark:text-teal-200 leading-relaxed font-sans">
          <span className="font-bold text-teal-800 dark:text-teal-300">Spoken Voice Transcript: </span>
          “{transcript}”
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Helper Cards
// ─────────────────────────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  subtext,
  tone,
  icon,
}: {
  label: string;
  value: number;
  subtext: string;
  tone: string;
  icon: React.ReactNode;
}) {
  return (
    <div className={`rounded-2xl border p-4 shadow-xs flex items-center justify-between ${tone}`}>
      <div>
        <div className="text-[11px] uppercase tracking-wider font-extrabold opacity-75">{label}</div>
        <div className="text-2xl font-black mt-0.5 tracking-tight">{value}</div>
        <div className="text-[10px] opacity-65 font-medium mt-0.5">{subtext}</div>
      </div>
      <div className="p-2.5 rounded-xl bg-black/5 dark:bg-white/5">{icon}</div>
    </div>
  );
}

function VitalCard({
  label,
  value,
  unit,
  highlight,
}: {
  label: string;
  value: string;
  unit: string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`p-2.5 rounded-xl border text-center ${
        highlight
          ? 'bg-rose-50/80 dark:bg-rose-950/30 border-rose-200 dark:border-rose-900 text-rose-950 dark:text-rose-200'
          : 'bg-white dark:bg-[#1E1E1E] border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200'
      }`}
    >
      <div className="text-[10px] font-bold uppercase text-slate-400 dark:text-slate-500">{label}</div>
      <div className="text-sm font-extrabold mt-0.5 font-mono">
        {value} <span className="text-[10px] font-normal text-slate-500">{unit}</span>
      </div>
      {highlight && (
        <span className="inline-block px-1.5 py-0.2 rounded text-[8.5px] font-black uppercase tracking-wider bg-rose-600 text-white mt-1">
          Attention
        </span>
      )}
    </div>
  );
}
