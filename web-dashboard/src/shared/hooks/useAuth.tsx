import { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { AuthUser, UserRole } from '@/types';
import { apiClient } from '@/shared/api/client';

export interface CredentialAccount {
  username: string;
  password: string;
  role: UserRole;
  name: string;
  facility: string;
  designation: string;
}

export const DEMO_CREDENTIALS: CredentialAccount[] = [
  {
    username: 'doctor',
    password: 'doctor123',
    role: 'PHC_MO',
    name: 'Dr. Alok Verma',
    facility: 'PHC Shahpur (24x7 Emergency)',
    designation: 'Medical Officer In-Charge',
  },
  {
    username: 'anm',
    password: 'anm123',
    role: 'ANM',
    name: 'Kavita Kumari',
    facility: 'Sub-Centre Shahpur North',
    designation: 'Auxiliary Nurse Midwife / CHO',
  },
  {
    username: 'af',
    password: 'af123',
    role: 'AF',
    name: 'Sarita Singh',
    facility: 'Shahpur Block Health Unit',
    designation: 'ASHA Facilitator (Field Supervisor)',
  },
  {
    username: 'dho',
    password: 'dho123',
    role: 'DISTRICT_OFFICER',
    name: 'Dr. Rajesh Pandey (CMO)',
    facility: 'District Health Command (Varanasi)',
    designation: 'Chief Medical Officer / DHO',
  },
  {
    username: 'admin',
    password: 'admin123',
    role: 'STATE_ADMIN',
    name: 'Priyanka Sen',
    facility: 'State Health Mission Directorate',
    designation: 'State Health Systems Administrator',
  },
];

interface AuthContextType {
  user: AuthUser | null;
  role: UserRole;
  isAuthenticated: boolean;
  login: (role: UserRole, name?: string) => void;
  loginWithCredentials: (username: string, password: string, roleOverride?: UserRole) => Promise<{ success: boolean; error?: string }>;
  logout: () => void;
  switchRole: (newRole: UserRole) => void;
}

const DEFAULT_USERS: Record<UserRole, AuthUser> = {
  AF: {
    id: 'af-01',
    name: 'Sarita Singh',
    role: 'AF',
    stateCode: 'UP',
    districtCode: 'DIST_01',
    blockCode: 'BLOCK_SHAHPUR',
  },
  ANM: {
    id: 'anm-01',
    name: 'Kavita Kumari',
    role: 'ANM',
    stateCode: 'UP',
    subcentreId: 'sc-shahpur',
    phcId: 'phc-shahpur',
  },
  PHC_MO: {
    id: 'mo-01',
    name: 'Dr. Alok Verma',
    role: 'PHC_MO',
    stateCode: 'UP',
    phcId: 'phc-shahpur',
  },
  DISTRICT_OFFICER: {
    id: 'dho-01',
    name: 'Dr. Rajesh Pandey (CMO)',
    role: 'DISTRICT_OFFICER',
    stateCode: 'UP',
    districtCode: 'DIST_01',
  },
  STATE_ADMIN: {
    id: 'admin-01',
    name: 'Priyanka Sen',
    role: 'STATE_ADMIN',
    stateCode: 'UP',
  },
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [role, setRole] = useState<UserRole>(() => {
    return (localStorage.getItem('asha_role') as UserRole) || 'PHC_MO';
  });

  const [user, setUser] = useState<AuthUser | null>(() => {
    const saved = localStorage.getItem('asha_user');
    if (saved) {
      try { return JSON.parse(saved); } catch {}
    }
    return DEFAULT_USERS[role] || DEFAULT_USERS.PHC_MO;
  });

  // Verify stored session with live backend on startup
  useEffect(() => {
    const token = localStorage.getItem('asha_auth_token');
    if (!token) return;

    apiClient
      .get('/auth/me')
      .then((res) => {
        if (res.data) {
          const freshUser: AuthUser = {
            id: res.data.id,
            name: res.data.name,
            role: res.data.role as UserRole,
            stateCode: res.data.stateCode || 'UP',
            districtCode: res.data.districtCode,
            blockCode: res.data.blockCode,
            subcentreId: res.data.subcentreId,
            phcId: res.data.phcId,
            token,
          };
          setUser(freshUser);
          setRole(freshUser.role);
          localStorage.setItem('asha_role', freshUser.role);
          localStorage.setItem('asha_user', JSON.stringify(freshUser));
        }
      })
      .catch(() => {
        // Stored token was rejected by server or server offline
      });
  }, []);

  const login = (selectedRole: UserRole, name?: string) => {
    const newUser = {
      ...DEFAULT_USERS[selectedRole],
      name: name || DEFAULT_USERS[selectedRole].name,
      token: `demo-jwt-${Date.now()}`,
    };
    setRole(selectedRole);
    setUser(newUser);
    localStorage.setItem('asha_role', selectedRole);
    localStorage.setItem('asha_auth_token', newUser.token);
    localStorage.setItem('asha_user', JSON.stringify(newUser));
  };

  const loginWithCredentials = async (
    username: string,
    password: string,
    roleOverride?: UserRole
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      // 1. Authenticate with real server endpoint
      const res = await apiClient.post('/auth/login', {
        username: username.trim(),
        password,
        device_id: 'web-dashboard',
      });

      const token = res.data?.access_token;
      if (!token) {
        return { success: false, error: 'Server did not return an access token.' };
      }

      localStorage.setItem('asha_auth_token', token);

      // 2. Fetch authenticated profile from server
      let userInfo: AuthUser;
      try {
        const meRes = await apiClient.get('/auth/me', {
          headers: { Authorization: `Bearer ${token}` },
        });
        userInfo = {
          id: meRes.data.id,
          name: meRes.data.name,
          role: (meRes.data.role as UserRole) || roleOverride || 'PHC_MO',
          stateCode: meRes.data.stateCode || 'UP',
          districtCode: meRes.data.districtCode,
          blockCode: meRes.data.blockCode,
          subcentreId: meRes.data.subcentreId,
          phcId: meRes.data.phcId,
          token,
        };
      } catch {
        userInfo = {
          id: res.data.worker_id || 'user-1',
          name: res.data.name || username,
          role: (res.data.role as UserRole) || roleOverride || 'PHC_MO',
          stateCode: 'UP',
          token,
        };
      }

      setRole(userInfo.role);
      setUser(userInfo);
      localStorage.setItem('asha_role', userInfo.role);
      localStorage.setItem('asha_user', JSON.stringify(userInfo));
      return { success: true };
    } catch (err: any) {
      const errorMsg =
        err.response?.data?.detail ||
        err.message ||
        'Authentication failed. Please verify your credentials.';
      return { success: false, error: errorMsg };
    }
  };

  const logout = () => {
    localStorage.removeItem('asha_auth_token');
    localStorage.removeItem('asha_user');
    setUser(null);
  };

  const switchRole = (newRole: UserRole) => {
    setRole(newRole);
    const switchedUser = DEFAULT_USERS[newRole];
    setUser(switchedUser);
    localStorage.setItem('asha_role', newRole);
    localStorage.setItem('asha_user', JSON.stringify(switchedUser));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        role,
        isAuthenticated: !!user,
        login,
        loginWithCredentials,
        logout,
        switchRole,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
