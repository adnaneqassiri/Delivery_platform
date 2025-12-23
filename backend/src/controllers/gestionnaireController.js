const { callProcedure, executeQuery } = require('../utils/oracleHelper');

// Get all colis with details (filtered by gestionnaire's entrepot)
const getColis = async (req, res, next) => {
  try {
    const id_user = req.session.userId;
    
    // Get user's entrepot
    let id_entrepot = req.session.id_entrepot;
    if (!id_entrepot) {
      try {
        const userInfo = await executeQuery(
          'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
          { id: id_user }
        );
        id_entrepot = userInfo[0]?.ID_ENTREPOT || null;
        req.session.id_entrepot = id_entrepot;
      } catch (err) {
        id_entrepot = null;
      }
    }
    
    if (!id_entrepot) {
      return res.status(400).json({
        success: false,
        message: 'User must be assigned to an entrepot to view colis'
      });
    }
    
    // Get colis that are:
    // 1. Sent from this entrepot (id_entrepot_localisation = user's entrepot) AND not yet delivered
    // 2. OR delivered to this entrepot (id_entrepot_localisation = user's entrepot) AND status is LIVRE or RECUPEREE
    const colis = await executeQuery(
      `SELECT c.* 
       FROM v_colis_details c
       JOIN colis col ON c.id_colis = col.id_colis
       WHERE (
         -- Colis sent from this entrepot (not yet delivered)
         (col.id_entrepot_localisation = :id_entrepot AND col.statut != 'LIVRE' AND col.statut != 'RECUPEREE')
         OR
         -- Colis delivered to this entrepot (can be marked as recovered)
         (col.id_entrepot_localisation = :id_entrepot AND col.statut IN ('LIVRE', 'RECUPEREE'))
       )
       ORDER BY c.id_colis DESC`,
      { id_entrepot: id_entrepot }
    );
    
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
    const { id_client, poids, type, receiver_cin, id_entrepot_reception } = req.body;
    const id_user = req.session.userId;
    
    // Get user's entrepot (if column exists)
    let id_entrepot_expedition = req.session.id_entrepot;
    if (!id_entrepot_expedition) {
      try {
        const userInfo = await executeQuery(
          'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
          { id: id_user }
        );
        id_entrepot_expedition = userInfo[0]?.ID_ENTREPOT || null;
        req.session.id_entrepot = id_entrepot_expedition;
      } catch (err) {
        // Column might not exist yet
        console.log('id_entrepot column not found');
        id_entrepot_expedition = null;
      }
    }
    
    if (!poids || poids < 1) {
      return res.status(400).json({
        success: false,
        message: 'poids is required and must be at least 1'
      });
    }
    
    if (!receiver_cin || !id_entrepot_reception) {
      return res.status(400).json({
        success: false,
        message: 'receiver_cin and id_entrepot_reception are required'
      });
    }
    
    if (!id_entrepot_expedition) {
      return res.status(400).json({
        success: false,
        message: 'User must be assigned to an entrepot (Entrepôt d\'expédition). Please contact admin to assign an entrepot to your account.'
      });
    }
    
    // Get ville_destination from entrepot_reception
    const entrepotInfo = await executeQuery(
      'SELECT ville FROM entrepots WHERE id_entrepot = :id',
      { id: parseInt(id_entrepot_reception) }
    );
    
    if (!entrepotInfo || entrepotInfo.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid entrepot de réception'
      });
    }
    
    const ville_destination = entrepotInfo[0].VILLE;
    
    const result = await callProcedure(
      'pkg_logitrack.p_ajouter_colis',
      {
        p_id_client: id_client || null,
        p_poids: poids,
        p_type: type || 'STANDARD',
        p_receiver_cin: receiver_cin,
        p_ville_destination: ville_destination,
        p_id_entrepot_localisation: id_entrepot_expedition,
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
    
    console.log('Marking colis as recovered for CIN:', receiver_cin);
    
    await callProcedure(
      'pkg_logitrack.p_marquer_colis_recuperee',
      {
        p_receiver_cin: receiver_cin.trim(),
        p_id_user: id_user
      },
      {}
    );
    
    res.json({
      success: true,
      message: 'Colis marked as recovered successfully'
    });
  } catch (err) {
    console.error('Error marking colis as recovered:', err.message);
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

// Get entrepots for dropdown (all entrepots for selection)
const getEntrepots = async (req, res, next) => {
  try {
    // Récupérer tous les entrepôts pour le dropdown "Entrepôt de réception"
    const entrepots = await executeQuery(
      'SELECT id_entrepot, ville, adresse FROM entrepots ORDER BY ville, adresse'
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



