import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSync, INDIRA_AIRPORT_HOTSPOT } from '@/shared/context/SyncContext';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  AlertTriangle,
  Radio,
  MapPin,
  Users,
  CheckCircle2,
  Navigation,
  ArrowRight,
  Flame,
  X,
  Stethoscope,
  RefreshCw,
  Sparkles,
  Plane,
} from 'lucide-react';

interface JudgeTriageTriggerModalProps {
  open: boolean;
  onClose: () => void;
}

export function JudgeTriageTriggerModal({ open, onClose }: JudgeTriageTriggerModalProps) {
  const navigate = useNavigate();
  const { activeHotspot, triggerHotspot, clearHotspot } = useSync();

  const [isActivating, setIsActivating] = useState(false);
  const [justActivated, setJustActivated] = useState(false);

  if (!open) return null;

  const handleActivate = () => {
    setIsActivating(true);
    setTimeout(() => {
      triggerHotspot();
      setIsActivating(false);
      setJustActivated(true);
    }, 600);
  };

  const handleReset = () => {
    clearHotspot();
    setJustActivated(false);
  };

  const goToMap = () => {
    onClose();
    navigate('/map?focus=hotspot');
  };

  const goToTriage = () => {
    onClose();
    navigate('/phc?hotspot=true');
  };

  const goToLogs = () => {
    onClose();
    navigate('/logs?search=Sunita%20Devi');
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-black/60 backdrop-blur-xs transition-opacity duration-200 animate-in fade-in"
      />

      {/* Modal Dialog */}
      <div className="relative w-full max-w-2xl rounded-3xl bg-white dark:bg-[#1C1C1F] border border-slate-200 dark:border-[#2E2E34] shadow-2xl overflow-hidden z-50 text-slate-900 dark:text-slate-100 animate-in zoom-in-95 duration-200">
        {/* Header with High-Impact Gradient */}
        <div className="p-6 bg-gradient-to-r from-rose-600 via-amber-600 to-emerald-700 text-white flex items-start justify-between">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <span className="p-1.5 rounded-lg bg-white/20 backdrop-blur-xs">
                <Sparkles className="w-5 h-5 text-white" />
              </span>
              <span className="text-[11px] font-black uppercase tracking-widest text-amber-200">
                Judges Presentation Mode
              </span>
            </div>
            <h2 className="text-xl font-black tracking-tight">
              Outbreak Hotspot &amp; Triage Field Trigger
            </h2>
            <p className="text-xs text-white/90">
              Live simulation of an epidemic cluster near Indira Airport, Delhi with automated field map drawing &amp; ASHA sync.
            </p>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-xl bg-black/20 hover:bg-black/30 text-white/80 hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-5 text-xs">
          {/* Active Hotspot Notification State */}
          {activeHotspot ? (
            <div className="p-4 rounded-2xl bg-rose-50 dark:bg-rose-950/30 border-2 border-rose-300 dark:border-rose-900 space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-rose-700 dark:text-rose-300 font-bold text-sm">
                  <span className="relative flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-rose-500"></span>
                  </span>
                  <span>HOTSPOT CURRENTLY ACTIVE ON FIELD MAP</span>
                </div>
                <Badge className="bg-rose-600 text-white border-0 text-[10px]">
                  14 Confirmed Cases
                </Badge>
              </div>

              <div className="text-slate-700 dark:text-slate-300 space-y-1">
                <div>
                  <strong>Location:</strong> {activeHotspot.locationName}
                </div>
                <div>
                  <strong>Condition:</strong> {activeHotspot.condition} ({activeHotspot.radiusMeters}m radius)
                </div>
                <div>
                  <strong>Synchronized ASHA Workers:</strong> {activeHotspot.nearbyAshas.length} field workers on active fever surveillance beat.
                </div>
              </div>

              {/* Quick Jump Buttons for Presentation */}
              <div className="pt-2 flex flex-wrap items-center gap-2">
                <Button
                  onClick={goToMap}
                  size="sm"
                  className="bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs gap-1.5 shadow-xs cursor-pointer"
                >
                  <Navigation className="w-3.5 h-3.5" />
                  <span>Show Drawn Map</span>
                </Button>

                <Button
                  onClick={goToTriage}
                  size="sm"
                  className="bg-[#0C5A3E] hover:bg-[#08422d] text-white font-bold text-xs gap-1.5 shadow-xs cursor-pointer"
                >
                  <Stethoscope className="w-3.5 h-3.5" />
                  <span>Examine Hotspot Triage</span>
                </Button>

                <Button
                  onClick={goToLogs}
                  variant="outline"
                  size="sm"
                  className="text-xs gap-1.5 cursor-pointer"
                >
                  <Radio className="w-3.5 h-3.5 text-emerald-600" />
                  <span>View Synced Tickets</span>
                </Button>

                <Button
                  onClick={handleReset}
                  variant="ghost"
                  size="sm"
                  className="text-xs text-rose-600 hover:text-rose-700 ml-auto cursor-pointer"
                >
                  Reset Hotspot
                </Button>
              </div>
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] space-y-2">
              <div className="flex items-center gap-2 text-slate-800 dark:text-slate-200 font-bold">
                <Plane className="w-4 h-4 text-emerald-600" />
                <span>Simulation Target: Indira Gandhi International Airport, New Delhi</span>
              </div>
              <p className="text-slate-500 text-[11px] leading-relaxed">
                Clicking the trigger below simulates an outbreak cluster near Indira Airport. The server will map the coordinates (28.5562° N, 77.1000° E), draw the containment perimeter on the field map, broadcast automated ABDM sync packets to 4 nearby ASHA workers, and activate outbreak-weighted triage considerations.
              </p>
            </div>
          )}

          {/* Details Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {/* Box 1: Geographic Target */}
            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] space-y-1.5">
              <div className="text-[10px] font-bold uppercase text-slate-400 flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-rose-500" />
                <span>Hotspot Geographic Target</span>
              </div>
              <div className="font-bold text-slate-900 dark:text-white">
                Indira Airport &amp; Mahipalpur Sector
              </div>
              <div className="text-[11px] text-slate-500 font-mono">
                Lat: 28.5562° N • Lng: 77.1000° E
              </div>
              <div className="text-[10px] text-emerald-600 font-semibold">
                Radius: 1.8 km Isochrone Containment Zone
              </div>
            </div>

            {/* Box 2: Disease Profile */}
            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#25252A] border border-slate-200 dark:border-[#323238] space-y-1.5">
              <div className="text-[10px] font-bold uppercase text-slate-400 flex items-center gap-1.5">
                <Flame className="w-3.5 h-3.5 text-amber-500" />
                <span>Epidemic Condition Profile</span>
              </div>
              <div className="font-bold text-slate-900 dark:text-white">
                Dengue &amp; Acute Febrile Illness (AFI)
              </div>
              <div className="text-[11px] text-rose-600 font-semibold">
                Critical Red Alert • 14 Confirmed Cases
              </div>
              <div className="text-[10px] text-slate-500">
                NS1 Ag Positive • High Vector Breeding Index
              </div>
            </div>
          </div>

          {/* Nearby ASHA Workers Tracked in Catchment */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <div className="text-[10px] font-bold uppercase text-slate-400 flex items-center gap-1.5">
                <Users className="w-3.5 h-3.5 text-emerald-600" />
                <span>Nearby ASHA Workers in Indira Airport Catchment (4 Tracked)</span>
              </div>
              <span className="text-[10px] text-emerald-600 font-bold">ABDM Sync Ready</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {INDIRA_AIRPORT_HOTSPOT.nearbyAshas.map((asha) => (
                <div
                  key={asha.id}
                  className="p-2.5 rounded-xl bg-white dark:bg-[#202024] border border-slate-200 dark:border-[#2C2C32] flex items-center justify-between text-[11px]"
                >
                  <div>
                    <span className="font-bold text-slate-900 dark:text-white">{asha.name}</span>
                    <span className="text-slate-400 block text-[10px]">{asha.beat}</span>
                  </div>
                  <span className="px-2 py-0.5 rounded-md bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 font-mono text-[10px] font-bold">
                    Connected
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Clinical Triage Rule Impact */}
          <div className="p-3.5 rounded-xl bg-amber-50/70 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-500/30 text-amber-900 dark:text-amber-200 space-y-1">
            <div className="font-bold flex items-center gap-1.5">
              <AlertTriangle className="w-3.5 h-3.5 text-amber-600" />
              <span>Clinical Triage Consideration Rule Activated:</span>
            </div>
            <p className="text-[11px] leading-relaxed text-slate-700 dark:text-slate-300">
              Any patient assessed within this 1.8 km Indira Airport perimeter presenting with fever &gt; 3 days will automatically receive <strong>Elevated Triage Weighting</strong>, prompting for immediate Platelet count, Tourniquet test, and Rapid NS1 antigen screening.
            </p>
          </div>
        </div>

        {/* Modal Footer Actions */}
        <div className="px-6 py-4 bg-slate-50 dark:bg-[#18181A] border-t border-slate-200 dark:border-[#2E2E34] flex flex-wrap items-center justify-between gap-3">
          <div className="text-[11px] text-slate-500">
            {activeHotspot ? 'Outbreak is live across dashboard.' : 'Ready to trigger live demo.'}
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={onClose}
              className="text-xs cursor-pointer"
            >
              Close
            </Button>

            {!activeHotspot ? (
              <Button
                onClick={handleActivate}
                disabled={isActivating}
                className="bg-gradient-to-r from-rose-600 to-amber-600 hover:from-rose-700 hover:to-amber-700 text-white font-bold text-xs gap-2 shadow-md cursor-pointer"
              >
                {isActivating ? (
                  <>
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    <span>Mapping &amp; Syncing to ASHAs...</span>
                  </>
                ) : (
                  <>
                    <Flame className="w-3.5 h-3.5" />
                    <span>⚡ TRIGGER HOTSPOT &amp; BROADCAST NOW</span>
                  </>
                )}
              </Button>
            ) : (
              <Button
                onClick={goToMap}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs gap-1.5 shadow-xs cursor-pointer"
              >
                <span>Fly to Indira Airport on Map</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
