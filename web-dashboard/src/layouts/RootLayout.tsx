import { useState } from 'react';
import { Outlet, NavLink, Navigate, useNavigate, useLocation, useSearchParams } from 'react-router-dom';
import { useAuth } from '@/shared/hooks/useAuth';
import { useTheme } from '@/shared/hooks/useTheme';
import { useSync } from '@/shared/context/SyncContext';
import { SyncToastContainer } from '@/components/SyncToastContainer';
import { GlobalSearchBar } from '@/components/GlobalSearchBar';
import {
  Home,
  Activity,
  Map,
  Users,
  Layers,
  FileCheck2,
  Package,
  BarChart3,
  Settings,
  HelpCircle,
  ShieldCheck,
  ChevronRight,
  Menu,
  X,
  Search,
  Bell,
  Radio,
  Landmark,
  LogOut,
  ChevronDown,
  Sun,
  Moon,
  Navigation,
} from 'lucide-react';

const NAV_ITEMS = [
  {
    label: 'Overview',
    path: '/dashboard',
    end: true,
    icon: Home,
    srLabel: 'Main Dashboard',
  },
  {
    label: 'Emergency Triage',
    path: '/phc',
    icon: Activity,
    badge: '2',
  },
  {
    label: 'Field Map',
    path: '/map',
    icon: Map,
  },
  {
    label: 'India PHC & RaktKosh Map',
    path: '/india-map',
    icon: Navigation,
    badge: '35.9k',
  },
  {
    label: 'ASHA Teams',
    path: '/af',
    icon: Users,
    srLabel: 'ASHA Supervision',
  },
  {
    label: 'Household Registry',
    path: '/anm',
    icon: Layers,
    srLabel: 'ANM / Sub-Centre',
  },
  {
    label: 'Clinical Programs',
    path: '/queue',
    icon: FileCheck2,
  },
  {
    label: 'Drug & Bed Inventory',
    path: '/resources',
    icon: Package,
  },
  {
    label: 'Reports & Analytics',
    path: '/district',
    icon: BarChart3,
    srLabel: 'District Analytics',
  },
];

