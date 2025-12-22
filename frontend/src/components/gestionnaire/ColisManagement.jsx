import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import { COLIS_STATUS, COLIS_TYPES, STATUS_COLORS } from '../../utils/constants';

const ColisManagement = () => {
  const { user } = useAuth();
  const [colis, setColis] = useState([]);
  const [clients, setClients] = useState([]);
  const [entrepots, setEntrepots] = useState([]);
  const [userEntrepot, setUserEntrepot] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isStatusModalOpen, setIsStatusModalOpen] = useState(false);
  const [isRecoverModalOpen, setIsRecoverModalOpen] = useState(false);
  const [selectedColis, setSelectedColis] = useState(null);
  const [formData, setFormData] = useState({
    id_client: '',
    poids: '',
    type: 'STANDARD',
    receiver_cin: '',
    id_entrepot_reception: ''
  });
  const [recoverCin, setRecoverCin] = useState('');
  const [newStatus, setNewStatus] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchColis();
    fetchClients();
    fetchEntrepots();
    fetchUserEntrepot();
  }, []);

  const fetchColis = async () => {
    try {
      const response = await api.get('/gestionnaire/colis');
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
      // Récupérer tous les entrepôts (pour le dropdown Entrepôt de réception)
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
      // Récupérer l'entrepôt de l'utilisateur connecté
      const response = await api.get('/auth/me');
      if (response.data.success && response.data.data.id_entrepot) {
        const entrepotId = response.data.data.id_entrepot;
        // Récupérer les détails de l'entrepôt depuis la liste des entrepôts
        const entrepotResponse = await api.get('/gestionnaire/entrepots');
        if (entrepotResponse.data.success) {
          const entrepot = entrepotResponse.data.data.find(
            e => e.ID_ENTREPOT === entrepotId
          );
          setUserEntrepot(entrepot);
        }
      } else {
        // User doesn't have an entrepot assigned
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
      await api.post('/gestionnaire/colis', {
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

  const handleChangeStatus = async () => {
    try {
      await api.put(`/gestionnaire/colis/${selectedColis.ID_COLIS}/statut`, {
        statut: newStatus
      });
      setSuccess('Status updated successfully');
      setIsStatusModalOpen(false);
      setSelectedColis(null);
      setNewStatus('');
      fetchColis();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to update status');
    }
  };

  const handleRecover = async (e) => {
    e.preventDefault();
    try {
      await api.post('/gestionnaire/colis/recuperer', {
        receiver_cin: recoverCin
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
    { key: 'POIDS', label: 'Weight (kg)' },
    { key: 'TYPE_COLIS', label: 'Type' },
    { 
      key: 'PRIX', 
      label: 'Price',
      render: (value) => value ? `${value} MAD` : 'N/A'
    },
    { key: 'RECEIVER_CIN', label: 'Receiver CIN' },
    { key: 'VILLE_DESTINATION', label: 'Destination' },
    { 
      key: 'STATUT', 
      label: 'Status',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs ${STATUS_COLORS[value] || 'bg-gray-100 text-gray-800'}`}>
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
        <Navbar title="Colis Management" />
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

          <div className="mb-4 flex space-x-3">
            <button
              onClick={() => setIsAddModalOpen(true)}
              className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700"
            >
              + Add Colis
            </button>
            <button
              onClick={() => setIsRecoverModalOpen(true)}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700"
            >
              Mark as Recovered
            </button>
          </div>

          <DataTable
            data={colis}
            columns={columns}
            actions={[
              {
                label: 'Change Status',
                onClick: (row) => {
                  setSelectedColis(row);
                  setNewStatus(row.STATUT);
                  setIsStatusModalOpen(true);
                },
                className: 'text-blue-600 hover:text-blue-900'
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
                      <option value="">Select a client (optional)</option>
                      {clients.map((client) => (
                        <option key={client.ID_CLIENT} value={client.ID_CLIENT}>
                          {client.PRENOM} {client.NOM}
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
                      step="0.1"
                      value={formData.poids}
                      onChange={(e) => setFormData({ ...formData, poids: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Type *</label>
                    <select
                      value={formData.type}
                      onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value={COLIS_TYPES.STANDARD}>STANDARD</option>
                      <option value={COLIS_TYPES.FRAGILE}>FRAGILE</option>
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
                    <label className="block text-sm font-medium text-gray-700">Entrepôt d'expédition</label>
                    <input
                      type="text"
                      readOnly
                      value={userEntrepot ? `${userEntrepot.VILLE} - ${userEntrepot.ADRESSE}` : 'Non assigné'}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm bg-gray-50 text-gray-600 cursor-not-allowed"
                    />
                    {!userEntrepot && (
                      <p className="mt-1 text-xs text-red-600">
                        Vous devez être assigné à un entrepôt pour créer un colis
                      </p>
                    )}
                  </div>

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

          {/* Change Status Modal */}
          <Dialog open={isStatusModalOpen} onClose={() => setIsStatusModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Change Status</Dialog.Title>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">New Status</label>
                    <select
                      value={newStatus}
                      onChange={(e) => setNewStatus(e.target.value)}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      {Object.values(COLIS_STATUS).map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setIsStatusModalOpen(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleChangeStatus}
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
                    >
                      Update
                    </button>
                  </div>
                </div>
              </Dialog.Panel>
            </div>
          </Dialog>

          {/* Recover Modal */}
          <Dialog open={isRecoverModalOpen} onClose={() => setIsRecoverModalOpen(false)} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">Mark as Recovered</Dialog.Title>
                <form onSubmit={handleRecover} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Receiver CIN *</label>
                    <input
                      type="text"
                      required
                      value={recoverCin}
                      onChange={(e) => setRecoverCin(e.target.value)}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
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

export default ColisManagement;



