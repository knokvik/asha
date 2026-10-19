import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/shared/hooks/useAuth';
import { useTheme } from '@/shared/hooks/useTheme';
import { UserRole } from '@/types';
import {
  Activity,
  Users,
  FileCheck2,
  BarChart3,
  ShieldCheck,
  ChevronDown,
  HeartPulse,
  Menu,
  X,
  Stethoscope,
  Radio,
  Sun,
  Moon,
  PhoneCall,
  MapPin,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

const ROLE_CONFIG: Record<
  UserRole,
  { label: string; badgeClass: string; path: string; icon: any; shortTitle: string }
> = {
  PHC_MO: {
    label: 'PHC Medical Officer (Doctor)',
    shortTitle: 'PHC Doctor',
    badgeClass: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-300 border-emerald-500/30',
    path: '/phc',
    icon: Stethoscope,
  },
  ANM: {
    label: 'ANM / CHO Sub-Centre',
    shortTitle: 'ANM Workspace',
    badgeClass: 'bg-teal-500/15 text-teal-600 dark:text-teal-300 border-teal-500/30',
    path: '/anm',
    icon: FileCheck2,
  },
  AF: {
    label: 'ASHA Facilitator (AF)',
    shortTitle: 'AF Supervision',
    badgeClass: 'bg-amber-500/15 text-amber-600 dark:text-amber-300 border-amber-500/30',
    path: '/af',
    icon: Users,
  },
  DISTRICT_OFFICER: {
    label: 'District Health Officer',
    shortTitle: 'District Health',
    badgeClass: 'bg-indigo-500/15 text-indigo-600 dark:text-indigo-300 border-indigo-500/30',
    path: '/district',
    icon: BarChart3,
  },
  STATE_ADMIN: {
    label: 'State Administrator',
    shortTitle: 'State Admin',
    badgeClass: 'bg-purple-500/15 text-purple-600 dark:text-purple-300 border-purple-500/30',
    path: '/admin',
    icon: ShieldCheck,
  },
};

export function RootLayout() {
  const { user, role, switchRole } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [roleDropdownOpen, setRoleDropdownOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const currentRoleConfig = ROLE_CONFIG[role] || ROLE_CONFIG.PHC_MO;

  const handleRoleSelect = (newRole: UserRole) => {
    switchRole(newRole);
    setRoleDropdownOpen(false);
    navigate(ROLE_CONFIG[newRole].path);
  };

  return (
    <div className="min-h-screen flex bg-white dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] font-sans antialiased transition-colors duration-200">
      {/* Mobile Drawer Backdrop */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 dark:bg-black/80 backdrop-blur-sm lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Non-Scrolling Fixed / Sticky Sidebar */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col h-screen max-h-screen overflow-hidden border-r border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] transition-all duration-300 lg:sticky lg:top-0 shrink-0 ${
          mobileMenuOpen ? 'translate-x-0 w-68 shadow-2xl' : '-translate-x-full lg:translate-x-0'
        } ${sidebarOpen ? 'w-68' : 'w-18'}`}
      >
        {/* 1. Header (Fixed, Non-scrolling) */}
        <div className="flex h-16 shrink-0 items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] px-4">
          <div className="flex items-center space-x-3 overflow-hidden">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 shadow-sm border border-emerald-500/30 text-white">
              <HeartPulse className="h-5 w-5" />
            </div>
            {sidebarOpen && (
              <div className="flex flex-col truncate">
                <span className="text-sm font-bold tracking-tight text-[#0F172A] dark:text-white flex items-center gap-1.5">
                  PHC Shahpur
                  <span className="h-2 w-2 rounded-full bg-[#10B981] animate-pulse" />
                </span>
                <span className="text-[10px] text-[#525252] dark:text-[#A3A3A3] font-medium">
                  Facility: PHC-SHP-04
                </span>
              </div>
            )}
          </div>
          <button
            onClick={() => setMobileMenuOpen(false)}
            className="rounded-lg p-1 text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] lg:hidden"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* 2. Facility Status Pill (Fixed, Non-scrolling) */}
        {sidebarOpen && (
          <div className="shrink-0 mx-3 mt-3 p-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-500/20 text-xs text-emerald-800 dark:text-emerald-300 space-y-1">
            <div className="flex items-center justify-between text-[11px] font-semibold">
              <span className="flex items-center gap-1">
                <Radio className="h-3 w-3 text-[#10B981] animate-pulse" />
                ABDM Gateway Active
              </span>
              <span className="font-mono text-[10px] bg-emerald-100 dark:bg-emerald-900/50 px-1.5 py-0.2 rounded text-emerald-800 dark:text-emerald-200">
                24x7 MO
              </span>
            </div>
            <div className="text-[10px] text-slate-600 dark:text-slate-400 flex items-center justify-between">
              <span>Beds: 12/16 Occupied</span>
              <span>Sub-Centres: 6</span>
            </div>
          </div>
        )}

        {/* 3. Navigation Links (Scrollable area ONLY if screen is very short, no outer scroll) */}
        <div className="flex-1 overflow-y-auto px-3 py-3 space-y-4 min-h-0">
          <div>
            {sidebarOpen && (
              <div className="px-2 mb-1.5 text-[10px] font-bold uppercase tracking-wider text-[#71717A]">
                Clinical Facility Portal
              </div>
            )}
            <nav className="space-y-1">
              <NavLink
                to="/phc"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <Activity className="h-4 w-4 shrink-0 text-[#F43F5E]" />
                {sidebarOpen && (
                  <div className="flex flex-1 items-center justify-between">
                    <span>Emergency Triage</span>
                    <Badge variant="destructive" className="h-5 px-1.5 text-[10px]">
                      2 RED
                    </Badge>
                  </div>
                )}
              </NavLink>

              <NavLink
                to="/map"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <MapPin className="h-4 w-4 shrink-0 text-emerald-500" />
                {sidebarOpen && (
                  <div className="flex flex-1 items-center justify-between">
                    <span>OsmAnd Field Map</span>
                    <Badge variant="outline" className="h-4 px-1 text-[9px] text-emerald-600 dark:text-emerald-400">
                      GPS
                    </Badge>
                  </div>
                )}
              </NavLink>

              <NavLink
                to="/anm"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <FileCheck2 className="h-4 w-4 shrink-0 text-teal-500" />
                {sidebarOpen && <span>ANM / Sub-Centre</span>}
              </NavLink>

              <NavLink
                to="/af"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <Users className="h-4 w-4 shrink-0 text-[#F59E0B]" />
                {sidebarOpen && <span>ASHA Supervision</span>}
              </NavLink>

              <NavLink
                to="/district"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <BarChart3 className="h-4 w-4 shrink-0 text-indigo-500" />
                {sidebarOpen && <span>District Analytics</span>}
              </NavLink>

              <NavLink
                to="/admin"
                className={({ isActive }) =>
                  `flex items-center space-x-3 rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-500/30 shadow-xs'
                      : 'text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] hover:text-[#0F172A] dark:hover:text-white'
                  } ${!sidebarOpen ? 'justify-center px-2' : ''}`
                }
              >
                <ShieldCheck className="h-4 w-4 shrink-0 text-purple-500" />
                {sidebarOpen && <span>Admin Console</span>}
              </NavLink>
            </nav>
          </div>

          {/* Quick Hotline */}
          {sidebarOpen && (
            <div className="pt-2 border-t border-[#E5E7EB] dark:border-[#2E2E2E]">
              <div className="px-2 mb-1.5 text-[10px] font-bold uppercase tracking-wider text-[#71717A]">
                Hotline & Dispatch
              </div>
              <a
                href="tel:108"
                className="flex items-center space-x-2.5 p-2 rounded-xl bg-rose-50 dark:bg-rose-950/20 text-[#F43F5E] border border-rose-200 dark:border-rose-500/20 text-xs font-semibold hover:bg-rose-100 transition-colors"
              >
                <PhoneCall className="h-3.5 w-3.5" />
                <span>Call 108 Ambulance</span>
              </a>
            </div>
          )}
        </div>

        {/* 4. Lower Footer & Doctor Profile (Firmly Pinned to Bottom, NOT Scrollable!) */}
        <div className="shrink-0 mt-auto border-t border-[#E5E7EB] dark:border-[#2E2E2E] p-3 space-y-2 bg-[#FFFFFF] dark:bg-[#1E1E1E]">
          {/* Theme Mode Toggle Row */}
          <div className="flex items-center justify-between px-1">
            {sidebarOpen && (
              <span className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3] flex items-center gap-1.5">
                {theme === 'dark' ? <Moon className="h-3.5 w-3.5" /> : <Sun className="h-3.5 w-3.5" />}
                <span>{theme === 'dark' ? 'Dark Mode' : 'Light Mode'}</span>
              </span>
            )}
            <Button
              size="xs"
              variant="outline"
              onClick={toggleTheme}
              className="h-7 px-2 text-[11px] gap-1 ml-auto"
              title="Toggle Light / Dark mode"
            >
              {theme === 'dark' ? (
                <>
                  <Sun className="h-3.5 w-3.5 text-amber-400" />
                  {sidebarOpen && <span>Light</span>}
                </>
              ) : (
                <>
                  <Moon className="h-3.5 w-3.5 text-slate-600" />
                  {sidebarOpen && <span>Dark</span>}
                </>
              )}
            </Button>
          </div>

          {/* Doctor Profile & Role Switcher */}
          <div className="relative">
            <button
              onClick={() => setRoleDropdownOpen(!roleDropdownOpen)}
              className="flex w-full items-center space-x-2.5 rounded-xl bg-slate-50 dark:bg-[#222224] p-2 border border-[#E5E7EB] dark:border-[#2E2E2E] hover:border-slate-300 dark:hover:border-slate-600 transition-colors text-left"
            >
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-emerald-100 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-500/30">
                <currentRoleConfig.icon className="h-4 w-4" />
              </div>
              {sidebarOpen && (
                <div className="flex flex-1 flex-col truncate">
                  <span className="text-xs font-bold text-[#0F172A] dark:text-white truncate">
                    {user?.name || 'Dr. Rajesh Sharma'}
                  </span>
                  <span className="text-[10px] text-[#10B981] font-medium flex items-center gap-1">
                    <span className="h-1.5 w-1.5 rounded-full bg-[#10B981]" />
                    {role} • On Duty
                  </span>
                </div>
              )}
              {sidebarOpen && <ChevronDown className="h-3.5 w-3.5 text-[#71717A]" />}
            </button>

            {/* Popup Role Switcher */}
            {roleDropdownOpen && (
              <div className="absolute bottom-full left-0 mb-2 w-64 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] p-2 shadow-2xl z-50">
                <div className="px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-[#71717A] border-b border-[#E5E7EB] dark:border-[#2E2E2E] mb-1">
                  Switch Active Role Shell
                </div>
                {(Object.keys(ROLE_CONFIG) as UserRole[]).map((r) => {
                  const cfg = ROLE_CONFIG[r];
                  const Icon = cfg.icon;
                  const isCurrent = r === role;
                  return (
                    <button
                      key={r}
                      onClick={() => handleRoleSelect(r)}
                      className={`flex w-full items-center space-x-2.5 rounded-lg px-2.5 py-1.5 text-xs transition-colors ${
                        isCurrent
                          ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 font-bold'
                          : 'text-[#0F172A] dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
                      }`}
                    >
                      <Icon className="h-3.5 w-3.5 text-slate-400" />
                      <div className="flex flex-1 items-center justify-between">
                        <span>{cfg.label}</span>
                        {isCurrent && <span className="h-1.5 w-1.5 rounded-full bg-[#10B981]" />}
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* Main Content Workspace */}
      <div className="flex flex-1 flex-col min-w-0 overflow-x-hidden">
        {/* Top Header Bar */}
        <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] bg-white/95 dark:bg-[#1E1E1E]/95 px-4 lg:px-8 backdrop-blur-md transition-colors">
          {/* Left: Sidebar Toggle & Facility Breadcrumb */}
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="rounded-lg p-2 text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] lg:hidden"
            >
              <Menu className="h-5 w-5" />
            </button>
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="hidden lg:flex rounded-lg p-2 text-[#525252] dark:text-[#A3A3A3] hover:bg-slate-100 dark:hover:bg-[#2A2A2A] transition-colors"
              title="Toggle Sidebar"
            >
              <Menu className="h-4 w-4" />
            </button>
            <div className="flex items-center space-x-2">
              <span className="text-xs font-semibold text-[#71717A] hidden sm:inline">
                National Health Mission •
              </span>
              <span className="text-xs font-bold text-[#0F172A] dark:text-white">
                Primary Health Centre Shahpur
              </span>
              <Badge variant="outline" className="hidden md:inline-flex text-[10px] text-emerald-600 dark:text-emerald-400 border-emerald-300 dark:border-emerald-500/30">
                ABDM Verified
              </Badge>
            </div>
          </div>

          {/* Right: Live Sync, Theme Toggle & Status */}
          <div className="flex items-center space-x-2.5">
            <div className="hidden sm:flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-[11px] text-emerald-700 dark:text-emerald-300 font-medium">
              <span className="h-2 w-2 rounded-full bg-[#10B981] animate-pulse" />
              <span>Live Sync 30s</span>
            </div>

            {/* Quick Header Theme Toggle */}
            <Button
              size="icon"
              variant="outline"
              onClick={toggleTheme}
              className="h-8 w-8 rounded-lg"
              title="Toggle Theme (Light / Dark)"
            >
              {theme === 'dark' ? (
                <Sun className="h-4 w-4 text-amber-400" />
              ) : (
                <Moon className="h-4 w-4 text-slate-700" />
              )}
            </Button>

            <div className="hidden md:flex items-center space-x-1.5 px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs">
              <span className="text-[#71717A]">Role:</span>
              <span className="font-bold text-emerald-700 dark:text-emerald-300">{currentRoleConfig.shortTitle}</span>
            </div>
          </div>
        </header>

        {/* Content View */}
        <main className="flex-1 bg-white dark:bg-[#1E1E1E] transition-colors duration-200">
          <Outlet />
        </main>

        {/* Clinical Portal Footer */}
        <footer className="border-t border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] px-4 py-3 text-xs text-[#71717A] flex flex-col sm:flex-row items-center justify-between gap-2 transition-colors">
          <div className="flex items-center space-x-2">
            <span className="font-semibold text-[#0F172A] dark:text-slate-300">ASHA Digital Platform</span>
            <span>•</span>
            <span>Facility: PHC Shahpur (Code: PHC-SHP-04)</span>
            <span>•</span>
            <span>Block: {user?.blockCode || 'Shahpur'}, UP</span>
          </div>
          <div className="text-[11px] flex items-center space-x-2">
            <span>ABDM HIU & DPDP Act 2023 Compliant</span>
            <span>•</span>
            <span className="text-emerald-600 dark:text-emerald-400">Confidential Health Records</span>
          </div>
        </footer>
      </div>
    </div>
  );
}
