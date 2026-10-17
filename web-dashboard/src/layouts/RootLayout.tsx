import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/shared/hooks/useAuth';
import { UserRole } from '@/types';
import {
  Activity,
  Users,
  Building2,
  FileCheck2,
  BarChart3,
  ShieldCheck,
  ChevronDown,
  RefreshCw,
  HeartPulse,
} from 'lucide-react';
import { useState } from 'react';

const ROLE_CONFIG: Record<
  UserRole,
  { label: string; badgeClass: string; path: string; icon: any }
> = {
  AF: {
    label: 'ASHA Facilitator (AF)',
    badgeClass: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
    path: '/af',
    icon: Users,
  },
  ANM: {
    label: 'ANM / CHO Workspace',
    badgeClass: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
    path: '/anm',
    icon: FileCheck2,
  },
  PHC_MO: {
    label: 'PHC Medical Officer (MO)',
    badgeClass: 'bg-rose-500/20 text-rose-300 border-rose-500/30',
    path: '/phc',
    icon: Activity,
  },
  DISTRICT_OFFICER: {
    label: 'District Health Officer',
    badgeClass: 'bg-indigo-500/20 text-indigo-300 border-indigo-500/30',
    path: '/district',
    icon: BarChart3,
  },
  STATE_ADMIN: {
    label: 'State Administrator',
    badgeClass: 'bg-purple-500/20 text-purple-300 border-purple-500/30',
    path: '/admin',
    icon: ShieldCheck,
  },
};

export function RootLayout() {
  const { user, role, switchRole } = useAuth();
  const navigate = useNavigate();
  const [roleDropdownOpen, setRoleDropdownOpen] = useState(false);
  const currentRoleConfig = ROLE_CONFIG[role];

  const handleRoleSelect = (newRole: UserRole) => {
    switchRole(newRole);
    setRoleDropdownOpen(false);
    navigate(ROLE_CONFIG[newRole].path);
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-slate-100 selection:bg-indigo-500 selection:text-white">
      {/* Top Header */}
      <header className="sticky top-0 z-50 glass-panel border-b border-slate-800/80 px-4 lg:px-8 py-3 flex items-center justify-between">
        {/* Left: Brand & Title */}
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-amber-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
            <HeartPulse className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-bold text-lg tracking-tight bg-gradient-to-r from-white via-slate-100 to-slate-400 bg-clip-text text-transparent">
                ASHA Digital Platform
              </span>
              <span className="text-xs px-2 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 font-medium">
                National Health Mission
              </span>
            </div>
            <p className="text-xs text-slate-400">
              Integrated Health Portal & Supervision Console
            </p>
          </div>
        </div>

        {/* Center: Navigation Links for Active Views */}
        <nav className="hidden md:flex items-center space-x-1 glass-card px-2 py-1.5 rounded-xl">
          <NavLink
            to="/phc"
            className={({ isActive }) =>
              `flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`
            }
          >
            <Activity className="w-3.5 h-3.5 text-rose-400" />
            <span>PHC Triage</span>
          </NavLink>
          <NavLink
            to="/af"
            className={({ isActive }) =>
              `flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`
            }
          >
            <Users className="w-3.5 h-3.5 text-amber-400" />
            <span>AF Supervision</span>
          </NavLink>
          <NavLink
            to="/anm"
            className={({ isActive }) =>
              `flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`
            }
          >
            <FileCheck2 className="w-3.5 h-3.5 text-emerald-400" />
            <span>ANM Workspace</span>
          </NavLink>
          <NavLink
            to="/district"
            className={({ isActive }) =>
              `flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`
            }
          >
            <BarChart3 className="w-3.5 h-3.5 text-indigo-400" />
            <span>District Analytics</span>
          </NavLink>
          <NavLink
            to="/admin"
            className={({ isActive }) =>
              `flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`
            }
          >
            <ShieldCheck className="w-3.5 h-3.5 text-purple-400" />
            <span>Admin</span>
          </NavLink>
        </nav>

        {/* Right: Role Switcher & User Profile */}
        <div className="flex items-center space-x-3">
          {/* Live Sync Status Pill */}
          <div className="hidden sm:flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-400 font-medium">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>Live Sync</span>
          </div>

          {/* Role Switcher Dropdown */}
          <div className="relative">
            <button
              onClick={() => setRoleDropdownOpen(!roleDropdownOpen)}
              className="flex items-center space-x-2 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-700/80 hover:border-slate-600 transition-all text-left text-xs"
            >
              <div className="w-7 h-7 rounded-lg bg-slate-800 flex items-center justify-center text-slate-300">
                <currentRoleConfig.icon className="w-4 h-4" />
              </div>
              <div className="hidden sm:block">
                <div className="font-semibold text-slate-200">{user?.name}</div>
                <div className="text-[10px] text-slate-400 flex items-center space-x-1">
                  <span className={`px-1.5 py-0.2 rounded border ${currentRoleConfig.badgeClass}`}>
                    {role}
                  </span>
                </div>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400 ml-1" />
            </button>

            {roleDropdownOpen && (
              <div className="absolute right-0 mt-2 w-64 rounded-xl glass-panel border border-slate-700 shadow-2xl py-2 z-50">
                <div className="px-3 py-1.5 border-b border-slate-800 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
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
                      className={`w-full px-3 py-2 flex items-center space-x-2.5 text-xs text-left transition-colors ${
                        isCurrent
                          ? 'bg-indigo-600/20 text-indigo-300 font-medium'
                          : 'text-slate-300 hover:bg-slate-800/80'
                      }`}
                    >
                      <div className="w-6 h-6 rounded-md bg-slate-800 flex items-center justify-center">
                        <Icon className="w-3.5 h-3.5" />
                      </div>
                      <div className="flex-1">
                        <div>{cfg.label}</div>
                        <div className="text-[10px] text-slate-400">Role: {r}</div>
                      </div>
                      {isCurrent && (
                        <span className="w-1.5 h-1.5 rounded-full bg-indigo-400"></span>
                      )}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Main Outlet */}
      <main className="flex-1">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/60 bg-slate-950/80 px-4 py-3 text-center text-xs text-slate-500 flex flex-col sm:flex-row items-center justify-between gap-2">
        <div className="flex items-center space-x-2">
          <span>ASHA Digital Platform (Task 14 Web Dashboards)</span>
          <span>•</span>
          <span className="text-slate-400">Role: {role}</span>
          <span>•</span>
          <span className="text-slate-400">Location: {user?.blockCode || 'Shahpur Block'}, {user?.stateCode || 'UP'}</span>
        </div>
        <div className="text-[11px] text-slate-600">
          DPDP & ABDM Compliant • Confidential Patient Health Information
        </div>
      </footer>
    </div>
  );
}
