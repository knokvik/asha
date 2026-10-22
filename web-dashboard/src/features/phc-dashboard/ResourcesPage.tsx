import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { getSupplyForecasts } from '@/shared/api/analyticsApi';

export function ResourcesPage() {
  const { data: supplies = [], isLoading } = useQuery({ queryKey: ['resources', 'supply-forecasts', 'phc-shahpur'], queryFn: () => getSupplyForecasts('phc-shahpur') });

  return (
    <div className="p-4 lg:p-8 max-w-5xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white tracking-tight">
          Drug & bed discovery
        </h1>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
          Live facility inventory and supply forecasts from the authenticated server.
        </p>
      </div>
      <div className="grid gap-3">
        {isLoading && <Card className="p-4 text-sm">Loading live facility inventory…</Card>}
        {!isLoading && supplies.length === 0 && <Card className="p-4 text-sm">No live inventory records are available for this facility.</Card>}
        {supplies.map((supply) => (
          <Card key={supply.itemCode} className="p-4 border-slate-200 space-y-1">
            <div className="flex items-center justify-between"><h2 className="text-sm font-bold">{supply.itemName}</h2><span className={`text-[10px] font-bold uppercase ${supply.status === 'critical_stockout' ? 'text-rose-600' : supply.status === 'warning' ? 'text-amber-600' : 'text-emerald-600'}`}>{supply.status.replace('_', ' ')}</span></div>
            <p className="text-xs">{supply.currentStock} units available · approximately {supply.estimatedDaysRemaining} days remaining · reorder at {supply.reorderLevel}</p>
          </Card>
        ))}
      </div>
    </div>
  );
}