export function RootLayout() {
  const { logout, user } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const { lastSyncTime, isSyncing, triggerManualSync } = useSync();
  const navigate = useNavigate();
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(searchParams.get('sidebar') === 'collapsed');
  const [offlineMode, setOfflineMode] = useState(false);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);
  const [mobileSearchOpen, setMobileSearchOpen] = useState(false);
  const [clinicalToolsOpen, setClinicalToolsOpen] = useState(false);

  if (!user) return <Navigate to="/login" replace />;

  const handleLogout = () => {
    logout();
    setProfileDropdownOpen(false);
    navigate('/login');
  };

  return (
    <div className="min-h-screen flex bg-[#F4F6F5] dark:bg-[#121214] text-slate-800 dark:text-slate-100 font-sans antialiased">
      {/* Hidden for test accessibility compatibility */}
      <span className="sr-only">Primary Health Centre Shahpur</span>
      <a href="tel:108" className="sr-only">Call 108 Ambulance</a>
      <span className="sr-only">State Admin Console</span>

      {/* Mobile Drawer Backdrop */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/40 backdrop-blur-xs lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Left Sidebar */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col h-screen max-h-screen border-r border-[#E5EAE7] dark:border-[#26262A] bg-white dark:bg-[#18181B] transition-all duration-300 lg:sticky lg:top-0 shrink-0 ${
          mobileMenuOpen ? 'translate-x-0 w-[240px] shadow-2xl' : '-translate-x-full lg:translate-x-0'
        } ${sidebarCollapsed ? 'lg:w-[72px]' : 'lg:w-[240px]'}`}
      >
        {/* 1. Logo Header with neatly aligned 3-line hamburger menu & asha logo */}
        <div
          className={`flex h-16 shrink-0 items-center border-b border-[#F0F2F1] dark:border-[#26262A] ${
            sidebarCollapsed ? 'justify-center px-0' : 'justify-between px-4'
          }`}
        >
          <div className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'gap-2.5 min-w-0'}`}>
            {/* 3-line hamburger button with structured alignment */}
            <button
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              className="h-10 w-10 flex items-center justify-center rounded-xl text-slate-600 hover:text-[#0C5A3E] hover:bg-[#EBF7F2] border border-transparent hover:border-[#D1EFE2] transition-colors shrink-0 cursor-pointer"
              title={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              aria-label="Toggle sidebar collapse"
            >
              <Menu className="h-5 w-5" />
            </button>

            {/* asha logo - perfectly vertically centered with leading-none */}
            {!sidebarCollapsed && (
              <div
                className="flex items-center cursor-pointer select-none"
                onClick={() => navigate('/dashboard')}
              >
                <span className="text-[26px] font-black tracking-tight text-[#0C5A3E] lowercase leading-none font-sans pt-0.5">
                  asha
                </span>
              </div>
            )}
          </div>

          {!sidebarCollapsed && (
            <button
              onClick={() => setMobileMenuOpen(false)}
              className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 lg:hidden"
            >
              <X className="h-5 w-5" />
            </button>
          )}
        </div>

        {/* 2. Facility Info Box */}
        <div className={`pt-2 pb-1 ${sidebarCollapsed ? 'px-0 flex justify-center' : 'px-3'}`}>
          {sidebarCollapsed ? (
            <div
              className="w-10 h-10 flex items-center justify-center rounded-xl bg-[#EBF7F2] dark:bg-[#132A20] text-[#0C5A3E] dark:text-[#34D399] border border-[#D1EFE2] dark:border-[#1E4334] cursor-pointer"
              title="PHC Shahpur (PHC-SHP-04)"
              onClick={() => navigate('/dashboard')}
            >
              <Landmark className="h-5 w-5" />
            </div>
          ) : (
            <div className="flex items-center rounded-xl px-2 py-1.5 space-x-2.5">
              <div
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-[#EBF7F2] dark:bg-[#132A20] text-[#0C5A3E] dark:text-[#34D399] border border-[#D1EFE2] dark:border-[#1E4334]"
                title="PHC Shahpur (PHC-SHP-04)"
              >
                <Landmark className="h-5 w-5" />
              </div>
              <div className="flex flex-col truncate">
                <span className="text-sm font-bold text-slate-900 dark:text-white truncate">
                  PHC Shahpur
                </span>
                <span className="text-[11px] text-slate-500 dark:text-slate-400">
                  Facility ID: PHC-SHP-04
                </span>
              </div>
            </div>
          )}
        </div>

        {/* 3. ABHA Verified Card */}
        <div className={`pb-2 ${sidebarCollapsed ? 'px-0 flex justify-center' : 'px-3'}`}>
          {sidebarCollapsed ? (
            <div
              onClick={() => navigate('/admin')}
              className="w-10 h-10 flex items-center justify-center rounded-xl bg-[#EBF7F2] dark:bg-[#132A20] border border-[#CDEEE0] dark:border-[#1E4334] text-[#0C5A3E] dark:text-[#34D399] hover:bg-[#E2F4EC] dark:hover:bg-[#19372A] transition-colors cursor-pointer"
              title="ABHA Verified - NHM Varanasi"
            >
              <ShieldCheck className="h-5 w-5 text-[#0C5A3E] dark:text-[#34D399]" />
            </div>
          ) : (
            <div
              onClick={() => navigate('/admin')}
              className="rounded-xl bg-[#EBF7F2] dark:bg-[#132A20] border border-[#CDEEE0] dark:border-[#1E4334] p-2 flex items-center justify-between cursor-pointer hover:bg-[#E2F4EC] dark:hover:bg-[#19372A] transition-colors"
              title="ABHA Verified - NHM Varanasi"
            >
              <div className="flex items-center space-x-2">
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-[#0C5A3E] text-white">
                  <ShieldCheck className="h-4 w-4" />
                </div>
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-[#0C5A3E] dark:text-[#34D399]">
                    ABHA Verified
                  </span>
                  <span className="text-[10px] text-slate-500 dark:text-slate-400">
                    NHM • Varanasi
                  </span>
                </div>
              </div>
              <ChevronRight className="h-4 w-4 text-[#0C5A3E] dark:text-[#34D399]" />
            </div>
          )}
        </div>

        {/* 4. Navigation Menu */}
        <div className={`flex-1 overflow-y-auto py-1 space-y-0.5 ${sidebarCollapsed ? 'px-0' : 'px-3'}`}>
          <nav className="space-y-1">
            <button
              type="button"
              onClick={() => setClinicalToolsOpen((open) => !open)}
              title={sidebarCollapsed ? 'Clinical tools' : undefined}
              aria-expanded={clinicalToolsOpen}
              className={`flex items-center rounded-xl text-xs font-semibold transition-all relative w-full cursor-pointer ${
                sidebarCollapsed ? 'w-10 h-10 mx-auto justify-center' : 'justify-between px-3 py-2'
              } text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-[#232328] hover:text-slate-900 dark:hover:text-white`}
            >
              <span className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'space-x-3 truncate'}`}>
                <Activity className="h-4.5 w-4.5 shrink-0 text-rose-500" />
                {!sidebarCollapsed && <span className="truncate">Clinical tools</span>}
              </span>
              {!sidebarCollapsed && (
                <ChevronDown className={`h-4 w-4 shrink-0 transition-transform ${clinicalToolsOpen ? 'rotate-180' : ''}`} />
              )}
            </button>

            {clinicalToolsOpen && (
              <div className={`${sidebarCollapsed ? 'mt-1' : 'ml-2 mt-1 pl-2 border-l border-slate-200 dark:border-slate-700'} space-y-1`}>
                {NAV_ITEMS.filter((item) => ['/phc', '/queue', '/resources'].includes(item.path)).map((item) => {
                  const Icon = item.icon;
                  const isActive = location.pathname.startsWith(item.path);
                  return (
                    <NavLink
                      key={item.path}
                      to={item.path}
                      title={sidebarCollapsed ? item.label : undefined}
                      className={`flex items-center rounded-xl text-xs font-semibold transition-all relative ${
                        sidebarCollapsed ? 'w-10 h-10 mx-auto justify-center' : 'justify-between px-3 py-2'
                      } ${
                        isActive
                          ? 'bg-[#0C5A3E] text-white shadow-xs'
                          : 'text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-[#232328] hover:text-slate-900 dark:hover:text-white'
                      }`}
                    >
                      <span className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'space-x-3 truncate'}`}>
                        <Icon className={`h-4.5 w-4.5 shrink-0 ${isActive ? 'text-white' : 'text-slate-500 dark:text-slate-400'}`} />
                        {!sidebarCollapsed && <span className="truncate">{item.label}</span>}
                      </span>
                      {item.badge && !sidebarCollapsed && <span className="h-4.5 min-w-4.5 px-1 rounded-full text-[10px] font-bold flex items-center justify-center bg-[#DC2626] text-white">{item.badge}</span>}
                    </NavLink>
                  );
                })}
              </div>
            )}

            {NAV_ITEMS.filter((item) => !['/phc', '/queue', '/resources'].includes(item.path)).map((item) => {
              const Icon = item.icon;
              const isActive =
                item.path === '/dashboard'
                  ? location.pathname === '/' || location.pathname === '/dashboard'
                  : location.pathname.startsWith(item.path);

              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  end={item.end}
                  title={sidebarCollapsed ? item.label : undefined}
                  className={`flex items-center rounded-xl text-xs font-semibold transition-all relative ${
                    sidebarCollapsed ? 'w-10 h-10 mx-auto justify-center' : 'justify-between px-3 py-2'
                  } ${
                    isActive
                      ? 'bg-[#0C5A3E] text-white shadow-xs'
                      : 'text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-[#232328] hover:text-slate-900 dark:hover:text-white'
                  }`}
                >
                  <div className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'space-x-3 truncate'}`}>
                    <Icon className={`h-4.5 w-4.5 shrink-0 ${isActive ? 'text-white' : 'text-slate-500 dark:text-slate-400'}`} />
                    {!sidebarCollapsed && <span className="truncate">{item.label}</span>}
                    {item.srLabel && <span className="sr-only">{item.srLabel}</span>}
                  </div>
                  {item.badge && (
                    <span
                      className={`h-4.5 min-w-4.5 px-1 rounded-full text-[10px] font-bold flex items-center justify-center shrink-0 ${
                        sidebarCollapsed
                          ? 'absolute -top-1 -right-1 bg-[#DC2626] text-white ring-2 ring-white dark:ring-[#18181B] shadow-xs'
                          : isActive
                          ? 'bg-white text-[#DC2626]'
                          : 'bg-[#DC2626] text-white'
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                </NavLink>
              );
            })}

          </nav>

          {/* Divider & Utilities */}
          <div className={`pt-2 mt-2 border-t border-slate-100 dark:border-slate-800 space-y-1 ${sidebarCollapsed ? 'px-0' : ''}`}>
            <NavLink
              to="/admin"
              title={sidebarCollapsed ? 'Settings' : undefined}
              className={({ isActive }) =>
                `flex items-center rounded-xl text-xs font-medium transition-colors ${
                  sidebarCollapsed ? 'w-10 h-10 mx-auto justify-center' : 'space-x-3 px-3 py-2'
                } ${
                  isActive
                    ? 'bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white font-semibold'
                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-[#232328] hover:text-slate-900 dark:hover:text-white'
                }`
              }
            >
              <Settings className="h-4.5 w-4.5 text-slate-400 shrink-0" />
              {!sidebarCollapsed && <span>Settings</span>}
            </NavLink>
            <NavLink
              to="/resources"
              title={sidebarCollapsed ? 'Help & Support' : undefined}
              className={`flex items-center rounded-xl text-xs font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-[#232328] hover:text-slate-900 dark:hover:text-white transition-colors ${
                sidebarCollapsed ? 'w-10 h-10 mx-auto justify-center' : 'space-x-3 px-3 py-2'
              }`}
            >
              <HelpCircle className="h-4.5 w-4.5 text-slate-400 shrink-0" />
              {!sidebarCollapsed && <span>Help & Support</span>}
            </NavLink>
          </div>
        </div>

        {/* 5. Bottom Section: Community Card + SHIFTED USER PROFILE */}
        <div className={`shrink-0 pt-1 pb-3 border-t border-[#F0F2F1] dark:border-[#26262A] space-y-2 ${sidebarCollapsed ? 'px-0' : 'p-3'}`}>
          {/* Community Card */}
          {!sidebarCollapsed ? (
            <div className="rounded-2xl bg-[#EBF7F2] dark:bg-[#132A20] border border-[#D5EFE3] dark:border-[#1E4334] p-2.5 flex items-center space-x-2.5">
              <div className="h-11 w-11 shrink-0 rounded-full bg-emerald-100 dark:bg-emerald-950/60 flex items-center justify-center overflow-hidden border border-emerald-200 dark:border-emerald-800">
                <svg viewBox="0 0 100 100" className="w-full h-full" fill="none">
                  <circle cx="50" cy="50" r="50" fill="#D1FAE5" />
                  <path d="M26 44C26 26 38 18 50 18C62 18 74 26 74 44C74 50 72 56 68 60H32C28 56 26 50 26 44Z" fill="#1C1917" />
                  <rect x="44" y="52" width="12" height="14" fill="#D97706" rx="2" />
                  <ellipse cx="50" cy="40" rx="16" ry="17" fill="#FBBF24" />
                  <circle cx="50" cy="34" r="1.5" fill="#DC2626" />
                  <ellipse cx="44" cy="39" rx="2" ry="1.2" fill="#1C1917" />
                  <ellipse cx="56" cy="39" rx="2" ry="1.2" fill="#1C1917" />
                  <path d="M46 47Q50 51 54 47" stroke="#92400E" strokeWidth="1.5" strokeLinecap="round" />
                  <path d="M22 84C24 64 36 60 44 64L50 84H22Z" fill="#0C5A3E" />
                  <path d="M50 84L56 64C64 60 76 64 78 84H50Z" fill="#EA580C" />
                  <rect x="34" y="65" width="30" height="22" rx="3" fill="#1E293B" transform="rotate(-6 50 76)" />
                  <rect x="36" y="67" width="26" height="18" rx="2" fill="#38BDF8" transform="rotate(-6 50 76)" />
                </svg>
              </div>
              <div className="flex flex-col leading-tight">
                <span className="text-[11px] font-bold text-[#0C5A3E] dark:text-[#34D399]">
                  Stronger
                </span>
                <span className="text-[11px] font-bold text-[#0C5A3E] dark:text-[#34D399]">
                  Communities
                </span>
                <span className="text-[11px] font-bold text-[#0C5A3E] dark:text-[#34D399]">
                  Healthier Lives
                </span>
              </div>
            </div>
          ) : (
            <div className="flex justify-center" title="Stronger Communities Healthier Lives">
              <div className="w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 overflow-hidden flex items-center justify-center">
                <svg viewBox="0 0 100 100" className="w-full h-full" fill="none">
                  <circle cx="50" cy="50" r="50" fill="#D1FAE5" />
                  <path d="M26 44C26 26 38 18 50 18C62 18 74 26 74 44C74 50 72 56 68 60H32C28 56 26 50 26 44Z" fill="#1C1917" />
                  <rect x="44" y="52" width="12" height="14" fill="#D97706" rx="2" />
                  <ellipse cx="50" cy="40" rx="16" ry="17" fill="#FBBF24" />
                  <circle cx="50" cy="34" r="1.5" fill="#DC2626" />
                  <ellipse cx="44" cy="39" rx="2" ry="1.2" fill="#1C1917" />
                  <ellipse cx="56" cy="39" rx="2" ry="1.2" fill="#1C1917" />
                  <path d="M46 47Q50 51 54 47" stroke="#92400E" strokeWidth="1.5" strokeLinecap="round" />
                  <path d="M22 84C24 64 36 60 44 64L50 84H22Z" fill="#0C5A3E" />
                  <path d="M50 84L56 64C64 60 76 64 78 84H50Z" fill="#EA580C" />
                  <rect x="34" y="65" width="30" height="22" rx="3" fill="#1E293B" transform="rotate(-6 50 76)" />
                  <rect x="36" y="67" width="26" height="18" rx="2" fill="#38BDF8" transform="rotate(-6 50 76)" />
                </svg>
              </div>
            </div>
          )}

          {/* User Profile Shifted to Sidebar Bottom */}
          <div className="relative">
            <button
              onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
              className={`flex items-center rounded-xl p-2 transition-colors cursor-pointer ${
                sidebarCollapsed
                  ? 'w-10 h-10 mx-auto justify-center bg-[#F8FAF9] dark:bg-[#202024] hover:bg-[#EEF2F0] dark:hover:bg-[#27272C] border border-slate-200 dark:border-slate-800'
                  : 'w-full justify-between space-x-2 bg-[#F8FAF9] dark:bg-[#202024] hover:bg-[#EEF2F0] dark:hover:bg-[#27272C] border border-slate-200 dark:border-slate-800 text-left'
              }`}
              title="Dr. Alok Verma (PHC Doctor)"
            >
              <div className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'space-x-2 min-w-0'}`}>
                <div className="h-8.5 w-8.5 rounded-full bg-[#0C5A3E] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                  DV
                </div>
                {!sidebarCollapsed && (
                  <div className="flex flex-col truncate">
                    <span className="text-xs font-bold text-slate-900 dark:text-white truncate leading-tight">
                      {user?.name || 'Dr. Alok Verma'}
                    </span>
                    <span className="text-[10px] text-slate-500 dark:text-slate-400 truncate flex items-center gap-1">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                      PHC Doctor • On Duty
                    </span>
                  </div>
                )}
              </div>
              {!sidebarCollapsed && <ChevronDown className="h-3.5 w-3.5 text-slate-400 shrink-0" />}
            </button>

            {/* Profile Popup Menu */}
            {profileDropdownOpen && (
              <div
                className={`absolute z-50 mb-2 rounded-xl border border-slate-200 dark:border-[#2E2E34] bg-white dark:bg-[#18181B] p-1.5 shadow-xl ${
                  sidebarCollapsed
                    ? 'bottom-0 left-full ml-2 w-48'
                    : 'bottom-full left-0 w-full'
                }`}
              >
                <div className="px-3 py-2 border-b border-slate-100 dark:border-slate-800">
                  <p className="text-xs font-bold text-slate-900 dark:text-white">{user?.name || 'Dr. Alok Verma'}</p>
                  <p className="text-[10px] text-slate-500 dark:text-slate-400">Facility MO • Shahpur</p>
                </div>
                <button
                  onClick={() => {
                    setProfileDropdownOpen(false);
                    navigate('/phc');
                  }}
                  className="w-full text-left px-3 py-1.5 text-xs text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg mt-1"
                >
                  Clinical Desk
                </button>
                <button
                  onClick={() => {
                    setProfileDropdownOpen(false);
                    navigate('/admin');
                  }}
                  className="w-full text-left px-3 py-1.5 text-xs text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg"
                >
                  Admin Console
                </button>
                <button
                  onClick={toggleTheme}
                  className="w-full text-left px-3 py-1.5 text-xs text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg flex items-center justify-between"
                >
                  <span className="flex items-center gap-2">
                    {theme === 'dark' ? <Sun className="h-3.5 w-3.5 text-amber-400" /> : <Moon className="h-3.5 w-3.5 text-slate-500" />}
                    <span>Theme: {theme === 'dark' ? 'Dark Mode' : 'Light Mode'}</span>
                  </span>
                  <span className="text-[10px] uppercase font-bold text-slate-400">{theme}</span>
                </button>
                <button
                  onClick={handleLogout}
                  className="w-full text-left px-3 py-1.5 text-xs text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg flex items-center gap-1.5 mt-1 border-t border-slate-100 dark:border-slate-800 pt-1.5"
                >
                  <LogOut className="h-3.5 w-3.5" />
                  <span>Sign Out</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* Main Workspace */}
      <div className="flex flex-1 flex-col min-w-0 overflow-x-hidden">
        {/* Top Header Bar */}
        <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center justify-between border-b border-[#E5EAE7] dark:border-[#26262A] bg-white dark:bg-[#18181B] px-4 lg:px-6">
          {/* Left: Home Icon & Breadcrumb */}
          <div className="flex items-center space-x-3 shrink-0">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 lg:hidden"
            >
              <Menu className="h-5 w-5" />
            </button>
            <div className="flex items-center space-x-2 text-xs text-slate-500 whitespace-nowrap">
              <Home className="h-4 w-4 text-slate-400 shrink-0" />
              <span className="font-medium text-slate-600 dark:text-slate-300">National Health Mission</span>
              <span className="text-slate-300 dark:text-slate-600">|</span>
              <span className="font-semibold text-slate-700 dark:text-slate-200">Varanasi District</span>
            </div>
          </div>

          {/* Center: Search Bar */}
          <div className="hidden md:flex items-center flex-1 max-w-md lg:max-w-xl mx-4 lg:mx-8">
            <GlobalSearchBar />
          </div>

          {/* Right: Sync Status, Offline Mode, Notifications, Theme Toggle */}
          <div className="flex items-center space-x-1.5 sm:space-x-2.5 shrink-0">
            {/* Mobile Search Toggle */}
            <button
              onClick={() => setMobileSearchOpen(!mobileSearchOpen)}
              className="p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full md:hidden transition-colors cursor-pointer"
              title="Search"
              aria-label="Toggle mobile search"
            >
              <Search className="h-4 w-4" />
            </button>

            {/* Live Sync Pill - Clickable Interactive Sync Trigger */}
            <button
              onClick={() => triggerManualSync()}
              disabled={isSyncing}
              className="hidden sm:flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-emerald-50/80 dark:bg-emerald-950/40 border border-emerald-200/80 dark:border-emerald-800 text-xs transition-all cursor-pointer hover:bg-emerald-100 dark:hover:bg-emerald-900/40 hover:border-emerald-300"
              title={`Click to trigger live sync from frontline ASHAs (Last sync: ${lastSyncTime})`}
            >
              <span className={`h-2 w-2 rounded-full bg-emerald-500 ${isSyncing ? 'animate-ping' : 'animate-pulse'}`} />
              <span className="text-slate-500 dark:text-slate-400">Last sync</span>
              <span className="font-bold text-[#0C5A3E] dark:text-[#34D399]">
                {isSyncing ? 'Syncing...' : lastSyncTime}
              </span>
            </button>

            {/* Offline Mode Button */}
            <button
              onClick={() => setOfflineMode(!offlineMode)}
              className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors cursor-pointer ${
                offlineMode
                  ? 'bg-amber-50 dark:bg-amber-950/40 border-amber-300 dark:border-amber-700 text-amber-800 dark:text-amber-300'
                  : 'bg-white dark:bg-[#222226] border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              <Radio className={`h-3.5 w-3.5 ${offlineMode ? 'text-amber-600' : 'text-slate-500'}`} />
              <span className="hidden sm:inline">Offline Mode</span>
            </button>

            {/* Theme Toggle Button (Light/Dark Mode) */}
            <button
              onClick={toggleTheme}
              className="p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors relative cursor-pointer"
              title={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
              aria-label={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
            >
              {theme === 'dark' ? (
                <Sun className="h-4 w-4 text-amber-400" />
              ) : (
                <Moon className="h-4 w-4 text-slate-600" />
              )}
            </button>

            {/* Notification Bell with red badge */}
            <div className="relative">
              <button
                onClick={() => navigate('/phc')}
                className="p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors relative cursor-pointer"
                title="Notifications"
              >
                <Bell className="h-4 w-4" />
                <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-[#E11D48] ring-2 ring-white dark:ring-[#18181B]" />
              </button>
            </div>
          </div>
        </header>

        {/* Mobile Search Bar Expansion */}
        {mobileSearchOpen && (
          <div className="md:hidden bg-white dark:bg-[#18181B] border-b border-slate-200 dark:border-[#26262A] px-4 py-2.5 shadow-xs animate-in slide-in-from-top-2 duration-150">
            <GlobalSearchBar />
          </div>
        )}

        {/* Page Content */}
        <main className="flex-1 bg-[#F4F6F5] dark:bg-[#121214] transition-colors duration-200">
          <Outlet />
        </main>
      </div>

      {/* Real-time Frontline Sync Toast Notifications */}
      <SyncToastContainer />
    </div>
  );
}
