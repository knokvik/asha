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
  PhoneCall,
  Info,
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
      {/* 1. Official Government of India Top Banner */}
      <div>
        {/* Tricolor Ribbon */}
        <div className="h-1.5 w-full flex">
          <div className="h-full w-1/3 bg-[#FF9933]" />
          <div className="h-full w-1/3 bg-white" />
          <div className="h-full w-1/3 bg-[#138808]" />
        </div>

        {/* Government Header Bar */}
        <header className="flex h-18 shrink-0 items-center justify-between border-b border-[#E5EAE7] dark:border-[#26262A] bg-white dark:bg-[#18181B] px-6 lg:px-12">
          {/* Left: National Emblem & NHM / ABDM Info */}
          <div className="flex items-center space-x-3.5">
            {/* National Emblem SVG Representation */}
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#F0FAF5] dark:bg-[#132A20] border border-[#D1EFE2] dark:border-[#1E4334] text-[#0C5A3E] dark:text-[#34D399]">
              <svg viewBox="0 0 24 24" className="h-6 w-6" fill="currentColor">
                <path d="M12 2L4 5v6.09c0 5.05 3.41 9.76 8 10.91 4.59-1.15 8-5.86 8-10.91V5l-8-3zm1 14.93V18h-2v-1.07A6.99 6.99 0 0 1 6.07 13H7v-2H5.07A7.008 7.008 0 0 1 11 5.07V6h2v-.93A7.008 7.008 0 0 1 18.93 11H17v2h1.93A6.99 6.99 0 0 1 13 16.93zM12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z" />
              </svg>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-base font-extrabold text-slate-900 dark:text-white tracking-tight">
                  राष्ट्रीय स्वास्थ्य मिशन • National Health Mission
                </span>
                <Badge variant="outline" className="text-[10px] text-emerald-800 dark:text-emerald-300 bg-emerald-50 dark:bg-emerald-950/40 border-emerald-200 dark:border-emerald-800">
                  Govt. of India
                </Badge>
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                Ministry of Health & Family Welfare • Government of Uttar Pradesh Catchment
              </div>
            </div>
          </div>

          {/* Right: Security & Helpdesk Pill */}
          <div className="hidden sm:flex items-center space-x-4">
            <div className="flex items-center space-x-2 text-xs text-slate-600 dark:text-slate-300 bg-slate-50 dark:bg-[#202024] px-3 py-1.5 rounded-full border border-slate-200 dark:border-[#2E2E34]">
              <PhoneCall className="h-3.5 w-3.5 text-emerald-700 dark:text-emerald-400" />
              <span>National Toll Free: <strong>104 / 14477</strong></span>
            </div>
            <div className="flex items-center space-x-1 text-xs text-slate-500 dark:text-slate-400">
              <span className="h-2 w-2 rounded-full bg-emerald-500" />
              <span>SSL Secure (TLS 1.3)</span>
            </div>
          </div>
        </header>
      </div>

      {/* 2. Main Login Body */}
      <main className="flex-1 flex items-center justify-center p-4 lg:p-8">
        <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Left Column: Official Credential Card */}
          <div className="lg:col-span-7">
            <Card className="border border-[#E5EAE7] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] shadow-md rounded-2xl overflow-hidden">
              <CardHeader className="p-5 pb-3 border-b border-slate-100 dark:border-[#2E2E2E] bg-[#FAFCFA] dark:bg-[#17171A]">
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-lg font-bold text-slate-900 dark:text-white">
                      Role-Based Portal Access
                    </CardTitle>
                    <CardDescription className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      National Health Portal (NHM) Single Sign-On (SSO) & ABHA Authentication
                    </CardDescription>
                  </div>
                  <div className="p-2 rounded-xl bg-[#EBF7F2] dark:bg-[#132A20] text-[#0C5A3E] dark:text-[#34D399] border border-[#D5EFE3] dark:border-[#1E4334]">
                    <ShieldCheck className="h-5 w-5" />
                  </div>
                </div>

              </CardHeader>

              <CardContent className="p-5 pt-4 space-y-3.5">
                {error && (
                  <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/40 text-rose-700 dark:text-rose-400 text-xs">
                    <AlertCircle className="h-4 w-4 shrink-0 text-rose-600 dark:text-rose-400" />
                    <span>{error}</span>
                  </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-3">
                  {/* Username / ABHA Input */}
                  <div className="space-y-1">
                    <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                      <span className="flex items-center gap-1.5">
                        <User className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
                        <span>Registered User ID / ABHA Address / Mobile</span>
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

                  {/* Password Input */}
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

                  {/* Hidden Role Select for form compatibility */}
                  <input type="hidden" name="role" value={selectedRole} />

                  {/* Government Visual CAPTCHA */}
                  <div className="space-y-1 pt-1">
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
                    className="w-full h-11 text-xs rounded-xl shadow-xs flex items-center justify-center gap-2 mt-3 font-bold bg-[#0C5A3E] hover:bg-[#08422E] text-white cursor-pointer"
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

