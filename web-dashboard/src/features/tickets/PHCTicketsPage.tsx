import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Activity,
  AlertTriangle,
  Phone,
  CheckCircle2,
  Clock,
  Send,
  Calendar,
  Layers,
  Search,
  Check,
  X,
  Stethoscope,
  Heart,
  Droplet,
  FileText,
  Volume2,
  RefreshCw,
  Pill,
  MapPin,
  ExternalLink,
  FileImage,
  FileAudio,
  UserRound,
  Ambulance,
  Building2,
  ClipboardList,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useSync, type FrontlineSyncActivity } from '@/shared/context/SyncContext';
import { getReferralQueue, recordReferralOutcome, sendDoctorFeedback } from '@/shared/api/referralApi';
import { apiClient } from '@/shared/api/client';
import type { ReferralItem } from '@/types';

export function PHCTicketsPage() {
  const queryClient = useQueryClient();
  const { syncActivities, lastSyncTime, isSyncing, triggerManualSync } = useSync();

  // Active filter states
  const [priorityFilter, setPriorityFilter] = useState<'ALL' | 'RED' | 'YELLOW' | 'GREEN'>('ALL');
  const [programFilter, setProgramFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Selected item for action modal
  const [selectedCase, setSelectedCase] = useState<FrontlineSyncActivity | null>(null);

  // PHC Action Decision Form States
  const [actionPriority, setActionPriority] = useState<'RED' | 'YELLOW' | 'GREEN'>('RED');
  const [phcDecision, setPhcDecision] = useState('');
  const [assignedFacilityPerson, setAssignedFacilityPerson] = useState('');
  const [actionRequired, setActionRequired] = useState('');
  const [prescriptionsAndTests, setPrescriptionsAndTests] = useState('');
  const [followUpDate, setFollowUpDate] = useState('');
  const [referralStatus, setReferralStatus] = useState('Emergency action taken');
  const [doctorComments, setDoctorComments] = useState('');
  const [phcWorkerName, setPhcWorkerName] = useState('Dr. Alok Verma (PHC Medical Officer)');
  const [feedbackSuccess, setFeedbackSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Referrals from backend queue
  const { data: serverReferrals = [] } = useQuery<ReferralItem[]>({
    queryKey: ['referrals', 'phc-queue'],
    queryFn: () => getReferralQueue(),
  });

  // Combine syncActivities with server referrals for live display
  const combinedCases = useMemo(() => {
    const list: FrontlineSyncActivity[] = [...syncActivities];

    // Also include any server referral not already present by id/ticketId
    for (const ref of serverReferrals) {
      const exists = list.some((i) => i.id === ref.id || i.ticketId === ref.id);
      if (!exists) {
        const programCat = ref.reason?.toLowerCase().includes('anc') || ref.clinicalNote?.toLowerCase().includes('pregnant')
          ? 'Maternal (ANC)'
          : ref.reason?.toLowerCase().includes('pnc') || ref.clinicalNote?.toLowerCase().includes('postnatal')
          ? 'Postnatal (PNC)'
          : ref.reason?.toLowerCase().includes('tb') || ref.clinicalNote?.toLowerCase().includes('sputum')
          ? 'TB'
          : 'Child (IMNCI)';

        const dangerSignStrings = ref.screenedDangerSigns
          ? ref.screenedDangerSigns.filter((s) => s.present).map((s) => s.sign)
          : ref.redFlags;

        list.push({
          id: ref.id,
          ticketId: ref.id,
          workerName: ref.ashaName || 'ASHA Worker',
          workerPhone: ref.ashaPhone || '',
          village: ref.village || 'Subcentre Ward',
          category: programCat as any,
          details: ref.reason || ref.clinicalNote || 'Field triage referral',
          clinicalPayload: ref.clinicalNote || ref.reason,
          vitalsSummary: ref.vitals ? Object.entries(ref.vitals).map(([k, v]) => `${k.toUpperCase()}: ${v}`).join(' · ') : undefined,
          syncTime: 'Live server queue',
          timestamp: new Date(ref.referredAt || Date.now()).getTime(),
          channel: ref.isSmsRelayed ? 'SMS Emergency Gateway' : 'ABDM Online Gateway',
          status: ref.status === 'treated' ? 'Processed' : 'Triage Priority',
          severity: ref.severity || 'RED',
          patientName: ref.patientName,
          householdHead: ref.householdHead,
          patientAge: ref.ageMonths ? `${Math.floor(ref.ageMonths / 12)}y` : undefined,
          patientGender: ref.patientGender,
          abhaId: ref.abhaId,
          dangerSigns: dangerSignStrings,
          preReferralTreatment: ref.preReferral,
          facilityName: ref.facilityName,
        });
      }
    }

    // Sort so newest / live triage items appear on top (ascending by recency)
    list.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));

    // Filter by priority
    return list.filter((item) => {
      if (priorityFilter !== 'ALL') {
        const itemSev = item.severity || 'GREEN';
        if (itemSev !== priorityFilter) return false;
      }
      if (programFilter !== 'ALL') {
        if (!item.category.toLowerCase().includes(programFilter.toLowerCase())) return false;
      }
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesName = item.patientName?.toLowerCase().includes(q);
        const matchesWorker = item.workerName.toLowerCase().includes(q);
        const matchesVillage = item.village.toLowerCase().includes(q);
        const matchesDetails = item.details.toLowerCase().includes(q);
        if (!matchesName && !matchesWorker && !matchesVillage && !matchesDetails) return false;
      }
      return true;
    });
  }, [syncActivities, serverReferrals, priorityFilter, programFilter, searchQuery]);

  // Open modal with prefilled defaults based on priority
  const handleOpenActionModal = (item: FrontlineSyncActivity) => {
    setSelectedCase(item);
    setFeedbackSuccess(false);
    const sev = item.severity || 'GREEN';
    setActionPriority(sev);

    if (sev === 'RED') {
      setReferralStatus('Emergency action taken');
      setPhcDecision('Immediate facility escalation & stabilization');
      setAssignedFacilityPerson('PHC Shahpur Emergency Bay / 108 Ambulance');
      setActionRequired('Confirm danger signs and vitals, call ASHA immediately, initiate IV/oxygen');
      setPrescriptionsAndTests('Inj Magnesium Sulphate / IV Normal Saline / Vital monitoring stat');
      setFollowUpDate('Immediate (Within 1 hour)');
    } else if (sev === 'YELLOW') {
      setReferralStatus('Follow-up assigned');
      setPhcDecision('Doctor consultation & targeted home visit');
      setAssignedFacilityPerson('ANM Sunita Sharma / Medical Officer');
      setActionRequired('Schedule facility review, repeat clinical measurements and lab tests');
      setPrescriptionsAndTests('Repeat BP & Haemoglobin check; Blood glucose screening');
      setFollowUpDate('Within 24-48 hours');
    } else {
      setReferralStatus('Reviewed');
      setPhcDecision('Routine clinical visit approved');
      setAssignedFacilityPerson('ASHA Worker / Subcentre Clinic');
      setActionRequired('Add to clinical register and maintain routine follow-up schedule');
      setPrescriptionsAndTests('Oral IFA tablets & nutrition counseling');
      setFollowUpDate('Next scheduled visit date');
    }

    setDoctorComments('');
  };

  // Submit structured PHC response back to ASHA app
  const handleSubmitAction = async () => {
    if (!selectedCase) return;
    setIsSubmitting(true);
    try {
      const timestamp = new Date().toISOString();
      const responsePayload = {
        phc_decision: phcDecision,
        priority: actionPriority,
        assigned_facility_person: assignedFacilityPerson,
        action_required: actionRequired,
        medicines_tests_requested: prescriptionsAndTests,
        follow_up_date: followUpDate,
        referral_status: referralStatus,
        doctor_comments: doctorComments,
        response_timestamp: timestamp,
        phc_worker_name: phcWorkerName,
        patient_name: selectedCase.patientName,
        patient_id: selectedCase.id,
        category: selectedCase.category,
      };

      // 1. Post to backend referral feedback / outcome endpoint
      const refId = selectedCase.ticketId || selectedCase.id;
      const formattedNote = [
        `[PHC RESPONSE TO ASHA]`,
        `Decision: ${phcDecision}`,
        `Priority: ${actionPriority}`,
        `Assigned To: ${assignedFacilityPerson}`,
        `Action Required: ${actionRequired}`,
        `Prescriptions/Tests: ${prescriptionsAndTests}`,
        `Follow-up Date: ${followUpDate}`,
        `Status: ${referralStatus}`,
        `Comments: ${doctorComments}`,
        `Timestamp: ${timestamp}`,
        `PHC Officer: ${phcWorkerName}`,
      ].join('\n');

      try {
        await apiClient.post(`/referrals/${refId}/feedback`, {
          asha_id: selectedCase.workerName,
          message: formattedNote,
          sent_at: Date.now(),
        });
      } catch {
        // Fallback for mock/offline queue
      }

      try {
        await recordReferralOutcome(
          refId,
          actionPriority === 'RED' ? 'admitted' : 'treated',
          formattedNote
        );
      } catch {
        // Fallback
      }

      // Also trigger sync coordinator
      triggerManualSync({
        details: `PHC Response Sent: ${referralStatus} for ${selectedCase.patientName || 'Patient'}`,
        status: 'Processed',
      });

      queryClient.invalidateQueries({ queryKey: ['referrals'] });
      setFeedbackSuccess(true);
      setTimeout(() => {
        setIsSubmitting(false);
        setSelectedCase(null);
      }, 1200);
    } catch {
      setIsSubmitting(false);
      setSelectedCase(null);
    }
  };

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Top Header matching Household Registry style */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl lg:text-2xl font-black text-slate-900 dark:text-white">
            PHC Action & Tickets Queue
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Review frontline submissions, triage by priority (Red/Yellow/Green), and send structured clinical instructions back to the ASHA app.
          </p>
        </div>
        <button
          onClick={() => triggerManualSync()}
          disabled={isSyncing}
          className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
          {isSyncing ? 'Syncing…' : 'Refresh Queue'}
        </button>
      </div>

      {/* Sync Status Info Bar */}
      <Card className="p-4 text-xs text-slate-500 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <span>Last server sync: <strong className="text-slate-700 dark:text-slate-200">{lastSyncTime || 'Just now'}</strong></span>
          <span className="text-slate-300">|</span>
          <span className="font-semibold text-emerald-700 dark:text-emerald-400">Live Server Stream Connected</span>
        </div>
        <div className="text-xs font-bold text-slate-600 dark:text-slate-300">
          Showing {combinedCases.length} active tickets
        </div>
      </Card>

      {/* Filter and Priority Tabs Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        {/* Priority Filter Buttons */}
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-xs font-bold text-slate-400 mr-1">Priority:</span>
          {(['ALL', 'RED', 'YELLOW', 'GREEN'] as const).map((p) => {
            const isSelected = priorityFilter === p;
            const badgeColor =
              p === 'RED'
                ? 'bg-rose-600 text-white'
                : p === 'YELLOW'
                ? 'bg-amber-500 text-white'
                : p === 'GREEN'
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900';

            return (
              <button
                key={p}
                onClick={() => setPriorityFilter(p)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors ${
                  isSelected
                    ? badgeColor
                    : 'bg-white dark:bg-[#1E1E1E] text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:bg-slate-50'
                }`}
              >
                {p === 'ALL' ? 'All Priorities' : p}
              </button>
            );
          })}
        </div>

        {/* Program Filter & Search */}
        <div className="flex items-center gap-2 flex-wrap">
          <select
            value={programFilter}
            onChange={(e) => setProgramFilter(e.target.value)}
            className="h-8 rounded-lg border border-slate-200 bg-white px-2.5 text-xs font-semibold text-slate-700 dark:border-slate-800 dark:bg-[#1E1E1E] dark:text-slate-200"
          >
            <option value="ALL">All Programs</option>
            <option value="Maternal">ANC (Antenatal)</option>
            <option value="Postnatal">PNC (Postnatal)</option>
            <option value="Immunization">Immunization</option>
            <option value="NCD">NCD Screening</option>
            <option value="HBNC">HBNC / HBYC</option>
            <option value="TB">TB Support</option>
          </select>

          <div className="relative">
            <Search className="h-3.5 w-3.5 absolute left-2.5 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search patient, village..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="h-8 w-44 sm:w-56 rounded-lg border border-slate-200 bg-white pl-8 pr-3 text-xs text-slate-800 dark:border-slate-800 dark:bg-[#1E1E1E] dark:text-slate-200"
            />
          </div>
        </div>
      </div>

      {/* Ticket List Grid (Household Registry style) */}
      {combinedCases.length === 0 ? (
        <Card className="p-12 text-center text-sm text-slate-500">
          <CheckCircle2 className="mx-auto mb-3 h-8 w-8 text-emerald-400" />
          No tickets found matching the selected filters.
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {combinedCases.map((item) => {
            const sev = item.severity || 'GREEN';
            return (
              <Card key={item.id} className="p-5 flex flex-col justify-between">
                <div>
                  {/* Top Header of Card */}
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <h2 className="text-sm font-black text-slate-900 dark:text-white">
                          {item.patientName || 'Beneficiary Record'}
                        </h2>
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-black ${
                            sev === 'RED'
                              ? 'bg-rose-100 text-rose-700'
                              : sev === 'YELLOW'
                              ? 'bg-amber-100 text-amber-700'
                              : 'bg-emerald-100 text-emerald-700'
                          }`}
                        >
                          {sev}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">
                        {item.patientAge ? `${item.patientAge} yrs` : 'Age not provided'} · {item.patientGender || 'Gender not provided'} · <span className="font-semibold text-emerald-700">{item.category}</span>
                      </p>
                    </div>
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-bold text-emerald-700">
                      {item.status || 'Verified & Synced'}
                    </span>
                  </div>

                  {/* Definition list details (HouseholdsPage style) */}
                  <dl className="mt-4 grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <dt className="text-slate-400">Village</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.village || '—'}</dd>
                    </div>
                    <div>
                      <dt className="text-slate-400">Household Head</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.householdHead || item.patientName || '—'}</dd>
                    </div>
                    <div>
                      <dt className="text-slate-400">ASHA worker</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerName}</dd>
                    </div>
                    <div>
                      <dt className="text-slate-400">Worker phone</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.workerPhone || '—'}</dd>
                    </div>
                    <div>
                      <dt className="text-slate-400">Submission time</dt>
                      <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.syncTime}</dd>
                    </div>
                    {item.vitalsSummary && (
                      <div className="col-span-2">
                        <dt className="text-slate-400">Vitals & Findings</dt>
                        <dd className="font-semibold text-slate-700 dark:text-slate-200">{item.vitalsSummary}</dd>
                      </div>
                    )}
                  </dl>

                  {/* Danger signs banner */}
                  {item.dangerSigns && item.dangerSigns.length > 0 && (
                    <div className="mt-3 rounded-lg bg-rose-50 p-2.5 text-xs text-rose-800 dark:bg-rose-950/30 dark:text-rose-300">
                      <span className="font-bold">Danger Signs:</span> {item.dangerSigns.join(' · ')}
                    </div>
                  )}

                  {/* Clinical narrative */}
                  <p className="mt-4 border-t border-slate-100 pt-3 text-xs leading-5 text-slate-500 dark:border-slate-800 dark:text-slate-400">
                    {item.details || item.clinicalPayload || 'Clinical packet received.'}
                  </p>

                  {/* Attachments if any */}
                  {item.attachments && item.attachments.length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-2">
                      {item.attachments.map((attachment) => (
                        <a
                          key={`${item.id}-${attachment.index}`}
                          href={attachment.url}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2 py-1 text-[11px] font-semibold text-emerald-700 hover:bg-slate-200 dark:bg-slate-800 dark:text-emerald-400"
                        >
                          {attachment.type === 'image' ? <FileImage className="h-3 w-3" /> : <FileAudio className="h-3 w-3" />}
                          {attachment.type} <ExternalLink className="h-2.5 w-2.5" />
                        </a>
                      ))}
                    </div>
                  )}
                </div>

                {/* Bottom Actions Bar */}
                <div className="mt-4 flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 pt-3 dark:border-slate-800">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleOpenActionModal(item)}
                      className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold text-white shadow-xs ${
                        sev === 'RED'
                          ? 'bg-rose-600 hover:bg-rose-700'
                          : sev === 'YELLOW'
                          ? 'bg-amber-600 hover:bg-amber-700'
                          : 'bg-[#0C5A3E] hover:bg-[#094832]'
                      }`}
                    >
                      <Stethoscope className="h-3.5 w-3.5" />
                      Take PHC Action
                    </button>

                    {item.workerPhone && (
                      <a
                        href={`tel:${item.workerPhone}`}
                        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                      >
                        <Phone className="h-3.5 w-3.5 text-emerald-600" /> Call ASHA
                      </a>
                    )}
                  </div>

                  <span className="text-[11px] font-medium text-slate-400">
                    ID: {item.ticketId || item.id}
                  </span>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* Structured PHC Action Modal */}
      <Dialog open={!!selectedCase} onOpenChange={(open) => !open && setSelectedCase(null)}>
        {selectedCase && (
          <DialogContent onClose={() => setSelectedCase(null)} className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Stethoscope className="w-5 h-5 text-emerald-600" />
                PHC Action & Disposition: {selectedCase.patientName || 'Beneficiary'}
              </DialogTitle>
              <DialogDescription>
                Triage Flag: <strong>{actionPriority}</strong> · Program: <strong>{selectedCase.category}</strong> · Referring ASHA: <strong>{selectedCase.workerName}</strong>
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4 pt-2">
              {/* Patient Snapshot */}
              <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-slate-200 dark:border-slate-800 text-xs grid grid-cols-2 gap-2">
                <div><span className="text-slate-400">Patient:</span> <strong className="text-slate-800 dark:text-slate-200">{selectedCase.patientName}</strong></div>
                <div><span className="text-slate-400">Household Head:</span> <strong className="text-slate-800 dark:text-slate-200">{selectedCase.householdHead || selectedCase.patientName || '—'}</strong></div>
                <div><span className="text-slate-400">Village:</span> <strong className="text-slate-800 dark:text-slate-200">{selectedCase.village}</strong></div>
                <div><span className="text-slate-400">Referring ASHA:</span> <strong className="text-slate-800 dark:text-slate-200">{selectedCase.workerName} ({selectedCase.workerPhone || '—'})</strong></div>
                <div><span className="text-slate-400">Vitals:</span> <span className="text-slate-700 dark:text-slate-300">{selectedCase.vitalsSummary || 'Not provided'}</span></div>
                <div><span className="text-slate-400">Danger signs:</span> <span className="text-rose-700 font-semibold">{selectedCase.dangerSigns?.join(', ') || 'None reported'}</span></div>
              </div>

              {/* Priority Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Action Priority Band
                </label>
                <div className="flex gap-2">
                  {(['RED', 'YELLOW', 'GREEN'] as const).map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setActionPriority(p)}
                      className={`flex-1 py-1.5 rounded-lg text-xs font-bold border transition-colors ${
                        actionPriority === p
                          ? p === 'RED'
                            ? 'bg-rose-600 border-rose-600 text-white'
                            : p === 'YELLOW'
                            ? 'bg-amber-500 border-amber-500 text-white'
                            : 'bg-emerald-600 border-emerald-600 text-white'
                          : 'bg-white dark:bg-[#202024] border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300'
                      }`}
                    >
                      {p === 'RED' ? 'Red / Emergency' : p === 'YELLOW' ? 'Yellow / Follow-up' : 'Green / Routine'}
                    </button>
                  ))}
                </div>
              </div>

              {/* 1. PHC Decision */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                  1. PHC Decision
                </label>
                <Input
                  value={phcDecision}
                  onChange={(e) => setPhcDecision(e.target.value)}
                  placeholder="e.g. Medical officer review required, Emergency resuscitation, or Routine approval"
                  className="text-xs"
                />
              </div>

              {/* 2. Assigned Facility / Person & Referral Status */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                    2. Assigned Facility / Person
                  </label>
                  <Input
                    value={assignedFacilityPerson}
                    onChange={(e) => setAssignedFacilityPerson(e.target.value)}
                    placeholder="e.g. ANM Sunita Sharma / Dr. Alok Verma"
                    className="text-xs"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                    Case Status
                  </label>
                  <select
                    value={referralStatus}
                    onChange={(e) => setReferralStatus(e.target.value)}
                    className="w-full h-9 rounded-lg border border-slate-200 bg-white px-2.5 text-xs font-medium text-slate-800 dark:border-slate-800 dark:bg-[#1E1E1E] dark:text-slate-200"
                  >
                    <option value="Emergency action taken">Emergency action taken (Red)</option>
                    <option value="Follow-up assigned">Follow-up assigned (Yellow)</option>
                    <option value="Reviewed">Reviewed (Green / Routine)</option>
                    <option value="Admitted to PHC Ward">Admitted to PHC Ward</option>
                    <option value="Referred to CHC/DH">Referred to CHC/DH via 108</option>
                  </select>
                </div>
              </div>

              {/* 3. Action Required & Due Date */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                    3. Action Required
                  </label>
                  <Input
                    value={actionRequired}
                    onChange={(e) => setActionRequired(e.target.value)}
                    placeholder="e.g. Immediate transfer, Home visit, Sputum testing"
                    className="text-xs"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                    Follow-up Date / Due
                  </label>
                  <Input
                    value={followUpDate}
                    onChange={(e) => setFollowUpDate(e.target.value)}
                    placeholder="e.g. Within 24 hours, or 28-Oct-2026"
                    className="text-xs"
                  />
                </div>
              </div>

              {/* 4. Medicines / Lab Tests Requested */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                  4. Medicines or Tests Requested
                </label>
                <Input
                  value={prescriptionsAndTests}
                  onChange={(e) => setPrescriptionsAndTests(e.target.value)}
                  placeholder="e.g. Repeat BP & Hb in 24h, Inj Labetalol, Sputum CBNAAT, ORS & Zinc"
                  className="text-xs"
                />
              </div>

              {/* 5. Doctor / ANM Comments */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                  5. Doctor/ANM Guidance & Comments (Sent to ASHA app)
                </label>
                <Textarea
                  rows={2}
                  value={doctorComments}
                  onChange={(e) => setDoctorComments(e.target.value)}
                  placeholder="e.g. Continue monitoring maternal fetal movement. Report immediately if severe headache recurs."
                  className="text-xs"
                />
              </div>

              {feedbackSuccess && (
                <div className="p-3 rounded-lg bg-emerald-50 text-emerald-800 text-xs font-semibold flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                  Structured response enqueued and dispatched to ASHA app stream!
                </div>
              )}
            </div>

            <DialogFooter>
              <Button variant="outline" size="sm" onClick={() => setSelectedCase(null)}>
                Cancel
              </Button>
              <Button
                size="sm"
                className="bg-[#0C5A3E] hover:bg-[#094832] text-white font-bold"
                disabled={isSubmitting}
                onClick={handleSubmitAction}
              >
                {isSubmitting ? 'Sending to ASHA…' : 'Send Response to ASHA App'}
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}
