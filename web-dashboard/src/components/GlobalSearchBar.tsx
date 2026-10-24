import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Search,
  X,
  User,
  Activity,
  MapPin,
  Users,
  Layers,
  FileCheck2,
  Package,
  BarChart3,
  ShieldCheck,
  ChevronRight,
  ArrowRight,
  ExternalLink,
  Sparkles,
  Command,
} from 'lucide-react';
import { INITIAL_REFERRALS, INITIAL_ASHA_CARDS } from '@/shared/api/mockData';

interface VillageInfo {
  name: string;
  subcentre: string;
  activeCases: number;
  ashaName: string;
}

const VILLAGES: VillageInfo[] = [
  { name: 'Rampur', subcentre: 'SC Rampur (SC-RAM-01)', activeCases: 3, ashaName: 'Meena Sharma' },
  { name: 'Kalyanpur', subcentre: 'SC Kalyanpur (SC-KLY-02)', activeCases: 4, ashaName: 'Poonam Devi' },
  { name: 'Shahpur Hamlet 2', subcentre: 'SC Shahpur (SC-SHP-03)', activeCases: 2, ashaName: 'Rekha Verma' },
  { name: 'Shahpur', subcentre: 'PHC Shahpur Central', activeCases: 5, ashaName: 'Facility HQ' },
  { name: 'Bishanpur', subcentre: 'SC Rampur (SC-RAM-01)', activeCases: 2, ashaName: 'Meena Sharma' },
  { name: 'Kotla Forest', subcentre: 'SC Kotla Remote', activeCases: 1, ashaName: 'Kamla Thakur' },
  { name: 'Shivpur', subcentre: 'SC Shivpur (SC-SHV-04)', activeCases: 2, ashaName: 'Sunita Yadav' },
  { name: 'Lohta', subcentre: 'SC Lohta (SC-LHT-05)', activeCases: 3, ashaName: 'Anjali Devi' },
];

const NAVIGATION_ITEMS = [
  {
    title: 'Emergency Triage Queue',
    path: '/phc',
    description: 'Active emergency referrals, RED/YELLOW triage protocols & clinical desk',
    category: 'Clinical',
    icon: Activity,
    badge: 'Critical',
    badgeColor: 'bg-rose-100 text-rose-700 border-rose-200',
  },
  {
    title: 'Catchment Field Map',
    path: '/map',
    description: 'Interactive OpenStreetMap with sub-centres, ambulances & high-risk clusters',
    category: 'Field',
    icon: MapPin,
  },
  {
    title: 'ASHA Team Supervision',
    path: '/af',
    description: 'Frontline ASHA due-list tracking, coverage scores and field incentives',
    category: 'Supervision',
    icon: Users,
  },
  {
    title: 'Household Registry & Due List',
    path: '/anm',
    description: 'ANM sub-centre beneficiaries, ANC registrations and immunizations',
    category: 'Sub-Centre',
    icon: Layers,
  },
  {
    title: 'Clinical Programs Hub',
    path: '/clinical-programs',
    description: 'Maternal health, child wellness, NCDs and tuberculosis care pathways',
    category: 'Clinical',
    icon: FileCheck2,
  },
  {
    title: 'Drug & Bed Inventory',
    path: '/resources',
    description: 'Emergency drug stock, oxygen cylinders and 24/7 PHC bed occupancy',
    category: 'Supplies',
    icon: Package,
  },
  {
    title: 'District Analytics & Outbreaks',
    path: '/district',
    description: 'Syndromic surveillance, outbreak alerts and block-level KPIs',
    category: 'Analytics',
    icon: BarChart3,
  },
  {
    title: 'Admin & ABHA Console',
    path: '/admin',
    description: 'Health facility registry, CSV staff upload and ABDM HIU gateway',
    category: 'Administration',
    icon: ShieldCheck,
  },
];

