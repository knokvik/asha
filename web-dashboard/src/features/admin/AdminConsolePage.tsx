import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
  getAdminUsers,
  bulkUploadUsers,
  getOtaDeploymentMetrics,
} from '@/shared/api/adminApi';
import {
  ShieldCheck,
  Users,
  Upload,
  CheckCircle2,
  FileCode,
  Smartphone,
  CheckSquare,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export function AdminConsolePage() {
  const [activeTab, setActiveTab] = useState<'users' | 'ota_health' | 'setup_checklist' | 'config_rollout'>('users');
  const [csvText, setCsvText] = useState('');
  const [uploadResult, setUploadResult] = useState<string | null>(null);

  const { data: users = [] } = useQuery({
    queryKey: ['admin-users'],
    queryFn: getAdminUsers,
  });

  const { data: otaMetrics } = useQuery({
    queryKey: ['admin-ota-metrics'],
    queryFn: getOtaDeploymentMetrics,
  });

  const bulkMutation = useMutation({
    mutationFn: (content: string) => bulkUploadUsers(content),
    onSuccess: (data) => {
      setUploadResult(`Successfully parsed & enrolled ${data.count} frontline health workers!`);
      setCsvText('');
      setTimeout(() => setUploadResult(null), 3500);
    },
  });

  return (
    <div className="p-4 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Banner */}
      <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center space-x-3.5">
            <div className="p-3 rounded-xl bg-purple-500/10 dark:bg-purple-500/15 border border-purple-500/20 text-purple-600 dark:text-purple-400">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
                State & Platform Administration Console (Requirement 43)
              </h1>
              <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
                State Admin: Priyanka Sen • State: Uttar Pradesh • User Hierarchy, OTA Deployment & Setup Checklist
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="px-4 py-2 rounded-xl border border-purple-200 dark:border-purple-500/30 bg-purple-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-purple-700 dark:text-purple-300 font-semibold uppercase">Total Workers</div>
              <div className="text-lg font-bold text-[#0F172A] dark:text-white">{users.length} Active Staff</div>
            </div>
            <div className="px-4 py-2 rounded-xl border border-emerald-200 dark:border-emerald-500/30 bg-emerald-50/50 dark:bg-[#1E1E1E]">
              <div className="text-[10px] text-emerald-700 dark:text-emerald-400 font-semibold uppercase">Latest Release</div>
              <div className="text-lg font-bold text-emerald-700 dark:text-emerald-400">{otaMetrics?.latestVersion || 'v2.4.1'}</div>
            </div>
          </div>
        </div>
      </Card>

      {/* Tabs */}
      <div className="flex items-center space-x-2 border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-2">
        <button
          onClick={() => setActiveTab('users')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'users'
              ? 'bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <Users className="w-4 h-4 text-purple-600 dark:text-purple-400" />
          <span>User Directory & Bulk Onboarding (Req 43.1)</span>
        </button>
        <button
          onClick={() => setActiveTab('ota_health')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'ota_health'
              ? 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <Smartphone className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
          <span>OTA Deployment Health (Req 43.5)</span>
        </button>
        <button
          onClick={() => setActiveTab('config_rollout')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'config_rollout'
              ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <FileCode className="w-4 h-4 text-amber-600 dark:text-amber-400" />
          <span>Config Versioning & Staged Rollout (Req 43.3, 43.4)</span>
        </button>
        <button
          onClick={() => setActiveTab('setup_checklist')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'setup_checklist'
              ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/30'
              : 'text-[#525252] dark:text-[#A3A3A3] hover:text-[#0F172A] dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#2A2A2A]'
          }`}
        >
          <CheckSquare className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>State Deployment Checklist (Req 43.6)</span>
        </button>
      </div>

      {/* Tab: Config Versioning & Staged Rollout (Req 43.3, 43.4) */}
      {activeTab === 'config_rollout' && (
        <div className="space-y-4">
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-3 shadow-xs">
            <h2 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
              <FileCode className="w-4 h-4 text-amber-600 dark:text-amber-400" />
              Dynamic Clinical Protocols, Schedules & Tariff Artefacts (OTA)
            </h2>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              Update clinical rules, form definitions, and state incentive rates without APK re-releases. Staged rollout delivers changes targeted by percentage or district with zero-downtime rollback.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
              {[
                { name: 'HBNC Visit Protocol & Schedules', version: 'v3.2.0', target: '100% Full State', status: 'active', updated: 'Yesterday' },
                { name: 'State Incentive Tariff Matrix (UP)', version: 'v2.4.1', target: '100% Full State', status: 'active', updated: '3 days ago' },
                { name: 'Experimental AI Lung Sound ASR Rule', version: 'v1.1.0-canary', target: '10% Pilot Block', status: 'staged', updated: '2 hours ago' },
              ].map((item, idx) => (
                <div key={idx} className="p-4 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] space-y-2.5">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs text-amber-600 dark:text-amber-300 font-bold">{item.version}</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-semibold uppercase border ${
                      item.status === 'active' ? 'bg-emerald-50 dark:bg-emerald-500/20 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-500/30' : 'bg-amber-50 dark:bg-amber-500/20 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-500/30'
                    }`}>
                      {item.status}
                    </span>
                  </div>
                  <div className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">{item.name}</div>
                  <div className="text-[11px] text-[#525252] dark:text-[#94A3B8]">Rollout Scope: <strong className="text-[#0F172A] dark:text-[#F8FAFC]">{item.target}</strong></div>
                  <div className="pt-2 border-t border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between">
                    <span className="text-[10px] text-[#71717A]">Updated {item.updated}</span>
                    <button
                      onClick={() => alert(`Initiating safe rollback of ${item.name} to prior stable version...`)}
                      className="px-2 py-1 rounded bg-rose-50 dark:bg-rose-500/20 hover:bg-rose-100 dark:hover:bg-rose-500/30 text-rose-700 dark:text-rose-300 text-[10px] font-semibold transition-all cursor-pointer border border-rose-200 dark:border-rose-500/30"
                    >
                      Rollback (Req 43.3)
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

      {/* Tab 1: User Directory & Bulk CSV Upload */}
      {activeTab === 'users' && (
        <div className="space-y-6">
          {/* Bulk Onboarding Box */}
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-3 shadow-xs">
            <h2 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
              <Upload className="w-4 h-4 text-purple-600 dark:text-purple-400" />
              Bulk Frontline Worker Onboarding via CSV / Excel (Req 43.1)
            </h2>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
              Paste CSV records: <code className="text-purple-700 dark:text-purple-300 font-mono bg-purple-50 dark:bg-purple-950/40 px-1 py-0.5 rounded">name,role,phone,block,subcentre</code> to automatically create secure accounts and assign geographic jurisdictions.
            </p>
            <div className="space-y-2">
              <textarea
                rows={3}
                value={csvText}
                onChange={(e) => setCsvText(e.target.value)}
                placeholder="Sunita Kumari,ASHA,+919811199988,Shahpur,SC Rampur&#10;Kamla Devi,ASHA,+919811199989,Shahpur,SC Kalyanpur"
                className="w-full p-3 rounded-xl bg-slate-50 dark:bg-[#181818] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#0F172A] dark:text-[#F8FAFC] font-mono focus:outline-none focus:ring-1 focus:ring-purple-500 placeholder-[#71717A]"
              />
              <div className="flex items-center justify-between">
                {uploadResult ? (
                  <span className="text-xs text-emerald-600 dark:text-emerald-400 flex items-center gap-1 font-semibold">
                    <CheckCircle2 className="w-4 h-4" /> {uploadResult}
                  </span>
                ) : <span />}
                <Button
                  disabled={!csvText.trim() || bulkMutation.isPending}
                  onClick={() => bulkMutation.mutate(csvText)}
                  className="bg-purple-600 hover:bg-purple-700 text-white font-semibold text-xs gap-1.5"
                >
                  <Upload className="w-3.5 h-3.5" />
                  <span>{bulkMutation.isPending ? 'Enrolling...' : 'Process Bulk Enrollment'}</span>
                </Button>
              </div>
            </div>
          </Card>

          {/* User List Table */}
          <Card className="rounded-2xl border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] overflow-hidden shadow-xs">
            <div className="p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between">
              <h3 className="font-bold text-[#0F172A] dark:text-[#F8FAFC] text-sm">Enrolled Health Workers ({users.length})</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-[#1E1E1E] border-b border-[#E5E7EB] dark:border-[#2E2E2E] text-[#525252] dark:text-[#94A3B8] uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="p-3.5">Name</th>
                    <th className="p-3.5">Role</th>
                    <th className="p-3.5">Phone Number</th>
                    <th className="p-3.5">Block / Sub-centre</th>
                    <th className="p-3.5">App Version</th>
                    <th className="p-3.5">Last Sync</th>
                    <th className="p-3.5 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB] dark:divide-[#2E2E2E] text-[#0F172A] dark:text-[#F8FAFC]">
                  {users.map((u) => (
                    <tr key={u.id} className="hover:bg-slate-50 dark:hover:bg-[#2A2A2A]/40 transition-colors">
                      <td className="p-3.5 font-bold">{u.name}</td>
                      <td className="p-3.5">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-purple-50 dark:bg-purple-500/20 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-500/30 font-mono">
                          {u.role}
                        </span>
                      </td>
                      <td className="p-3.5 font-mono text-[#525252] dark:text-[#94A3B8]">{u.phone}</td>
                      <td className="p-3.5">
                        {u.block} {u.subcentre && <span className="text-[#71717A]">({u.subcentre})</span>}
                      </td>
                      <td className="p-3.5 font-mono text-[#525252] dark:text-[#94A3B8]">{u.appVersion || 'v2.4.1'}</td>
                      <td className="p-3.5 text-emerald-600 dark:text-emerald-400">{u.lastSyncAt || 'Live'}</td>
                      <td className="p-3.5 text-right">
                        <span className="text-emerald-600 dark:text-emerald-400 font-semibold uppercase text-[10px]">
                          {u.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>
      )}

      {/* Tab 2: OTA Deployment Health (Req 43.5) */}
      {activeTab === 'ota_health' && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Active Mobile Devices</div>
            <div className="text-3xl font-extrabold text-[#0F172A] dark:text-white">{otaMetrics?.activeDevicesCount}</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">Enrolled frontline Android devices in field.</p>
          </Card>
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Version Adoption</div>
            <div className="text-3xl font-extrabold text-emerald-600 dark:text-emerald-400">{otaMetrics?.versionAdoptionPct}%</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">Running current release {otaMetrics?.latestVersion}.</p>
          </Card>
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Sync Success Rate</div>
            <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">{otaMetrics?.syncSuccessRatePct}%</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">Over last 24 hours (zero data loss).</p>
          </Card>
          <Card className="p-5 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-2 shadow-xs">
            <div className="text-xs text-[#525252] dark:text-[#94A3B8]">Storage Warnings</div>
            <div className="text-3xl font-extrabold text-amber-600 dark:text-amber-400">{otaMetrics?.storageWarningCount}</div>
            <p className="text-xs text-[#525252] dark:text-[#94A3B8]">Devices with &lt; 500MB free storage space.</p>
          </Card>
        </div>
      )}

      {/* Tab 3: State Deployment Setup Checklist (Req 43.6) */}
      {activeTab === 'setup_checklist' && (
        <Card className="p-6 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] space-y-4 max-w-2xl shadow-xs">
          <h2 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
            <CheckSquare className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
            State-Setup Onboarding Checklist (Requirement 43.6)
          </h2>
          <p className="text-xs text-[#525252] dark:text-[#94A3B8]">
            Self-service deployment configuration for launching in a new state or district without engineering intervention.
          </p>

          <div className="space-y-3 pt-2">
            {[
              { title: 'Regional Languages Configured', desc: '12 Indian regional language ARB translations verified (Hindi, Bhojpuri, Maithili, etc.)', checked: true },
              { title: 'State Incentive Catalogue Loaded', desc: 'Loaded state health department incentive tariffs with effective date versioning', checked: true },
              { title: 'Facility Hierarchy & GIS Mapped', desc: 'PHC, Sub-centre, Village, and Hamlet codes mapped to administrative boundaries', checked: true },
              { title: 'ABDM Health Facility Registry (HFR) Linked', desc: 'Facility IDs verified against National Health Authority ABDM gateway', checked: true },
              { title: 'Government Portal Integrations Active', desc: 'U-WIN, Ni-kshay, and HMIS monthly indicator export templates configured', checked: true },
            ].map((item, idx) => (
              <div key={idx} className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#2E2E2E] flex items-start space-x-3">
                <CheckCircle2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
                <div>
                  <div className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">{item.title}</div>
                  <div className="text-[11px] text-[#525252] dark:text-[#94A3B8]">{item.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
