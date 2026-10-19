export type Flag = 'RED' | 'YELLOW' | 'GREEN';
export type OutcomeAction = 'treated' | 'referred_up' | 'sent_home';

/** One row the supervisor table can score. Mapped from ReferralItem. */
export interface DeskCase {
  id: string;
  flag: Flag;
  ashaId: string;
  ashaName: string;
  wardId: string;
  followUpDays: number | null;
  outcomeAction?: OutcomeAction;
}

export interface ClinicalTicket {
  id: string;
  createdAt: string;
  flag: Flag;
  status: 'open' | 'closed' | 'acknowledged' | 'in_consult';
  patient: {
    abhaId?: string;
    name: string;
    ageMonths?: number;
    sex: string;
    village: string;
    wardId: string;
  };
  asha: { id: string; name: string; wardId: string };
  vitals?: Record<string, any>;
  firedRules?: { ruleId: string; reason: string; guidelineRef?: string }[];
  suspected?: string;
  outbreakContext?: string;
  preReferral?: string[];
  urgency?: string;
  facilityId?: string | null;
  facilityName?: string;
  sms?: string;
  followUpDays?: number | null;
  outcome?: {
    action: OutcomeAction;
    diagnosis: string;
    noteForAsha?: string;
    recordedAt: string;
  };
}

export interface WeekPoint {
  week: number;
  dengueLike: number;
  fever: number;
  diarrhoea: number;
  measlesLike: number;
  aes: number;
  flags: number;
}

export interface WardWeek {
  wardId: string;
  population: number;
  anaemiaPct: number;
  stuntingPct: number;
  weeks: WeekPoint[];
}

export const RED_SLA_MS = 30 * 60 * 1000;
export const DENGUE_WEEKLY_THRESHOLD = 3;

export function sortQueue<T extends { flag: Flag; createdAt: string; status?: string }>(tickets: T[]): T[] {
  const live = tickets.filter(
    (ticket) => ticket.status !== 'closed' && (ticket.flag === 'RED' || ticket.flag === 'YELLOW'),
  );
  const rank = (flag: Flag) => (flag === 'RED' ? 0 : 1);
  return [...live].sort(
    (a, b) => rank(a.flag) - rank(b.flag) || a.createdAt.localeCompare(b.createdAt),
  );
}

export function slaLabel(createdAt: string, now: number): { text: string; overdue: boolean } {
  const left = new Date(createdAt).getTime() + RED_SLA_MS - now;
  const mins = Math.max(1, Math.ceil(Math.abs(left) / 60000));
  if (left >= 0) return { text: `${mins}m left`, overdue: false };
  return { text: `overdue ${mins}m`, overdue: true };
}

export function minutesSince(createdAt: string, now: number): string {
  const mins = Math.max(0, Math.floor((now - new Date(createdAt).getTime()) / 60000));
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  return `${hours}h ${mins % 60}m ago`;
}

export function validateOutcome(input: { diagnosis: string; action: string }): string | null {
  if (!input.diagnosis.trim()) return 'Enter a diagnosis.';
  if (input.action !== 'treated' && input.action !== 'referred_up' && input.action !== 'sent_home') {
    return 'Choose what was done.';
  }
  return null;
}

export function flagsPerThousand(flags: number, population: number): number {
  if (population <= 0) return 0;
  return Math.round((flags / population) * 1000 * 10) / 10;
}

export function weekPoint(ward: WardWeek, week: number): WeekPoint {
  return ward.weeks.find((point) => point.week === week) ?? ward.weeks[ward.weeks.length - 1];
}

export function outbreakWards(wards: WardWeek[], week: number): string[] {
  return wards
    .filter((ward) => weekPoint(ward, week).dengueLike >= DENGUE_WEEKLY_THRESHOLD)
    .map((ward) => ward.wardId);
}

export interface ResourceCard {
  id: string;
  wardId: string;
  title: string;
  detail: string;
}

