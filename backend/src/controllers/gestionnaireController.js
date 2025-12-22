const { callProcedure, executeQuery } = require('../utils/oracleHelper');

// Get all colis with details
const getColis = async (req, res, next) => {
  try {
    const colis = await executeQuery('SELECT * FROM v_colis_details ORDER BY id_colis DESC');
    
    res.json({
      success: true,
      data: colis
    });
  } catch (err) {
    next(err);
  }
};

// Add colis
const addColis = async (req, res, next) => {
  try {
    const { id_client, poids, type, receiver_cin, ville_destination, id_entrepot_localisation } = req.body;
    const id_user = req.session.userId;
    
    if (!poids || poids < 1) {
      return res.status(400).json({
        success: false,
        message: 'poids is required and must be at least 1'
      });
    }
    
    if (!receiver_cin || !ville_destination || !id_entrepot_localisation) {
      return res.status(400).json({
        success: false,
        message: 'receiver_cin, ville_destination, and id_entrepot_localisation are required'
      });
    }
    
    const result = await callProcedure(
      'pkg_logitrack.p_ajouter_colis',
      {
        p_id_client: id_client || null,
        p_poids: poids,
        p_type: type || 'STANDARD',
        p_receiver_cin: receiver_cin,
        p_ville_destination: ville_destination,
        p_id_entrepot_localisation: id_entrepot_localisation,
        p_id_user: id_user
      },
      {
        p_id_colis: 'NUMBER'
      }
    );
    
    console.log('Add colis - result.p_id_colis:', result.p_id_colis);
    
    if (!result || result.p_id_colis === undefined || result.p_id_colis === null) {
      console.error('Add colis failed - invalid result:', result);
      return res.status(500).json({
        success: false,
        message: 'Failed to add colis - invalid response from database'
      });
    }
    
    res.json({
      success: true,
      data: { id: result.p_id_colis },
      message: 'Colis added successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Modify colis status
const modifyColisStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;
    const id_user = req.session.userId;
    
    if (!statut) {
      return res.status(400).json({
        success: false,
        message: 'statut is required'
      });
    }
    
    await callProcedure(
      'pkg_logitrack.p_modifier_statut_colis',
      {
        p_id_colis: parseInt(id),
        p_statut: statut,
        p_id_user: id_user
      },
      {}
    );
    
    res.json({
      success: true,
      message: 'Colis status updated successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Mark colis as recovered
const markColisRecuperee = async (req, res, next) => {
  try {
    const { receiver_cin } = req.body;
    const id_user = req.session.userId;
    
    if (!receiver_cin) {
      return res.status(400).json({
        success: false,
        message: 'receiver_cin is required'
      });
    }
    
    await callProcedure(
      'pkg_logitrack.p_marquer_colis_recuperee',
      {
        p_receiver_cin: receiver_cin,
        p_id_user: id_user
      },
      {}
    );
    
    res.json({
      success: true,
      message: 'Colis marked as recovered successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get all clients
const getClients = async (req, res, next) => {
  try {
    const clients = await executeQuery(
      'SELECT * FROM clients ORDER BY id_client'
    );
    
    res.json({
      success: true,
      data: clients
    });
  } catch (err) {
    next(err);
  }
};

// Create client
const createClient = async (req, res, next) => {
  try {
    const { prenom, nom, cin, telephone, email, adresse } = req.body;
    const id_gestionnaire = req.session.userId;
    
    if (!prenom || !nom) {
      return res.status(400).json({
        success: false,
        message: 'prenom and nom are required'
      });
    }
    
    const result = await callProcedure(
      'pkg_logitrack.p_creer_client',
      {
        p_prenom: prenom,
        p_nom: nom,
        p_cin: cin || null,
        p_tel: telephone || null,
        p_email: email || null,
        p_adresse: adresse || null,
        p_id_gestionnaire: id_gestionnaire
      },
      {
        p_id: 'NUMBER'
      }
    );
    
    res.json({
      success: true,
      data: { id: result.p_id },
      message: 'Client created successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get entrepots for dropdown
const getEntrepots = async (req, res, next) => {
  try {
    const entrepots = await executeQuery(
      'SELECT id_entrepot, ville, adresse FROM entrepots ORDER BY ville'
    );
    
    res.json({
      success: true,
      data: entrepots
    });
  } catch (err) {
    next(err);
  }
};

// Get colis history
const getColisHistory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const history = await executeQuery(
      `SELECT h.*, u.nom_utilisateur 
       FROM historique_statut_colis h
       LEFT JOIN utilisateurs u ON h.id_utilisateur = u.id_utilisateur
       WHERE h.id_colis = :id
       ORDER BY h.date_changement DESC`,
      { id: parseInt(id) }
    );
    
    res.json({
      success: true,
      data: history
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getColis,
  addColis,
  modifyColisStatus,
  markColisRecuperee,
  getClients,
  createClient,
  getEntrepots,
  getColisHistory
};



