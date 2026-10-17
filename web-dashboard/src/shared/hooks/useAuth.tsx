import { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { AuthUser, UserRole } from '@/types';

interface AuthContextType {
  user: AuthUser | null;
  role: UserRole;
  isAuthenticated: boolean;
  login: (role: UserRole, name?: string) => void;
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
    return DEFAULT_USERS[role];
  });

  useEffect(() => {
    localStorage.setItem('asha_role', role);
    const updated = { ...DEFAULT_USERS[role], ...(user?.name ? { name: user.name } : {}) };
    setUser(updated);
    localStorage.setItem('asha_user', JSON.stringify(updated));
  }, [role]);

  const login = (selectedRole: UserRole, name?: string) => {
    const newUser = {
      ...DEFAULT_USERS[selectedRole],
      name: name || DEFAULT_USERS[selectedRole].name,
      token: `demo-jwt-${Date.now()}`,
    };
    setRole(selectedRole);
    setUser(newUser);
    localStorage.setItem('asha_auth_token', newUser.token);
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
    localStorage.setItem('asha_user', JSON.stringify(switchedUser));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        role,
        isAuthenticated: !!user,
        login,
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
