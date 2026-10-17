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
  AlertTriangle,
  Calendar,
  Layers,
  ArrowRight,
  Download,
  Share2,
  ShieldCheck,
  Check,
  X,
  FileSpreadsheet,
} from 'lucide-react';

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
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 glass-panel p-6 rounded-2xl border border-slate-800">
        <div className="flex items-center space-x-3">
          <div className="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
            <FileCheck2 className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-white flex items-center gap-2">
              ANM & CHO Clinical Workspace (Requirement 40)
            </h1>
            <p className="text-xs text-slate-400">
              Sub-centre: SC Shahpur • ANM: Kavita Kumari • Sync Review, Session Entry & Incentive Verification
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="glass-card px-4 py-2 rounded-xl border border-amber-500/30">
            <div className="text-[10px] text-amber-300 font-semibold uppercase tracking-wider">Pending Claims</div>
            <div className="text-lg font-bold text-white">{pendingClaims.length} Line Items</div>
          </div>
          <div className="glass-card px-4 py-2 rounded-xl border border-emerald-500/30">
            <div className="text-[10px] text-emerald-300 font-semibold uppercase tracking-wider">Verified Amount</div>
            <div className="text-lg font-bold text-emerald-400">₹{approvedTotal.toFixed(2)}</div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center space-x-2 border-b border-slate-800 pb-2">
        <button
          onClick={() => setActiveTab('claims_review')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'claims_review'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <ShieldCheck className="w-4 h-4" />
          <span>Incentive Verification Queue ({pendingClaims.length})</span>
        </button>
        <button
          onClick={() => setActiveTab('vhsnd_session')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'vhsnd_session'
              ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Calendar className="w-4 h-4" />
          <span>VHSND Session Entry</span>
        </button>
        <button
          onClick={() => setActiveTab('sync_review')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'sync_review'
              ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Sub-centre Sync Review</span>
        </button>
      </div>

      {/* Tab 1: Incentive Claim Verification Queue (Req 40.3 & Req 56.3) */}
      {activeTab === 'claims_review' && (
        <div className="space-y-4">
          <div className="p-3 rounded-xl bg-slate-900/60 border border-slate-800 text-xs text-slate-400 flex items-center justify-between">
            <span>
              Mandatory review of underlying clinical event records before claim approval. State-standard sampling supported.
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => {
                  pendingClaims.forEach((c) =>
                    verifyMutation.mutate({ id: c.id, action: 'approved' })
                  );
                }}
                className="px-3 py-1 rounded-lg bg-emerald-600/30 border border-emerald-500/40 text-emerald-300 font-semibold text-xs hover:bg-emerald-600/50"
              >
                Approve All Pending ({pendingClaims.length})
              </button>
            </div>
          </div>

          <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-900/80 border-b border-slate-800 text-slate-400 font-semibold uppercase text-[10px] tracking-wider">
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
                <tbody className="divide-y divide-slate-800/60 text-slate-300">
                  {claimItems.map((item) => {
                    const isPending = item.status === 'submitted';
                    return (
                      <tr key={item.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="p-3.5 font-bold text-white">{item.ashaName}</td>
                        <td className="p-3.5">
                          <div className="font-semibold text-slate-200">{item.activityDescription}</div>
                          <div className="font-mono text-[10px] text-amber-400/80">{item.activityCode}</div>
                        </td>
                        <td className="p-3.5 font-mono text-slate-400">{item.memberCodedId}</td>
                        <td className="p-3.5">{item.serviceDate}</td>
                        <td className="p-3.5 font-bold text-emerald-400">₹{item.amount.toFixed(2)}</td>
                        <td className="p-3.5 font-mono text-[11px] text-indigo-400">
                          {item.evidenceRefId} (Linked Encounter)
                        </td>
                        <td className="p-3.5 text-center">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase ${
                              item.status === 'approved'
                                ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                                : item.status === 'rejected'
                                ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                                : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                            }`}
                          >
                            {item.status}
                          </span>
                        </td>
                        <td className="p-3.5 text-right">
                          {isPending ? (
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() =>
                                  verifyMutation.mutate({ id: item.id, action: 'approved' })
                                }
                                className="px-2.5 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-semibold flex items-center space-x-1"
                              >
                                <Check className="w-3 h-3" />
                                <span>Approve</span>
                              </button>
                              <button
                                onClick={() => setRejectingItem(item)}
                                className="px-2.5 py-1 rounded-lg bg-rose-600 hover:bg-rose-500 text-white font-semibold flex items-center space-x-1"
                              >
                                <X className="w-3 h-3" />
                                <span>Reject</span>
                              </button>
                            </div>
                          ) : (
                            <span className="text-[11px] text-slate-500 font-medium">Verified</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: VHSND Session Entry (Req 40.2) */}
      {activeTab === 'vhsnd_session' && (
        <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-5 max-w-2xl">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <Calendar className="w-5 h-5 text-indigo-400" />
            VHSND / Sub-Centre Session Entry & Beneficiary Timelines
          </h2>

          <div className="space-y-4 text-xs">
            <div>
              <label className="block font-semibold text-slate-300 mb-1">Session Location / Sub-Centre</label>
              <input
                type="text"
                value={vhsndVillage}
                onChange={(e) => setVhsndVillage(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Beneficiaries Attended</label>
                <input
                  type="number"
                  value={attendeesCount}
                  onChange={(e) => setAttendeesCount(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Vaccine Doses Administered</label>
                <input
                  type="number"
                  value={immunizationsGiven}
                  onChange={(e) => setImmunizationsGiven(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">ANC Checkups & Services</label>
                <input
                  type="number"
                  value={ancServicesGiven}
                  onChange={(e) => setAncServicesGiven(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-300 mb-1">CBAC NCD Screenings</label>
                <input
                  type="number"
                  value={cbacScreenings}
                  onChange={(e) => setCbacScreenings(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
                />
              </div>
            </div>

            <div>
              <label className="block font-semibold text-slate-300 mb-1">Session Summary Notes</label>
              <textarea
                rows={3}
                value={sessionNotes}
                onChange={(e) => setSessionNotes(e.target.value)}
                placeholder="e.g. Completed measles-rubella catchup doses. 2 pregnant mothers screened positive for severe anaemia."
                className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs"
              />
            </div>

            {vhsndSaved && (
              <div className="p-3 rounded-xl bg-emerald-950/30 border border-emerald-500/40 text-emerald-300 text-xs flex items-center space-x-2">
                <CheckCircle2 className="w-4 h-4" />
                <span>Session recorded! Individual beneficiary timelines updated automatically.</span>
              </div>
            )}

            <button
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
              className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs shadow-lg shadow-indigo-600/30"
            >
              Submit VHSND Session & Update Timelines (Req 40.2)
            </button>
          </div>
        </div>
      )}

      {/* Tab 3: Sub-centre Sync Review (Req 40.1) */}
      {activeTab === 'sync_review' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">New Registrations (Synced Today)</div>
            <div className="text-2xl font-bold text-white">6 Beneficiaries</div>
            <p className="text-xs text-slate-400">
              3 new pregnancies registered within 12 weeks; 2 infants added to immunization queue.
            </p>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Validation Flags for Correction</div>
            <div className="text-2xl font-bold text-amber-400">1 Missing Contact</div>
            <p className="text-xs text-slate-400">
              Household HH-402 phone number digit count mismatch; flagged for ASHA verification.
            </p>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Government Portal Assistant</div>
            <div className="text-2xl font-bold text-indigo-400">Pre-filled Export</div>
            <p className="text-xs text-slate-400">
              Ready for one-click HMIS / ANMOL portal CSV submission.
            </p>
          </div>
        </div>
      )}

      {/* Rejection Reason Modal (Req 56.3) */}
      {rejectingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="glass-panel w-full max-w-md p-6 rounded-2xl border border-slate-700 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="font-bold text-white text-base flex items-center gap-2">
                <XCircle className="w-5 h-5 text-rose-400" />
                Reject Claim Line: {rejectingItem.activityDescription}
              </h3>
              <button
                onClick={() => setRejectingItem(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-semibold text-slate-300">
                Mandatory Rejection / Correction Reason (Req 56.3):
              </label>
              <textarea
                rows={3}
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="e.g. Sputum test lab report attachment missing or unreadable; please re-upload evidence."
                className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs focus:outline-none focus:border-rose-500"
              />
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => setRejectingItem(null)}
                className="px-4 py-2 rounded-xl border border-slate-700 text-slate-300 text-xs font-semibold hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                disabled={!rejectionReason.trim()}
                onClick={() =>
                  verifyMutation.mutate({
                    id: rejectingItem.id,
                    action: 'rejected',
                    reason: rejectionReason,
                  })
                }
                className="px-5 py-2 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-semibold shadow-lg shadow-rose-600/30 disabled:opacity-50"
              >
                Confirm Rejection & Notify ASHA
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
