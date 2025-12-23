import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { VEHICULE_TYPES, STATUS_COLORS } from '../../utils/constants';

const VehiculesManagement = () => {
  const [vehicules, setVehicules] = useState([]);
  const [entrepots, setEntrepots] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedEntrepot, setSelectedEntrepot] = useState('');
  const [formData, setFormData] = useState({
    immatriculation: '',
    type_vehicule: 'PETIT_CAMION',
    id_entrepot: ''
  });
  const [editingVehicule, setEditingVehicule] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchVehicules();
    fetchEntrepots();
  }, [selectedEntrepot]);

  const fetchVehicules = async () => {
    try {
      const url = selectedEntrepot 
        ? `/admin/vehicules?id_entrepot=${selectedEntrepot}`
        : '/admin/vehicules';
      const response = await api.get(url);
      if (response.data.success) {
        setVehicules(response.data.data);
      }
    } catch (err) {
      setError('Failed to load vehicules');
    } finally {
      setLoading(false);
    }
  };

  const fetchEntrepots = async () => {
    try {
      const response = await api.get('/admin/entrepots');
      if (response.data.success) {
        setEntrepots(response.data.data);
      }
    } catch (err) {
      console.error('Failed to load entrepots');
    }
  };

  const handleOpenModal = (vehicule = null) => {
    if (vehicule) {
      setEditingVehicule(vehicule);
      setFormData({
        immatriculation: vehicule.IMMATRICULATION,
        type_vehicule: vehicule.TYPE_VEHICULE,
        id_entrepot: vehicule.ID_ENTREPOT || ''
      });
    } else {
      setEditingVehicule(null);
      setFormData({
        immatriculation: '',
        type_vehicule: 'PETIT_CAMION',
        id_entrepot: ''
      });
    }
    setIsModalOpen(true);
    setError('');
    setSuccess('');
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingVehicule(null);
    setFormData({
      immatriculation: '',
      type_vehicule: 'PETIT_CAMION',
      id_entrepot: ''
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      if (editingVehicule) {
        await api.put(`/admin/vehicules/${editingVehicule.ID_VEHICULE}`, {
          id_entrepot: formData.id_entrepot || null
        });
        setSuccess('Vehicule updated successfully');
      } else {
        await api.post('/admin/vehicules', formData);
        setSuccess('Vehicule created successfully');
      }
      handleCloseModal();
      fetchVehicules();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Operation failed');
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
    },
    { 
      key: 'ENTREPOT_NOM', 
      label: 'Entrepot',
      render: (value) => value || 'Non assigné'
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

          <div className="mb-4 flex justify-between items-center">
            <button
              onClick={() => handleOpenModal()}
              className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700"
            >
              + Add Vehicule
            </button>
            
            <div className="flex items-center space-x-2">
              <label className="text-sm font-medium text-gray-700">Filter by Entrepot:</label>
              <select
                value={selectedEntrepot}
                onChange={(e) => setSelectedEntrepot(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              >
                <option value="">All Entreports</option>
                {entrepots.map((entrepot) => (
                  <option key={entrepot.ID_ENTREPOT} value={entrepot.ID_ENTREPOT}>
                    {entrepot.VILLE} - {entrepot.ADRESSE}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <DataTable
            data={vehicules}
            columns={columns}
            actions={[
              {
                label: 'Edit',
                onClick: (row) => handleOpenModal(row),
                className: 'text-blue-600 hover:text-blue-900'
              }
            ]}
          />

          {/* Add/Edit Modal */}
          <Dialog open={isModalOpen} onClose={handleCloseModal} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">
                  {editingVehicule ? 'Edit Vehicule' : 'Add Vehicule'}
                </Dialog.Title>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Immatriculation *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.immatriculation}
                      onChange={(e) => setFormData({ ...formData, immatriculation: e.target.value })}
                      disabled={!!editingVehicule}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 disabled:bg-gray-100"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Type *</label>
                    <select
                      required
                      value={formData.type_vehicule}
                      onChange={(e) => setFormData({ ...formData, type_vehicule: e.target.value })}
                      disabled={!!editingVehicule}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 disabled:bg-gray-100"
                    >
                      {Object.entries(VEHICULE_TYPES).map(([key, value]) => (
                        <option key={key} value={value}>
                          {key === 'PETIT_CAMION' ? 'Petit Camion' : 'Grand Camion'}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Entrepot</label>
                    <select
                      value={formData.id_entrepot}
                      onChange={(e) => setFormData({ ...formData, id_entrepot: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value="">Select entrepot</option>
                      {entrepots.map((entrepot) => (
                        <option key={entrepot.ID_ENTREPOT} value={entrepot.ID_ENTREPOT}>
                          {entrepot.VILLE} - {entrepot.ADRESSE}
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
                      onClick={handleCloseModal}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
                    >
                      {editingVehicule ? 'Update' : 'Add'}
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

export default VehiculesManagement;


