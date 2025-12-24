const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');
const {
  getStats,
  getColisEnvoyes,
  getColisRecus,
  addColis,
  modifyColisStatusEnvoyes,
  markColisRecupereeRecus,
  getClients,
  createClient,
  getEntrepots,
  getColisHistory,
  getVehicules,
  updateVehiculeStatus
} = require('../controllers/gestionnaireController');

// All gestionnaire routes require authentication and GESTIONNAIRE role
router.use(requireAuth);
router.use(requireRole('GESTIONNAIRE', 'ADMIN'));

// Statistics
router.get('/stats', getStats);

// Colis Envoyés
router.get('/colis/envoyes', getColisEnvoyes);
router.post('/colis/envoyes', addColis); // Add new colis
router.put('/colis/envoyes/:id/statut', modifyColisStatusEnvoyes); // Only ANNULEE

// Colis Reçus
router.get('/colis/recus', getColisRecus);
router.post('/colis/recus/recuperer', markColisRecupereeRecus); // Mark as RECUPEREE

// History
router.get('/colis/:id/history', getColisHistory);

// Clients
router.get('/clients', getClients);
router.post('/clients', createClient);

// Entrepots (for dropdowns)
router.get('/entrepots', getEntrepots);

// Vehicules
router.get('/vehicules', getVehicules);
router.put('/vehicules/:id/statut', updateVehiculeStatus);

module.exports = router;



