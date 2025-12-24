import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { ROLES } from '../../utils/constants';

const Sidebar = () => {
  const location = useLocation();
  const { user, logout, isAdmin, isGestionnaire, isLivreur } = useAuth();

  const isActive = (path) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  const adminMenuItems = [
    { path: '/admin', label: 'Dashboard', icon: '📊' },
    { path: '/admin/users', label: 'Users', icon: '👥' },
    { path: '/admin/clients', label: 'Clients', icon: '👤' },
    { path: '/admin/entrepots', label: 'Entrepots', icon: '🏢' },
    { path: '/admin/vehicules', label: 'Vehicules', icon: '🚛' },
  ];

  const gestionnaireMenuItems = [
    { path: '/gestionnaire', label: 'Dashboard', icon: '📊' },
    { path: '/gestionnaire/colis/envoyes', label: 'Colis Envoyés', icon: '📤' },
    { path: '/gestionnaire/colis/recus', label: 'Colis Reçus', icon: '📥' },
    { path: '/gestionnaire/clients', label: 'Clients', icon: '👤' },
    { path: '/gestionnaire/vehicules', label: 'Vehicules', icon: '🚛' },
  ];

  const livreurMenuItems = [
    { path: '/livreur', label: 'Dashboard', icon: '📊' },
    { path: '/livreur/livraisons/disponibles', label: 'Available Livraisons', icon: '🚚' },
    { path: '/livreur/livraisons/mes-livraisons', label: 'My Livraisons', icon: '📋' },
  ];

  let menuItems = [];
  if (isAdmin()) {
    menuItems = adminMenuItems;
  } else if (isGestionnaire()) {
    menuItems = gestionnaireMenuItems;
  } else if (isLivreur()) {
    menuItems = livreurMenuItems;
  }

  return (
    <div className="w-64 bg-gray-900 text-white min-h-screen flex flex-col">
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center space-x-2">
          <div className="h-10 w-10 bg-primary-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold">LT</span>
          </div>
          <div>
            <h1 className="text-xl font-bold">LogiTrack</h1>
            <p className="text-xs text-gray-400">{user?.role}</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {menuItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
              isActive(item.path)
                ? 'bg-primary-600 text-white'
                : 'text-gray-300 hover:bg-gray-800'
            }`}
          >
            <span className="text-xl">{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>

      <div className="p-4 border-t border-gray-700">
        <button
          onClick={logout}
          className="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-gray-300 hover:bg-gray-800 transition-colors"
        >
          <span>🚪</span>
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;



