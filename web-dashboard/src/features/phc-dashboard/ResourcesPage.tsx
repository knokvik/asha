import { useState } from 'react';
import { INITIAL_OUTBREAK_ALERTS, PCMC_WARDS } from '@/shared/api/mockData';
import { resourceCards, type WardWeek } from '@/features/clinical-desk/logic';
import { Card } from '@/components/ui/card';

export function ResourcesPage() {
  const [week, setWeek] = useState(11);
  const cards = resourceCards(PCMC_WARDS as WardWeek[], week);

  return (
    <div className="p-4 lg:p-8 max-w-5xl mx-auto space-y-4">
      <h1 className="text-xl font-bold">Early-warning resources</h1>
      <p className="text-xs text-slate-600">
        PCMC child flags sit next to the existing Shahpur outbreak alerts. Week {week + 1} of 12.
      </p>
      <label className="text-xs font-semibold block">
        Week
        <input
          aria-label="Resource week"
          type="range"
          min={0}
          max={11}
          value={week}
          onChange={(event) => setWeek(Number(event.target.value))}
          className="block w-full max-w-sm"
        />
      </label>
      <div className="grid gap-3">
        {cards.length === 0 && (
          <Card className="p-4 text-sm">No ward is over the dengue or diarrhoea threshold this week.</Card>
        )}
        {cards.map((card) => (
          <Card key={card.id} className="p-4 border-rose-200 space-y-1">
            <h2 className="text-sm font-bold">{card.title}</h2>
            <p className="text-xs">{card.detail}</p>
          </Card>
        ))}
      </div>
      <h2 className="text-sm font-bold pt-2">Existing block alerts</h2>
      <div className="grid gap-3">
        {INITIAL_OUTBREAK_ALERTS.map((alert) => (
          <Card key={alert.id} className="p-4 text-xs space-y-1">
            <div className="font-bold">{alert.disease} · {alert.affectedVillage}</div>
            <div>{alert.caseCount} cases in {alert.timeframeDays} days · {alert.block} · {alert.status}</div>
          </Card>
        ))}
      </div>
    </div>
  );
}
