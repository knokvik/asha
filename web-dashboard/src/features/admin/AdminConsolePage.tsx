import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
  getAdminUsers,
  bulkUploadUsers,
  getOtaDeploymentMetrics,
  AdminUserRecord,
} from '@/shared/api/adminApi';
import {
  ShieldCheck,
  Users,
  Upload,
  CheckCircle2,
  FileCode,
  Smartphone,
  CheckSquare,
  Radio,
  RefreshCw,
  Search,
} from 'lucide-react';

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
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 glass-panel p-6 rounded-2xl border border-slate-800">
        <div className="flex items-center space-x-3">
          <div className="p-2.5 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-white flex items-center gap-2">
              State & Platform Administration Console (Requirement 43)
            </h1>
            <p className="text-xs text-slate-400">
              State Admin: Priyanka Sen • State: Uttar Pradesh • User Hierarchy, OTA Deployment & Setup Checklist
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="glass-card px-4 py-2 rounded-xl border border-purple-500/30">
            <div className="text-[10px] text-purple-300 font-semibold uppercase">Total Workers</div>
            <div className="text-lg font-bold text-white">{users.length} Active Staff</div>
          </div>
          <div className="glass-card px-4 py-2 rounded-xl border border-emerald-500/30">
            <div className="text-[10px] text-emerald-300 font-semibold uppercase">Latest Release</div>
            <div className="text-lg font-bold text-emerald-400">{otaMetrics?.latestVersion || 'v2.4.1'}</div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center space-x-2 border-b border-slate-800 pb-2">
        <button
          onClick={() => setActiveTab('users')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'users'
              ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>User Directory & Bulk Onboarding (Req 43.1)</span>
        </button>
        <button
          onClick={() => setActiveTab('ota_health')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'ota_health'
              ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <Smartphone className="w-4 h-4" />
          <span>OTA Deployment Health (Req 43.5)</span>
        </button>
        <button
          onClick={() => setActiveTab('config_rollout')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'config_rollout'
              ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <FileCode className="w-4 h-4" />
          <span>Config Versioning & Staged Rollout (Req 43.3, 43.4)</span>
        </button>
        <button
          onClick={() => setActiveTab('setup_checklist')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeTab === 'setup_checklist'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
          }`}
        >
          <CheckSquare className="w-4 h-4" />
          <span>State Deployment Checklist (Req 43.6)</span>
        </button>
      </div>

      {/* Tab: Config Versioning & Staged Rollout (Req 43.3, 43.4) */}
      {activeTab === 'config_rollout' && (
        <div className="space-y-4">
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <h2 className="text-sm font-bold text-white flex items-center gap-2">
              <FileCode className="w-4 h-4 text-amber-400" />
              Dynamic Clinical Protocols, Schedules & Tariff Artefacts (OTA)
            </h2>
            <p className="text-xs text-slate-400">
              Update clinical rules, form definitions, and state incentive rates without APK re-releases. Staged rollout delivers changes targeted by percentage or district with zero-downtime rollback.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
              {[
                { name: 'HBNC Visit Protocol & Schedules', version: 'v3.2.0', target: '100% Full State', status: 'active', updated: 'Yesterday' },
                { name: 'State Incentive Tariff Matrix (UP)', version: 'v2.4.1', target: '100% Full State', status: 'active', updated: '3 days ago' },
                { name: 'Experimental AI Lung Sound ASR Rule', version: 'v1.1.0-canary', target: '10% Pilot Block', status: 'staged', updated: '2 hours ago' },
              ].map((item, idx) => (
                <div key={idx} className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2.5">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs text-amber-300 font-bold">{item.version}</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-semibold uppercase ${
                      item.status === 'active' ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                    }`}>
                      {item.status}
                    </span>
                  </div>
                  <div className="text-xs font-bold text-white">{item.name}</div>
                  <div className="text-[11px] text-slate-400">Rollout Scope: <strong className="text-slate-200">{item.target}</strong></div>
                  <div className="pt-2 border-t border-slate-800 flex items-center justify-between">
                    <span className="text-[10px] text-slate-500">Updated {item.updated}</span>
                    <button
                      onClick={() => alert(`Initiating safe rollback of ${item.name} to prior stable version...`)}
                      className="px-2 py-1 rounded bg-rose-500/20 hover:bg-rose-500/30 text-rose-300 text-[10px] font-semibold transition-all"
                    >
                      Rollback (Req 43.3)
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Tab 1: User Directory & Bulk CSV Upload */}
      {activeTab === 'users' && (
        <div className="space-y-6">
          {/* Bulk Onboarding Box */}
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-3">
            <h2 className="text-sm font-bold text-white flex items-center gap-2">
              <Upload className="w-4 h-4 text-purple-400" />
              Bulk Frontline Worker Onboarding via CSV / Excel (Req 43.1)
            </h2>
            <p className="text-xs text-slate-400">
              Paste CSV records: <code className="text-purple-300">name,role,phone,block,subcentre</code> to automatically create secure accounts and assign geographic jurisdictions.
            </p>
            <div className="space-y-2">
              <textarea
                rows={3}
                value={csvText}
                onChange={(e) => setCsvText(e.target.value)}
                placeholder="Sunita Kumari,ASHA,+919811199988,Shahpur,SC Rampur&#10;Kamla Devi,ASHA,+919811199989,Shahpur,SC Kalyanpur"
                className="w-full p-3 rounded-xl bg-slate-900 border border-slate-700 text-xs text-slate-200 font-mono focus:outline-none focus:border-purple-500"
              />
              <div className="flex items-center justify-between">
                {uploadResult ? (
                  <span className="text-xs text-emerald-400 flex items-center gap-1 font-semibold">
                    <CheckCircle2 className="w-4 h-4" /> {uploadResult}
                  </span>
                ) : <span />}
                <button
                  disabled={!csvText.trim() || bulkMutation.isPending}
                  onClick={() => bulkMutation.mutate(csvText)}
                  className="px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-semibold shadow-lg shadow-purple-600/30 disabled:opacity-50 flex items-center gap-1.5"
                >
                  <Upload className="w-3.5 h-3.5" />
                  <span>{bulkMutation.isPending ? 'Enrolling...' : 'Process Bulk Enrollment'}</span>
                </button>
              </div>
            </div>
          </div>

          {/* User List Table */}
          <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden">
            <div className="p-4 border-b border-slate-800 flex items-center justify-between">
              <h3 className="font-bold text-white text-sm">Enrolled Health Workers ({users.length})</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-900/80 border-b border-slate-800 text-slate-400 uppercase text-[10px] tracking-wider">
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
                <tbody className="divide-y divide-slate-800/60 text-slate-300">
                  {users.map((u) => (
                    <tr key={u.id} className="hover:bg-slate-800/30">
                      <td className="p-3.5 font-bold text-white">{u.name}</td>
                      <td className="p-3.5">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-purple-500/20 text-purple-300 border border-purple-500/30 font-mono">
                          {u.role}
                        </span>
                      </td>
                      <td className="p-3.5 font-mono text-slate-400">{u.phone}</td>
                      <td className="p-3.5">
                        {u.block} {u.subcentre && <span className="text-slate-500">({u.subcentre})</span>}
                      </td>
                      <td className="p-3.5 font-mono text-slate-400">{u.appVersion || 'v2.4.1'}</td>
                      <td className="p-3.5 text-emerald-400">{u.lastSyncAt || 'Live'}</td>
                      <td className="p-3.5 text-right">
                        <span className="text-emerald-400 font-semibold uppercase text-[10px]">
                          {u.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: OTA Deployment Health (Req 43.5) */}
      {activeTab === 'ota_health' && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Active Mobile Devices</div>
            <div className="text-3xl font-extrabold text-white">{otaMetrics?.activeDevicesCount}</div>
            <p className="text-xs text-slate-400">Enrolled frontline Android devices in field.</p>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Version Adoption</div>
            <div className="text-3xl font-extrabold text-emerald-400">{otaMetrics?.versionAdoptionPct}%</div>
            <p className="text-xs text-slate-400">Running current release {otaMetrics?.latestVersion}.</p>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Sync Success Rate</div>
            <div className="text-3xl font-extrabold text-indigo-400">{otaMetrics?.syncSuccessRatePct}%</div>
            <p className="text-xs text-slate-400">Over last 24 hours (zero data loss).</p>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-slate-800 space-y-2">
            <div className="text-xs text-slate-400">Storage Warnings</div>
            <div className="text-3xl font-extrabold text-amber-400">{otaMetrics?.storageWarningCount}</div>
            <p className="text-xs text-slate-400">Devices with &lt; 500MB free storage space.</p>
          </div>
        </div>
      )}

      {/* Tab 3: State Deployment Setup Checklist (Req 43.6) */}
      {activeTab === 'setup_checklist' && (
        <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-4 max-w-2xl">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <CheckSquare className="w-5 h-5 text-emerald-400" />
            State-Setup Onboarding Checklist (Requirement 43.6)
          </h2>
          <p className="text-xs text-slate-400">
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
              <div key={idx} className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 flex items-start space-x-3">
                <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
                <div>
                  <div className="text-xs font-bold text-white">{item.title}</div>
                  <div className="text-[11px] text-slate-400">{item.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
