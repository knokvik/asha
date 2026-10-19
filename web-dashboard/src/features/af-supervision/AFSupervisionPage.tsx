import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getAshaPerformanceCards,
  submitSupervisionChecklist,
  sendAshaRecognition,
} from '@/shared/api/supervisionApi';
import { AshaPerformanceCard, SupervisionChecklist } from '@/types';
import {
  Users,
  Award,
  ClipboardCheck,
  AlertCircle,
  CheckCircle2,
  BookOpen,
  Sparkles,
  Phone,
  Search,
  X,
  Star,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ImciAshaTable } from '@/features/af-supervision/ImciAshaTable';

export function AFSupervisionPage() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAsha, setSelectedAsha] = useState<AshaPerformanceCard | null>(null);
  const [checklistOpen, setChecklistOpen] = useState(false);
  const [badgeModalOpen, setBadgeModalOpen] = useState(false);
  const [selectedBadge, setSelectedBadge] = useState<
    'star_performer' | 'care_champion' | 'prompt_referrer' | 'learning_master'
  >('star_performer');
  const [badgeNote, setBadgeNote] = useState('');
  const [badgeSent, setBadgeSent] = useState(false);

  // Supervision checklist form state
  const [visitType, setVisitType] = useState<SupervisionChecklist['visitType']>('household_visit');
  const [checklistScore, setChecklistScore] = useState(90);
  const [checklistNotes, setChecklistNotes] = useState('');
  const [recommendations, setRecommendations] = useState('');
  const [followUpRequired, setFollowUpRequired] = useState(false);
  const [followUpDate, setFollowUpDate] = useState('');

  const { data: ashas = [], isLoading } = useQuery({
    queryKey: ['af-supervision', 'ashas'],
    queryFn: () => getAshaPerformanceCards('af-01'),
  });

  const checklistMutation = useMutation({
    mutationFn: (data: SupervisionChecklist) => submitSupervisionChecklist(data),
    onSuccess: () => {
      setChecklistOpen(false);
      setChecklistNotes('');
      setRecommendations('');
      queryClient.invalidateQueries({ queryKey: ['af-supervision'] });
    },
  });

  const badgeMutation = useMutation({
    mutationFn: ({ ashaId, badge, msg }: { ashaId: string; badge: any; msg: string }) =>
      sendAshaRecognition(ashaId, badge, msg),
    onSuccess: () => {
      setBadgeSent(true);
      setTimeout(() => {
        setBadgeSent(false);
        setBadgeModalOpen(false);
        setBadgeNote('');
      }, 2000);
    },
  });

  const filteredAshas = ashas.filter(
    (a) =>
      a.ashaName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.village.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Header Banner */}
      <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center space-x-3.5">
            <div className="p-3 rounded-xl bg-amber-500/10 dark:bg-amber-500/15 border border-amber-500/20 text-amber-600 dark:text-amber-400">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
                ASHA Facilitator (AF) Supportive Supervision
              </h1>
              <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
                Facilitator: Sarita Singh • Sector: Shahpur Central • Mentoring, Checklists & Recognition
              </p>
            </div>
          </div>

          {/* Global Stats */}
          <div className="flex items-center gap-3">
            <div className="px-4 py-2 rounded-xl border border-amber-200 dark:border-amber-500/30 bg-amber-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-amber-700 dark:text-amber-300 font-semibold uppercase tracking-wider">Supervised ASHAs</div>
              <div className="text-lg font-bold text-[#0F172A] dark:text-white">{ashas.length} Active Workers</div>
            </div>
            <div className="px-4 py-2 rounded-xl border border-emerald-200 dark:border-emerald-500/30 bg-emerald-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-emerald-700 dark:text-emerald-400 font-semibold uppercase tracking-wider">Avg Sector Coverage</div>
              <div className="text-lg font-bold text-emerald-700 dark:text-emerald-400">89.0% Target Met</div>
            </div>
          </div>
        </div>
      </Card>

      <ImciAshaTable />

      {/* Search Bar */}
      <div className="relative max-w-md">
        <Search className="w-4 h-4 text-[#71717A] absolute left-3.5 top-3" />
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Search ASHA by name or village..."
          className="w-full pl-10 pr-4 py-2 rounded-xl bg-white dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A] focus:outline-none focus:ring-1 focus:ring-amber-500 transition-colors"
        />
      </div>

      {/* ASHA Performance Cards Grid (Req 39.1) */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {filteredAshas.map((asha) => {
          return (
            <Card
              key={asha.ashaId}
              className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-300 dark:hover:border-[#404040] transition-all space-y-4 shadow-xs"
            >
              {/* Card Top: Name, Village, Sync Time */}
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="flex items-center space-x-2">
                    <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">{asha.ashaName}</h2>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-slate-100 dark:bg-[#2E2E2E] text-[#525252] dark:text-[#94A3B8] font-mono border border-slate-200 dark:border-[#404040]">
                      {asha.village}
                    </span>
                  </div>
                  <div className="text-xs text-[#525252] dark:text-[#94A3B8] flex items-center space-x-2 pt-0.5">
                    <span>{asha.totalAssignedHouseholds} HHs</span>
                    <span>•</span>
                    <span>{asha.hamletsCount} Hamlets</span>
                    <span>•</span>
                    <span className="text-emerald-600 dark:text-emerald-400">Synced {new Date(asha.lastSyncAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                  </div>
                </div>

                <a
                  href={`tel:${asha.phone}`}
                  className="p-2 rounded-xl bg-slate-100 dark:bg-[#2A2A2A] hover:bg-slate-200 dark:hover:bg-[#383838] text-[#0F172A] dark:text-[#F8FAFC] text-xs flex items-center space-x-1.5 transition-colors"
                >
                  <Phone className="w-3.5 h-3.5 text-slate-500" />
                  <span className="hidden sm:inline font-mono">{asha.phone}</span>
                </a>
              </div>

              {/* 4 Core Metrics Grid */}
              <div className="grid grid-cols-4 gap-2 pt-1">
                <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Coverage</div>
                  <div className={`text-base font-bold ${asha.coveragePct >= 90 ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400'}`}>
                    {asha.coveragePct}%
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Overdue</div>
                  <div className={`text-base font-bold ${asha.overdueVisitsCount > 4 ? 'text-rose-600 dark:text-rose-400' : 'text-[#0F172A] dark:text-[#F8FAFC]'}`}>
                    {asha.overdueVisitsCount}
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Data Quality</div>
                  <div className="text-base font-bold text-indigo-600 dark:text-indigo-400">
                    {asha.dataQualityScorePct}%
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] text-center">
                  <div className="text-[10px] text-[#525252] dark:text-[#94A3B8]">Learning</div>
                  <div className="text-base font-bold text-amber-600 dark:text-amber-400">
                    {asha.learningModulesCompleted} / 16
                  </div>
                </div>
              </div>

              {/* Mentoring Pattern Detection Callout (Req 39.3) */}
              {asha.mentoringFlags && asha.mentoringFlags.length > 0 && (
                <div className="space-y-2">
                  {asha.mentoringFlags.map((flag, idx) => (
                    <div
                      key={idx}
                      className={`p-3 rounded-xl border text-xs flex items-start space-x-2.5 ${
                        flag.type === 'positive'
                          ? 'bg-emerald-50 dark:bg-emerald-950/20 border-emerald-200 dark:border-emerald-500/30 text-emerald-800 dark:text-emerald-300'
                          : flag.type === 'warning'
                          ? 'bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-500/30 text-amber-800 dark:text-amber-300'
                          : 'bg-indigo-50 dark:bg-indigo-950/20 border-indigo-200 dark:border-indigo-500/30 text-indigo-800 dark:text-indigo-300'
                      }`}
                    >
                      <Sparkles className="w-4 h-4 shrink-0 mt-0.5" />
                      <div>
                        <div className="font-semibold">{flag.message}</div>
                        {flag.suggestedModule && (
                          <div className="text-[11px] text-[#525252] dark:text-[#94A3B8] pt-0.5 flex items-center gap-1">
                            <BookOpen className="w-3 h-3 text-amber-600 dark:text-amber-400" />
                            <span>Recommended Micro-Lesson: <span className="font-mono font-medium text-amber-700 dark:text-amber-300">{flag.suggestedModule}</span></span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Card Actions: Checklist & Recognition */}
              <div className="flex items-center gap-2 pt-2 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setSelectedAsha(asha);
                    setChecklistOpen(true);
                  }}
                  className="flex-1 gap-1.5"
                >
                  <ClipboardCheck className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
                  <span>Digital Supervision Checklist (Req 39.2)</span>
                </Button>
                <Button
                  size="sm"
                  onClick={() => {
                    setSelectedAsha(asha);
                    setBadgeModalOpen(true);
                  }}
                  className="bg-amber-500/10 hover:bg-amber-500/20 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-500/30 gap-1.5 shadow-none"
                >
                  <Award className="w-3.5 h-3.5" />
                  <span>Give Recognition (Req 39.5)</span>
                </Button>
              </div>
            </Card>
          );
        })}
      </div>

      {/* Digital Field Supervision Checklist Modal (Req 39.2) */}
      {checklistOpen && selectedAsha && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-lg p-6 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <h3 className="font-bold text-base flex items-center gap-2">
                <ClipboardCheck className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                Supervision Checklist: {selectedAsha.ashaName}
              </h3>
              <button
                onClick={() => setChecklistOpen(false)}
                className="p-1 rounded-lg text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Checklist Type</label>
                <select
                  value={visitType}
                  onChange={(e) => setVisitType(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC]"
                >
                  <option value="household_visit">Observing Beneficiary Home Visit (HBNC / ANC)</option>
                  <option value="record_audit">Checking Registers & Digital Entries</option>
                  <option value="kit_inspection">Reviewing Equipment, BLE Devices & Medicine Kit</option>
                  <option value="vhsnd_session">Observing VHSND Clinic Session Mobilisation</option>
                </select>
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">
                  Overall Competency Score: <span className="font-bold text-amber-600 dark:text-amber-400">{checklistScore}%</span>
                </label>
                <input
                  type="range"
                  min="50"
                  max="100"
                  value={checklistScore}
                  onChange={(e) => setChecklistScore(Number(e.target.value))}
                  className="w-full accent-amber-500"
                />
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Observation Notes</label>
                <textarea
                  rows={3}
                  value={checklistNotes}
                  onChange={(e) => setChecklistNotes(e.target.value)}
                  placeholder="e.g. Demonstrated proper hand hygiene and thermometer sanitization. Clear communication with mother on danger signs."
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A]"
                />
              </div>

              <div>
                <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Supportive Recommendations / Action Items</label>
                <textarea
                  rows={2}
                  value={recommendations}
                  onChange={(e) => setRecommendations(e.target.value)}
                  placeholder="e.g. Advised to practice neonatal respiratory tap counter timer during quiet hours."
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A]"
                />
              </div>

              <div className="flex items-center space-x-2 pt-1">
                <input
                  type="checkbox"
                  id="chk-followup"
                  checked={followUpRequired}
                  onChange={(e) => setFollowUpRequired(e.target.checked)}
                  className="rounded border-[#E5E7EB] dark:border-[#2E2E2E] text-amber-500 focus:ring-0"
                />
                <label htmlFor="chk-followup" className="font-semibold cursor-pointer text-[#0F172A] dark:text-[#F8FAFC]">
                  Schedule follow-up supervision check
                </label>
              </div>

              {followUpRequired && (
                <div>
                  <label className="block font-semibold mb-1 text-[#0F172A] dark:text-[#F8FAFC]">Follow-up Date</label>
                  <input
                    type="date"
                    value={followUpDate}
                    onChange={(e) => setFollowUpDate(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC]"
                  />
                </div>
              )}
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setChecklistOpen(false)}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                disabled={checklistMutation.isPending}
                onClick={() =>
                  checklistMutation.mutate({
                    afId: 'af-01',
                    ashaId: selectedAsha.ashaId,
                    visitDate: new Date().toISOString(),
                    visitType,
                    score: checklistScore,
                    notes: checklistNotes || 'Observation checklist completed in the field.',
                    recommendations: recommendations || 'Continue regular home visit protocol.',
                    followUpRequired,
                    followUpDate: followUpRequired ? followUpDate : undefined,
                  })
                }
                className="bg-amber-600 hover:bg-amber-700 text-white"
              >
                {checklistMutation.isPending ? 'Saving...' : 'Save & Sync Offline'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Recognition & Badge Modal (Req 39.5) */}
      {badgeModalOpen && selectedAsha && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md p-6 rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3">
              <h3 className="font-bold text-base flex items-center gap-2">
                <Award className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                Send Recognition to {selectedAsha.ashaName}
              </h3>
              <button
                onClick={() => setBadgeModalOpen(false)}
                className="p-1 rounded-lg text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-semibold">Select Recognition Badge</label>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'star_performer', label: 'Star Performer', icon: Star, color: 'text-amber-600 dark:text-amber-400 border-amber-300 dark:border-amber-500/40 bg-amber-50 dark:bg-amber-500/10' },
                  { id: 'care_champion', label: 'Care Champion', icon: Sparkles, color: 'text-rose-600 dark:text-rose-400 border-rose-300 dark:border-rose-500/40 bg-rose-50 dark:bg-rose-500/10' },
                  { id: 'prompt_referrer', label: 'Prompt Referrer', icon: AlertCircle, color: 'text-indigo-600 dark:text-indigo-400 border-indigo-300 dark:border-indigo-500/40 bg-indigo-50 dark:bg-indigo-500/10' },
                  { id: 'learning_master', label: 'Learning Master', icon: BookOpen, color: 'text-emerald-600 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/40 bg-emerald-50 dark:bg-emerald-500/10' },
                ].map((b) => (
                  <button
                    key={b.id}
                    onClick={() => setSelectedBadge(b.id as any)}
                    className={`p-3 rounded-xl border text-left flex items-center space-x-2 transition-all cursor-pointer ${
                      selectedBadge === b.id
                        ? `${b.color} ring-2 ring-amber-500 font-bold`
                        : 'border-[#E5E7EB] dark:border-[#2E2E2E] bg-slate-50 dark:bg-[#181818] text-[#525252] dark:text-[#94A3B8] hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
                    }`}
                  >
                    <b.icon className="w-4 h-4 shrink-0" />
                    <span className="text-xs">{b.label}</span>
                  </button>
                ))}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1">
                  Congratulatory Note (Pushed to ASHA Home Screen)
                </label>
                <textarea
                  rows={2}
                  value={badgeNote}
                  onChange={(e) => setBadgeNote(e.target.value)}
                  placeholder="e.g. Great dedication on completing all high-risk pregnancy visits this week!"
                  className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#71717A] focus:outline-none focus:ring-1 focus:ring-amber-500"
                />
              </div>

              {badgeSent && (
                <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-500/40 text-emerald-800 dark:text-emerald-300 text-xs flex items-center space-x-2">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Recognition badge sent to {selectedAsha.ashaName}'s mobile app!</span>
                </div>
              )}
            </div>

            <div className="flex justify-end space-x-2 pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setBadgeModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                disabled={badgeMutation.isPending}
                onClick={() =>
                  badgeMutation.mutate({
                    ashaId: selectedAsha.ashaId,
                    badge: selectedBadge,
                    msg: badgeNote || 'Thank you for your dedicated community healthcare service!',
                  })
                }
                className="bg-amber-600 hover:bg-amber-700 text-white"
              >
                {badgeMutation.isPending ? 'Sending...' : 'Award Badge'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
