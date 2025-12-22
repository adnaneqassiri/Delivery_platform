import React, { useState, useEffect } from 'react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { STATUS_COLORS } from '../../utils/constants';

const MyLivraisons = () => {
  const [livraisons, setLivraisons] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchLivraisons();
  }, []);

  const fetchLivraisons = async () => {
    try {
      const response = await api.get('/livreur/livraisons/mes-livraisons');
      if (response.data.success) {
        setLivraisons(response.data.data);
      }
    } catch (err) {
      setError('Failed to load livraisons');
    } finally {
      setLoading(false);
    }
  };

  const handleDeliver = async (livraison) => {
    if (!window.confirm('Are you sure you want to mark this livraison as delivered?')) {
      return;
    }

    try {
      await api.post(`/livreur/livraisons/${livraison.ID_LIVRAISON}/livrer`);
      setSuccess('Livraison marked as delivered');
      fetchLivraisons();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to deliver livraison');
    }
  };

  const columns = [
    { key: 'ID_LIVRAISON', label: 'ID' },
    { key: 'SOURCE', label: 'Source' },
    { key: 'DESTINATION', label: 'Destination' },
    { key: 'NB_COLIS', label: 'Number of Colis' },
    {
      key: 'STATUT',
      label: 'Status',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs ${STATUS_COLORS[value] || 'bg-gray-100 text-gray-800'}`}>
          {value}
        </span>
      )
    },
    { key: 'DATE_CREATION', label: 'Date Created' },
    { key: 'DATE_LIVRAISON', label: 'Delivery Date', render: (value) => value || 'N/A' }
  ];

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
        <Navbar title="My Livraisons" />
        <main className="flex-1 overflow-y-auto p-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}
          {success && (
            <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded mb-4">
              {success}
            </div>
          )}

          <DataTable
            data={livraisons}
            columns={columns}
            actions={[
              {
                label: 'Deliver',
                onClick: (row) => {
                  if (row.STATUT === 'EN_COURS') {
                    handleDeliver(row);
                  }
                },
                className: 'text-green-600 hover:text-green-900',
                condition: (row) => row.STATUT === 'EN_COURS'
              }
            ]}
          />
        </main>
      </div>
    </div>
  );
};

export default MyLivraisons;

