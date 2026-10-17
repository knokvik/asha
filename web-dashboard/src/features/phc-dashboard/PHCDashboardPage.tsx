import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getReferralQueue, recordReferralOutcome, sendDoctorFeedback } from '@/shared/api/referralApi';
import { ReferralItem } from '@/types';
import {
  Activity,
  AlertTriangle,
  Phone,
  CheckCircle2,
  Clock,
  User,
  Send,
  Calendar,
  Layers,
  Search,
  Filter,
  Check,
  X,
  Stethoscope,
  Heart,
  Droplet,
} from 'lucide-react';

export function PHCDashboardPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<'referrals' | 'area_lists' | 'planning'>('referrals');
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'RED' | 'YELLOW'>('ALL');
  const [selectedReferral, setSelectedReferral] = useState<ReferralItem | null>(null);
  const [outcomeStatus, setOutcomeStatus] = useState<'treated' | 'admitted' | 'discharged' | 'did_not_reach'>('treated');
  const [outcomeNotes, setOutcomeNotes] = useState('');
  const [feedbackMessage, setFeedbackMessage] = useState('');
  const [feedbackSent, setFeedbackSent] = useState(false);

  // Poll referral queue every 30 seconds for live triage (Req 41.1, Design 2.7)
  const { data: referrals = [], isLoading, isRefetching } = useQuery({
    queryKey: ['referrals', 'pending', 'phc-shahpur'],
    queryFn: () => getReferralQueue('phc-shahpur'),
    refetchInterval: 30_000,
  });

  const outcomeMutation = useMutation({
    mutationFn: ({ id, status, notes }: { id: string; status: any; notes: string }) =>
      recordReferralOutcome(id, status, notes),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referrals'] });
      setSelectedReferral(null);
      setOutcomeNotes('');
    },
  });

  const feedbackMutation = useMutation({
    mutationFn: ({ refId, ashaId, msg }: { refId: string; ashaId: string; msg: string }) =>
      sendDoctorFeedback(refId, ashaId, msg),
    onSuccess: () => {
      setFeedbackSent(true);
      setTimeout(() => {
        setFeedbackSent(false);
        setFeedbackMessage('');
      }, 2500);
    },
  });

  const filteredReferrals = referrals.filter((r) => {
    if (severityFilter === 'ALL') return true;
    return r.severity === severityFilter;
  });

  const redCount = referrals.filter((r) => r.severity === 'RED' && r.status === 'pending').length;

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Top Banner / Triage Stats */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 glass-panel p-6 rounded-2xl border border-slate-800">
        <div>
          <div className="flex items-center space-x-3">
            <div className="p-2.5 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400">
              <Activity className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white flex items-center gap-2">
                PHC Shahpur Emergency Triage & Referral Queue
                {isRefetching && (
                  <span className="text-[10px] text-slate-400 font-normal animate-pulse">
                    (Refreshing...)
                  </span>
                )}
              </h1>
              <p className="text-xs text-slate-400">
                Facility Code: PHC-SHP-04 • Polling live every 30s • Sorted by severity (RED first)
              </p>
            </div>
          </div>
        </div>

        {/* Quick Triage Counters */}
        <div className="flex items-center gap-3">
          <div className="glass-card px-4 py-2.5 rounded-xl border border-rose-500/30 flex items-center space-x-3">
            <div className="w-3 h-3 rounded-full bg-rose-500 animate-ping"></div>
            <div>
              <div className="text-xs text-rose-300 font-medium">Pending RED Flags</div>
              <div className="text-lg font-extrabold text-white">{redCount} Urgent Cases</div>
            </div>
          </div>
          <div className="glass-card px-4 py-2.5 rounded-xl border border-slate-700 flex items-center space-x-3">
            <Clock className="w-4 h-4 text-amber-400" />
            <div>
              <div className="text-xs text-slate-400 font-medium">Total in Queue</div>
              <div className="text-lg font-extrabold text-slate-200">{referrals.length} Beneficiaries</div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center space-x-2 border-b border-slate-800 pb-2">
        <button
          onClick={() => setActiveTab('referrals')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'referrals'
              ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Activity className="w-4 h-4" />
          <span>Live Referral Queue ({referrals.length})</span>
        </button>
        <button
          onClick={() => setActiveTab('area_lists')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'area_lists'
              ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Active Area Health Lists</span>
        </button>
        <button
          onClick={() => setActiveTab('planning')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'planning'
              ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Calendar className="w-4 h-4" />
          <span>Facility Planning (4-Week Demand)</span>
        </button>
      </div>

      {/* Tab 1: Live Referral Queue */}
      {activeTab === 'referrals' && (
        <div className="space-y-4">
          {/* Filters Bar */}
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center space-x-2">
              <span className="text-xs text-slate-400">Filter Severity:</span>
              <button
                onClick={() => setSeverityFilter('ALL')}
                className={`px-3 py-1 rounded-lg text-xs font-medium border ${
                  severityFilter === 'ALL'
                    ? 'bg-slate-800 border-slate-600 text-white'
                    : 'border-slate-800 text-slate-400 hover:text-slate-200'
                }`}
              >
                All ({referrals.length})
              </button>
              <button
                onClick={() => setSeverityFilter('RED')}
                className={`px-3 py-1 rounded-lg text-xs font-medium border flex items-center gap-1 ${
                  severityFilter === 'RED'
                    ? 'bg-rose-500/20 border-rose-500/40 text-rose-300 font-bold'
                    : 'border-slate-800 text-rose-400/80 hover:text-rose-300'
                }`}
              >
                <span className="w-2 h-2 rounded-full bg-rose-500"></span>
                RED Flag ({referrals.filter((r) => r.severity === 'RED').length})
              </button>
              <button
                onClick={() => setSeverityFilter('YELLOW')}
                className={`px-3 py-1 rounded-lg text-xs font-medium border flex items-center gap-1 ${
                  severityFilter === 'YELLOW'
                    ? 'bg-amber-500/20 border-amber-500/40 text-amber-300 font-bold'
                    : 'border-slate-800 text-amber-400/80 hover:text-amber-300'
                }`}
              >
                <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                YELLOW ({referrals.filter((r) => r.severity === 'YELLOW').length})
              </button>
            </div>
          </div>

          {/* Referral Cards Grid */}
          <div className="grid grid-cols-1 gap-4">
            {filteredReferrals.map((item) => {
              const isRed = item.severity === 'RED';
              return (
                <div
                  key={item.id}
                  className={`glass-panel p-5 rounded-2xl border transition-all ${
                    isRed
                      ? 'border-rose-500/40 bg-gradient-to-r from-rose-950/20 via-slate-900/40 to-slate-900/30'
                      : 'border-slate-800 hover:border-slate-700'
                  }`}
                >
                  <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4">
                    {/* Patient & Danger Signs Overview */}
                    <div className="space-y-2.5 flex-1">
                      <div className="flex items-center space-x-3">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-xs font-bold tracking-wide uppercase border flex items-center gap-1.5 ${
                            isRed
                              ? 'bg-rose-500/20 text-rose-300 border-rose-500/40 pulse-urgent'
                              : 'bg-amber-500/20 text-amber-300 border-amber-500/40'
                          }`}
                        >
                          <AlertTriangle className="w-3.5 h-3.5" />
                          {item.severity} TRIAGE
                        </span>
                        <h2 className="text-lg font-bold text-white flex items-center gap-2">
                          {item.patientName}
                          <span className="text-xs font-normal text-slate-400">
                            ({item.patientAge < 1 ? `${Math.round(item.patientAge * 12)} months` : `${item.patientAge} yrs`}, {item.patientGender})
                          </span>
                        </h2>
                        <span className="text-xs px-2 py-0.5 rounded-md bg-slate-800 text-slate-400">
                          {item.village}
                        </span>
                      </div>

                      {/* Primary Referral Reason */}
                      <div className="text-sm font-semibold text-rose-200/90">
                        {item.reason}
                      </div>

                      {/* Clinical Note from ASHA */}
                      <p className="text-xs text-slate-300 leading-relaxed bg-slate-900/60 p-3 rounded-xl border border-slate-800">
                        <span className="font-semibold text-slate-200">Clinical Field Note: </span>
                        {item.clinicalNote}
                      </p>

                      {/* Vitals Pills */}
                      {item.vitals && (
                        <div className="flex flex-wrap items-center gap-2 pt-1">
                          {item.vitals.bpSystolic && (
                            <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 font-mono">
                              BP: <span className="font-bold text-rose-300">{item.vitals.bpSystolic}/{item.vitals.bpDiastolic}</span> mmHg
                            </span>
                          )}
                          {item.vitals.respRate && (
                            <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 font-mono">
                              Resp: <span className="font-bold text-rose-300">{item.vitals.respRate}</span>/min
                            </span>
                          )}
                          {item.vitals.spo2 && (
                            <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 font-mono">
                              SpO2: <span className="font-bold text-amber-300">{item.vitals.spo2}%</span>
                            </span>
                          )}
                          {item.vitals.hemoglobin && (
                            <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 font-mono">
                              Hb: <span className="font-bold text-rose-300">{item.vitals.hemoglobin}</span> g/dL
                            </span>
                          )}
                          {item.vitals.temp && (
                            <span className="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 font-mono">
                              Temp: {item.vitals.temp} °F
                            </span>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Right: ASHA Contact, Referral Status, & Actions */}
                    <div className="lg:w-80 space-y-3 lg:border-l lg:border-slate-800/80 lg:pl-5">
                      {/* Originating ASHA Info */}
                      <div className="p-2.5 rounded-xl bg-slate-900/70 border border-slate-800 text-xs space-y-1">
                        <div className="text-[11px] font-semibold text-slate-400">Referring ASHA Worker:</div>
                        <div className="font-bold text-slate-200">{item.ashaName}</div>
                        <div className="flex items-center justify-between text-slate-400">
                          <span className="font-mono">{item.ashaPhone}</span>
                          <a
                            href={`tel:${item.ashaPhone}`}
                            className="inline-flex items-center space-x-1 px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30 font-semibold"
                          >
                            <Phone className="w-3 h-3" />
                            <span>Call</span>
                          </a>
                        </div>
                      </div>

                      {/* Current Status Pill */}
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-slate-400">Referred: {new Date(item.referredAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                        <span className={`px-2 py-0.5 rounded-full font-semibold uppercase text-[10px] ${
                          item.status === 'pending'
                            ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                            : item.status === 'treated' || item.status === 'admitted'
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                            : 'bg-slate-800 text-slate-300'
                        }`}>
                          {item.status.replace('_', ' ')}
                        </span>
                      </div>

                      {/* Outcome Action Button */}
                      <div className="flex items-center gap-2 pt-1">
                        <button
                          onClick={() => {
                            setSelectedReferral(item);
                            setOutcomeStatus('treated');
                          }}
                          className="flex-1 px-3 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold shadow-lg shadow-indigo-600/20 transition-all flex items-center justify-center space-x-1.5"
                        >
                          <Stethoscope className="w-3.5 h-3.5" />
                          <span>Record Outcome</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Tab 2: Active Area Health Lists */}
      {activeTab === 'area_lists' && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <div className="flex items-center space-x-2 text-rose-400">
              <Heart className="w-5 h-5" />
              <h3 className="font-bold text-white text-sm">High-Risk Pregnancies</h3>
            </div>
            <div className="text-2xl font-extrabold text-white">18 Identified</div>
            <p className="text-xs text-slate-400">
              Severe anaemia (6), Pre-eclampsia (4), Previous C-section (5), Gestational Diabetes (3).
            </p>
            <div className="text-[11px] text-slate-500 font-medium">All assigned to MO review queue.</div>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <div className="flex items-center space-x-2 text-amber-400">
              <AlertTriangle className="w-5 h-5" />
              <h3 className="font-bold text-white text-sm">Sick Newborns (PSBI)</h3>
            </div>
            <div className="text-2xl font-extrabold text-white">7 Monitored</div>
            <p className="text-xs text-slate-400">
              Active HBNC home visit follow-ups. 2 referred for immediate paediatric assessment.
            </p>
            <div className="text-[11px] text-slate-500 font-medium">Daily ASHA pulse check enforced.</div>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <div className="flex items-center space-x-2 text-indigo-400">
              <Activity className="w-5 h-5" />
              <h3 className="font-bold text-white text-sm">TB Defaulters & Sputum</h3>
            </div>
            <div className="text-2xl font-extrabold text-white">12 on Regimen</div>
            <p className="text-xs text-slate-400">
              Nikshay synced daily. 1 treatment interruption flagged in Majra Khas; ASHA notified.
            </p>
            <div className="text-[11px] text-slate-500 font-medium">Nikshay ID linking active.</div>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <div className="flex items-center space-x-2 text-emerald-400">
              <Droplet className="w-5 h-5" />
              <h3 className="font-bold text-white text-sm">NCD HTN/Diabetes Defaulters</h3>
            </div>
            <div className="text-2xl font-extrabold text-white">34 Overdue Meds</div>
            <p className="text-xs text-slate-400">
              Hypertension prescription renewals due this month. Sub-centre drug refill lists mapped.
            </p>
            <div className="text-[11px] text-slate-500 font-medium">Automated SMS reminder queued.</div>
          </div>
        </div>
      )}

      {/* Tab 3: Facility Planning (4-Week Demand) */}
      {activeTab === 'planning' && (
        <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-4">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <Calendar className="w-5 h-5 text-amber-400" />
            4-Week Facility Demand Forecast (Requirement 41.4)
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <div className="text-xs text-slate-400">Expected Institutional Deliveries</div>
              <div className="text-2xl font-extrabold text-amber-300">42 Mothers</div>
              <p className="text-xs text-slate-400">
                12 high-risk pregnancies scheduled with transport advance booking.
              </p>
            </div>
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <div className="text-xs text-slate-400">VHSND Immunization Demand</div>
              <div className="text-2xl font-extrabold text-emerald-300">18 Sessions Planned</div>
              <p className="text-xs text-slate-400">
                Target: 210 Pentavalent, 185 BCG, 140 MR doses required from cold-chain store.
              </p>
            </div>
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <div className="text-xs text-slate-400">Commodity Stock Readiness</div>
              <div className="text-2xl font-extrabold text-rose-300">1 Critical Stockout</div>
              <p className="text-xs text-slate-400">
                Pregnancy test kits low (4 days left). Emergency indents raised to District CMSO.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Record Outcome & Doctor Feedback Modal */}
      {selectedReferral && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="glass-panel w-full max-w-lg p-6 rounded-2xl border border-slate-700 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="font-bold text-white text-base flex items-center gap-2">
                <Stethoscope className="w-5 h-5 text-indigo-400" />
                Record Outcome: {selectedReferral.patientName}
              </h3>
              <button
                onClick={() => setSelectedReferral(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Outcome Status (Req 41.2 pushes notification to ASHA & ANM)
                </label>
                <select
                  value={outcomeStatus}
                  onChange={(e) => setOutcomeStatus(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-sm focus:outline-none focus:border-indigo-500"
                >
                  <option value="treated">Treated & Discharged (Outpatient)</option>
                  <option value="admitted">Admitted to Inpatient Ward</option>
                  <option value="discharged">Transferred / Higher Centre Referral</option>
                  <option value="did_not_reach">Did Not Reach Facility (Defaulted)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Clinical Outcome & Diagnosis Notes
                </label>
                <textarea
                  rows={3}
                  value={outcomeNotes}
                  onChange={(e) => setOutcomeNotes(e.target.value)}
                  placeholder="e.g. Administered IV labetalol; BP stabilized to 135/88 mmHg. Continue oral alpha-methyldopa."
                  className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              {/* Feedback to ASHA */}
              <div className="pt-2 border-t border-slate-800">
                <label className="block text-xs font-semibold text-slate-300 mb-1 flex items-center justify-between">
                  <span>Send Doctor Feedback to ASHA {selectedReferral.ashaName} (Req 41.5)</span>
                  {feedbackSent && (
                    <span className="text-emerald-400 text-xs flex items-center gap-1">
                      <Check className="w-3.5 h-3.5" /> Sent to ASHA app
                    </span>
                  )}
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={feedbackMessage}
                    onChange={(e) => setFeedbackMessage(e.target.value)}
                    placeholder="e.g., Excellent triage detection. Patient is now stable."
                    className="flex-1 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-700 text-slate-200 text-xs focus:outline-none focus:border-indigo-500"
                  />
                  <button
                    disabled={!feedbackMessage || feedbackMutation.isPending}
                    onClick={() =>
                      feedbackMutation.mutate({
                        refId: selectedReferral.id,
                        ashaId: selectedReferral.ashaId,
                        msg: feedbackMessage,
                      })
                    }
                    className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold disabled:opacity-50 flex items-center gap-1"
                  >
                    <Send className="w-3 h-3" />
                    <span>Send</span>
                  </button>
                </div>
              </div>
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => setSelectedReferral(null)}
                className="px-4 py-2 rounded-xl border border-slate-700 text-slate-300 text-xs font-semibold hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                disabled={outcomeMutation.isPending}
                onClick={() =>
                  outcomeMutation.mutate({
                    id: selectedReferral.id,
                    status: outcomeStatus,
                    notes: outcomeNotes,
                  })
                }
                className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold shadow-lg shadow-indigo-600/30 disabled:opacity-50"
              >
                {outcomeMutation.isPending ? 'Saving...' : 'Confirm & Push Notification'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
