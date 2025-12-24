import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { STATUS_COLORS } from '../../utils/constants';

const ColisRecus = () => {
  const [colis, setColis] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isRecoverModalOpen, setIsRecoverModalOpen] = useState(false);
  const [recoverCin, setRecoverCin] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchColis();
  }, []);

  const fetchColis = async () => {
    try {
      const response = await api.get('/gestionnaire/colis/recus');
      if (response.data.success) {
        setColis(response.data.data);
      }
    } catch (err) {
      setError('Failed to load colis');
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
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs font-semibold ${STATUS_COLORS[value] || 'bg-gray-100 text-gray-800'}`}>
          {value}
        </span>
      )
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

          <div className="mb-4">
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

          <DataTable
            data={colis}
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


