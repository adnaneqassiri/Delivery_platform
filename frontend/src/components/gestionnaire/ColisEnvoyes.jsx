import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import { COLIS_TYPES, STATUS_COLORS } from '../../utils/constants';

const ColisEnvoyes = () => {
  const { user, refreshUser } = useAuth();
  const [colis, setColis] = useState([]);
  const [clients, setClients] = useState([]);
  const [entrepots, setEntrepots] = useState([]);
  const [userEntrepot, setUserEntrepot] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isStatusModalOpen, setIsStatusModalOpen] = useState(false);
  const [selectedColis, setSelectedColis] = useState(null);
  const [formData, setFormData] = useState({
    id_client: '',
    poids: '',
    type: 'STANDARD',
    receiver_cin: '',
    id_entrepot_reception: ''
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchColis();
    fetchClients();
    fetchEntrepots();
    fetchUserEntrepot();
  }, []);

  useEffect(() => {
    if (isAddModalOpen) {
      refreshUser().then(() => {
        fetchUserEntrepot();
      });
    }
  }, [isAddModalOpen]);

  const fetchColis = async () => {
    try {
      const response = await api.get('/gestionnaire/colis/envoyes');
      if (response.data.success) {
        setColis(response.data.data);
      }
    } catch (err) {
      setError('Failed to load colis');
    } finally {
      setLoading(false);
    }
  };

  const fetchClients = async () => {
    try {
      const response = await api.get('/gestionnaire/clients');
      if (response.data.success) {
        setClients(response.data.data);
      }
    } catch (err) {
      console.error('Failed to load clients');
    }
  };

  const fetchEntrepots = async () => {
    try {
      const response = await api.get('/gestionnaire/entrepots');
      if (response.data.success) {
        setEntrepots(response.data.data);
      }
    } catch (err) {
      console.error('Failed to load entrepots');
    }
  };

  const fetchUserEntrepot = async () => {
    try {
      const response = await api.get('/auth/me');
      if (response.data.success && response.data.data.id_entrepot) {
        const entrepotId = response.data.data.id_entrepot;
        const entrepotResponse = await api.get('/gestionnaire/entrepots');
        if (entrepotResponse.data.success) {
          const entrepot = entrepotResponse.data.data.find(
            e => e.ID_ENTREPOT === entrepotId
          );
          setUserEntrepot(entrepot);
        }
      } else {
        setUserEntrepot(null);
      }
    } catch (err) {
      console.error('Failed to load user entrepot:', err);
      setUserEntrepot(null);
    }
  };

  const handleAddColis = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      await api.post('/gestionnaire/colis/envoyes', {
        ...formData,
        poids: parseFloat(formData.poids),
        id_client: formData.id_client || null,
        id_entrepot_reception: parseInt(formData.id_entrepot_reception)
      });
      setSuccess('Colis added successfully');
      setIsAddModalOpen(false);
      setFormData({
        id_client: '',
        poids: '',
        type: 'STANDARD',
        receiver_cin: '',
        id_entrepot_reception: ''
      });
      fetchColis();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to add colis');
    }
  };

  const handleCancelColis = async () => {
    if (!selectedColis) return;
    
    setError('');
    setSuccess('');

    try {
      await api.put(`/gestionnaire/colis/envoyes/${selectedColis.ID_COLIS}/statut`, {
        statut: 'ANNULEE'
      });
      setSuccess('Colis cancelled successfully');
      setIsStatusModalOpen(false);
      setSelectedColis(null);
      fetchColis();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to cancel colis');
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
        <Navbar title="Colis Envoyés" />
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
              onClick={() => setIsAddModalOpen(true)}
              className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700"
            >
              + Add Colis
            </button>
          </div>

          <DataTable
            data={colis}
            columns={columns}
            actions={[
              {
                label: 'Cancel',
                onClick: (row) => {
                  setSelectedColis(row);
                  setIsStatusModalOpen(true);
                },
                className: 'text-red-600 hover:text-red-900',
                condition: (row) => row.STATUT !== 'ANNULEE' && row.STATUT !== 'RECUPEREE'
              }
            ]}
          />

          {/* Add Colis Modal */}
          <Dialog open={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full max-h-[90vh] overflow-y-auto">
                <Dialog.Title className="text-xl font-bold mb-4">Add Colis</Dialog.Title>
                <form onSubmit={handleAddColis} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Client</label>
                    <select
                      value={formData.id_client}
                      onChange={(e) => setFormData({ ...formData, id_client: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value="">Select client (optional)</option>
                      {clients.map((client) => (
                        <option key={client.ID_CLIENT} value={client.ID_CLIENT}>
                          {client.NOM} {client.PRENOM}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Weight (kg) *</label>
                    <input
                      type="number"
                      required
                      min="1"
                      step="0.01"
                      value={formData.poids}
                      onChange={(e) => setFormData({ ...formData, poids: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Type *</label>
                    <select
                      required
                      value={formData.type}
                      onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      {Object.entries(COLIS_TYPES).map(([key, value]) => (
                        <option key={key} value={value}>
                          {value}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Receiver CIN *</label>
                    <input
                      type="text"
                      required
                      value={formData.receiver_cin}
                      onChange={(e) => setFormData({ ...formData, receiver_cin: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Entrepôt de réception *</label>
                    <select
                      required
                      value={formData.id_entrepot_reception}
                      onChange={(e) => setFormData({ ...formData, id_entrepot_reception: e.target.value })}
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

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Entrepôt d'envoi</label>
                    <input
                      type="text"
                      value={userEntrepot ? `${userEntrepot.VILLE} - ${userEntrepot.ADRESSE}` : 'Non assigné'}
                      disabled
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm bg-gray-100 cursor-not-allowed"
                    />
                  </div>

                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
                      {error}
                    </div>
                  )}

                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setIsAddModalOpen(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
                    >
                      Add Colis
                    </button>
                  </div>
                </form>
              </Dialog.Panel>
            </div>
          </Dialog>

          {/* Cancel Confirmation Modal */}
          <Dialog open={isStatusModalOpen} onClose={() => setIsStatusModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Cancel Colis</Dialog.Title>
                <div className="space-y-4">
                  <p className="text-gray-700">
                    Are you sure you want to cancel this colis? This action cannot be undone.
                  </p>
                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
                      {error}
                    </div>
                  )}
                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setIsStatusModalOpen(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      No
                    </button>
                    <button
                      onClick={handleCancelColis}
                      className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
                    >
                      Yes, Cancel
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

export default ColisEnvoyes;


