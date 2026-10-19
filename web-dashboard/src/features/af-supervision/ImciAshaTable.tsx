import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getReferralQueue } from '@/shared/api/referralApi';
import {
  ashaRows,
  sortAshas,
  type AshaSortKey,
  type DeskCase,
} from '@/features/clinical-desk/logic';
import { Card } from '@/components/ui/card';

export function ImciAshaTable() {
  const { data: referrals = [] } = useQuery({
    queryKey: ['referrals', 'supervisor'],
    queryFn: () => getReferralQueue('pcmc'),
  });
  const [sortKey, setSortKey] = useState<AshaSortKey>('flagsRaised');
  const [dir, setDir] = useState<'asc' | 'desc'>('desc');
  const [openId, setOpenId] = useState<string | null>(null);

  const rows = useMemo(() => {
    const cases: DeskCase[] = referrals
      .filter((item) => item.wardId)
      .map((item) => ({
        id: item.id,
        flag: item.severity,
        ashaId: item.ashaId,
        ashaName: item.ashaName,
        wardId: item.wardId ?? '',
        followUpDays: item.followUpDays ?? null,
        outcomeAction: item.outcomeAction,
      }));
    return sortAshas(ashaRows(cases), sortKey, dir);
  }, [referrals, sortKey, dir]);

  const drill = referrals.filter((item) => item.ashaId === openId);

  const header = (key: AshaSortKey, label: string) => (
    <th className="px-2 py-1 text-left">
      <button
        type="button"
        className="font-semibold"
        onClick={() => {
          if (sortKey === key) setDir(dir === 'asc' ? 'desc' : 'asc');
          else {
            setSortKey(key);
            setDir('desc');
          }
        }}
      >
        {label}
      </button>
    </th>
  );

  return (
    <Card className="p-4 space-y-3" data-testid="imci-asha-table">
      <h2 className="text-sm font-bold">PCMC child triage — ASHA completion</h2>
      <p className="text-[11px] text-slate-500">
        Cases, flags, referral completion, missed follow-ups, and over or under triage from recorded outcomes.
      </p>
      <div className="overflow-x-auto">
        <table className="w-full text-xs">
          <thead>
            <tr>
              {header('name', 'ASHA')}
              <th className="px-2 py-1 text-left">Ward</th>
              {header('casesSeen', 'Cases')}
              {header('flagsRaised', 'Flags')}
              {header('completionPct', 'Completion %')}
              {header('missedFollowUps', 'Missed follow-ups')}
              <th className="px-2 py-1 text-left">Over %</th>
              <th className="px-2 py-1 text-left">Under %</th>
              <th className="px-2 py-1 text-left">Escalation</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} className="border-t border-slate-200">
                <td className="px-2 py-1">
                  <button type="button" className="underline" onClick={() => setOpenId(row.id)}>
                    {row.name}
                  </button>
                </td>
                <td className="px-2 py-1">{row.wardId}</td>
                <td className="px-2 py-1">{row.casesSeen}</td>
                <td className="px-2 py-1">{row.flagsRaised}</td>
                <td className="px-2 py-1">{row.completionPct}</td>
                <td className="px-2 py-1">{row.missedFollowUps}</td>
                <td className="px-2 py-1">{row.overTriagePct}</td>
                <td className="px-2 py-1">{row.underTriagePct}</td>
                <td className="px-2 py-1">{row.escalation}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {openId && (
        <div className="text-xs space-y-1">
          <div className="font-semibold">Recent assessments</div>
          {drill.map((item) => (
            <p key={item.id}>
              {item.id} · {item.severity} · {item.reason} · {item.status}
            </p>
          ))}
        </div>
      )}
    </Card>
  );
}
