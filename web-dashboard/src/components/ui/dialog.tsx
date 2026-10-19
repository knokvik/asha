import * as React from 'react';
import { X } from 'lucide-react';
import { cn } from '@/shared/utils';

export interface DialogProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  children: React.ReactNode;
}

export function Dialog({ open = false, onOpenChange, children }: DialogProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-sm transition-opacity animate-in fade-in"
        onClick={() => onOpenChange?.(false)}
      />
      {/* Dialog content wrapper */}
      <div className="relative z-50 w-full max-w-lg">{children}</div>
    </div>
  );
}

export interface DialogContentProps extends React.HTMLAttributes<HTMLDivElement> {
  onClose?: () => void;
}

export function DialogContent({
  className,
  children,
  onClose,
  ...props
}: DialogContentProps) {
  return (
    <div
      className={cn(
        'relative w-full rounded-2xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] p-6 shadow-2xl animate-in zoom-in-95 duration-200 text-[#0F172A] dark:text-[#F8FAFC] max-h-[90vh] overflow-y-auto transition-colors',
        className
      )}
      {...props}
    >
      {onClose && (
        <button
          onClick={onClose}
          className="absolute right-4 top-4 rounded-lg p-1.5 text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-black dark:hover:text-white transition-colors cursor-pointer"
        >
          <X className="h-4 w-4" />
          <span className="sr-only">Close</span>
        </button>
      )}
      {children}
    </div>
  );
}

export function DialogHeader({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'flex flex-col space-y-1.5 text-left border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-3 mb-4',
        className
      )}
      {...props}
    />
  );
}

export function DialogTitle({
  className,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn(
        'text-base font-bold leading-none tracking-tight text-[#0F172A] dark:text-white flex items-center gap-2',
        className
      )}
      {...props}
    />
  );
}

export function DialogDescription({
  className,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p
      className={cn('text-xs text-[#525252] dark:text-[#A3A3A3] leading-relaxed', className)}
      {...props}
    />
  );
}

export function DialogFooter({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'flex items-center justify-end space-x-2 pt-4 border-t border-[#E5E7EB] dark:border-[#2E2E2E] mt-4',
        className
      )}
      {...props}
    />
  );
}
