import { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { AuthUser, UserRole } from '@/types';

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
  loginWithCredentials: (username: string, password: string, roleOverride?: UserRole) => { success: boolean; error?: string };
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

  useEffect(() => {
    if (user) {
      localStorage.setItem('asha_role', role);
      const updated = { ...DEFAULT_USERS[role], ...(user.name ? { name: user.name } : {}) };
      setUser(updated);
      localStorage.setItem('asha_user', JSON.stringify(updated));
    }
  }, [role]);

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

  const loginWithCredentials = (username: string, password: string, roleOverride?: UserRole) => {
    const trimmedUser = username.trim().toLowerCase();
    const match = DEMO_CREDENTIALS.find((c) => c.username.toLowerCase() === trimmedUser);

    if (match) {
      if (match.password !== password) {
        return { success: false, error: 'Incorrect password. Please check your credentials.' };
      }
      const targetRole = roleOverride || match.role;
      const baseUser = DEFAULT_USERS[targetRole];
      const newUser: AuthUser = {
        ...baseUser,
        name: match.name,
        token: `jwt-${targetRole.toLowerCase()}-${Date.now()}`,
      };
      setRole(targetRole);
      setUser(newUser);
      localStorage.setItem('asha_role', targetRole);
      localStorage.setItem('asha_auth_token', newUser.token!);
      localStorage.setItem('asha_user', JSON.stringify(newUser));
      return { success: true };
    }

    // Generic username verification
    if (!username.trim()) {
      return { success: false, error: 'Please enter a valid username.' };
    }
    if (!password || password.length < 4) {
      return { success: false, error: 'Password must be at least 4 characters.' };
    }

    const targetRole = roleOverride || 'PHC_MO';
    const baseUser = DEFAULT_USERS[targetRole];
    const newUser: AuthUser = {
      ...baseUser,
      name: username.trim(),
      token: `jwt-custom-${Date.now()}`,
    };
    setRole(targetRole);
    setUser(newUser);
    localStorage.setItem('asha_role', targetRole);
    localStorage.setItem('asha_auth_token', newUser.token!);
    localStorage.setItem('asha_user', JSON.stringify(newUser));
    return { success: true };
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
