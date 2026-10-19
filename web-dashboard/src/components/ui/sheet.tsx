import * as React from 'react';
import { X } from 'lucide-react';
import { cn } from '@/shared/utils';

export interface SheetProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  children: React.ReactNode;
}

export function Sheet({ open = false, onOpenChange, children }: SheetProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/75 backdrop-blur-sm transition-opacity animate-in fade-in"
        onClick={() => onOpenChange?.(false)}
      />
      {/* Drawer */}
      <div className="relative z-50 h-full w-full max-w-xl bg-white dark:bg-[#181818] border-l border-[#E5E7EB] dark:border-[#2A2A2A] text-[#0F172A] dark:text-[#F8FAFC] shadow-2xl animate-in slide-in-from-right duration-300 overflow-y-auto">
        {children}
      </div>
    </div>
  );
}

export function SheetContent({
  className,
  children,
  onClose,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & { onClose?: () => void }) {
  return (
    <div className={cn('p-6 space-y-6', className)} {...props}>
      {onClose && (
        <button
          onClick={onClose}
          className="absolute right-4 top-4 rounded-lg p-1.5 text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white transition-colors cursor-pointer"
        >
          <X className="h-5 w-5" />
          <span className="sr-only">Close</span>
        </button>
      )}
      {children}
    </div>
  );
}

export function SheetHeader({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'flex flex-col space-y-2 text-left border-b border-[#E5E7EB] dark:border-[#2A2A2A] pb-4',
        className
      )}
      {...props}
    />
  );
}

export function SheetTitle({
  className,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn(
        'text-lg font-bold leading-none tracking-tight text-[#0F172A] dark:text-white flex items-center gap-2',
        className
      )}
      {...props}
    />
  );
}

export function SheetDescription({
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
