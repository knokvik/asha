import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth, DEMO_CREDENTIALS, CredentialAccount } from '@/shared/hooks/useAuth';
import { UserRole } from '@/types';
import {
  Lock,
  User,
  ShieldCheck,
  Stethoscope,
  FileCheck2,
  Users,
  BarChart3,
  ArrowRight,
  AlertCircle,
  Building2,
  CheckCircle2,
  RotateCw,
  Info,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';

const ROLE_ICONS: Record<UserRole, any> = {
  PHC_MO: Stethoscope,
  ANM: FileCheck2,
  AF: Users,
  DISTRICT_OFFICER: BarChart3,
  STATE_ADMIN: ShieldCheck,
};

const ROLE_TABS: { role: UserRole; label: string; short: string; defaultUser: string }[] = [
  { role: 'PHC_MO', label: 'PHC Medical Officer', short: 'Doctor', defaultUser: 'doctor' },
  { role: 'ANM', label: 'ANM / CHO Sub-Centre', short: 'ANM', defaultUser: 'anm' },
  { role: 'AF', label: 'ASHA Facilitator (AF)', short: 'Facilitator', defaultUser: 'af' },
  { role: 'DISTRICT_OFFICER', label: 'District Health Officer', short: 'CMO Desk', defaultUser: 'dho' },
  { role: 'STATE_ADMIN', label: 'State Administrator', short: 'Admin', defaultUser: 'admin' },
];

function generateCaptcha(): string {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  let str = '';
  for (let i = 0; i < 5; i++) {
    str += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return str;
}

export function LoginPage() {
  const navigate = useNavigate();
  const { loginWithCredentials } = useAuth();

  const [username, setUsername] = useState('doctor');
  const [password, setPassword] = useState('doctor123');
  const [selectedRole, setSelectedRole] = useState<UserRole>('PHC_MO');
  const [selectedCatchment, setSelectedCatchment] = useState('delhi-aerocity');
  const [captchaCode, setCaptchaCode] = useState('8K4X2');
  const [captchaInput, setCaptchaInput] = useState('8K4X2');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const code = generateCaptcha();
    setCaptchaCode(code);
    setCaptchaInput(code); // Pre-filled for effortless login convenience
  }, [selectedRole]);

  const handleRefreshCaptcha = () => {
    const code = generateCaptcha();
    setCaptchaCode(code);
    setCaptchaInput('');
  };

  const handleRoleTabChange = (role: UserRole) => {
    setSelectedRole(role);
    const demo = DEMO_CREDENTIALS.find((c) => c.role === role);
    if (demo) {
      setUsername(demo.username);
      setPassword(demo.password);
    }
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Verify Captcha (case-insensitive check)
    if (captchaInput.trim().toUpperCase() !== captchaCode.toUpperCase()) {
      setError('Invalid CAPTCHA code. Please enter the characters shown in the image.');
      handleRefreshCaptcha();
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await loginWithCredentials(username, password, selectedRole);
      if (result.success) {
        localStorage.setItem('asha_catchment', selectedCatchment);
        navigate('/dashboard');
      } else {
        setError(result.error || 'Authentication failed. Please verify credentials.');
        setIsSubmitting(false);
        handleRefreshCaptcha();
      }
    } catch (err: any) {
      setError(err?.message || 'Server connection error during authentication.');
      setIsSubmitting(false);
      handleRefreshCaptcha();
    }
  };

  const handleQuickLogin = async (demo: CredentialAccount) => {
    setUsername(demo.username);
    setPassword(demo.password);
    setSelectedRole(demo.role);
    setError(null);
    setIsSubmitting(true);

    try {
      const result = await loginWithCredentials(demo.username, demo.password, demo.role);
      if (result.success) {
        navigate('/dashboard');
      } else {
        setError(result.error || 'Server rejected credentials.');
        setIsSubmitting(false);
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to connect to authentication server.');
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-between bg-[#F8FAF9] dark:bg-[#121214] text-slate-900 dark:text-slate-100 font-sans antialiased">
      {/* Main Login Body */}
      <main className="flex-1 flex items-center justify-center p-4 lg:p-8">
        <div className="w-full max-w-md">
          {/* Official Credential Card */}
          <Card className="border border-[#E5EAE7] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] shadow-md rounded-2xl overflow-hidden">
            {/* Header: ASHA Logo -> Title */}
            <div className="p-6 pb-4 border-b border-slate-100 dark:border-[#2E2E2E] bg-[#FAFCFA] dark:bg-[#17171A] text-center flex flex-col items-center">
              {/* Official ASHA Logo */}
              <div className="mb-3 flex items-center justify-center">
                <img
                  src="/asha_logo.jpg"
                  alt="Asha Logo"
                  className="h-16 w-auto object-contain rounded-lg shadow-xs"
                />
              </div>

              {/* Title & Subtitle */}
              <CardTitle className="text-xl font-bold text-slate-900 dark:text-white tracking-tight">
                Asha Portal Login
              </CardTitle>
              <CardDescription className="text-xs text-slate-500 dark:text-slate-400 mt-1 max-w-xs mx-auto">
                National Health Mission (NHM) • Single Sign-On & Healthcare Command Center
              </CardDescription>
            </div>

            <CardContent className="p-6 pt-5 space-y-4">
              {error && (
                <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/40 text-rose-700 dark:text-rose-400 text-xs">
                  <AlertCircle className="h-4 w-4 shrink-0 text-rose-600 dark:text-rose-400" />
                  <span>{error}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-3.5">
                {/* Field 1: Role Selection */}
                <div className="space-y-1">
                  <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                    <span className="flex items-center gap-1.5">
                      <ShieldCheck className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
                      <span>Select Portal Role</span>
                    </span>
                    <span className="text-[10px] text-emerald-700 dark:text-emerald-400 font-medium">RBAC Access</span>
                  </label>
                  <select
                    value={selectedRole}
                    onChange={(e) => handleRoleTabChange(e.target.value as UserRole)}
                    className="w-full h-10 px-3 text-xs bg-[#FBFDFB] dark:bg-[#17171A] border border-slate-300 dark:border-[#2E2E2E] rounded-md text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#0C5A3E] cursor-pointer"
                  >
                    {ROLE_TABS.map((tab) => (
                      <option key={tab.role} value={tab.role}>
                        {tab.label} ({tab.short})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                    <Building2 className="h-3.5 w-3.5 text-slate-500" />
                    <span>Service catchment</span>
                  </label>
                  <select
                    value={selectedCatchment}
                    onChange={(e) => setSelectedCatchment(e.target.value)}
                    className="w-full h-10 px-3 text-xs bg-[#FBFDFB] dark:bg-[#17171A] border border-slate-300 dark:border-[#2E2E2E] rounded-md text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#0C5A3E] cursor-pointer"
                  >
                    <option value="delhi-aerocity">Delhi • IGI Airport / Aerocity catchment</option>
                    <option value="varanasi-shahpur">Varanasi • Shahpur catchment</option>
                  </select>
                </div>

                {/* Field 2: Username / ABHA Input */}
                <div className="space-y-1">
                  <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                    <span className="flex items-center gap-1.5">
                      <User className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
                      <span>Registered User ID / ABHA Address</span>
                    </span>
                    <span className="text-[10px] text-emerald-800 dark:text-emerald-400 font-medium">ABDM Linked</span>
                  </label>
                  <Input
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="e.g. doctor, anm, af, dho, admin"
                    required
                    className="h-10 text-xs bg-[#FBFDFB] dark:bg-[#17171A] border-slate-300 dark:border-[#2E2E2E] text-slate-900 dark:text-white focus-visible:ring-[#0C5A3E]"
                  />
                </div>

                {/* Field 3: Password Input */}
                <div className="space-y-1">
                  <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                    <span className="flex items-center gap-1.5">
                      <Lock className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
                      <span>Password</span>
                    </span>
                    <a href="#forgot" onClick={(e) => e.preventDefault()} className="text-[10px] text-[#0C5A3E] dark:text-[#34D399] hover:underline">
                      Forgot Password?
                    </a>
                  </label>
                  <Input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter account password"
                    required
                    className="h-10 text-xs bg-[#FBFDFB] dark:bg-[#17171A] border-slate-300 dark:border-[#2E2E2E] text-slate-900 dark:text-white focus-visible:ring-[#0C5A3E]"
                  />
                </div>

                {/* Field 4: Government Visual CAPTCHA */}
                <div className="space-y-1 pt-0.5">
                  <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                    <span>Government Security CAPTCHA</span>
                    <span className="text-[10px] text-slate-500 dark:text-slate-400">Case-insensitive</span>
                  </label>
                  <div className="flex items-center gap-3">
                    {/* Stylized Distortion Captcha Box */}
                    <div className="relative h-10 px-4 bg-[#EDF4F0] dark:bg-[#142A1F] border-2 border-slate-300 dark:border-[#1E4334] rounded-lg flex items-center justify-center select-none overflow-hidden shrink-0">
                      {/* Captcha Background Noise Lines */}
                      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30" viewBox="0 0 120 40">
                        <line x1="0" y1="10" x2="120" y2="30" stroke="#0C5A3E" strokeWidth="1.5" />
                        <line x1="10" y1="35" x2="110" y2="5" stroke="#E11D48" strokeWidth="1.2" />
                        <circle cx="30" cy="20" r="12" fill="none" stroke="#D97706" strokeWidth="1" />
                        <circle cx="85" cy="18" r="10" fill="none" stroke="#2563EB" strokeWidth="1" />
                      </svg>
                      {/* Distorted letters */}
                      <span className="font-mono text-base font-black tracking-widest text-[#0C5A3E] dark:text-[#34D399] skew-x-6 relative z-10">
                        {captchaCode}
                      </span>
                    </div>

                    {/* Refresh Captcha Button */}
                    <button
                      type="button"
                      onClick={handleRefreshCaptcha}
                      className="p-2 rounded-lg border border-slate-200 dark:border-[#2E2E2E] text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-[#2A2A2E] hover:text-slate-900 dark:hover:text-white transition-colors shrink-0 cursor-pointer"
                      title="Generate New CAPTCHA"
                    >
                      <RotateCw className="h-4 w-4" />
                    </button>

                    {/* Captcha Text Input */}
                    <Input
                      type="text"
                      value={captchaInput}
                      onChange={(e) => setCaptchaInput(e.target.value)}
                      placeholder="Enter CAPTCHA"
                      required
                      className="h-10 text-xs bg-[#FBFDFB] dark:bg-[#17171A] border-slate-300 dark:border-[#2E2E2E] text-slate-900 dark:text-white uppercase tracking-wider font-mono flex-1 focus-visible:ring-[#0C5A3E]"
                    />
                  </div>
                </div>

                {/* Submit Button */}
                <Button
                  type="submit"
                  variant="default"
                  disabled={isSubmitting}
                  className="w-full h-11 text-xs rounded-xl shadow-xs flex items-center justify-center gap-2 mt-4 font-bold bg-[#0C5A3E] hover:bg-[#08422E] text-white cursor-pointer"
                >
                  <span>Authenticate & Open Command Center</span>
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </form>

              {/* Statutory Warning & Compliance Notice */}
              <div className="pt-2.5 border-t border-slate-100 dark:border-[#2E2E2E] text-[10px] text-slate-500 dark:text-slate-400 space-y-1">
                <div className="flex items-center justify-between text-slate-600 dark:text-slate-300">
                  <span className="flex items-center gap-1">
                    <CheckCircle2 className="h-3 w-3 text-emerald-600 dark:text-emerald-400" />
                    <span>DPDP Act 2023 Compliant</span>
                  </span>
                  <span>ABDM Gateway • HIU / HIP Ready</span>
                </div>
                <p className="text-slate-400 dark:text-slate-500 leading-tight">
                  Warning: Unauthorized access to this Government healthcare network is punishable under Sections 43 & 66 of the Information Technology Act, 2000.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>

      {/* 3. Official Footer */}
      <footer className="border-t border-[#E5EAE7] dark:border-[#26262A] bg-white dark:bg-[#18181B] py-3 px-6 text-center text-xs text-slate-500 dark:text-slate-400 space-y-0.5">
        <div>
          ASHA Setu Healthcare Information System • National Health Mission (NHM) • Ministry of Health & Family Welfare
        </div>
        <div className="text-[10px] text-slate-400 dark:text-slate-500">
          Designed in compliance with ABDM Standards, EHR 2016 Guidelines & DPDP Act 2023.
        </div>
      </footer>
    </div>
  );
}

