import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { STATUS_COLORS } from '../../utils/constants';

const VehiculesManagement = () => {
  const [vehicules, setVehicules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isStatusModalOpen, setIsStatusModalOpen] = useState(false);
  const [selectedVehicule, setSelectedVehicule] = useState(null);
  const [newStatus, setNewStatus] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchVehicules();
  }, []);

  const fetchVehicules = async () => {
    try {
      const response = await api.get('/gestionnaire/vehicules');
      if (response.data.success) {
        setVehicules(response.data.data);
      }
    } catch (err) {
      setError('Failed to load vehicules');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenStatusModal = (vehicule) => {
    // Only allow status change if not EN_UTILISATION
    if (vehicule.STATUT === 'EN_UTILISATION') {
      setError('Cannot change status of a vehicule that is EN_UTILISATION');
      setTimeout(() => setError(''), 3000);
      return;
    }
    
    setSelectedVehicule(vehicule);
    setNewStatus(vehicule.STATUT);
    setIsStatusModalOpen(true);
    setError('');
    setSuccess('');
  };

  const handleCloseStatusModal = () => {
    setIsStatusModalOpen(false);
    setSelectedVehicule(null);
    setNewStatus('');
  };

  const handleUpdateStatus = async () => {
    if (!selectedVehicule) return;
    
    setError('');
    setSuccess('');

    try {
      await api.put(`/gestionnaire/vehicules/${selectedVehicule.ID_VEHICULE}/statut`, {
        statut: newStatus
      });
      setSuccess('Vehicule status updated successfully');
      handleCloseStatusModal();
      fetchVehicules();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to update status');
    }
  };

  const columns = [
    { key: 'IMMATRICULATION', label: 'Immatriculation' },
    { 
      key: 'TYPE_VEHICULE', 
      label: 'Type',
      render: (value) => value === 'PETIT_CAMION' ? 'Petit Camion' : 'Grand Camion'
    },
    { 
      key: 'STATUT', 
      label: 'Status',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs font-semibold ${STATUS_COLORS[value] || 'bg-gray-100 text-gray-800'}`}>
          {value}
        </span>
      )
    }
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
        <Navbar title="Vehicules Management" />
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
            <p className="text-sm text-gray-600">
              You can view and manage vehicules from your entrepot. You can only change status between DISPONIBLE and MAINTENANCE.
            </p>
          </div>

          <DataTable
            data={vehicules}
            columns={columns}
            actions={[
              {
                label: 'Change Status',
                onClick: (row) => handleOpenStatusModal(row),
                className: 'text-blue-600 hover:text-blue-900',
                condition: (row) => row.STATUT !== 'EN_UTILISATION' // Only show if not EN_UTILISATION
              }
            ]}
          />

          {/* Change Status Modal */}
          <Dialog open={isStatusModalOpen} onClose={handleCloseStatusModal} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Change Status</Dialog.Title>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Vehicule</label>
                    <input
                      type="text"
                      value={selectedVehicule?.IMMATRICULATION || ''}
                      disabled
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm bg-gray-100 cursor-not-allowed"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">New Status</label>
                    <select
                      value={newStatus}
                      onChange={(e) => setNewStatus(e.target.value)}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value="DISPONIBLE">DISPONIBLE</option>
                      <option value="MAINTENANCE">MAINTENANCE</option>
                    </select>
                    <p className="mt-1 text-xs text-gray-500">
                      You can only change status between DISPONIBLE and MAINTENANCE
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
                      onClick={handleCloseStatusModal}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleUpdateStatus}
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
                    >
                      Update
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

export default VehiculesManagement;

