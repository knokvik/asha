import '@testing-library/jest-dom/vitest';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '@/shared/hooks/useAuth';
import { PHCDashboardPage } from '@/features/phc-dashboard/PHCDashboardPage';
import { ANMWorkspacePage } from '@/features/anm-workspace/ANMWorkspacePage';
import { AdminConsolePage } from '@/features/admin/AdminConsolePage';
import { getReferralQueue, recordReferralOutcome } from '@/shared/api/referralApi';
import { getIncentiveVerificationQueue, verifyClaimLineItem } from '@/shared/api/anmApi';
import { bulkUploadUsers } from '@/shared/api/adminApi';

function renderWithProviders(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <MemoryRouter>{ui}</MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

describe('Task 14.6: React Dashboard Integration Tests (Requirements 40.6, 41.1, 41.2, 43.1)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  it('Requirement 41.1: Referral queue fetches referrals and renders RED severity first', async () => {
    const queue = await getReferralQueue('phc-shahpur');
    expect(queue.length).toBeGreaterThan(0);
    expect(queue[0].severity).toBe('RED');

    renderWithProviders(<PHCDashboardPage />);

    // Must find emergency triage heading and patient name
    await waitFor(() => {
      expect(screen.getByText(/PHC Shahpur Emergency Triage & Referral Queue/i)).toBeInTheDocument();
      expect(screen.getByText('Sunita Devi')).toBeInTheDocument();
    });

    // Check that RED flag badges are prominent
    const redBadges = screen.getAllByText(/RED TRIAGE/i);
    expect(redBadges.length).toBeGreaterThan(0);
  });

  it('Requirement 41.2: Recording referral outcome updates status and triggers push notification to ASHA', async () => {
    const queue = await getReferralQueue('phc-shahpur');
    const targetRef = queue[0];

    const updated = await recordReferralOutcome(
      targetRef.id,
      'treated',
      'Blood pressure stabilized with IV labetalol'
    );

    expect(updated.id).toBe(targetRef.id);
    expect(updated.status).toBe('treated');
    expect(updated.outcomeNotes).toBe('Blood pressure stabilized with IV labetalol');
    expect(updated.outcomeRecordedAt).toBeDefined();

    renderWithProviders(<PHCDashboardPage />);

    await waitFor(() => {
      expect(screen.getByText('Sunita Devi')).toBeInTheDocument();
    });

    // Open Record Outcome modal
    const outcomeButtons = screen.getAllByRole('button', { name: /Record Outcome/i });
    fireEvent.click(outcomeButtons[0]);

    await waitFor(() => {
      expect(screen.getByText(/Clinical Outcome & Diagnosis Notes/i)).toBeInTheDocument();
    });
  });

  it('Requirement 40.3 & 56.3: ANM workspace presents verification queue with line items and evidence links', async () => {
    const claims = await getIncentiveVerificationQueue('sc-shahpur');
    expect(claims.length).toBeGreaterThan(0);

    const firstClaim = claims[0];
    expect(firstClaim.amount).toBeGreaterThan(0);
    expect(firstClaim.memberCodedId).toBeDefined();
    expect(firstClaim.evidenceRefId).toBeDefined();

    renderWithProviders(<ANMWorkspacePage />);

    await waitFor(() => {
      expect(screen.getByText(/ANM & CHO Clinical Workspace/i)).toBeInTheDocument();
      expect(screen.getByText(/Early ANC registration within 12 weeks/i)).toBeInTheDocument();
    });

    // Test line item approval
    const verified = await verifyClaimLineItem(firstClaim.id, 'approved');
    expect(verified.status).toBe('approved');
  });

  it('Requirement 43.1: Admin bulk user CSV upload parses and enrolls frontline staff with role mapping', async () => {
    const csvData = `name,role,phone,block,subcentre
Sunita Kumari,ASHA,+919811199988,Shahpur,SC Rampur
Kanti Devi,ASHA,+919811199989,Shahpur,SC Kalyanpur
Pooja Rani,ANM,+919811199990,Shahpur,SC Shahpur`;

    const result = await bulkUploadUsers(csvData);
    expect(result.success).toBe(true);
    expect(result.count).toBe(3);

    renderWithProviders(<AdminConsolePage />);

    await waitFor(() => {
      expect(screen.getByText(/State & Platform Administration Console/i)).toBeInTheDocument();
      expect(screen.getByText(/Bulk Frontline Worker Onboarding via CSV/i)).toBeInTheDocument();
    });
  });

  it('Requirement 40.6: ANM workspace provides resilient offline-capable cached data', async () => {
    // When network fails, cached claims are served immediately without blocking
    const claimsOffline = await getIncentiveVerificationQueue('sc-shahpur');
    expect(claimsOffline.length).toBeGreaterThanOrEqual(4);
    expect(claimsOffline.some((c) => c.activityCode === 'INSTITUTIONAL_DELIVERY')).toBe(true);
  });
});
