import { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/shared/hooks/useAuth';
import {
  Activity,
  AlertTriangle,
  Stethoscope,
  FileCheck2,
  Users,
  BarChart3,
  ShieldCheck,
  MapPin,
  Package,
  HeartPulse,
  Clock,
  Radio,
  Layers,
  ArrowUpRight,
  TrendingUp,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export function MainDashboardPage() {
  const { user, role } = useAuth();
  const navigate = useNavigate();

  // Emergency Triage Cases
  const activeEmergencies = [
    {
      id: 'ref-001',
      patient: 'Sunita Devi',
      age: 24,
      gestation: '34 Weeks (G2P1)',
      severity: 'RED',
      condition: 'Severe Pre-Eclampsia (BP 160/110 mmHg, 3+ Proteinuria)',
      subcentre: 'SC Shahpur North',
      asha: 'Sunita Maurya',
      time: '12 min ago',
      slaMinutes: 15,
      slaRemaining: 3,
    },
    {
      id: 'ref-002',
      patient: 'Meena Devi',
      age: 21,
      gestation: '38 Weeks (G1P0)',
      severity: 'RED',
      condition: 'Prolonged 2nd Stage Labor (> 14 hrs, FHR 102 bpm decelerating)',
      subcentre: 'SC Dindaspur',
      asha: 'Rekha Devi',
      time: '28 min ago',
      slaMinutes: 30,
      slaRemaining: 2,
    },
    {
      id: 'ref-003',
      patient: 'Rani Kumari',
      age: 26,
      gestation: '28 Weeks (G3P2)',
      severity: 'YELLOW',
      condition: 'Severe Nutritional Anemia (Hb 6.8 g/dL, severe fatigue)',
      subcentre: 'SC Bhadwar',
      asha: 'Geeta Devi',
      time: '45 min ago',
      slaMinutes: 60,
      slaRemaining: 15,
    },
  ];

  // Sub-Centre Facility Network
  const subcentres = [
    { name: 'SC Shahpur North', anm: 'Kavita Kumari', pop: '9,420', highRisk: 4, ashaCount: 8, status: 'Optimal', stock: '94%' },
    { name: 'SC Dindaspur', anm: 'Anjali Sharma', pop: '8,850', highRisk: 3, ashaCount: 7, status: 'Optimal', stock: '91%' },
    { name: 'SC Bhadwar', anm: 'Pooja Verma', pop: '10,120', highRisk: 5, ashaCount: 9, status: 'Needs IFA', stock: '82%' },
    { name: 'SC Katesar', anm: 'Sunita Yadav', pop: '7,600', highRisk: 2, ashaCount: 6, status: 'Optimal', stock: '96%' },
    { name: 'SC Madhopur', anm: 'Rashmi Gupta', pop: '11,200', highRisk: 3, ashaCount: 8, status: 'Optimal', stock: '89%' },
    { name: 'SC Chitaipur', anm: 'Reena Patel', pop: '11,210', highRisk: 1, ashaCount: 6, status: 'Optimal', stock: '95%' },
  ];

  return (
    <div className="p-4 lg:p-8 space-y-6 max-w-7xl mx-auto">
      {/* 1. Executive Facility Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E]">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-xl lg:text-2xl font-bold tracking-tight text-[#0F172A] dark:text-white">
              PHC Shahpur Integrated Command Center
            </h1>
            <Badge variant="outline" className="text-xs text-slate-600 dark:text-slate-300 border-[#E5E7EB] dark:border-[#2E2E2E]">
              24x7 Emergency
            </Badge>
          </div>
          <p className="text-xs text-[#525252] dark:text-[#A3A3A3] mt-1">
            Varanasi District Health Catchment • Block Shahpur • Population Served: 58,400 across 6 Sub-Centres
          </p>
        </div>

        {/* Quick Action Buttons (Minimalist, white background, colored border) */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <Button
            size="sm"
            variant="destructive"
            onClick={() => navigate('/phc')}
            className="h-9 px-3.5 gap-1.5"
          >
            <Activity className="h-4 w-4" />
            <span>Doctor Emergency Triage (2 RED)</span>
          </Button>

          <Button
            size="sm"
            variant="outline"
            onClick={() => navigate('/map')}
            className="h-9 px-3 gap-1.5 text-slate-700 dark:text-slate-300"
          >
            <MapPin className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <span>Open Field GIS Map</span>
          </Button>
        </div>
      </div>

      {/* 2. Top Emergency Alert Banner (Minimalist: white background, clean red border) */}
      <div className="p-4 rounded-xl border border-rose-300 dark:border-rose-500/40 border-l-4 border-l-rose-500 bg-white dark:bg-[#222224] shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center space-x-3">
          <div className="h-8 w-8 shrink-0 rounded-lg bg-white dark:bg-[#222224] text-rose-600 dark:text-rose-400 flex items-center justify-center border border-rose-200 dark:border-rose-500/30">
            <AlertTriangle className="h-4 w-4" />
          </div>
          <div>
            <div className="text-xs font-bold text-[#0F172A] dark:text-white flex items-center gap-2">
              <span>CRITICAL RED TRIAGE ALERT</span>
              <span className="h-1.5 w-1.5 rounded-full bg-rose-500" />
            </div>
            <div className="text-xs text-[#525252] dark:text-[#A3A3A3]">
              2 high-risk maternal referrals awaiting clinical evaluation at PHC Emergency Desk. SLA limit: &lt; 15 mins.
            </div>
          </div>
        </div>
        <Button
          size="sm"
          variant="destructive"
          onClick={() => navigate('/phc')}
          className="text-xs shrink-0 font-semibold"
        >
          Review Clinical Queue &rarr;
        </Button>
      </div>

      {/* 3. Key Catchment KPIs (Minimalist: white background, subtle left border) */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3.5">
        {/* Red Triages */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-rose-500 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">Red Triages</div>
          <div className="text-xl font-bold text-rose-600 dark:text-rose-400 mt-1">2 Cases</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">SLA: &lt; 15m target</div>
        </div>

        {/* High Risk ANC */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-amber-500 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">High-Risk ANC</div>
          <div className="text-xl font-bold text-amber-600 dark:text-amber-400 mt-1">18 Monitored</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">Across 6 sub-centres</div>
        </div>

        {/* Active ASHAs */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-emerald-500 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">Active ASHAs</div>
          <div className="text-xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">42 / 44 Synced</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">95.5% field sync</div>
        </div>

        {/* Ward Bed Occupancy */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-slate-400 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">IPD Ward Beds</div>
          <div className="text-xl font-bold text-[#0F172A] dark:text-white mt-1">12 / 16 Beds</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">4 Available (75%)</div>
        </div>

        {/* Immunizations Due */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-teal-500 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">Immunizations Due</div>
          <div className="text-xl font-bold text-teal-600 dark:text-teal-400 mt-1">34 Children</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">MR-1 & Pentavalent</div>
        </div>

        {/* Claims Pending */}
        <div className="p-3.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] border-l-2 border-l-purple-500 bg-white dark:bg-[#222224] shadow-xs">
          <div className="text-[11px] font-semibold text-[#525252] dark:text-[#A3A3A3]">Incentive Claims</div>
          <div className="text-xl font-bold text-purple-600 dark:text-purple-400 mt-1">₹28,450</div>
          <div className="text-[10px] text-[#71717A] mt-0.5">14 pending signoff</div>
        </div>
      </div>

      {/* 4. Main Two-Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column (8 cols): Priority Emergencies & Sub-Centre Network */}
        <div className="lg:col-span-8 space-y-6">
          {/* Active Triage Snapshot */}
          <Card className="border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs rounded-xl overflow-hidden">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between">
              <div className="flex items-center space-x-2.5">
                <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-white dark:bg-[#222224] text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30">
                  <Activity className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-[#0F172A] dark:text-white">
                    Emergency Triage & Active Referral Cases
                  </h3>
                  <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3]">
                    Incoming obstetric, maternal, and pediatric referrals flagged by frontline ASHAs
                  </p>
                </div>
              </div>
              <Button
                size="sm"
                variant="outline"
                onClick={() => navigate('/phc')}
                className="text-xs h-7 px-2.5"
              >
                Open Triage Desk
              </Button>
            </div>

            <div className="divide-y divide-[#E5E7EB] dark:divide-[#2E2E2E]">
              {activeEmergencies.map((item) => (
                <div
                  key={item.id}
                  className="p-4 hover:bg-slate-50/60 dark:hover:bg-[#262626]/60 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-3"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold text-[#0F172A] dark:text-white">
                        {item.patient}
                      </span>
                      <span className="text-[11px] text-[#71717A]">({item.age}y • {item.gestation})</span>
                      <Badge
                        variant={item.severity === 'RED' ? 'destructive' : 'warning'}
                        className="text-[10px] px-2 py-0.2"
                      >
                        {item.severity} TRIAGE
                      </Badge>
                    </div>
                    <div className="text-xs text-[#0F172A] dark:text-slate-200 font-medium">
                      {item.condition}
                    </div>
                    <div className="text-[11px] text-[#525252] dark:text-[#A3A3A3] flex items-center gap-3">
                      <span>Sub-Centre: <strong className="text-[#0F172A] dark:text-slate-300">{item.subcentre}</strong></span>
                      <span>•</span>
                      <span>ASHA: <strong>{item.asha}</strong></span>
                      <span>•</span>
                      <span className="flex items-center gap-1 text-rose-600 dark:text-rose-400 font-medium">
                        <Clock className="h-3 w-3" />
                        SLA Remaining: {item.slaRemaining}m
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 self-end md:self-center">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => navigate('/phc')}
                      className="h-8 px-3 text-xs border-[#E5E7EB] dark:border-[#2E2E2E] hover:border-slate-400 font-medium rounded-lg"
                    >
                      Consult & Prescribe
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          {/* Sub-Centres Catchment Status */}
          <Card className="border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs rounded-xl overflow-hidden">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between">
              <div>
                <h3 className="text-sm font-bold text-[#0F172A] dark:text-white">
                  Catchment Sub-Centre Facility Performance
                </h3>
                <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3]">
                  Status of 6 attached Health & Wellness Centres (Sub-Centres) under PHC Shahpur
                </p>
              </div>
              <Button
                size="sm"
                variant="outline"
                onClick={() => navigate('/anm')}
                className="text-xs h-7 px-2.5"
              >
                ANM Workspaces
              </Button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] text-[#525252] dark:text-[#A3A3A3] font-semibold">
                    <th className="py-2.5 px-3">Sub-Centre Name</th>
                    <th className="py-2.5 px-3">ANM In-Charge</th>
                    <th className="py-2.5 px-3">Population</th>
                    <th className="py-2.5 px-3">High-Risk ANC</th>
                    <th className="py-2.5 px-3">Active ASHAs</th>
                    <th className="py-2.5 px-3">Medicine Stock</th>
                    <th className="py-2.5 px-3">Field Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB] dark:divide-[#2E2E2E]">
                  {subcentres.map((sc) => (
                    <tr key={sc.name} className="hover:bg-slate-50/50 dark:hover:bg-[#262626]/50">
                      <td className="py-2.5 px-3 font-semibold text-[#0F172A] dark:text-white">{sc.name}</td>
                      <td className="py-2.5 px-3 text-[#525252] dark:text-[#A3A3A3]">{sc.anm}</td>
                      <td className="py-2.5 px-3 font-mono text-[#525252] dark:text-[#A3A3A3]">{sc.pop}</td>
                      <td className="py-2.5 px-3">
                        <span className="font-semibold text-amber-600 dark:text-amber-400">{sc.highRisk} ANC</span>
                      </td>
                      <td className="py-2.5 px-3 text-[#525252] dark:text-[#A3A3A3]">{sc.ashaCount} ASHAs</td>
                      <td className="py-2.5 px-3 font-mono font-medium">{sc.stock}</td>
                      <td className="py-2.5 px-3">
                        <Badge
                          variant="outline"
                          className="text-[10px] text-slate-700 dark:text-slate-300 border-[#E5E7EB] dark:border-[#2E2E2E]"
                        >
                          {sc.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>

        {/* Right Column (4 cols): GIS Catchment Preview & Offline Sync Feed */}
        <div className="lg:col-span-4 space-y-6">
          {/* Catchment GIS Field Map Card */}
          <Card className="border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs rounded-xl overflow-hidden">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E]">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <MapPin className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                  <h3 className="text-xs font-bold uppercase tracking-wider text-[#0F172A] dark:text-white">
                    Catchment GIS Map & Ambulance GPS
                  </h3>
                </div>
                <Badge variant="outline" className="text-[9px] text-slate-600 dark:text-slate-400 border-[#E5E7EB] dark:border-[#2E2E2E]">
                  Live GPS
                </Badge>
              </div>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1">
                Real-time tracking of PHC, 6 Sub-Centres, 108 BLS Ambulance, and village coordinates
              </p>
            </div>

            <div className="p-4 space-y-3">
              {/* Mini Map Visual Card (Minimalist: clean surface, delicate border) */}
              <div
                onClick={() => navigate('/map')}
                className="relative h-44 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] overflow-hidden cursor-pointer group flex flex-col justify-between p-3.5 hover:border-slate-400 dark:hover:border-slate-500 transition-colors"
              >
                <div className="flex items-center justify-between z-10">
                  <span className="text-[10px] font-medium px-2 py-0.5 rounded bg-slate-50 dark:bg-[#222224] text-[#0F172A] dark:text-white border border-[#E5E7EB] dark:border-[#2E2E2E]">
                    Varanasi Rural: 25.3176° N, 82.9739° E
                  </span>
                  <span className="text-[10px] font-mono text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-[#222224] px-1.5 py-0.5 rounded border border-[#E5E7EB] dark:border-[#2E2E2E]">
                    OsmAnd
                  </span>
                </div>

                {/* Tactical pin representation */}
                <div className="my-auto flex flex-col items-center justify-center space-y-1 text-center">
                  <div className="flex items-center justify-center h-9 w-9 rounded-full bg-white dark:bg-[#222224] text-emerald-600 dark:text-emerald-400 border border-emerald-300 dark:border-emerald-500/40 group-hover:scale-105 transition-transform">
                    <MapPin className="h-4 w-4" />
                  </div>
                  <span className="text-xs font-semibold text-[#0F172A] dark:text-white">
                    Open Full OsmAnd Tactical Map
                  </span>
                  <span className="text-[10px] text-[#525252] dark:text-[#A3A3A3]">
                    6 Sub-Centres • 42 Field Pins • 1 Ambulance En Route
                  </span>
                </div>

                <div className="flex items-center justify-between text-[10px] text-[#71717A] z-10">
                  <span>Ambulance BLS-04: ETA 8m</span>
                  <span className="text-slate-700 dark:text-slate-300 font-semibold group-hover:underline flex items-center gap-0.5">
                    Launch Interactive Map &rarr;
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => navigate('/map')}
                  className="h-8 text-[11px] border-[#E5E7EB] dark:border-[#2E2E2E]"
                >
                  <MapPin className="h-3.5 w-3.5 mr-1 text-[#71717A]" />
                  Catchment Map
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => navigate('/heatmap')}
                  className="h-8 text-[11px] border-[#E5E7EB] dark:border-[#2E2E2E]"
                >
                  <TrendingUp className="h-3.5 w-3.5 mr-1 text-[#71717A]" />
                  PCMC Heatmap
                </Button>
              </div>
            </div>
          </Card>

          {/* Offline Sync & ABDM Status */}
          <Card className="border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs rounded-xl overflow-hidden">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Radio className="h-4 w-4 text-slate-700 dark:text-slate-300" />
                <h3 className="text-xs font-bold uppercase tracking-wider text-[#0F172A] dark:text-white">
                  Frontline Sync & Telephony Feed
                </h3>
              </div>
              <span className="text-[10px] font-mono text-emerald-600 dark:text-emerald-400">
                Online
              </span>
            </div>

            <div className="p-4 space-y-3 text-xs">
              <div className="flex items-start space-x-2.5 pb-2.5 border-b border-[#E5E7EB] dark:border-[#2E2E2E]">
                <div className="h-1.5 w-1.5 rounded-full bg-emerald-500 mt-1.5 shrink-0" />
                <div>
                  <div className="font-semibold text-[#0F172A] dark:text-white text-[11px]">
                    SMS Gateway: Referral Broadcast Received
                  </div>
                  <div className="text-[10px] text-[#525252] dark:text-[#A3A3A3]">
                    Emergency SMS parsed for patient Sunita Devi via ASHA phone +91-9876543210
                  </div>
                  <span className="text-[9px] text-[#71717A]">4 mins ago</span>
                </div>
              </div>

              <div className="flex items-start space-x-2.5 pb-2.5 border-b border-[#E5E7EB] dark:border-[#2E2E2E]">
                <div className="h-1.5 w-1.5 rounded-full bg-emerald-500 mt-1.5 shrink-0" />
                <div>
                  <div className="font-semibold text-[#0F172A] dark:text-white text-[11px]">
                    Cold-Chain ILR Refrigerator Monitoring
                  </div>
                  <div className="text-[10px] text-[#525252] dark:text-[#A3A3A3]">
                    Storage temperature stable at 4.2°C (Acceptable range 2°C - 8°C)
                  </div>
                  <span className="text-[9px] text-[#71717A]">18 mins ago</span>
                </div>
              </div>

              <div className="flex items-start space-x-2.5">
                <div className="h-1.5 w-1.5 rounded-full bg-slate-400 mt-1.5 shrink-0" />
                <div>
                  <div className="font-semibold text-[#0F172A] dark:text-white text-[11px]">
                    ABDM HIU Health Records Pull
                  </div>
                  <div className="text-[10px] text-[#525252] dark:text-[#A3A3A3]">
                    Previous antenatal blood test lab reports synced for 3 patients
                  </div>
                  <span className="text-[9px] text-[#71717A]">35 mins ago</span>
                </div>
              </div>
            </div>
          </Card>
        </div>
      </div>

      {/* 5. Role-Based Workspaces Launchpad (Minimalist: white cards, clean neutral icon boxes) */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-sm font-bold uppercase tracking-wider text-[#0F172A] dark:text-white">
              Health System Workspaces & Portals
            </h2>
            <p className="text-xs text-[#525252] dark:text-[#A3A3A3]">
              Direct access to clinical, frontline, analytics, and administrative management desks
            </p>
          </div>
          <Badge variant="outline" className="text-xs border-[#E5E7EB] dark:border-[#2E2E2E]">
            All 8 Portals Active
          </Badge>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {/* 1. Doctor Triage Desk */}
          <NavLink
            to="/phc"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <Stethoscope className="h-4 w-4" />
                </div>
                <Badge variant="destructive" className="text-[10px] px-1.5">
                  2 RED
                </Badge>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                PHC Doctor Clinical Desk
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Emergency triage, clinical outcomes, digital prescriptions & ABDM records.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Desk</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 2. ANM Workspace */}
          <NavLink
            to="/anm"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <FileCheck2 className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">Sub-Centre</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                ANM / Sub-Centre Register
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                MCH register, ANC line-listing, immunization sessions & ASHA claim signoff.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Workspace</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 3. ASHA Facilitator Desk */}
          <NavLink
            to="/af"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <Users className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">Field Sync</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                ASHA Supervision Desk
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Track 42 ASHAs in field, resolve sync conflicts & inspect village home visits.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Desk</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 4. OsmAnd GIS Map */}
          <NavLink
            to="/map"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <MapPin className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">GPS Live</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                OsmAnd Catchment Map
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Full-screen field GIS map, offline tiles, patient clusters & 108 GPS dispatch.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Full Map</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 5. PCMC Outbreak Heatmap */}
          <NavLink
            to="/heatmap"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <Layers className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">Surveillance</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                PCMC Outbreak Heatmap
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Ward-wise diarrhea, dengue & high-risk maternal cluster density analysis.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>View Heatmap</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 6. Drug & Ward Bed Inventory */}
          <NavLink
            to="/resources"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <Package className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">12/16 Beds</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                Drug Stock & Bed Desk
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Real-time stock of oxytocin, IFA tablets, magnesium sulfate & bed occupancy.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>View Inventory</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 7. District Analytics */}
          <NavLink
            to="/district"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <BarChart3 className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">Analytics</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                District Health Command
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                CMO block-level rankings, maternal mortality index & institutional deliveries.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Analytics</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>

          {/* 8. State Admin Console */}
          <NavLink
            to="/admin"
            className="p-4 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex flex-col justify-between group shadow-xs"
          >
            <div>
              <div className="flex items-center justify-between mb-2.5">
                <div className="p-2 rounded-lg bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E] group-hover:border-slate-400">
                  <ShieldCheck className="h-4 w-4" />
                </div>
                <span className="text-[10px] font-mono text-[#71717A]">Admin</span>
              </div>
              <h4 className="text-xs font-bold text-[#0F172A] dark:text-white group-hover:text-slate-900 dark:group-hover:text-white transition-colors">
                State Admin Console
              </h4>
              <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3] mt-1 line-clamp-2">
                Master user roster CSV bulk upload, facility mappings & security access keys.
              </p>
            </div>
            <div className="text-[11px] font-semibold text-slate-600 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-white mt-3 flex items-center justify-between">
              <span>Open Console</span>
              <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
            </div>
          </NavLink>
        </div>
      </div>
    </div>
  );
}
