import * as React from 'react';
import { cn } from '@/shared/utils';

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-9 w-full rounded-lg border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] px-3 py-1 text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder:text-[#71717A] shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[#10B981] focus-visible:border-[#10B981] disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
Input.displayName = 'Input';

export { Input };
