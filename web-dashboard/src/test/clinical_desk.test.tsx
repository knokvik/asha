import '@testing-library/jest-dom/vitest';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { PCMC_WARDS } from '@/shared/api/mockData';
import {
  getReferralQueue,
  recordClinicalOutcome,
  resetReferralCache,
  wardConfirmations,
} from '@/shared/api/referralApi';
import {
  ashaRows,
  flagsPerThousand,
  outbreakWards,
  resourceCards,
  slaLabel,
  sortAshas,
  unseenRedIds,
  validateOutcome,
  type DeskCase,
  type WardWeek,
} from '@/features/clinical-desk/logic';
import { TicketPage } from '@/features/phc-dashboard/TicketPage';
import { ResourcesPage } from '@/features/phc-dashboard/ResourcesPage';
import { PcmcHeatPanel } from '@/features/map/PcmcHeatPanel';

function renderWithQuery(ui: React.ReactElement) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}

describe('PCMC desk on the existing dashboard', () => {
  beforeEach(() => resetReferralCache());
  afterEach(() => resetReferralCache());

  it('puts the oldest RED ahead of newer reds, then yellow', async () => {
    const queue = await getReferralQueue('phc-shahpur');
    const reds = queue.filter((item) => item.severity === 'RED');
    expect(reds[0].id).toBe('CASE-W3-RED-OLD');
    expect(new Date(reds[0].referredAt).getTime()).toBeLessThan(new Date(reds[1].referredAt).getTime());
    const firstYellow = queue.findIndex((item) => item.severity === 'YELLOW');
    const lastRed = queue.map((item) => item.severity).lastIndexOf('RED');
    expect(firstYellow).toBeGreaterThan(lastRed);
    expect(queue.some((item) => item.patientName === 'Sunita Devi')).toBe(true);
  });

  it('counts a 30 minute SLA and marks older reds overdue', () => {
    const now = Date.now();
    expect(slaLabel(new Date(now - 10 * 60 * 1000).toISOString(), now).overdue).toBe(false);
    expect(slaLabel(new Date(now - 10 * 60 * 1000).toISOString(), now).text).toMatch(/left/);
    expect(slaLabel(new Date(now - 40 * 60 * 1000).toISOString(), now).overdue).toBe(true);
    expect(slaLabel(new Date(now - 40 * 60 * 1000).toISOString(), now).text).toMatch(/overdue/);
  });

  it('requires a diagnosis and one of the three actions', () => {
    expect(validateOutcome({ diagnosis: '  ', action: 'treated' })).toBe('Enter a diagnosis.');
    expect(validateOutcome({ diagnosis: 'Pneumonia', action: 'admitted' })).toBe('Choose what was done.');
    expect(validateOutcome({ diagnosis: 'Pneumonia', action: 'sent_home' })).toBeNull();
  });

  it('keeps the child name and any phone number out of the referral SMS', async () => {
    const queue = await getReferralQueue();
    const child = queue.find((item) => item.id === 'CASE-W3-RED-OLD');
    expect(child?.sms).toBe('REF|CASE-W3-RED-OLD|RED|8m|F|RR52|T38.5|DS-CONV|W3');
    expect(child?.sms).not.toContain('Demo child');
    expect(child?.sms).not.toMatch(/\+91/);
    expect(child?.outbreakContext).toBe('8 dengue-like cases in W3 in the last 2 weeks');
  });

  it('raises an NS1 card for W3 when dengue-like flags reach 5', () => {
    const cards = resourceCards(PCMC_WARDS as WardWeek[], 11);
    expect(cards.some((card) => card.detail.includes('NS1'))).toBe(true);
    expect(outbreakWards(PCMC_WARDS as WardWeek[], 11)).toEqual(['W3']);
    expect(outbreakWards(PCMC_WARDS as WardWeek[], 8)).toEqual([]);
    expect(flagsPerThousand(5, 8000)).toBe(0.6);
  });

  it('sorts ASHA rows and flags a missed follow-up', () => {
    const cases: DeskCase[] = [
      { id: 'a', flag: 'YELLOW', ashaId: 'ASHA-MEENA', ashaName: 'Meena Patil', wardId: 'W1', followUpDays: 2 },
      { id: 'b', flag: 'RED', ashaId: 'ASHA-SUNITA', ashaName: 'Sunita Sharma', wardId: 'W3', followUpDays: null },
    ];
    const rows = sortAshas(ashaRows(cases), 'missedFollowUps', 'desc');
    expect(rows[0].name).toBe('Meena Patil');
    expect(rows[0].missedFollowUps).toBe(1);
  });

  it('ignores reds that were already on the board', () => {
    expect(unseenRedIds(['CASE-W3-RED-OLD'], ['CASE-W3-RED-OLD', 'CASE-LIVE'])).toEqual(['CASE-LIVE']);
  });

  it('adds the outcome to the ward confirmation the heatmap reads', async () => {
    expect(wardConfirmations().W3).toBeUndefined();
    const saved = await recordClinicalOutcome('CASE-W3-RED-OLD', {
      diagnosis: 'Very severe febrile disease',
      action: 'referred_up',
      noteForAsha: 'Child sent to the UPHC. Stay with the caregiver.',
    });
    expect(saved.status).toBe('admitted');
    expect(saved.noteForAsha).toContain('caregiver');
    expect(wardConfirmations().W3).toBe(1);
  });

  it('blocks the ticket form until a diagnosis is entered', async () => {
    renderWithQuery(
      <MemoryRouter initialEntries={['/ticket/CASE-W3-RED-OLD']}>
        <Routes>
          <Route path="/ticket/:id" element={<TicketPage />} />
        </Routes>
      </MemoryRouter>,
    );
    expect(await screen.findByText('REF|CASE-W3-RED-OLD|RED|8m|F|RR52|T38.5|DS-CONV|W3')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: /Record outcome/i }));
    expect(await screen.findByText('Enter a diagnosis.')).toBeInTheDocument();
  });

  it('shows the W3 NS1 card and the dengue sparkline on the existing views', async () => {
    renderWithQuery(<ResourcesPage />);
    expect(await screen.findByText(/Verify NS1 rapid test stock/i)).toBeInTheDocument();
    renderWithQuery(<PcmcHeatPanel />);
    expect(await screen.findByText(/Latest weeks run 1, 2, 3, 5/i)).toBeInTheDocument();
    expect(screen.getByText(/W3 outbreak/i)).toBeInTheDocument();
  });
});
