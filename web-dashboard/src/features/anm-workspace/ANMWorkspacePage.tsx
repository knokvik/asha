import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getIncentiveVerificationQueue,
  verifyClaimLineItem,
  recordVhsndSession,
} from '@/shared/api/anmApi';
import { IncentiveClaimLineItem } from '@/types';
import {
  FileCheck2,
  CheckCircle2,
  XCircle,
  Calendar,
  Layers,
  ShieldCheck,
  Check,
  X,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export function ANMWorkspacePage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<'claims_review' | 'vhsnd_session' | 'sync_review'>('claims_review');
  const [rejectingItem, setRejectingItem] = useState<IncentiveClaimLineItem | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  // VHSND Session state
  const [vhsndVillage, setVhsndVillage] = useState('Shahpur Central Subcentre');
  const [attendeesCount, setAttendeesCount] = useState(24);
  const [immunizationsGiven, setImmunizationsGiven] = useState(18);
  const [ancServicesGiven, setAncServicesGiven] = useState(8);
  const [cbacScreenings, setCbacScreenings] = useState(12);
  const [sessionNotes, setSessionNotes] = useState('');
  const [vhsndSaved, setVhsndSaved] = useState(false);

  const { data: claimItems = [], isLoading } = useQuery({
    queryKey: ['anm-claims-review'],
    queryFn: () => getIncentiveVerificationQueue('sc-shahpur'),
  });

  const verifyMutation = useMutation({
    mutationFn: ({ id, action, reason }: { id: string; action: any; reason?: string }) =>
      verifyClaimLineItem(id, action, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['anm-claims-review'] });
      setRejectingItem(null);
      setRejectionReason('');
    },
  });

  const vhsndMutation = useMutation({
    mutationFn: (data: any) => recordVhsndSession(data),
    onSuccess: () => {
      setVhsndSaved(true);
      setTimeout(() => setVhsndSaved(false), 2500);
    },
  });

  const pendingClaims = claimItems.filter((c) => c.status === 'submitted');
  const approvedTotal = claimItems
    .filter((c) => c.status === 'approved')
    .reduce((sum, c) => sum + c.amount, 0);

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Banner */}
      <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center space-x-3.5">
            <div className="p-3 rounded-xl bg-emerald-500/10 dark:bg-emerald-500/15 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400">
              <FileCheck2 className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
                ANM & CHO Clinical Workspace (Requirement 40)
              </h1>
              <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
                Sub-centre: SC Shahpur • ANM: Kavita Kumari • Sync Review, Session Entry & Incentive Verification
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="px-4 py-2 rounded-xl border border-amber-200 dark:border-amber-500/30 bg-amber-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-amber-700 dark:text-amber-300 font-semibold uppercase tracking-wider">Pending Claims</div>
              <div className="text-lg font-bold text-[#0F172A] dark:text-white">{pendingClaims.length} Line Items</div>
            </div>
            <div className="px-4 py-2 rounded-xl border border-emerald-200 dark:border-emerald-500/30 bg-emerald-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-emerald-700 dark:text-emerald-400 font-semibold uppercase tracking-wider">Verified Amount</div>
              <div className="text-lg font-bold text-emerald-700 dark:text-emerald-400">₹{approvedTotal.toFixed(2)}</div>
            </div>
          </div>
        </div>
      </Card>

      {/* Tabs */}
      <div className="flex items-center space-x-2 border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-2">
        <button
          onClick={() => setActiveTab('claims_review')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'claims_review'
              ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <ShieldCheck className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Incentive Verification Queue ({pendingClaims.length})</span>
        </button>
        <button
          onClick={() => setActiveTab('vhsnd_session')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'vhsnd_session'
              ? 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <Calendar className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
          <span>VHSND Session Entry</span>
        </button>
        <button
          onClick={() => setActiveTab('sync_review')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'sync_review'
              ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <Layers className="w-4 h-4 text-amber-600 dark:text-amber-400" />
          <span>Sub-centre Sync Review</span>
        </button>
      </div>

      {/* Tab 1: Incentive Claim Verification Queue (Req 40.3 & Req 56.3) */}
      {activeTab === 'claims_review' && (
        <div className="space-y-4">
          <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#525252] dark:text-[#94A3B8] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <span>
              Mandatory review of underlying clinical event records before claim approval. State-standard sampling supported.
            </span>
            <div className="flex items-center gap-2">
              <Button
                size="sm"
                onClick={() => {
                  pendingClaims.forEach((c) =>
                    verifyMutation.mutate({ id: c.id, action: 'approved' })
                  );
                }}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs"
              >
                Approve All Pending ({pendingClaims.length})
              </Button>
            </div>
          </div>

          <Card className="rounded-2xl border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-[#1E1E1E] border-b border-[#E5E7EB] dark:border-[#2E2E2E] text-[#525252] dark:text-[#94A3B8] font-semibold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="p-3.5">ASHA Worker</th>
                    <th className="p-3.5">Activity Code & Description</th>
                    <th className="p-3.5">Beneficiary Reference</th>
                    <th className="p-3.5">Service Date</th>
                    <th className="p-3.5">Amount</th>
                    <th className="p-3.5">Clinical Evidence</th>
                    <th className="p-3.5 text-center">Status</th>
                    <th className="p-3.5 text-right">Verification Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB] dark:divide-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC]">
                  {claimItems.map((item) => {
                    const isPending = item.status === 'submitted';
                    return (
                      <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-[#2A2A2A]/40 transition-colors">
                        <td className="p-3.5 font-bold">{item.ashaName}</td>
                        <td className="p-3.5">
                          <div className="font-semibold">{item.activityDescription}</div>
                          <div className="font-mono text-[10px] text-amber-600 dark:text-amber-400">{item.activityCode}</div>
                        </td>
                        <td className="p-3.5 font-mono text-[#525252] dark:text-[#94A3B8]">{item.memberCodedId}</td>
                        <td className="p-3.5 text-[#525252] dark:text-[#94A3B8]">{item.serviceDate}</td>
                        <td className="p-3.5 font-bold text-emerald-600 dark:text-emerald-400">₹{item.amount.toFixed(2)}</td>
                        <td className="p-3.5 font-mono text-[11px] text-indigo-600 dark:text-indigo-400">
                          {item.evidenceRefId} (Linked Encounter)
                        </td>
                        <td className="p-3.5 text-center">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase border ${
                              item.status === 'approved'
                                ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-500/30'
                                : item.status === 'rejected'
                                ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-500/30'
                                : 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-500/30'
                            }`}
                          >
                            {item.status}
                          </span>
                        </td>
                        <td className="p-3.5 text-right">
                          {isPending ? (
                            <div className="flex items-center justify-end gap-1.5">
                              <Button
                                size="xs"
                                onClick={() =>
                                  verifyMutation.mutate({ id: item.id, action: 'approved' })
                                }
                                className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold flex items-center space-x-1"
                              >
                                <Check className="w-3 h-3" />
                                <span>Approve</span>
                              </Button>
                              <Button
                                size="xs"
                                variant="destructive"
                                onClick={() => setRejectingItem(item)}
                                className="flex items-center space-x-1"
                              >
                                <X className="w-3 h-3" />
                                <span>Reject</span>
                              </Button>
                            </div>
                          ) : (
                            <span className="text-[11px] text-[#71717A] font-medium">Verified</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </Card>
        </div>
      )}

      {/* Tab 2: VHSND Session Entry (Req 40.2) */}
      {activeTab === 'vhsnd_session' && (
        <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-5 max-w-2xl shadow-xs">
          <h2 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
            <Calendar className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
            VHSND / Sub-Centre Session Entry & Beneficiary Timelines
          </h2>

          <div className="space-y-4 text-xs">
            <div>
              <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Session Location / Sub-Centre</label>
              <input
                type="text"
                value={vhsndVillage}
                onChange={(e) => setVhsndVillage(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Attendees Count</label>
                <input
                  type="number"
                  value={attendeesCount}
                  onChange={(e) => setAttendeesCount(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs font-mono"
                />
              </div>
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Immunizations Given</label>
                <input
                  type="number"
                  value={immunizationsGiven}
                  onChange={(e) => setImmunizationsGiven(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs font-mono"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">ANC Checkups (with Hb/BP)</label>
                <input
                  type="number"
                  value={ancServicesGiven}
                  onChange={(e) => setAncServicesGiven(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs font-mono"
                />
              </div>
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">NCD / CBAC Screenings (30+)</label>
                <input
                  type="number"
                  value={cbacScreenings}
                  onChange={(e) => setCbacScreenings(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs font-mono"
                />
              </div>
            </div>

            <div>
              <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Clinical Observation Notes</label>
              <textarea
                rows={3}
                value={sessionNotes}
                onChange={(e) => setSessionNotes(e.target.value)}
                placeholder="e.g. Completed measles-rubella catchup doses. 2 pregnant mothers screened positive for severe anaemia."
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] text-xs placeholder-[#71717A]"
              />
            </div>

            {vhsndSaved && (
              <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-500/40 text-emerald-800 dark:text-emerald-300 text-xs flex items-center space-x-2">
                <CheckCircle2 className="w-4 h-4" />
                <span>Session recorded! Individual beneficiary timelines updated automatically.</span>
              </div>
            )}

            <Button
              onClick={() =>
                vhsndMutation.mutate({
                  subcentreId: 'sc-shahpur',
                  village: vhsndVillage,
                  sessionDate: new Date().toISOString(),
                  attendeesCount,
                  immunizationsGiven,
                  ancServicesGiven,
                  cbacScreenings,
                  notes: sessionNotes,
                })
              }
              className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-xs py-2.5"
            >
              Submit VHSND Session & Update Timelines (Req 40.2)
            </Button>
          </div>
        </Card>
      )}

      {/* Tab 3: Sub-centre Sync Review (Req 40.1) */}
      {activeTab === 'sync_review' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">New Registrations (Synced Today)</div>
            <div className="text-2xl font-bold text-[#0F172A] dark:text-white">6 Beneficiaries</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              3 new pregnancies registered within 12 weeks; 2 infants added to immunization queue.
            </p>
          </Card>
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Validation Flags for Correction</div>
            <div className="text-2xl font-bold text-amber-600 dark:text-amber-400">1 Missing Contact</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              Household HH-402 phone number digit count mismatch; flagged for ASHA verification.
            </p>
          </Card>
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Government Portal Assistant</div>
            <div className="text-2xl font-bold text-indigo-600 dark:text-indigo-400">Pre-filled Export</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              Ready for one-click HMIS / ANMOL portal CSV submission.
            </p>
          </Card>
        </div>
      )}

      {/* Rejection Reason Modal (Req 56.3) */}
      {rejectingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md p-6 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <h3 className="font-bold text-base flex items-center gap-2">
                <XCircle className="w-5 h-5 text-rose-600 dark:text-rose-400" />
                Reject Claim Line: {rejectingItem.activityDescription}
              </h3>
              <button
                onClick={() => setRejectingItem(null)}
                className="p-1 rounded-lg text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-semibold">
                Mandatory Rejection / Correction Reason (Req 56.3):
              </label>
              <textarea
                rows={3}
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="e.g. Sputum test lab report attachment missing or unreadable; please re-upload evidence."
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A] focus:outline-none focus:ring-1 focus:ring-rose-500"
              />
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setRejectingItem(null)}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                variant="destructive"
                disabled={!rejectionReason.trim()}
                onClick={() =>
                  verifyMutation.mutate({
                    id: rejectingItem.id,
                    action: 'rejected',
                    reason: rejectionReason,
                  })
                }
              >
                Confirm Rejection & Notify ASHA
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