export function resourceCards(wards: WardWeek[], week: number): ResourceCard[] {
  const cards: ResourceCard[] = [];
  for (const ward of wards) {
    const point = weekPoint(ward, week);
    if (point.dengueLike >= DENGUE_WEEKLY_THRESHOLD) {
      cards.push({
        id: `${ward.wardId}-dengue`,
        wardId: ward.wardId,
        title: `Ward ${ward.wardId}: ${point.dengueLike} dengue-like flags this week`,
        detail: 'Verify NS1 rapid test stock at the ward UPHC before the next clinic.',
      });
    }
    if (point.diarrhoea >= 8) {
      cards.push({
        id: `${ward.wardId}-diarrhoea`,
        wardId: ward.wardId,
        title: `Ward ${ward.wardId}: ${point.diarrhoea} acute diarrhoea flags this week`,
        detail: 'Check ORS and zinc packets.',
      });
    }
  }
  return cards;
}

export interface AshaRow {
  id: string;
  name: string;
  wardId: string;
  casesSeen: number;
  flagsRaised: number;
  completionPct: number;
  missedFollowUps: number;
  overTriagePct: number;
  underTriagePct: number;
  escalation: 'none' | 'watch' | 'escalate';
}

export function ashaRows(tickets: (DeskCase | ClinicalTicket)[]): AshaRow[] {
  const byId = new Map<string, { ticket: DeskCase | ClinicalTicket; outcomeAction?: OutcomeAction }[]>();
  for (const ticket of tickets) {
    const ashaId = 'asha' in ticket && ticket.asha ? ticket.asha.id : (ticket as DeskCase).ashaId;
    const outcomeAction = 'outcome' in ticket && ticket.outcome ? ticket.outcome.action : (ticket as DeskCase).outcomeAction;
    const list = byId.get(ashaId) ?? [];
    list.push({ ticket, outcomeAction });
    byId.set(ashaId, list);
  }
  return [...byId.entries()].map(([id, list]) => {
    const closed = list.filter((item) => item.outcomeAction);
    const reds = list.filter((item) => item.ticket.flag === 'RED');
    const yellows = list.filter((item) => item.ticket.flag === 'YELLOW');
    const over = reds.filter((item) => item.outcomeAction === 'sent_home').length;
    const under = yellows.filter((item) => item.outcomeAction === 'referred_up').length;
    const missed = list.filter(
      (item) => item.ticket.followUpDays != null && !item.outcomeAction && item.ticket.flag !== 'RED',
    ).length;
    const completion = list.length === 0 ? 0 : Math.round((closed.length / list.length) * 100);
    const overTriagePct = reds.length === 0 ? 0 : Math.round((over / reds.length) * 100);
    const underTriagePct = yellows.length === 0 ? 0 : Math.round((under / yellows.length) * 100);
    const escalation: AshaRow['escalation'] =
      missed >= 2 || underTriagePct >= 50 ? 'escalate' : overTriagePct >= 40 ? 'watch' : 'none';
    const firstTicket = list[0].ticket;
    const ashaName = 'asha' in firstTicket && firstTicket.asha ? firstTicket.asha.name : (firstTicket as DeskCase).ashaName;
    const wardId = 'asha' in firstTicket && firstTicket.asha ? firstTicket.asha.wardId : (firstTicket as DeskCase).wardId;
    return {
      id,
      name: ashaName,
      wardId,
      casesSeen: list.length,
      flagsRaised: list.filter((item) => item.ticket.flag !== 'GREEN').length,
      completionPct: completion,
      missedFollowUps: missed,
      overTriagePct,
      underTriagePct,
      escalation,
    };
  });
}

export type AshaSortKey = 'name' | 'casesSeen' | 'flagsRaised' | 'completionPct' | 'missedFollowUps';

export function sortAshas(rows: AshaRow[], key: AshaSortKey, dir: 'asc' | 'desc'): AshaRow[] {
  const sign = dir === 'asc' ? 1 : -1;
  return [...rows].sort((a, b) => {
    const left = a[key];
    const right = b[key];
    if (typeof left === 'number' && typeof right === 'number') return (left - right) * sign;
    return String(left).localeCompare(String(right)) * sign;
  });
}

export function unseenRedIds(previous: string[], next: string[]): string[] {
  const known = new Set(previous);
  return next.filter((id) => !known.has(id));
}
