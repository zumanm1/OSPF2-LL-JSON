/**
 * Auth Wrapper Component
 * Blocks access to the application until user is authenticated
 * Shows loading spinner during auth initialization
 * Shows login screen when not authenticated
 * Enforces password change when required
 */

import React, { ReactNode, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import LoginScreen from './LoginScreen';
import ChangePasswordModal from './ChangePasswordModal';
import { Shield, AlertTriangle, Key } from 'lucide-react';

interface AuthWrapperProps {
  children: ReactNode;
}

const AuthWrapper: React.FC<AuthWrapperProps> = ({ children }) => {
  const { isAuthenticated, isLoading, user, changePassword } = useAuth();
  const { theme } = useTheme();
  const isDark = theme === 'dark';
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [changePasswordError, setChangePasswordError] = useState('');

  // Show loading screen while checking auth status
  if (isLoading) {
    return (
      <div className={`min-h-screen flex items-center justify-center ${isDark ? 'bg-gray-900' : 'bg-gray-100'}`}>
        <div className="text-center">
          <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 ${isDark ? 'bg-emerald-900/50' : 'bg-emerald-100'}`}>
            <Shield className={`w-8 h-8 ${isDark ? 'text-emerald-400' : 'text-emerald-600'}`} />
          </div>
          <div className="flex items-center justify-center gap-2 mb-2">
            <div className="w-5 h-5 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
            <span className={`${isDark ? 'text-gray-300' : 'text-gray-700'}`}>
              Initializing...
            </span>
          </div>
          <p className={`text-sm ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>
            Checking authentication status
          </p>
        </div>
      </div>
    );
  }

  // Show login screen if not authenticated
  if (!isAuthenticated) {
    return <LoginScreen />;
  }

  // Check if account is expired
  if (user?.isExpired) {
    return (
      <div className={`min-h-screen flex items-center justify-center ${isDark ? 'bg-gray-900' : 'bg-gray-100'}`}>
        <div className={`max-w-md p-8 rounded-xl shadow-2xl ${isDark ? 'bg-gray-800' : 'bg-white'}`}>
          <div className="text-center">
            <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 ${isDark ? 'bg-red-900/50' : 'bg-red-100'}`}>
              <Shield className={`w-8 h-8 ${isDark ? 'text-red-400' : 'text-red-600'}`} />
            </div>
            <h1 className={`text-2xl font-bold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              Account Expired
            </h1>
            <p className={`mb-6 ${isDark ? 'text-gray-400' : 'text-gray-600'}`}>
              Your account has reached the maximum number of uses ({user.maxUses}).
              Please contact an administrator to reset your usage counter.
            </p>
            <button
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Force password change when grace logins exhausted
  if (user?.forcePasswordChange) {
    return (
      <div className={`min-h-screen flex items-center justify-center ${isDark ? 'bg-gray-900' : 'bg-gray-100'}`}>
        <div className={`max-w-md p-8 rounded-xl shadow-2xl ${isDark ? 'bg-gray-800' : 'bg-white'}`}>
          <div className="text-center">
            <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 ${isDark ? 'bg-amber-900/50' : 'bg-amber-100'}`}>
              <Key className={`w-8 h-8 ${isDark ? 'text-amber-400' : 'text-amber-600'}`} />
            </div>
            <h1 className={`text-2xl font-bold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              Password Change Required
            </h1>
            <p className={`mb-6 ${isDark ? 'text-gray-400' : 'text-gray-600'}`}>
              You must change your password to continue using NetViz Pro.
              This is required for security purposes.
            </p>

            {changePasswordError && (
              <div className="mb-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-sm">
                {changePasswordError}
              </div>
            )}

            <button
              onClick={() => setShowChangePassword(true)}
              className="px-6 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-medium"
            >
              Change Password Now
            </button>
          </div>
        </div>

        {showChangePassword && (
          <ChangePasswordModal
            onClose={() => setShowChangePassword(false)}
            onSuccess={() => {
              setShowChangePassword(false);
              setChangePasswordError('');
            }}
          />
        )}
      </div>
    );
  }

  // User is authenticated - render the app with optional password warning
  return (
    <>
      {/* Password change warning banner */}
      {user?.mustChangePassword && (user.graceLoginsRemaining || 0) > 0 && (
        <div className={`fixed top-0 left-0 right-0 z-50 px-4 py-2 flex items-center justify-center gap-3 ${isDark ? 'bg-amber-900/90' : 'bg-amber-500'}`}>
          <AlertTriangle className="w-5 h-5 text-white" />
          <span className="text-white text-sm font-medium">
            Please change your default password. {user.graceLoginsRemaining} login(s) remaining.
          </span>
          <button
            onClick={() => setShowChangePassword(true)}
            className="px-3 py-1 bg-white/20 hover:bg-white/30 text-white text-sm rounded-lg"
          >
            Change Now
          </button>
        </div>
      )}

      {/* Main content with top padding if warning is shown */}
      <div className={user?.mustChangePassword && (user.graceLoginsRemaining || 0) > 0 ? 'pt-10' : ''}>
        {children}
      </div>

      {/* Change password modal */}
      {showChangePassword && (
        <ChangePasswordModal
          onClose={() => setShowChangePassword(false)}
          onSuccess={() => {
            setShowChangePassword(false);
            setChangePasswordError('');
          }}
        />
      )}
    </>
  );
};

export default AuthWrapper;
