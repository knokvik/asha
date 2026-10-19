import * as React from 'react';
import { cn } from '@/shared/utils';

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?:
    | 'default'
    | 'secondary'
    | 'destructive'
    | 'outline'
    | 'warning'
    | 'success'
    | 'info'
    | 'critical'
    | 'sms';
}

function Badge({ className, variant = 'default', ...props }: BadgeProps) {
  return (
    <div
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-[11px] font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 tracking-wide uppercase',
        {
          'bg-emerald-600 text-white border-transparent dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-500/30':
            variant === 'default',
          'bg-slate-100 text-slate-700 border-slate-200 dark:bg-[#2A2A2A] dark:text-[#A3A3A3] dark:border-[#383838]':
            variant === 'secondary',
          'bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-950/50 dark:text-rose-300 dark:border-rose-500/30':
            variant === 'destructive',
          'border-[#E5E7EB] bg-white text-[#525252] dark:border-[#2E2E2E] dark:bg-[#222224] dark:text-[#A3A3A3]':
            variant === 'outline',
          'bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-950/50 dark:text-amber-300 dark:border-amber-500/30':
            variant === 'warning',
          'bg-emerald-50 text-emerald-800 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-300 dark:border-emerald-500/30':
            variant === 'success',
          'bg-sky-50 text-sky-800 border-sky-200 dark:bg-sky-950/50 dark:text-sky-300 dark:border-sky-500/30':
            variant === 'info',
          'bg-rose-100 text-rose-800 border-rose-300 dark:bg-rose-950/70 dark:text-rose-200 dark:border-rose-500/40 font-bold':
            variant === 'critical',
          'bg-slate-100 text-slate-800 border-slate-300 dark:bg-[#181818] dark:text-cyan-300 dark:border-[#2E2E2E] font-mono':
            variant === 'sms',
        },
        className
      )}
      {...props}
    />
  );
}

export { Badge };
