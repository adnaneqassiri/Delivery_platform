import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import Sidebar from '../common/Sidebar';
import Navbar from '../common/Navbar';
import DataTable from '../common/DataTable';
import api from '../../services/api';
import { ROLES } from '../../utils/constants';

const UsersManagement = () => {
  const [users, setUsers] = useState([]);
  const [entrepots, setEntrepots] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [formData, setFormData] = useState({
    nom_utilisateur: '',
    mot_de_passe: '',
    role: 'GESTIONNAIRE',
    cin: '',
    id_entrepot: '',
    actif: 1
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    fetchUsers();
    fetchEntrepots();
  }, []);

  const fetchUsers = async () => {
    try {
      const response = await api.get('/admin/users');
      if (response.data.success) {
        setUsers(response.data.data);
      }
    } catch (err) {
      setError('Failed to load users');
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

  const handleOpenModal = (user = null) => {
    if (user) {
      setEditingUser(user);
      setFormData({
        nom_utilisateur: user.NOM_UTILISATEUR,
        mot_de_passe: '',
        role: user.ROLE,
        cin: user.CIN || '',
        id_entrepot: user.ID_ENTREPOT || '',
        actif: user.ACTIF
      });
    } else {
      setEditingUser(null);
      setFormData({
        nom_utilisateur: '',
        mot_de_passe: '',
        role: 'GESTIONNAIRE',
        cin: '',
        id_entrepot: '',
        actif: 1
      });
    }
    setIsModalOpen(true);
    setError('');
    setSuccess('');
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingUser(null);
    setFormData({
      nom_utilisateur: '',
      mot_de_passe: '',
      role: 'GESTIONNAIRE',
      cin: '',
      id_entrepot: '',
      actif: 1
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      if (editingUser) {
        // Update user
        await api.put(`/admin/users/${editingUser.ID_UTILISATEUR}`, {
          role: formData.role,
          cin: formData.cin,
          id_entrepot: formData.id_entrepot || null,
          actif: formData.actif
        });
        setSuccess('User updated successfully');
      } else {
        // Create user
        await api.post('/admin/users', {
          ...formData,
          id_entrepot: formData.id_entrepot || null
        });
        setSuccess('User created successfully');
      }
      handleCloseModal();
      fetchUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Operation failed');
    }
  };

  const handleToggleActive = async (user) => {
    try {
      await api.put(`/admin/users/${user.ID_UTILISATEUR}`, {
        actif: user.ACTIF === 1 ? 0 : 1
      });
      fetchUsers();
    } catch (err) {
      setError('Failed to update user');
    }
  };

  const columns = [
    { key: 'NOM_UTILISATEUR', label: 'Username' },
    { key: 'ROLE', label: 'Role' },
    { key: 'CIN', label: 'CIN' },
    { 
      key: 'ENTREPOT_NOM', 
      label: 'Entrepôt',
      render: (value) => value || 'Non assigné'
    },
    {
      key: 'ACTIF',
      label: 'Status',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs ${
          value === 1 ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {value === 1 ? 'Active' : 'Inactive'}
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
        <Navbar title="Users Management" />
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
              onClick={() => handleOpenModal()}
              className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700"
            >
              + Add User
            </button>
          </div>

          <DataTable
            data={users}
            columns={columns}
            onEdit={handleOpenModal}
            actions={[
              {
                label: user => user.ACTIF === 1 ? 'Deactivate' : 'Activate',
                onClick: handleToggleActive,
                className: 'text-yellow-600 hover:text-yellow-900'
              }
            ]}
          />

          {/* Modal */}
          <Dialog open={isModalOpen} onClose={handleCloseModal} className="relative z-50">
            <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <Dialog.Panel className="mx-auto max-w-md rounded bg-white p-6 w-full">
                <Dialog.Title className="text-xl font-bold mb-4">
                  {editingUser ? 'Edit User' : 'Add User'}
                </Dialog.Title>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Username</label>
                    <input
                      type="text"
                      required
                      value={formData.nom_utilisateur}
                      onChange={(e) => setFormData({ ...formData, nom_utilisateur: e.target.value })}
                      disabled={!!editingUser}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>

                  {!editingUser && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Password</label>
                      <input
                        type="password"
                        required={!editingUser}
                        value={formData.mot_de_passe}
                        onChange={(e) => setFormData({ ...formData, mot_de_passe: e.target.value })}
                        className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                      />
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-700">Role</label>
                    <select
                      value={formData.role}
                      onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value={ROLES.ADMIN}>ADMIN</option>
                      <option value={ROLES.GESTIONNAIRE}>GESTIONNAIRE</option>
                      <option value={ROLES.LIVREUR}>LIVREUR</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">CIN</label>
                    <input
                      type="text"
                      value={formData.cin}
                      onChange={(e) => setFormData({ ...formData, cin: e.target.value })}
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>

                  {(formData.role === 'GESTIONNAIRE' || formData.role === 'LIVREUR') && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Entrepôt {formData.role === 'LIVREUR' ? '(requis)' : '(optionnel)'}
                      </label>
                      <select
                        required={formData.role === 'LIVREUR'}
                        value={formData.id_entrepot}
                        onChange={(e) => setFormData({ ...formData, id_entrepot: e.target.value })}
                        className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                      >
                        <option value="">Sélectionner un entrepôt</option>
                        {entrepots.map((entrepot) => (
                          <option key={entrepot.ID_ENTREPOT} value={entrepot.ID_ENTREPOT}>
                            {entrepot.VILLE} - {entrepot.ADRESSE}
                          </option>
                        ))}
                      </select>
                      {formData.role === 'GESTIONNAIRE' && (
                        <p className="mt-1 text-xs text-gray-500">
                          L'entrepôt est nécessaire pour créer des colis
                        </p>
                      )}
                    </div>
                  )}

                  {editingUser && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Status</label>
                      <select
                        value={formData.actif}
                        onChange={(e) => setFormData({ ...formData, actif: parseInt(e.target.value) })}
                        className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                      >
                        <option value={1}>Active</option>
                        <option value={0}>Inactive</option>
                      </select>
                    </div>
                  )}

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
                      {editingUser ? 'Update' : 'Create'}
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

export default UsersManagement;



