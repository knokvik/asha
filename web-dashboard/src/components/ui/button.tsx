import * as React from 'react';
import { cn } from '@/shared/utils';

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:
    | 'default'
    | 'destructive'
    | 'outline'
    | 'secondary'
    | 'ghost'
    | 'link'
    | 'success'
    | 'warning'
    | 'subtle';
  size?: 'default' | 'sm' | 'lg' | 'icon' | 'xs';
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'default', size = 'default', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center whitespace-nowrap rounded-lg text-xs font-semibold ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-[0.98] cursor-pointer select-none',
          {
            // Variants
            'bg-[#10B981] text-white hover:bg-emerald-600 shadow-sm shadow-emerald-950/20':
              variant === 'default',
            'bg-[#F43F5E] text-white hover:bg-rose-600 shadow-sm shadow-rose-950/20':
              variant === 'destructive',
            'border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] hover:bg-[#F4F4F5] dark:hover:bg-[#2A2A2A] shadow-xs':
              variant === 'outline',
            'bg-[#F1F5F9] dark:bg-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC] hover:bg-[#E2E8F0] dark:hover:bg-[#383838] border border-[#E2E8F0] dark:border-[#404040]':
              variant === 'secondary',
            'text-[#525252] dark:text-[#A3A3A3] hover:bg-[#F4F4F5] dark:hover:bg-[#2E2E2E] hover:text-[#0F172A] dark:hover:text-white':
              variant === 'ghost',
            'text-[#10B981] underline-offset-4 hover:underline p-0 h-auto':
              variant === 'link',
            'bg-emerald-700 text-white hover:bg-emerald-600 border border-emerald-600/30':
              variant === 'success',
            'bg-[#F59E0B] text-white hover:bg-amber-600 shadow-sm':
              variant === 'warning',
            'bg-slate-100 dark:bg-[#222224] text-slate-700 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-[#2A2A2A] border border-[#E5E7EB] dark:border-[#2E2E2E]':
              variant === 'subtle',

            // Sizes
            'h-9 px-4 py-2': size === 'default',
            'h-7 rounded-md px-2.5 text-[11px]': size === 'xs',
            'h-8 rounded-md px-3 text-xs': size === 'sm',
            'h-10 rounded-lg px-6 text-sm': size === 'lg',
            'h-9 w-9 p-0': size === 'icon',
          },
          className
        )}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';

export { Button };
