import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useSync, SyncToastItem } from '@/shared/context/SyncContext';
import {
  RefreshCw,
  AlertTriangle,
  CheckCircle2,
  X,
  ExternalLink,
  Users,
  Activity,
  ArrowRight,
} from 'lucide-react';

export function SyncToastContainer() {
  const { toasts, dismissToast } = useSync();
  const navigate = useNavigate();

  if (toasts.length === 0) return null;

  return (
    <div
      aria-live="polite"
      aria-atomic="true"
      className="fixed bottom-5 right-5 z-50 flex flex-col gap-2.5 max-w-sm sm:max-w-md w-full pointer-events-none px-4 sm:px-0"
    >
      {toasts.map((toast) => {
        const isUrgent = toast.type === 'urgent_triage';
        const isOutcome = toast.type === 'outcome_pushed';

        return (
          <div
            key={toast.id}
            className={`pointer-events-auto rounded-2xl p-3.5 shadow-2xl border transition-all animate-in slide-in-from-bottom-5 duration-200 ${
              isUrgent
                ? 'bg-white dark:bg-[#1C181A] border-rose-400 dark:border-rose-500/60 shadow-rose-500/10'
                : isOutcome
                ? 'bg-white dark:bg-[#181B22] border-blue-400 dark:border-blue-500/60 shadow-blue-500/10'
                : 'bg-white dark:bg-[#181C1A] border-emerald-400 dark:border-emerald-500/60 shadow-emerald-500/10'
            }`}
          >
            {/* Header row */}
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className="relative flex h-2.5 w-2.5">
                  <span
                    className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${
                      isUrgent
                        ? 'bg-rose-400'
                        : isOutcome
                        ? 'bg-blue-400'
                        : 'bg-emerald-400'
                    }`}
                  />
                  <span
                    className={`relative inline-flex rounded-full h-2.5 w-2.5 ${
                      isUrgent
                        ? 'bg-rose-600'
                        : isOutcome
                        ? 'bg-blue-600'
                        : 'bg-emerald-600'
                    }`}
                  />
                </span>

                <div className="flex items-center gap-1.5">
                  {isUrgent ? (
                    <AlertTriangle className="h-4 w-4 text-rose-600 dark:text-rose-400" />
                  ) : isOutcome ? (
                    <CheckCircle2 className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                  ) : (
                    <RefreshCw className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                  )}
                  <span
                    className={`text-xs font-black tracking-tight ${
                      isUrgent
                        ? 'text-rose-700 dark:text-rose-300'
                        : isOutcome
                        ? 'text-blue-700 dark:text-blue-300'
                        : 'text-emerald-700 dark:text-emerald-300'
                    }`}
                  >
                    {toast.title}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-[10px] text-slate-400 dark:text-slate-500 font-mono">
                  {toast.syncTime}
                </span>
                <button
                  onClick={() => dismissToast(toast.id)}
                  className="p-1 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
                  title="Dismiss notification"
                  aria-label="Close notification"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>

            {/* Worker Context & Category */}
            <div className="flex items-center gap-2 mt-2">
              <span className="text-[11px] font-bold text-slate-900 dark:text-white flex items-center gap-1">
                <Users className="h-3 w-3 text-slate-400" />
                <span>{toast.workerName}</span>
              </span>
              <span className="text-[10px] text-slate-400">•</span>
              <span className="text-[10px] text-slate-500 dark:text-slate-400 truncate">
                {toast.village}
              </span>
              <span
                className={`ml-auto text-[9px] font-bold px-1.5 py-0.5 rounded-full border ${
                  isUrgent
                    ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-800'
                    : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800'
                }`}
              >
                {toast.category}
              </span>
            </div>

            {/* Details */}
            <p className="text-[11px] text-slate-600 dark:text-slate-300 mt-1 leading-snug">
              {toast.details}
            </p>

            {/* Quick Actions */}
            <div className="flex items-center gap-2 mt-2.5 pt-2 border-t border-slate-100 dark:border-slate-800/80">
              {toast.link && (
                <button
                  onClick={() => {
                    dismissToast(toast.id);
                    navigate(toast.link!);
                  }}
                  className={`text-[11px] font-bold px-2.5 py-1 rounded-lg flex items-center gap-1 transition-colors cursor-pointer ${
                    isUrgent
                      ? 'bg-rose-600 hover:bg-rose-700 text-white'
                      : isOutcome
                      ? 'bg-blue-600 hover:bg-blue-700 text-white'
                      : 'bg-[#0C5A3E] hover:bg-[#094731] text-white'
                  }`}
                >
                  {isUrgent ? (
                    <>
                      <Activity className="h-3 w-3" />
                      <span>Open Triage Desk</span>
                    </>
                  ) : (
                    <>
                      <span>View Live Activity</span>
                      <ArrowRight className="h-3 w-3" />
                    </>
                  )}
                </button>
              )}

              <button
                onClick={() => dismissToast(toast.id)}
                className="text-[11px] text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 px-2 py-1 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800/60 ml-auto transition-colors cursor-pointer"
              >
                Dismiss
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}
