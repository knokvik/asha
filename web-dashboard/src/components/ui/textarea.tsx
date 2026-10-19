import * as React from 'react';
import { cn } from '@/shared/utils';

export interface TextareaProps
  extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, ...props }, ref) => {
    return (
      <textarea
        className={cn(
          'flex min-h-[70px] w-full rounded-lg border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] px-3 py-2 text-xs text-[#0F172A] dark:text-[#F8FAFC] placeholder:text-[#71717A] shadow-xs focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[#10B981] focus-visible:border-[#10B981] disabled:cursor-not-allowed disabled:opacity-50 transition-colors',
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
Textarea.displayName = 'Textarea';

export { Textarea };
