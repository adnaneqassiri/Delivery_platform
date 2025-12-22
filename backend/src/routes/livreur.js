const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');
const {
  getAvailableLivraisons,
  prendreLivraison,
  getMyLivraisons,
  livrerLivraison,
  getVehicules
} = require('../controllers/livreurController');

// All livreur routes require authentication and LIVREUR role
router.use(requireAuth);
router.use(requireRole('LIVREUR'));

// Livraisons
router.get('/livraisons/disponibles', getAvailableLivraisons);
router.post('/livraisons/:id/prendre', prendreLivraison);
router.get('/livraisons/mes-livraisons', getMyLivraisons);
router.post('/livraisons/:id/livrer', livrerLivraison);

// Vehicles
router.get('/vehicules', getVehicules);

module.exports = router;



