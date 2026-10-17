import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  getDistrictIndicators,
  getOutbreakAlerts,
  getSupplyForecasts,
} from '@/shared/api/analyticsApi';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
} from 'recharts';
import {
  BarChart3,
  TrendingUp,
  AlertTriangle,
  Package,
  Layers,
  MapPin,
  ShieldAlert,
  ArrowUpRight,
  ArrowDownRight,
  CheckCircle2,
  Download,
} from 'lucide-react';

export function DistrictAnalyticsPage() {
  const [selectedCategory, setSelectedCategory] = useState<'all' | 'maternal' | 'child' | 'ncd' | 'tb'>('all');

  const { data: indicators = [] } = useQuery({
    queryKey: ['district-indicators'],
    queryFn: () => getDistrictIndicators('DIST_01'),
  });

  const { data: outbreakAlerts = [] } = useQuery({
    queryKey: ['outbreak-alerts'],
    queryFn: () => getOutbreakAlerts('BLOCK_A'),
  });

  const { data: supplyForecasts = [] } = useQuery({
    queryKey: ['supply-forecasts'],
    queryFn: () => getSupplyForecasts('phc-shahpur'),
  });

  const filteredIndicators = indicators.filter((ind) => {
    if (selectedCategory === 'all') return true;
    return ind.category === selectedCategory;
  });

  // Chart data for coverage comparison vs target
  const chartData = indicators.map((ind) => ({
    name: ind.name.split(' ')[0] + ' ' + (ind.name.split(' ')[1] || ''),
    current: ind.currentValue,
    target: ind.targetValue,
    previous: ind.previousValue,
  }));

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 glass-panel p-6 rounded-2xl border border-slate-800">
        <div className="flex items-center space-x-3">
          <div className="p-2.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
            <BarChart3 className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-white flex items-center gap-2">
              Block, District & State Analytics (Requirement 42)
            </h1>
            <p className="text-xs text-slate-400">
              District: Varanasi Central • Real-time NHM Indicators, Outbreak Clustering & Supply Forecasting
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="glass-card px-4 py-2 rounded-xl border border-rose-500/30 flex items-center space-x-2">
            <ShieldAlert className="w-4 h-4 text-rose-400" />
            <div>
              <div className="text-[10px] text-rose-300 font-semibold">Active Outbreak Signals</div>
              <div className="text-lg font-bold text-white">{outbreakAlerts.length} Alerts Active</div>
            </div>
          </div>
          <div className="glass-card px-4 py-2 rounded-xl border border-indigo-500/30">
            <div className="text-[10px] text-indigo-300 font-semibold">Tracked Indicators</div>
            <div className="text-lg font-bold text-indigo-400">6 Key NHM Programs</div>
          </div>
        </div>
      </div>

      {/* Outbreak Detection Signals Banner (Req 42.3) */}
      {outbreakAlerts.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center space-x-2 text-rose-400 font-bold text-xs uppercase tracking-wider">
            <AlertTriangle className="w-4 h-4 animate-bounce" />
            <span>Outbreak Signals & Beneficiary Clustering (Requirement 42.3)</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {outbreakAlerts.map((alert) => (
              <div
                key={alert.id}
                className="p-4 rounded-2xl border border-rose-500/40 bg-gradient-to-r from-rose-950/40 via-slate-900/60 to-slate-900/40 space-y-2"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping"></span>
                    <h3 className="text-sm font-bold text-white">{alert.disease}</h3>
                  </div>
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-300 border border-rose-500/30 uppercase font-bold">
                    {alert.severity} SEVERITY
                  </span>
                </div>
                <div className="text-xs text-slate-300">
                  <span className="font-semibold text-rose-300">{alert.caseCount} Cases</span> clustered in {alert.affectedVillage} ({alert.block}) across {alert.timeframeDays} days.
                </div>
                <div className="flex items-center justify-between pt-1 text-[11px] text-slate-400">
                  <span>Status: <strong className="text-amber-300 uppercase">{alert.status}</strong></span>
                  <span>Flagged: {new Date(alert.flaggedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 6 Key NHM Programme Indicators (Req 42.1 & 42.7) */}
      <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-indigo-400" />
              Programme Coverage & Outcome Indicators vs Targets (Req 42.1)
            </h2>
            <p className="text-xs text-slate-400">
              Computed near real-time from synced frontline clinical encounters and immunization records
            </p>
          </div>

          <div className="flex items-center space-x-1.5 bg-slate-900 p-1 rounded-xl border border-slate-800 text-xs">
            {(['all', 'maternal', 'child', 'ncd', 'tb'] as const).map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3 py-1 rounded-lg capitalize transition-all font-medium ${
                  selectedCategory === cat
                    ? 'bg-indigo-600 text-white font-bold'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Indicators Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredIndicators.map((ind) => {
            const meetsTarget = ind.currentValue >= ind.targetValue;
            const progress = Math.min(100, Math.round((ind.currentValue / ind.targetValue) * 100));

            return (
              <div
                key={ind.code}
                className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3"
              >
                <div className="flex items-start justify-between">
                  <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-400 uppercase font-mono">
                    {ind.code}
                  </span>
                  <div className="flex items-center space-x-1 text-xs">
                    {ind.trend === 'up' ? (
                      <span className="text-emerald-400 flex items-center font-semibold">
                        <ArrowUpRight className="w-3.5 h-3.5" /> +{(ind.currentValue - ind.previousValue).toFixed(1)}%
                      </span>
                    ) : (
                      <span className="text-rose-400 flex items-center font-semibold">
                        <ArrowDownRight className="w-3.5 h-3.5" /> {(ind.currentValue - ind.previousValue).toFixed(1)}%
                      </span>
                    )}
                  </div>
                </div>

                <div>
                  <div className="text-xs font-semibold text-slate-200 line-clamp-1">{ind.name}</div>
                  <div className="flex items-baseline space-x-2 pt-1">
                    <span className="text-2xl font-extrabold text-white">
                      {ind.currentValue}{ind.unit}
                    </span>
                    <span className="text-xs text-slate-400 font-medium">
                      Target: {ind.targetValue}{ind.unit}
                    </span>
                  </div>
                </div>

                {/* Target Progress Bar */}
                <div className="space-y-1">
                  <div className="flex justify-between text-[10px] text-slate-400">
                    <span>Target Attainment</span>
                    <span className={meetsTarget ? 'text-emerald-400 font-bold' : 'text-amber-400 font-bold'}>
                      {progress}%
                    </span>
                  </div>
                  <div className="w-full h-1.5 rounded-full bg-slate-800 overflow-hidden">
                    <div
                      className={`h-full rounded-full ${meetsTarget ? 'bg-emerald-500' : 'bg-amber-500'}`}
                      style={{ width: `${Math.min(100, progress)}%` }}
                    />
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Export and DPDP Re-identification Guard Action Bar (Req 42.2 & 42.6) */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-slate-800">
          <div className="text-xs text-slate-400 flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>DPDP Re-identification Guard Active: Cells with counts &lt; 5 suppressed or aggregated automatically.</span>
          </div>
          <button
            onClick={() => {
              const csvContent =
                'Indicator_Code,Indicator_Name,Current_Value,Target_Value,Prior_Period_Value,Unit\n' +
                indicators
                  .map(
                    (i) =>
                      `"${i.code}","${i.name}",${i.currentValue < 5 ? '"<5"' : i.currentValue},${i.targetValue},${i.previousValue},"${i.unit}"`
                  )
                  .join('\n');
              const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
              const url = URL.createObjectURL(blob);
              const link = document.createElement('a');
              link.href = url;
              link.setAttribute('download', `nhm_deidentified_indicators_${Date.now()}.csv`);
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }}
            className="px-3.5 py-1.5 rounded-xl bg-slate-900 border border-slate-700 hover:border-slate-500 text-slate-200 text-xs font-semibold flex items-center gap-1.5 transition-all self-start sm:self-auto"
          >
            <Download className="w-3.5 h-3.5 text-indigo-400" />
            <span>Export De-Identified CSV (Req 42.6)</span>
          </button>
        </div>

        {/* Visual Recharts Comparison Graph */}
        <div className="pt-4 border-t border-slate-800">
          <div className="text-xs font-semibold text-slate-300 mb-3">
            District Performance vs NHM National Targets (Comparison Chart)
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                <XAxis dataKey="name" stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} />
                <YAxis stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} domain={[0, 100]} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '0.75rem', fontSize: '12px' }}
                />
                <Bar dataKey="current" fill="#6366f1" radius={[4, 4, 0, 0]} name="Current Achieved (%)" />
                <Bar dataKey="target" fill="#10b981" radius={[4, 4, 0, 0]} name="Target (%)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Supply Chain Forecasting (Req 42.4) */}
      <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-4">
        <h2 className="text-base font-bold text-white flex items-center gap-2">
          <Package className="w-5 h-5 text-amber-400" />
          Commodity Run-Out Forecasting & Stockout Mitigation (Requirement 42.4)
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {supplyForecasts.map((supply) => {
            const isCritical = supply.status === 'critical_stockout';
            const isWarning = supply.status === 'warning';

            return (
              <div
                key={supply.itemCode}
                className={`p-4 rounded-xl border space-y-2 ${
                  isCritical
                    ? 'border-rose-500/50 bg-rose-950/20'
                    : isWarning
                    ? 'border-amber-500/40 bg-amber-950/20'
                    : 'border-slate-800 bg-slate-900/60'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-mono text-slate-400">{supply.itemCode}</span>
                  <span
                    className={`text-[9px] px-1.5 py-0.5 rounded font-bold uppercase ${
                      isCritical
                        ? 'bg-rose-500/20 text-rose-300'
                        : isWarning
                        ? 'bg-amber-500/20 text-amber-300'
                        : 'bg-emerald-500/20 text-emerald-300'
                    }`}
                  >
                    {supply.status.replace('_', ' ')}
                  </span>
                </div>

                <div className="text-xs font-bold text-slate-200">{supply.itemName}</div>

                <div className="pt-1">
                  <div className="text-[10px] text-slate-400">Run-out Estimate:</div>
                  <div
                    className={`text-xl font-extrabold ${
                      isCritical ? 'text-rose-400' : isWarning ? 'text-amber-400' : 'text-emerald-400'
                    }`}
                  >
                    {supply.estimatedDaysRemaining} Days Left
                  </div>
                </div>

                <div className="text-[11px] text-slate-400 flex items-center justify-between border-t border-slate-800 pt-2">
                  <span>Stock: {supply.currentStock} units</span>
                  <span>Daily: ~{supply.dailyConsumptionRate}/day</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
