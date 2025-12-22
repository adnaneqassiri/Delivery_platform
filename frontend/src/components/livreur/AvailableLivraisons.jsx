import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { STATUS_COLORS } from '../../utils/constants';

const AvailableLivraisons = () => {
  const [livraisons, setLivraisons] = useState([]);
  const [vehicules, setVehicules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedLivraison, setSelectedLivraison] = useState(null);
  const [selectedVehicule, setSelectedVehicule] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchLivraisons();
    fetchVehicules();
  }, []);

  const fetchLivraisons = async () => {
    try {
      const response = await api.get('/livreur/livraisons/disponibles');
      if (response.data.success) {
        setLivraisons(response.data.data);
      }
    } catch (err) {
      setError('Failed to load livraisons');
    } finally {
      setLoading(false);
    }
  };

  const fetchVehicules = async () => {
    try {
      const response = await api.get('/livreur/vehicules');
      if (response.data.success) {
        setVehicules(response.data.data);
      }
    } catch (err) {
      console.error('Failed to load vehicules');
    }
  };

  const handleTakeLivraison = (livraison) => {
    setSelectedLivraison(livraison);
    setSelectedVehicule('');
    setIsModalOpen(true);
    setError('');
    setSuccess('');
  };

  const handleConfirmTake = async () => {
    if (!selectedVehicule) {
      setError('Please select a vehicle');
      return;
    }

    try {
      await api.post(`/livreur/livraisons/${selectedLivraison.ID_LIVRAISON}/prendre`, {
        id_vehicule: parseInt(selectedVehicule)
      });
      setSuccess('Livraison taken successfully');
      setIsModalOpen(false);
      setSelectedLivraison(null);
      setSelectedVehicule('');
      fetchLivraisons();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to take livraison');
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
    { key: 'DATE_CREATION', label: 'Date Created' }
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
        <Navbar title="Available Livraisons" />
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
                label: 'Take Livraison',
                onClick: handleTakeLivraison,
                className: 'text-green-600 hover:text-green-900'
              }
            ]}
          />

          {/* Take Livraison Modal */}
          <Dialog open={isModalOpen} onClose={() => setIsModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Take Livraison</Dialog.Title>
                <div className="space-y-4">
                  {selectedLivraison && (
                    <div className="bg-gray-50 p-4 rounded">
                      <p className="text-sm text-gray-600">Source: {selectedLivraison.SOURCE}</p>
                      <p className="text-sm text-gray-600">Destination: {selectedLivraison.DESTINATION}</p>
                      <p className="text-sm text-gray-600">Colis: {selectedLivraison.NB_COLIS}</p>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Select Vehicle *</label>
                    <select
                      value={selectedVehicule}
                      onChange={(e) => setSelectedVehicule(e.target.value)}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value="">Select a vehicle</option>
                      {vehicules.map((vehicule) => (
                        <option key={vehicule.ID_VEHICULE} value={vehicule.ID_VEHICULE}>
                          {vehicule.IMMATRICULATION} - {vehicule.TYPE_VEHICULE} ({vehicule.ENTREPOT_ACTUEL || 'N/A'})
                        </option>
                      ))}
                    </select>
                  </div>

                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
                      {error}
                    </div>
                  )}

                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setIsModalOpen(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleConfirmTake}
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
                    >
                      Confirm
                    </button>
                  </div>
                </div>
              </Dialog.Panel>
            </div>
          </Dialog>
        </main>
      </div>
    </div>
  );
};

export default AvailableLivraisons;