export function GlobalSearchBar() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const initialQ = searchParams.get('q') || '';
  const [query, setQuery] = useState(initialQ);
  const [isOpen, setIsOpen] = useState(Boolean(initialQ));
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [isMac, setIsMac] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Detect platform for keyboard hint (Cmd vs Ctrl)
  useEffect(() => {
    if (typeof navigator !== 'undefined') {
      setIsMac(/(Mac|iPhone|iPod|iPad)/i.test(navigator.platform || ''));
    }
  }, []);

  // Keyboard shortcut listener (Cmd+K or Ctrl+K or '/')
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
        setIsOpen(true);
      } else if (e.key === '/' && document.activeElement?.tagName !== 'INPUT' && document.activeElement?.tagName !== 'TEXTAREA') {
        e.preventDefault();
        inputRef.current?.focus();
        setIsOpen(true);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Click outside listener to close dropdown
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Filtered Results
  const trimmed = query.trim().toLowerCase();

  const matchingPatients = useMemo(() => {
    if (!trimmed) return INITIAL_REFERRALS.slice(0, 3);
    return INITIAL_REFERRALS.filter((item) => {
      return (
        item.patientName.toLowerCase().includes(trimmed) ||
        (item.abhaId && item.abhaId.toLowerCase().includes(trimmed)) ||
        item.village.toLowerCase().includes(trimmed) ||
        item.reason.toLowerCase().includes(trimmed) ||
        (item.ashaName && item.ashaName.toLowerCase().includes(trimmed)) ||
        item.id.toLowerCase().includes(trimmed)
      );
    }).slice(0, 4);
  }, [trimmed]);

  const matchingVillages = useMemo(() => {
    if (!trimmed) return VILLAGES.slice(0, 3);
    return VILLAGES.filter((v) => {
      return (
        v.name.toLowerCase().includes(trimmed) ||
        v.subcentre.toLowerCase().includes(trimmed) ||
        v.ashaName.toLowerCase().includes(trimmed)
      );
    }).slice(0, 3);
  }, [trimmed]);

  const matchingAshas = useMemo(() => {
    if (!trimmed) return INITIAL_ASHA_CARDS.slice(0, 2);
    return INITIAL_ASHA_CARDS.filter((a) => {
      return (
        a.ashaName.toLowerCase().includes(trimmed) ||
        a.village.toLowerCase().includes(trimmed) ||
        a.phone.toLowerCase().includes(trimmed)
      );
    }).slice(0, 3);
  }, [trimmed]);

  const matchingNavItems = useMemo(() => {
    if (!trimmed) return NAVIGATION_ITEMS.slice(0, 4);
    return NAVIGATION_ITEMS.filter((item) => {
      return (
        item.title.toLowerCase().includes(trimmed) ||
        item.description.toLowerCase().includes(trimmed) ||
        item.category.toLowerCase().includes(trimmed)
      );
    }).slice(0, 4);
  }, [trimmed]);

  // Combined flat list for keyboard arrow navigation
  const flatResults = useMemo(() => {
    const list: Array<{ type: string; item: any }> = [];
    matchingPatients.forEach((p) => list.push({ type: 'patient', item: p }));
    matchingVillages.forEach((v) => list.push({ type: 'village', item: v }));
    matchingAshas.forEach((a) => list.push({ type: 'asha', item: a }));
    matchingNavItems.forEach((n) => list.push({ type: 'nav', item: n }));
    return list;
  }, [matchingPatients, matchingVillages, matchingAshas, matchingNavItems]);

  const hasAnyResults = flatResults.length > 0;

  // Handle item selection
  const handleSelectItem = (type: string, item: any) => {
    setIsOpen(false);
    if (type === 'patient') {
      // Navigate to referral queue pre-filtered by patient name
      navigate(`/phc?search=${encodeURIComponent(item.patientName)}`);
    } else if (type === 'village') {
      navigate(`/phc?search=${encodeURIComponent(item.name)}`);
    } else if (type === 'asha') {
      navigate(`/af?search=${encodeURIComponent(item.ashaName)}`);
    } else if (type === 'nav') {
      navigate(item.path);
    }
  };

  // Keyboard navigation within dropdown
  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % (flatResults.length || 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + flatResults.length) % (flatResults.length || 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (flatResults.length > 0 && selectedIndex < flatResults.length) {
        const target = flatResults[selectedIndex];
        handleSelectItem(target.type, target.item);
      } else if (query.trim()) {
        setIsOpen(false);
        navigate(`/phc?search=${encodeURIComponent(query.trim())}`);
      }
    } else if (e.key === 'Escape') {
      setIsOpen(false);
      inputRef.current?.blur();
    }
  };

  return (
    <div ref={containerRef} className="relative w-full">
      {/* Search Input Bar */}
      <div className="relative flex items-center">
        <Search className="absolute left-3.5 h-4 w-4 text-slate-400 dark:text-slate-500 pointer-events-none transition-colors" />
        
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setIsOpen(true);
            setSelectedIndex(0);
          }}
          onFocus={() => setIsOpen(true)}
          onKeyDown={handleKeyDown}
          placeholder="Search patient, ABHA ID, village, ASHA..."
          className="w-full h-9.5 rounded-full bg-[#F3F5F4] dark:bg-[#202024] hover:bg-[#EDF1EF] dark:hover:bg-[#28282D] focus:bg-white dark:focus:bg-[#1A1A1E] pl-9.5 pr-20 text-xs font-medium text-slate-800 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 border border-slate-200 dark:border-[#34343A] focus:border-slate-300 dark:focus:border-[#45454D] focus:ring-0 focus:outline-none transition-all shadow-2xs"
          role="combobox"
          aria-expanded={isOpen}
          aria-label="Universal Health Search"
        />

        <div className="absolute right-2.5 flex items-center gap-1.5">
          {query ? (
            <button
              onClick={() => {
                setQuery('');
                setIsOpen(true);
                inputRef.current?.focus();
              }}
              className="p-1 rounded-full text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-200/60 dark:hover:bg-slate-700/60 transition-colors cursor-pointer"
              title="Clear search"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          ) : (
            <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-semibold text-slate-400 dark:text-slate-400 bg-white dark:bg-[#2A2A30] border border-slate-200 dark:border-slate-700 rounded-md shadow-2xs">
              <Command className="h-2.5 w-2.5" />
              <span>K</span>
            </kbd>
          )}
        </div>
      </div>

      {/* Floating Dropdown Results */}
      {isOpen && (
        <div className="absolute left-0 right-0 top-full mt-2 z-50 rounded-2xl bg-white dark:bg-[#18181B] border border-slate-200/80 dark:border-[#2E2E34] shadow-2xl overflow-hidden max-h-[82vh] flex flex-col animate-in fade-in-50 zoom-in-95 duration-150">
          {/* Header Status Bar */}
          <div className="flex items-center justify-between px-3.5 py-2 bg-slate-50 dark:bg-[#202024] border-b border-slate-100 dark:border-[#2E2E34] text-[11px] text-slate-500 dark:text-slate-400 font-medium">
            <div className="flex items-center gap-1.5">
              <Sparkles className="h-3.5 w-3.5 text-[#0C5A3E] dark:text-[#34D399]" />
              <span>
                {trimmed ? `Search results for "${query}"` : 'Quick Jump & Recent Records'}
              </span>
            </div>
            {trimmed && (
              <span className="text-[10px] bg-slate-200/70 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold px-1.5 py-0.5 rounded-full">
                {flatResults.length} matches
              </span>
            )}
          </div>

          {/* Scrollable Results Content */}
          <div className="flex-1 overflow-y-auto divide-y divide-slate-100/80 dark:divide-[#2E2E34] p-1.5 space-y-2">
            {/* 1. PATIENTS & REFERRALS */}
            {matchingPatients.length > 0 && (
              <div className="pt-1">
                <div className="px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center justify-between">
                  <span>Patients & Triage Referrals</span>
                  <span className="text-[9px] text-[#0C5A3E] dark:text-[#34D399] font-semibold">Active Queue</span>
                </div>
                <div className="space-y-1 mt-0.5">
                  {matchingPatients.map((patient) => {
                    const idx = flatResults.findIndex((r) => r.type === 'patient' && r.item.id === patient.id);
                    const isSelected = idx === selectedIndex;
                    const isRed = patient.severity === 'RED';
                    const isYellow = patient.severity === 'YELLOW';

                    return (
                      <div
                        key={patient.id}
                        onClick={() => handleSelectItem('patient', patient)}
                        onMouseEnter={() => setSelectedIndex(idx)}
                        className={`group px-3 py-2 rounded-xl cursor-pointer transition-all flex items-start justify-between gap-3 ${
                          isSelected
                            ? 'bg-[#EBF7F2] dark:bg-[#132A20] border border-[#C6EBDA] dark:border-[#1E4334]'
                            : 'hover:bg-slate-50 dark:hover:bg-[#202024] border border-transparent'
                        }`}
                      >
                        <div className="flex items-start gap-2.5 min-w-0">
                          <div
                            className={`h-8 w-8 rounded-lg shrink-0 flex items-center justify-center font-bold text-xs ${
                              isRed
                                ? 'bg-rose-100 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40'
                                : isYellow
                                ? 'bg-amber-100 dark:bg-amber-950/40 text-amber-800 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40'
                                : 'bg-emerald-100 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40'
                            }`}
                          >
                            <User className="h-4 w-4" />
                          </div>

                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-bold text-slate-900 dark:text-white group-hover:text-[#0C5A3E] dark:group-hover:text-[#34D399] transition-colors truncate">
                                {patient.patientName}
                              </span>
                              <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium shrink-0">
                                {patient.patientAge < 1
                                  ? `${Math.round(patient.patientAge * 12)}m`
                                  : `${Math.round(patient.patientAge)}y`}{' '}
                                • {patient.patientGender}
                              </span>
                              <span
                                className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full shrink-0 ${
                                  isRed
                                    ? 'bg-rose-100 dark:bg-rose-950/60 text-rose-800 dark:text-rose-300 border border-rose-200 dark:border-rose-900/60'
                                    : isYellow
                                    ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-900/60'
                                    : 'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900/60'
                                }`}
                              >
                                {patient.severity}
                              </span>
                            </div>

                            <p className="text-[11px] text-slate-600 dark:text-slate-300 truncate mt-0.5">
                              {patient.reason}
                            </p>

                            <div className="flex items-center gap-3 text-[10px] text-slate-400 dark:text-slate-500 mt-1">
                              <span className="flex items-center gap-1 font-mono">
                                ABHA: {patient.abhaId || 'Verified'}
                              </span>
                              <span>•</span>
                              <span className="flex items-center gap-1">
                                <MapPin className="h-2.5 w-2.5 text-slate-400 dark:text-slate-500" />
                                {patient.village}
                              </span>
                              <span>•</span>
                              <span>ASHA: {patient.ashaName}</span>
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-1 text-[11px] text-[#0C5A3E] dark:text-[#34D399] opacity-0 group-hover:opacity-100 shrink-0 self-center font-semibold transition-opacity">
                          <span>View Case</span>
                          <ChevronRight className="h-3.5 w-3.5" />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* 2. VILLAGES & CATCHMENT */}
            {matchingVillages.length > 0 && (
              <div className="pt-2">
                <div className="px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center justify-between">
                  <span>Catchment Villages & Sub-Centres</span>
                  <span className="text-[9px] text-slate-400 dark:text-slate-500">Varanasi Block</span>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-1 mt-0.5">
                  {matchingVillages.map((village) => {
                    const idx = flatResults.findIndex((r) => r.type === 'village' && r.item.name === village.name);
                    const isSelected = idx === selectedIndex;

                    return (
                      <div
                        key={village.name}
                        onClick={() => handleSelectItem('village', village)}
                        onMouseEnter={() => setSelectedIndex(idx)}
                        className={`p-2 rounded-xl cursor-pointer transition-all flex items-center justify-between ${
                          isSelected
                            ? 'bg-[#EBF7F2] dark:bg-[#132A20] border border-[#C6EBDA] dark:border-[#1E4334]'
                            : 'hover:bg-slate-50 dark:hover:bg-[#202024] border border-transparent'
                        }`}
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <div className="h-7 w-7 rounded-lg bg-emerald-50 dark:bg-[#132A20] text-[#0C5A3E] dark:text-[#34D399] border border-emerald-100 dark:border-[#1E4334] flex items-center justify-center shrink-0">
                            <MapPin className="h-3.5 w-3.5" />
                          </div>
                          <div className="min-w-0">
                            <div className="text-xs font-bold text-slate-900 dark:text-white truncate">
                              {village.name}
                            </div>
                            <div className="text-[10px] text-slate-500 dark:text-slate-400 truncate">
                              {village.subcentre}
                            </div>
                          </div>
                        </div>
                        <span className="text-[10px] font-bold bg-slate-100 dark:bg-[#28282D] text-slate-600 dark:text-slate-300 px-1.5 py-0.5 rounded-full shrink-0">
                          {village.activeCases} cases
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* 3. ASHA WORKERS */}
            {matchingAshas.length > 0 && (
              <div className="pt-2">
                <div className="px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center justify-between">
                  <span>Frontline ASHA Workers</span>
                  <span className="text-[9px] text-slate-400 dark:text-slate-500">Field Staff</span>
                </div>
                <div className="space-y-1 mt-0.5">
                  {matchingAshas.map((asha) => {
                    const idx = flatResults.findIndex((r) => r.type === 'asha' && r.item.ashaId === asha.ashaId);
                    const isSelected = idx === selectedIndex;

                    return (
                      <div
                        key={asha.ashaId}
                        onClick={() => handleSelectItem('asha', asha)}
                        onMouseEnter={() => setSelectedIndex(idx)}
                        className={`p-2 rounded-xl cursor-pointer transition-all flex items-center justify-between ${
                          isSelected
                            ? 'bg-[#EBF7F2] dark:bg-[#132A20] border border-[#C6EBDA] dark:border-[#1E4334]'
                            : 'hover:bg-slate-50 dark:hover:bg-[#202024] border border-transparent'
                        }`}
                      >
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className="h-7 w-7 rounded-full bg-emerald-100 dark:bg-[#132A20] text-[#0C5A3E] dark:text-[#34D399] font-bold text-xs flex items-center justify-center shrink-0">
                            {asha.ashaName.slice(0, 2).toUpperCase()}
                          </div>
                          <div className="min-w-0">
                            <div className="text-xs font-bold text-slate-900 dark:text-white truncate flex items-center gap-2">
                              <span>{asha.ashaName}</span>
                              <span className="text-[10px] font-semibold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-1.5 py-0.2 rounded-full border border-emerald-200 dark:border-emerald-800">
                                {asha.coveragePct}% coverage
                              </span>
                            </div>
                            <div className="text-[10px] text-slate-500 dark:text-slate-400 truncate">
                              {asha.village} • {asha.phone}
                            </div>
                          </div>
                        </div>

                        <span className="text-[10px] text-[#0C5A3E] dark:text-[#34D399] font-semibold flex items-center gap-1 shrink-0">
                          Supervision
                          <ChevronRight className="h-3 w-3" />
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* 4. WORKSPACES & MODULES */}
            {matchingNavItems.length > 0 && (
              <div className="pt-2">
                <div className="px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center justify-between">
                  <span>Portals & Workspaces</span>
                  <span className="text-[9px] text-slate-400 dark:text-slate-500">Direct Jump</span>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-1 mt-0.5">
                  {matchingNavItems.map((nav) => {
                    const Icon = nav.icon;
                    const idx = flatResults.findIndex((r) => r.type === 'nav' && r.item.path === nav.path);
                    const isSelected = idx === selectedIndex;

                    return (
                      <div
                        key={nav.path}
                        onClick={() => handleSelectItem('nav', nav)}
                        onMouseEnter={() => setSelectedIndex(idx)}
                        className={`p-2 rounded-xl cursor-pointer transition-all flex items-center gap-2.5 ${
                          isSelected
                            ? 'bg-[#EBF7F2] dark:bg-[#132A20] border border-[#C6EBDA] dark:border-[#1E4334]'
                            : 'hover:bg-slate-50 dark:hover:bg-[#202024] border border-transparent'
                        }`}
                      >
                        <div className="h-7 w-7 rounded-lg bg-slate-100 dark:bg-[#28282D] text-slate-700 dark:text-slate-300 flex items-center justify-center shrink-0">
                          <Icon className="h-4 w-4" />
                        </div>
                        <div className="min-w-0">
                          <div className="text-xs font-bold text-slate-900 dark:text-white truncate">
                            {nav.title}
                          </div>
                          <div className="text-[10px] text-slate-500 dark:text-slate-400 truncate">
                            {nav.category}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* NO RESULTS EMPTY STATE */}
            {!hasAnyResults && (
              <div className="py-8 px-4 text-center">
                <div className="h-10 w-10 mx-auto rounded-full bg-slate-100 dark:bg-[#28282D] flex items-center justify-center text-slate-400 dark:text-slate-500 mb-2">
                  <Search className="h-5 w-5" />
                </div>
                <p className="text-xs font-bold text-slate-800 dark:text-slate-200">No matching records found</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 max-w-xs mx-auto">
                  We could not find any patients, ABHA IDs, or villages matching &ldquo;{query}&rdquo;.
                </p>
                <button
                  onClick={() => {
                    setIsOpen(false);
                    navigate(`/phc?search=${encodeURIComponent(query)}`);
                  }}
                  className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#0C5A3E] text-white hover:bg-[#094731] transition-colors cursor-pointer"
                >
                  <span>Search across all clinical referrals</span>
                  <ArrowRight className="h-3 w-3" />
                </button>
              </div>
            )}
          </div>

          {/* Footer Bar with Navigation Hints */}
          <div className="px-3.5 py-2 bg-slate-50 dark:bg-[#202024] border-t border-slate-100 dark:border-[#2E2E34] flex items-center justify-between text-[10px] text-slate-400">
            <div className="flex items-center gap-3">
              <span className="flex items-center gap-1">
                <kbd className="px-1 py-0.5 bg-white dark:bg-[#2A2A30] border border-slate-200 dark:border-slate-700 rounded font-mono text-[9px] text-slate-600 dark:text-slate-300">↑↓</kbd>
                <span>Navigate</span>
              </span>
              <span className="flex items-center gap-1">
                <kbd className="px-1 py-0.5 bg-white dark:bg-[#2A2A30] border border-slate-200 dark:border-slate-700 rounded font-mono text-[9px] text-slate-600 dark:text-slate-300">↵</kbd>
                <span>Select</span>
              </span>
              <span className="flex items-center gap-1">
                <kbd className="px-1 py-0.5 bg-white dark:bg-[#2A2A30] border border-slate-200 dark:border-slate-700 rounded font-mono text-[9px] text-slate-600 dark:text-slate-300">ESC</kbd>
                <span>Close</span>
              </span>
            </div>

            {trimmed && (
              <button
                onClick={() => {
                  setIsOpen(false);
                  navigate(`/phc?search=${encodeURIComponent(trimmed)}`);
                }}
                className="text-[#0C5A3E] dark:text-[#34D399] hover:underline font-semibold flex items-center gap-1 cursor-pointer"
              >
                <span>Full queue search</span>
                <ChevronRight className="h-3 w-3" />
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
