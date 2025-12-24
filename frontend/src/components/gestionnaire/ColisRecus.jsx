import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { STATUS_COLORS } from '../../utils/constants';

const ColisRecus = () => {
  const [colis, setColis] = useState([]);
  const [filteredColis, setFilteredColis] = useState([]);
  const [statusFilter, setStatusFilter] = useState('all'); // 'all', 'recus', 'recuperee'
  const [loading, setLoading] = useState(true);
  const [isRecoverModalOpen, setIsRecoverModalOpen] = useState(false);
  const [recoverCin, setRecoverCin] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchColis();
  }, []);

  useEffect(() => {
    // Filter colis based on selected status
    // Handle both uppercase and lowercase column names from Oracle
    let filtered = colis;
    if (statusFilter === 'recus') {
      // Filter for colis with status LIVRE (displayed as RECUS)
      filtered = colis.filter(c => {
        const statut = c.STATUT || c.statut || c.STATUS || c.status;
        return statut === 'LIVRE';
      });
    } else if (statusFilter === 'recuperee') {
      filtered = colis.filter(c => {
        const statut = c.STATUT || c.statut || c.STATUS || c.status;
        return statut === 'RECUPEREE';
      });
    }
    setFilteredColis(filtered);
  }, [colis, statusFilter]);

  const fetchColis = async () => {
    try {
      const response = await api.get('/gestionnaire/colis/recus');
      if (response.data.success) {
        console.log('Colis reçus:', response.data.data);
        console.log('Colis avec statut RECUPEREE:', response.data.data.filter(c => (c.STATUT || c.statut) === 'RECUPEREE'));
        setColis(response.data.data);
        setError(''); // Clear any previous errors
      } else {
        setError(response.data.message || 'Failed to load colis');
      }
    } catch (err) {
      const errorMessage = err.response?.data?.message || err.message || 'Failed to load colis';
      setError(errorMessage);
      console.error('Error fetching colis:', err);
      console.error('Error response:', err.response);
    } finally {
      setLoading(false);
    }
  };

  const handleRecover = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!recoverCin.trim()) {
      setError('Receiver CIN is required');
      return;
    }

    try {
      await api.post('/gestionnaire/colis/recus/recuperer', {
        receiver_cin: recoverCin.trim()
      });
      setSuccess('Colis marked as recovered');
      setIsRecoverModalOpen(false);
      setRecoverCin('');
      fetchColis();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to mark as recovered');
    }
  };

  const columns = [
    { key: 'ID_COLIS', label: 'ID' },
    { key: 'CLIENT', label: 'Client', render: (value) => value || 'N/A' },
    { key: 'POIDS', label: 'Weight (KG)' },
    { key: 'TYPE_COLIS', label: 'Type' },
    { key: 'PRIX', label: 'Price', render: (value) => value ? `${value} MAD` : 'N/A' },
    { key: 'RECEIVER_CIN', label: 'Receiver CIN' },
    { key: 'VILLE_DESTINATION', label: 'Destination' },
    { 
      key: 'STATUT', 
      label: 'Status',
      render: (value, row) => {
        const statut = value || row.statut || row.STATUS || row.status || 'N/A';
        // Map LIVRE to RECUS for display in colis reçus
        const displayStatut = statut === 'LIVRE' ? 'RECUS' : statut;
        return (
          <span className={`px-2 py-1 rounded-full text-xs font-semibold ${STATUS_COLORS[statut] || 'bg-gray-100 text-gray-800'}`}>
            {displayStatut}
          </span>
        );
      }
    },
    { key: 'TRAJET', label: 'Route', render: (value) => value || 'N/A' }
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
        <Navbar title="Colis Reçus" />
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

          <div className="mb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <button
                onClick={() => setIsRecoverModalOpen(true)}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700"
              >
                Mark as Recovered
              </button>
              <p className="mt-2 text-sm text-gray-600">
                Enter the receiver CIN to mark colis as recovered when they come to pick up their package.
              </p>
            </div>
            <div className="flex items-center gap-2">
              <label className="text-sm font-medium text-gray-700">Filter:</label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              >
                <option value="all">Tous</option>
                <option value="recus">Reçus (RECUS)</option>
                <option value="recuperee">Récupérés (RECUPEREE)</option>
              </select>
            </div>
          </div>

          <DataTable
            data={filteredColis}
            columns={columns}
          />

          {/* Recover Modal */}
          <Dialog open={isRecoverModalOpen} onClose={() => setIsRecoverModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Mark Colis as Recovered</Dialog.Title>
                <form onSubmit={handleRecover} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Receiver CIN *</label>
                    <input
                      type="text"
                      required
                      value={recoverCin}
                      onChange={(e) => setRecoverCin(e.target.value)}
                      placeholder="Enter receiver CIN"
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                    <p className="mt-1 text-xs text-gray-500">
                      All colis with this CIN that are in LIVRE status will be marked as RECUPEREE
                    </p>
                  </div>

                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
                      {error}
                    </div>
                  )}

                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setIsRecoverModalOpen(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                    >
                      Mark as Recovered
                    </button>
                  </div>
                </form>
              </Dialog.Panel>
            </div>
          </Dialog>
        </main>
      </div>
    </div>
  );
};

export default ColisRecus;


