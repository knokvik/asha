import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth, DEMO_CREDENTIALS, CredentialAccount } from '@/shared/hooks/useAuth';
import { useTheme } from '@/shared/hooks/useTheme';
import { UserRole } from '@/types';
import {
  HeartPulse,
  Lock,
  User,
  ShieldCheck,
  Stethoscope,
  FileCheck2,
  Users,
  BarChart3,
  Sun,
  Moon,
  ArrowRight,
  AlertCircle,
  KeyRound,
  Building2,
  CheckCircle2,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const ROLE_ICONS: Record<UserRole, any> = {
  PHC_MO: Stethoscope,
  ANM: FileCheck2,
  AF: Users,
  DISTRICT_OFFICER: BarChart3,
  STATE_ADMIN: ShieldCheck,
};

export function LoginPage() {
  const navigate = useNavigate();
  const { loginWithCredentials } = useAuth();
  const { theme, toggleTheme } = useTheme();

  const [username, setUsername] = useState('doctor');
  const [password, setPassword] = useState('doctor123');
  const [selectedRole, setSelectedRole] = useState<UserRole>('PHC_MO');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    const result = loginWithCredentials(username, password, selectedRole);
    if (result.success) {
      navigate('/dashboard');
    } else {
      setError(result.error || 'Authentication failed. Please verify credentials.');
      setIsSubmitting(false);
    }
  };

  const handleQuickLogin = (demo: CredentialAccount) => {
    setUsername(demo.username);
    setPassword(demo.password);
    setSelectedRole(demo.role);
    setError(null);

    const result = loginWithCredentials(demo.username, demo.password, demo.role);
    if (result.success) {
      navigate('/dashboard');
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-between bg-slate-50 dark:bg-[#1E1E1E] text-[#0F172A] dark:text-[#F8FAFC] transition-colors duration-200">
      {/* Top Header Bar */}
      <header className="flex h-16 shrink-0 items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] px-6 lg:px-12">
        <div className="flex items-center space-x-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] text-slate-800 dark:text-white shadow-xs">
            <HeartPulse className="h-5 w-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-sm font-bold text-[#0F172A] dark:text-white">
                ASHA Setu • Frontline Health Command
              </span>
              <Badge variant="outline" className="text-[10px] text-slate-600 dark:text-slate-400 border-[#E5E7EB] dark:border-[#2E2E2E]">
                NHM Portal
              </Badge>
            </div>
            <div className="text-[11px] text-[#525252] dark:text-[#A3A3A3]">
              National Health Mission • Ministry of Health & Family Welfare
            </div>
          </div>
        </div>

        <Button
          size="sm"
          variant="outline"
          onClick={toggleTheme}
          className="h-8 px-3 text-xs gap-1.5 border-[#E5E7EB] dark:border-[#2E2E2E]"
        >
          {theme === 'dark' ? (
            <>
              <Sun className="h-3.5 w-3.5 text-amber-400" />
              <span>Light Mode</span>
            </>
          ) : (
            <>
              <Moon className="h-3.5 w-3.5 text-slate-700" />
              <span>Dark Mode</span>
            </>
          )}
        </Button>
      </header>

      {/* Main Login Body */}
      <main className="flex-1 flex items-center justify-center p-4 lg:p-10">
        <div className="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left Form: Credential Login Card */}
          <div className="lg:col-span-7">
            <Card className="border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-xs rounded-2xl overflow-hidden">
              <CardHeader className="p-6 pb-4">
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-xl font-bold text-[#0F172A] dark:text-white">
                      Role-Based Portal Access
                    </CardTitle>
                    <CardDescription className="text-xs text-[#525252] dark:text-[#A3A3A3] mt-1">
                      Sign in with your government NHM healthcare credentials
                    </CardDescription>
                  </div>
                  <div className="p-2 rounded-xl bg-white dark:bg-[#1E1E1E] text-slate-700 dark:text-slate-300 border border-[#E5E7EB] dark:border-[#2E2E2E]">
                    <KeyRound className="h-5 w-5" />
                  </div>
                </div>
              </CardHeader>

              <CardContent className="p-6 pt-2 space-y-4">
                {error && (
                  <div className="flex items-center gap-2 p-3 rounded-xl bg-white dark:bg-[#222224] border border-rose-300 dark:border-rose-500/40 text-rose-600 dark:text-rose-400 text-xs">
                    <AlertCircle className="h-4 w-4 shrink-0" />
                    <span>{error}</span>
                  </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-4">
                  {/* Username Field */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-[#0F172A] dark:text-slate-200 flex items-center gap-1.5">
                      <User className="h-3.5 w-3.5 text-[#71717A]" />
                      <span>Username / Mobile / ABDM ID</span>
                    </label>
                    <Input
                      type="text"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="e.g. doctor, anm, af, dho, admin"
                      required
                      className="h-10 text-xs bg-white dark:bg-[#1E1E1E] border-[#E5E7EB] dark:border-[#3F3F46] focus-visible:ring-slate-400"
                    />
                  </div>

                  {/* Password Field */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-[#0F172A] dark:text-slate-200 flex items-center gap-1.5">
                      <Lock className="h-3.5 w-3.5 text-[#71717A]" />
                      <span>Password</span>
                    </label>
                    <Input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Enter account password"
                      required
                      className="h-10 text-xs bg-white dark:bg-[#1E1E1E] border-[#E5E7EB] dark:border-[#3F3F46] focus-visible:ring-slate-400"
                    />
                  </div>

                  {/* Target Role Selector */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-[#0F172A] dark:text-slate-200 flex items-center gap-1.5">
                      <Building2 className="h-3.5 w-3.5 text-[#71717A]" />
                      <span>Access Role Level</span>
                    </label>
                    <select
                      value={selectedRole}
                      onChange={(e) => setSelectedRole(e.target.value as UserRole)}
                      className="w-full h-10 rounded-xl px-3 text-xs bg-white dark:bg-[#1E1E1E] border border-[#E5E7EB] dark:border-[#3F3F46] text-[#0F172A] dark:text-white focus:outline-none focus:ring-1 focus:ring-slate-400"
                    >
                      <option value="PHC_MO">PHC Medical Officer (Doctor Triage & Consults)</option>
                      <option value="ANM">ANM / CHO Sub-Centre (Maternal & Child Register)</option>
                      <option value="AF">ASHA Facilitator (Field Supervision & Sync Desk)</option>
                      <option value="DISTRICT_OFFICER">District Health Officer / CMO (District Analytics)</option>
                      <option value="STATE_ADMIN">State Administrator (Roster & Security Config)</option>
                    </select>
                  </div>

                  {/* Submit Button */}
                  <Button
                    type="submit"
                    variant="default"
                    disabled={isSubmitting}
                    className="w-full h-11 text-xs rounded-xl shadow-xs flex items-center justify-center gap-2 mt-2 font-semibold"
                  >
                    <span>Authenticate & Open Command Center</span>
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                </form>

                <div className="pt-3 border-t border-[#E5E7EB] dark:border-[#2E2E2E] flex items-center justify-between text-[11px] text-[#71717A]">
                  <span className="flex items-center gap-1">
                    <CheckCircle2 className="h-3.5 w-3.5 text-slate-600 dark:text-slate-400" />
                    <span>DPDP Act 2023 Compliant</span>
                  </span>
                  <span>256-bit TLS Encrypted Session</span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Right Column: Demo 1-Click Role Accounts */}
          <div className="lg:col-span-5 space-y-4">
            <div className="p-4 rounded-2xl bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] shadow-xs">
              <div className="flex items-center justify-between mb-3 pb-2 border-b border-[#E5E7EB] dark:border-[#2E2E2E]">
                <div>
                  <h4 className="text-xs font-bold uppercase tracking-wider text-[#0F172A] dark:text-white">
                    Quick-Login Demo Accounts
                  </h4>
                  <p className="text-[11px] text-[#525252] dark:text-[#A3A3A3]">
                    Click any role to test instant authenticated access
                  </p>
                </div>
                <Badge variant="outline" className="text-[9px] border-[#E5E7EB] dark:border-[#2E2E2E] text-slate-700 dark:text-slate-300">
                  5 Roles
                </Badge>
              </div>

              <div className="space-y-2">
                {DEMO_CREDENTIALS.map((demo) => {
                  const Icon = ROLE_ICONS[demo.role];
                  return (
                    <button
                      key={demo.role}
                      type="button"
                      onClick={() => handleQuickLogin(demo)}
                      className="w-full text-left p-2.5 rounded-xl border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] hover:border-slate-400 dark:hover:border-slate-500 transition-all flex items-center justify-between group"
                    >
                      <div className="flex items-center space-x-2.5 min-w-0">
                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] text-slate-700 dark:text-slate-300 group-hover:text-slate-900 dark:group-hover:text-white">
                          <Icon className="h-4 w-4" />
                        </div>
                        <div className="truncate">
                          <div className="text-xs font-bold text-[#0F172A] dark:text-white flex items-center gap-1.5 truncate">
                            <span>{demo.name}</span>
                            <span className="text-[9px] font-mono px-1.5 py-0.2 rounded bg-slate-100 dark:bg-[#2E2E2E] text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-[#383838]">
                              {demo.username}
                            </span>
                          </div>
                          <div className="text-[10px] text-[#525252] dark:text-[#A3A3A3] truncate">
                            {demo.designation}
                          </div>
                        </div>
                      </div>
                      <span className="text-slate-600 dark:text-slate-400 text-xs font-semibold shrink-0 ml-2 group-hover:text-slate-900 dark:group-hover:text-white group-hover:translate-x-0.5 transition-transform">
                        Login &rarr;
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Verification & Security Notice */}
            <div className="p-3.5 rounded-2xl bg-white dark:bg-[#222224] border border-[#E5E7EB] dark:border-[#2E2E2E] text-xs text-[#525252] dark:text-[#A3A3A3] space-y-1.5">
              <div className="text-[11px] font-bold text-[#0F172A] dark:text-white flex items-center gap-1.5">
                <ShieldCheck className="h-3.5 w-3.5 text-slate-600 dark:text-slate-400" />
                <span>Health System Verification</span>
              </div>
              <p className="text-[11px] leading-relaxed">
                All roles maintain end-to-end visibility across clinical desks, sub-centre registers, ASHA field syncs, and GIS maps with audit logs.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] py-3 px-6 text-center text-xs text-[#71717A]">
        ASHA Setu Healthcare Information System • Government of India • Ministry of Health & Family Welfare
      </footer>
    </div>
  );
}
