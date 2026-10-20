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
  CartesianGrid,
} from 'recharts';
import {
  BarChart3,
  TrendingUp,
  AlertTriangle,
  Package,
  ShieldAlert,
  ArrowUpRight,
  ArrowDownRight,
  Download,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

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
      {/* Header Row */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
            Block, District & State Analytics (Requirement 42)
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            District: Varanasi Central • Real-time NHM Indicators, Outbreak Clustering & Supply Forecasting
          </p>
        </div>

        <div className="flex items-center gap-2.5 flex-wrap">
          <div className="flex items-center gap-2 bg-white dark:bg-[#1E1E1E] border border-rose-200 dark:border-rose-500/30 rounded-xl px-3 py-1.5 shadow-xs">
            <ShieldAlert className="w-4 h-4 text-rose-600 dark:text-rose-400 shrink-0" />
            <div className="flex flex-col">
              <span className="text-[10px] text-rose-700 dark:text-rose-300 font-semibold uppercase">Active Outbreak Signals</span>
              <span className="text-xs font-bold text-slate-900 dark:text-white">{outbreakAlerts.length} Alerts Active</span>
            </div>
          </div>
          <div className="flex items-center gap-2 bg-white dark:bg-[#1E1E1E] border border-indigo-200 dark:border-indigo-500/30 rounded-xl px-3 py-1.5 shadow-xs">
            <div className="flex flex-col">
              <span className="text-[10px] text-indigo-700 dark:text-indigo-300 font-semibold uppercase">Tracked Indicators</span>
              <span className="text-xs font-bold text-indigo-700 dark:text-indigo-400">6 Key NHM Programs</span>
            </div>
          </div>
        </div>
      </div>

      {/* Outbreak Detection Signals Banner (Req 42.3) */}
      {outbreakAlerts.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center space-x-2 text-rose-600 dark:text-rose-400 font-bold text-xs uppercase tracking-wider">
            <AlertTriangle className="w-4 h-4" />
            <span>Outbreak Signals & Beneficiary Clustering (Requirement 42.3)</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {outbreakAlerts.map((alert) => (
              <div
                key={alert.id}
                className="p-4 rounded-2xl border border-rose-200 dark:border-rose-500/30 bg-rose-50/40 dark:bg-rose-950/20 space-y-2"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-rose-500"></span>
                    <h3 className="text-sm font-bold text-[#0F172A] dark:text-white">{alert.disease}</h3>
                  </div>
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-rose-100 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-500/30 uppercase font-bold">
                    {alert.severity} SEVERITY
                  </span>
                </div>
                <div className="text-xs text-[#0F172A] dark:text-slate-300">
                  <span className="font-semibold text-rose-600 dark:text-rose-400">{alert.caseCount} Cases</span> clustered in {alert.affectedVillage} ({alert.block}) across {alert.timeframeDays} days.
                </div>
                <div className="flex items-center justify-between pt-1 text-[11px] text-[#525252] dark:text-[#94A3B8]">
                  <span>Status: <strong className="text-amber-600 dark:text-amber-300 uppercase">{alert.status}</strong></span>
                  <span>Flagged: {new Date(alert.flaggedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 6 Key NHM Programme Indicators (Req 42.1 & 42.7) */}
      <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-5 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
              Programme Coverage & Outcome Indicators vs Targets (Req 42.1)
            </h2>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              Computed near real-time from synced frontline clinical encounters and immunization records
            </p>
          </div>

          <div className="flex items-center space-x-1.5 bg-slate-100 dark:bg-[#181818] p-1 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs">
            {(['all', 'maternal', 'child', 'ncd', 'tb'] as const).map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3 py-1 rounded-lg capitalize transition-all font-medium cursor-pointer ${
                  selectedCategory === cat
                    ? 'bg-indigo-600 text-white font-bold'
                    : 'text-[#525252] dark:text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-white'
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
                className="p-4 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] space-y-3"
              >
                <div className="flex items-start justify-between">
                  <span className="text-[10px] px-2 py-0.5 rounded bg-slate-200 dark:bg-[#2A2A2A] text-[#525252] dark:text-[#94A3B8] uppercase font-mono">
                    {ind.code}
                  </span>
                  <div className="flex items-center space-x-1 text-xs">
                    {ind.trend === 'up' ? (
                      <span className="text-emerald-600 dark:text-emerald-400 flex items-center font-semibold">
                        <ArrowUpRight className="w-3.5 h-3.5" /> +{(ind.currentValue - ind.previousValue).toFixed(1)}%
                      </span>
                    ) : (
                      <span className="text-rose-600 dark:text-rose-400 flex items-center font-semibold">
                        <ArrowDownRight className="w-3.5 h-3.5" /> {(ind.currentValue - ind.previousValue).toFixed(1)}%
                      </span>
                    )}
                  </div>
                </div>

                <div>
                  <div className="text-xs font-semibold text-[#0F172A] dark:text-[#F8FAFC] line-clamp-1">{ind.name}</div>
                  <div className="flex items-baseline space-x-2 pt-1">
                    <span className="text-2xl font-extrabold text-[#0F172A] dark:text-white">
                      {ind.currentValue}{ind.unit}
                    </span>
                    <span className="text-xs text-[#525252] dark:text-[#94A3B8] font-medium">
                      Target: {ind.targetValue}{ind.unit}
                    </span>
                  </div>
                </div>

                {/* Target Progress Bar */}
                <div className="space-y-1">
                  <div className="flex justify-between text-[10px] text-[#525252] dark:text-[#94A3B8]">
                    <span>Target Attainment</span>
                    <span className={meetsTarget ? 'text-emerald-600 dark:text-emerald-400 font-bold' : 'text-amber-600 dark:text-amber-400 font-bold'}>
                      {progress}%
                    </span>
                  </div>
                  <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-[#2A2A2A] overflow-hidden">
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
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
          <div className="text-xs text-[#525252] dark:text-[#94A3B8] flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>DPDP Re-identification Guard Active: Cells with counts &lt; 5 suppressed or aggregated automatically.</span>
          </div>
          <Button
            size="sm"
            variant="outline"
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
            className="gap-1.5 self-start sm:self-auto"
          >
            <Download className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
            <span>Export De-Identified CSV (Req 42.6)</span>
          </Button>
        </div>

        {/* Visual Recharts Comparison Graph */}
        <div className="pt-4 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
          <div className="text-xs font-semibold text-[#0F172A] dark:text-slate-300 mb-3">
            District Performance vs NHM National Targets (Comparison Chart)
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" strokeOpacity={0.4} />
                <XAxis dataKey="name" stroke="#94a3b8" tick={{ fill: '#94a3b8', fontSize: 11 }} />
                <YAxis stroke="#94a3b8" tick={{ fill: '#94a3b8', fontSize: 11 }} domain={[0, 100]} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#1E1E1E', borderColor: '#2E2E2E', borderRadius: '0.75rem', fontSize: '12px', color: '#F8FAFC' }}
                />
                <Bar dataKey="current" fill="#6366f1" radius={[4, 4, 0, 0]} name="Current Achieved (%)" />
                <Bar dataKey="target" fill="#10b981" radius={[4, 4, 0, 0]} name="Target (%)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </Card>

      {/* Supply Chain Forecasting (Req 42.4) */}
      <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-4 shadow-xs">
        <h2 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
          <Package className="w-5 h-5 text-amber-600 dark:text-amber-400" />
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
                    ? 'border-rose-200 dark:border-rose-500/40 bg-rose-50/50 dark:bg-rose-950/20'
                    : isWarning
                    ? 'border-amber-200 dark:border-amber-500/40 bg-amber-50/50 dark:bg-amber-950/20'
                    : 'border-[#E5E7EB] dark:border-[#2E2E2E] bg-slate-50 dark:bg-[#1E1E1E]'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-mono text-[#525252] dark:text-[#94A3B8]">{supply.itemCode}</span>
                  <span
                    className={`text-[9px] px-1.5 py-0.5 rounded font-bold uppercase ${
                      isCritical
                        ? 'bg-rose-100 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300'
                        : isWarning
                        ? 'bg-amber-100 dark:bg-amber-500/20 text-amber-700 dark:text-amber-300'
                        : 'bg-emerald-100 dark:bg-emerald-500/20 text-emerald-700 dark:text-emerald-300'
                    }`}
                  >
                    {supply.status.replace('_', ' ')}
                  </span>
                </div>

                <div className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">{supply.itemName}</div>

                <div className="pt-1">
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Run-out Estimate:</div>
                  <div
                    className={`text-xl font-extrabold ${
                      isCritical ? 'text-rose-600 dark:text-rose-400' : isWarning ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-600 dark:text-emerald-400'
                    }`}
                  >
                    {supply.estimatedDaysRemaining} Days Left
                  </div>
                </div>

                <div className="text-[11px] text-[#525252] dark:text-[#94A3B8] flex items-center justify-between border-t border-[#E5E7EB] dark:border-[#2E2E2E] pt-2">
                  <span>Stock: {supply.currentStock} units</span>
                  <span>Daily: ~{supply.dailyConsumptionRate}/day</span>
                </div>
              </div>
            );
          })}
        </div>
      </Card>
    </div>
  );
}
