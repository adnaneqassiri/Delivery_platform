const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');
const {
  getKPIs,
  getUsers,
  createUser,
  updateUser,
  getEntrepots,
  createEntrepot,
  getClients,
  createClient,
  getGestionnaires
} = require('../controllers/adminController');

// All admin routes require authentication and ADMIN role
router.use(requireAuth);
router.use(requireRole('ADMIN'));

// KPIs
router.get('/kpis', getKPIs);

// Users
router.get('/users', getUsers);
router.post('/users', createUser);
router.put('/users/:id', updateUser);

// Entrepots
router.get('/entrepots', getEntrepots);
router.post('/entrepots', createEntrepot);
router.get('/gestionnaires', getGestionnaires);

// Clients
router.get('/clients', getClients);
router.post('/clients', createClient);

module.exports = router;



