const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');
const {
  getColis,
  addColis,
  modifyColisStatus,
  markColisRecuperee,
  getClients,
  createClient,
  getEntrepots,
  getColisHistory
} = require('../controllers/gestionnaireController');

// All gestionnaire routes require authentication and GESTIONNAIRE role
router.use(requireAuth);
router.use(requireRole('GESTIONNAIRE', 'ADMIN'));

// Colis
router.get('/colis', getColis);
router.post('/colis', addColis);
router.put('/colis/:id/statut', modifyColisStatus);
router.post('/colis/recuperer', markColisRecuperee);
router.get('/colis/:id/history', getColisHistory);

// Clients
router.get('/clients', getClients);
router.post('/clients', createClient);

// Entrepots (for dropdowns)
router.get('/entrepots', getEntrepots);

module.exports = router;



