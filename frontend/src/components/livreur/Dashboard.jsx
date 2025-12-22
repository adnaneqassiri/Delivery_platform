import React, { useState, useEffect } from 'react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import KPIcard from '../common/KPIcard';
import api from '../../services/api';

const LivreurDashboard = () => {
  const [stats, setStats] = useState({
    total: 0,
    enCours: 0,
    livree: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await api.get('/livreur/livraisons/mes-livraisons');
      if (response.data.success) {
        const livraisons = response.data.data;
        setStats({
          total: livraisons.length,
          enCours: livraisons.filter(l => l.STATUT === 'EN_COURS').length,
          livree: livraisons.filter(l => l.STATUT === 'LIVREE').length
        });
      }
    } catch (err) {
      setError('Failed to load statistics');
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
        <Navbar title="Livreur Dashboard" />
        <main className="flex-1 overflow-y-auto p-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <KPIcard
              title="Total Livraisons"
              value={stats.total}
              icon="🚚"
              color="blue"
            />
            <KPIcard
              title="En Cours"
              value={stats.enCours}
              icon="⏳"
              color="yellow"
            />
            <KPIcard
              title="Livree"
              value={stats.livree}
              icon="✅"
              color="green"
            />
          </div>
        </main>
      </div>
    </div>
  );
};

export default LivreurDashboard;



