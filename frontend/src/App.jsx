import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ROLES } from './utils/constants';

// Auth
import Login from './components/auth/Login';

// Admin
import AdminDashboard from './components/admin/Dashboard';
import UsersManagement from './components/admin/UsersManagement';
import ClientsManagement from './components/admin/ClientsManagement';
import EntrepotsManagement from './components/admin/EntrepotsManagement';

// Gestionnaire
import GestionnaireDashboard from './components/gestionnaire/Dashboard';
import ColisManagement from './components/gestionnaire/ColisManagement';
import GestionnaireClients from './components/gestionnaire/ClientsManagement';

// Livreur
import LivreurDashboard from './components/livreur/Dashboard';
import AvailableLivraisons from './components/livreur/AvailableLivraisons';
import MyLivraisons from './components/livreur/MyLivraisons';

// Protected Route Component
const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

// Role-based redirect after login
const RoleRedirect = () => {
  const { user } = useAuth();
  
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  switch (user.role) {
    case ROLES.ADMIN:
      return <Navigate to="/admin" replace />;
    case ROLES.GESTIONNAIRE:
      return <Navigate to="/gestionnaire" replace />;
    case ROLES.LIVREUR:
      return <Navigate to="/livreur" replace />;
    default:
      return <Navigate to="/login" replace />;
  }
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<RoleRedirect />} />
          
          {/* Admin Routes */}
          <Route
            path="/admin"
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/users"
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <UsersManagement />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/clients"
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <ClientsManagement />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/entrepots"
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <EntrepotsManagement />
              </ProtectedRoute>
            }
          />

          {/* Gestionnaire Routes */}
          <Route
            path="/gestionnaire"
            element={
              <ProtectedRoute allowedRoles={[ROLES.GESTIONNAIRE, ROLES.ADMIN]}>
                <GestionnaireDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/gestionnaire/colis"
            element={
              <ProtectedRoute allowedRoles={[ROLES.GESTIONNAIRE, ROLES.ADMIN]}>
                <ColisManagement />
              </ProtectedRoute>
            }
          />
          <Route
            path="/gestionnaire/clients"
            element={
              <ProtectedRoute allowedRoles={[ROLES.GESTIONNAIRE, ROLES.ADMIN]}>
                <GestionnaireClients />
              </ProtectedRoute>
            }
          />

          {/* Livreur Routes */}
          <Route
            path="/livreur"
            element={
              <ProtectedRoute allowedRoles={[ROLES.LIVREUR]}>
                <LivreurDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/livreur/livraisons/disponibles"
            element={
              <ProtectedRoute allowedRoles={[ROLES.LIVREUR]}>
                <AvailableLivraisons />
              </ProtectedRoute>
            }
          />
          <Route
            path="/livreur/livraisons/mes-livraisons"
            element={
              <ProtectedRoute allowedRoles={[ROLES.LIVREUR]}>
                <MyLivraisons />
              </ProtectedRoute>
            }
          />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;



