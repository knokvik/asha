import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { PCMC_FACILITIES, PCMC_WARDS } from '@/shared/api/mockData';
import { wardConfirmations } from '@/shared/api/referralApi';
import {
  flagsPerThousand,
  outbreakWards,
  weekPoint,
  type WardWeek,
} from '@/features/clinical-desk/logic';
import { getDiseaseHotspots, type DiseaseHotspot } from '@/shared/api/mapApi';

export interface HeatView {
  week: number;
  showFlags: boolean;
  showAnaemia: boolean;
  showStunting: boolean;
  showFacilities: boolean;
}

export function PcmcHeatPanel({ onView }: { onView?: (view: HeatView) => void }) {
  const [week, setWeek] = useState(11);
  const [selected, setSelected] = useState('W3');
  const [showFlags, setShowFlags] = useState(true);
  const [showAnaemia, setShowAnaemia] = useState(true);
  const [showStunting, setShowStunting] = useState(false);
  const [showFacilities, setShowFacilities] = useState(true);
  const wards = PCMC_WARDS as WardWeek[];

  const { data: liveContext } = useQuery({
    queryKey: ['disease-hotspots'],
    queryFn: getDiseaseHotspots,
    refetchInterval: 60_000,
  });

  const { data: confirmed = {} } = useQuery({
    queryKey: ['heatmap', 'confirmed'],
    queryFn: async () => wardConfirmations(),
  });

  useEffect(() => {
    onView?.({ week, showFlags, showAnaemia, showStunting, showFacilities });
  }, [week, showFlags, showAnaemia, showStunting, showFacilities, onView]);

  const hot = new Set(outbreakWards(wards, week));
  const ward = wards.find((item) => item.wardId === selected) ?? wards[2];
  const point = weekPoint(ward, week);

  return (
    <section className="shrink-0 border-b border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] p-4 space-y-3" data-testid="pcmc-heat-panel">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-sm font-bold">PCMC wards W1–W8</h2>
          <p className="text-[11px] text-slate-500">Flags per 1,000 this week. Outbreak ring when dengue-like flags reach 3.</p>
        </div>
        <label className="text-[11px] font-semibold">
          Week {week + 1}/12
          <input
            aria-label="Heatmap week"
            type="range"
            min={0}
            max={11}
            value={week}
            onChange={(event) => setWeek(Number(event.target.value))}
            className="block w-40"
          />
        </label>
      </div>
      <div className="flex flex-wrap gap-3 text-[11px]">
        <label><input type="checkbox" checked={showFlags} onChange={(event) => setShowFlags(event.target.checked)} /> Triage flags</label>
        <label><input type="checkbox" checked={showAnaemia} onChange={(event) => setShowAnaemia(event.target.checked)} /> NFHS-5 anaemia</label>
        <label><input type="checkbox" checked={showStunting} onChange={(event) => setShowStunting(event.target.checked)} /> NFHS-5 stunting</label>
        <label><input type="checkbox" checked={showFacilities} onChange={(event) => setShowFacilities(event.target.checked)} /> Facilities</label>
      </div>
      <LiveHotspotSummary hotspots={liveContext?.hotspots ?? []} />
      <div className="grid grid-cols-4 gap-2 max-w-xl">
        {wards.map((item) => {
          const value = weekPoint(item, week);
          const rate = flagsPerThousand(value.flags + (confirmed[item.wardId] ?? 0), item.population);
          return (
            <button
              key={item.wardId}
              type="button"
              onClick={() => setSelected(item.wardId)}
              className={`rounded-lg border px-2 py-2 text-left text-[11px] ${
                hot.has(item.wardId) ? 'border-rose-500 bg-rose-50' : 'border-slate-200'
              } ${selected === item.wardId ? 'ring-2 ring-emerald-600' : ''}`}
            >
              <div className="font-bold">{item.wardId}{hot.has(item.wardId) ? ' outbreak' : ''}</div>
              {showFlags && <div>{rate}/1000</div>}
              {showAnaemia && <div>Anaemia {item.anaemiaPct}%</div>}
              {showStunting && <div>Stunting {item.stuntingPct}%</div>}
              <div>Confirmed {confirmed[item.wardId] ?? 0}</div>
            </button>
          );
        })}
      </div>
      {showFacilities && (
        <p className="text-[11px] text-slate-600">
          {PCMC_FACILITIES.map((facility) => facility.name).join(' · ')}
        </p>
      )}
      <div>
        <div className="text-[11px] font-semibold mb-1">{ward.wardId} 12-week dengue-like flags</div>
        <div className="flex items-end gap-1 h-16" data-testid="ward-sparkline">
          {ward.weeks.map((bar) => (
            <div
              key={bar.week}
              title={`Week ${bar.week + 1}: ${bar.dengueLike}`}
              className={`w-3 ${bar.week === week ? 'bg-emerald-700' : 'bg-rose-400'}`}
              style={{ height: `${Math.max(4, bar.dengueLike * 10)}px` }}
            />
          ))}
        </div>
        <p className="text-[11px] text-slate-600 mt-1">
          This week: {point.dengueLike} dengue-like, {point.flags} flags.
          {ward.wardId === 'W3' ? ' Latest weeks run 1, 2, 3, 5.' : ''}
        </p>
      </div>
    </section>
  );
}

function LiveHotspotSummary({ hotspots }: { hotspots: DiseaseHotspot[] }) {
  const active = hotspots.filter((hotspot) => hotspot.active);
  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50/70 p-3 dark:border-amber-900/70 dark:bg-amber-950/20" data-testid="live-hotspot-summary">
      <div className="flex items-center justify-between gap-2">
        <div>
          <div className="text-xs font-bold text-amber-900 dark:text-amber-200">Live cross-worker disease signals</div>
          <div className="text-[11px] text-amber-800/80 dark:text-amber-300/80">Aggregated from authenticated ASHA sync packets; no patient details shown.</div>
        </div>
        <span className="rounded-full bg-amber-200 px-2 py-1 text-[10px] font-bold text-amber-900 dark:bg-amber-900/60 dark:text-amber-100">{active.length} active</span>
      </div>
      {active.length === 0 ? (
        <p className="mt-2 text-[11px] text-slate-600 dark:text-slate-400">No multi-worker hotspot has crossed the activation threshold in the current block.</p>
      ) : (
        <div className="mt-2 grid gap-2 sm:grid-cols-2">
          {active.map((hotspot) => (
            <div key={`${hotspot.ward_id}-${hotspot.module_id}`} className="rounded-lg border border-amber-200 bg-white/80 px-2.5 py-2 text-[11px] dark:border-amber-900/60 dark:bg-slate-900/50">
              <div className="font-bold text-slate-900 dark:text-white">{hotspot.ward_id} · {hotspot.module_id}</div>
              <div className="text-slate-600 dark:text-slate-400">{hotspot.cases} reports from {hotspot.worker_count} ASHA workers</div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
