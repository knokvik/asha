import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { getReferralById, recordClinicalOutcome } from '@/shared/api/referralApi';
import { validateOutcome, type OutcomeAction } from '@/features/clinical-desk/logic';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

export function TicketPage() {
  const { id = '' } = useParams();
  const queryClient = useQueryClient();
  const [diagnosis, setDiagnosis] = useState('');
  const [action, setAction] = useState<OutcomeAction | ''>('');
  const [noteForAsha, setNoteForAsha] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  const { data: ticket, isLoading, error } = useQuery({
    queryKey: ['referrals', 'ticket', id],
    queryFn: () => getReferralById(id),
    enabled: id.length > 0,
  });

  const outcomeMutation = useMutation({
    mutationFn: () =>
      recordClinicalOutcome(id, {
        diagnosis,
        action: action as OutcomeAction,
        noteForAsha,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referrals'] });
      queryClient.invalidateQueries({ queryKey: ['heatmap'] });
      setFormError(null);
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const submit = () => {
    const problem = validateOutcome({ diagnosis, action });
    if (problem) {
      setFormError(problem);
      return;
    }
    outcomeMutation.mutate();
  };

  if (isLoading) return <p className="p-6 text-sm">Loading ticket…</p>;
  if (error || !ticket) return <p className="p-6 text-sm">Ticket not found.</p>;

  return (
    <div className="p-4 lg:p-8 max-w-3xl mx-auto space-y-4">
      <Link to="/queue" className="text-xs font-semibold text-emerald-700">
        Back to queue
      </Link>
      <Card className="p-5 space-y-3 border-[#E5E7EB] dark:border-[#2E2E2E]">
        <h1 className="text-lg font-bold">Referral {ticket.id}</h1>
        <p className="text-sm">
          {ticket.patientName}
          {ticket.ageMonths != null ? `, ${ticket.ageMonths} mo` : ''} {ticket.patientGender}
          {ticket.wardId ? ` · ${ticket.village} ${ticket.wardId}` : ` · ${ticket.village}`}
        </p>
        <p className="text-sm font-semibold">{ticket.severity} — {ticket.reason}</p>
        {ticket.urgency && <p className="text-xs">{ticket.urgency}</p>}
        {ticket.outbreakContext && <p className="text-xs text-amber-700">{ticket.outbreakContext}</p>}
        {ticket.sms && <p className="font-mono text-xs">{ticket.sms}</p>}
        <p className="text-xs text-slate-600">{ticket.clinicalNote}</p>
        {ticket.preReferral && (
          <ul className="text-xs list-disc pl-4">
            {ticket.preReferral.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        )}
        <p className="text-xs">ASHA {ticket.ashaName}{ticket.facilityName ? ` · ${ticket.facilityName}` : ''}</p>
      </Card>

      <Card className="p-5 space-y-3 border-[#E5E7EB] dark:border-[#2E2E2E]">
        <h2 className="text-sm font-bold">Outcome for the ASHA</h2>
        <label className="block text-xs font-semibold">
          Diagnosis
          <input
            aria-label="Diagnosis"
            value={diagnosis}
            onChange={(event) => setDiagnosis(event.target.value)}
            className="mt-1 w-full rounded-lg border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
        <label className="block text-xs font-semibold">
          Action
          <select
            aria-label="Action"
            value={action}
            onChange={(event) => setAction(event.target.value as OutcomeAction | '')}
            className="mt-1 w-full rounded-lg border border-slate-300 px-2 py-1.5 text-sm"
          >
            <option value="">Choose what was done</option>
            <option value="treated">Treated</option>
            <option value="referred_up">Referred up</option>
            <option value="sent_home">Sent home</option>
          </select>
        </label>
        <label className="block text-xs font-semibold">
          Note for the ASHA
          <textarea
            aria-label="Note for the ASHA"
            value={noteForAsha}
            onChange={(event) => setNoteForAsha(event.target.value)}
            className="mt-1 w-full rounded-lg border border-slate-300 px-2 py-1.5 text-sm"
            rows={3}
          />
        </label>
        {formError && <p className="text-xs text-rose-600">{formError}</p>}
        {outcomeMutation.isSuccess && (
          <p className="text-xs text-emerald-700">Outcome saved. The ward heatmap includes this confirmation.</p>
        )}
        <Button type="button" onClick={submit} disabled={outcomeMutation.isPending}>
          Record outcome
        </Button>
      </Card>
    </div>
  );
}
