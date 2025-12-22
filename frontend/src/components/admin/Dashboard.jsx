import React, { useState, useEffect } from 'react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import KPIcard from '../common/KPIcard';
import api from '../../services/api';

const AdminDashboard = () => {
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchKPIs();
  }, []);

  const fetchKPIs = async () => {
    try {
      const response = await api.get('/admin/kpis');
      if (response.data.success) {
        setKpis(response.data.data);
      }
    } catch (err) {
      setError('Failed to load KPIs');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-screen">
        <Sidebar />
        <div className="flex-1 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Navbar title="Admin Dashboard" />
        <main className="flex-1 overflow-y-auto p-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <KPIcard
              title="Total Clients"
              value={kpis?.clients_count || 0}
              icon="👤"
              color="blue"
            />
            <KPIcard
              title="Total Colis"
              value={kpis?.colis_count || 0}
              icon="📦"
              color="green"
            />
            <KPIcard
              title="Total Livraisons"
              value={kpis?.livraisons_count || 0}
              icon="🚚"
              color="yellow"
            />
            <KPIcard
              title="Active Livreurs"
              value={kpis?.livreurs_count || 0}
              icon="👷"
              color="purple"
            />
            <KPIcard
              title="Total Entrepots"
              value={kpis?.entrepots_count || 0}
              icon="🏢"
              color="indigo"
            />
            <KPIcard
              title="Admins"
              value={kpis?.admins_count || 0}
              icon="👑"
              color="red"
            />
            <KPIcard
              title="Gestionnaires"
              value={kpis?.gestionnaires_count || 0}
              icon="💼"
              color="gray"
            />
            <KPIcard
              title="Chiffre d'Affaires"
              value={`${(kpis?.chiffre_affaire || 0).toLocaleString()} MAD`}
              icon="💰"
              color="green"
            />
          </div>
        </main>
      </div>
    </div>
  );
};

export default AdminDashboard;



