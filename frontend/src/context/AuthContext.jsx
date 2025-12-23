import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../services/api';
import { ROLES } from '../utils/constants';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const response = await api.get('/auth/me');
      if (response.data.success) {
        setUser(response.data.data);
      } else {
        setUser(null);
      }
    } catch (error) {
      // Only set user to null if it's a real auth error, not a network error
      if (error.response?.status === 401) {
        setUser(null);
      }
      // For other errors, keep current state to avoid unnecessary re-renders
    } finally {
      setLoading(false);
    }
  };

  const login = async (nom_utilisateur, mot_de_passe) => {
    try {
      const response = await api.post('/auth/login', {
        nom_utilisateur,
        mot_de_passe
      });

      if (response.data.success) {
        const userData = response.data.data;
        setUser(userData);
        return { success: true, role: userData.role };
      }
      return { success: false, message: response.data.message };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || 'Login failed'
      };
    }
  };

  const logout = async () => {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setUser(null);
      window.location.href = '/login';
    }
  };

  const isAdmin = () => user?.role === ROLES.ADMIN;
  const isGestionnaire = () => user?.role === ROLES.GESTIONNAIRE;
  const isLivreur = () => user?.role === ROLES.LIVREUR;

  const refreshUser = async () => {
    await checkAuth();
  };

  const value = {
    user,
    loading,
    login,
    logout,
    isAdmin,
    isGestionnaire,
    isLivreur,
    checkAuth,
    refreshUser
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};



