const { callProcedure, executeQuery } = require('../utils/oracleHelper');

// Get vehicules for gestionnaire's entrepot
const getVehicules = async (req, res, next) => {
  try {
    const id_user = req.session.userId;
    const id_entrepot = req.session.id_entrepot;
    
    if (!id_entrepot) {
      // Get user's entrepot from database
      try {
        const userInfo = await executeQuery(
          'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
          { id: id_user }
        );
        if (userInfo[0]?.ID_ENTREPOT) {
          req.session.id_entrepot = userInfo[0].ID_ENTREPOT;
          id_entrepot = userInfo[0].ID_ENTREPOT;
        } else {
          return res.status(400).json({
            success: false,
            message: 'Gestionnaire must be assigned to an entrepot'
          });
        }
      } catch (err) {
        return res.status(400).json({
          success: false,
          message: 'Gestionnaire must be assigned to an entrepot'
        });
      }
    }
    
    const vehicules = await executeQuery(
      `SELECT v.id_vehicule, v.immatriculation, v.type_vehicule, v.statut, 
              v.id_entrepot, v.date_creation,
              e.ville || ' - ' || e.adresse AS entrepot_nom
       FROM vehicules v
       LEFT JOIN entrepots e ON v.id_entrepot = e.id_entrepot
       WHERE v.id_entrepot = :id_entrepot
       ORDER BY v.immatriculation`,
      { id_entrepot }
    );
    
    res.json({
      success: true,
      data: vehicules
    });
  } catch (err) {
    next(err);
  }
};

// Update vehicule status (only DISPONIBLE <-> MAINTENANCE, not EN_UTILISATION)
const updateVehiculeStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;
    const id_user = req.session.userId;
    const id_entrepot = req.session.id_entrepot;
    
    if (!id_entrepot) {
      // Get user's entrepot from database
      try {
        const userInfo = await executeQuery(
          'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
          { id: id_user }
        );
        if (userInfo[0]?.ID_ENTREPOT) {
          req.session.id_entrepot = userInfo[0].ID_ENTREPOT;
          id_entrepot = userInfo[0].ID_ENTREPOT;
        } else {
          return res.status(400).json({
            success: false,
            message: 'Gestionnaire must be assigned to an entrepot'
          });
        }
      } catch (err) {
        return res.status(400).json({
          success: false,
          message: 'Gestionnaire must be assigned to an entrepot'
        });
      }
    }
    
    if (!statut) {
      return res.status(400).json({
        success: false,
        message: 'statut is required'
      });
    }
    
    // Validate statut
    if (!['DISPONIBLE', 'MAINTENANCE'].includes(statut)) {
      return res.status(400).json({
        success: false,
        message: 'statut must be DISPONIBLE or MAINTENANCE'
      });
    }
    
    // Check if vehicule exists and belongs to gestionnaire's entrepot
    const vehicule = await executeQuery(
      'SELECT id_vehicule, statut, id_entrepot FROM vehicules WHERE id_vehicule = :id',
      { id: parseInt(id) }
    );
    
    if (vehicule.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Vehicule not found'
      });
    }
    
    if (vehicule[0].ID_ENTREPOT !== id_entrepot) {
      return res.status(403).json({
        success: false,
        message: 'You can only modify vehicules from your entrepot'
      });
    }
    
    // Cannot change status if it's EN_UTILISATION
    if (vehicule[0].STATUT === 'EN_UTILISATION') {
      return res.status(400).json({
        success: false,
        message: 'Cannot change status of a vehicule that is EN_UTILISATION'
      });
    }
    
    // Update status
    await executeQuery(
      'UPDATE vehicules SET statut = :statut WHERE id_vehicule = :id',
      { statut, id: parseInt(id) }
    );
    
    res.json({
      success: true,
      message: 'Vehicule status updated successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get colis expédiés (sent from gestionnaire's entrepot)
const getColisExpedies = async (req, res, next) => {
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
    
    // Get colis expédiés: colis sent from this gestionnaire's entrepot
    // These are colis where id_entrepot_localisation = gestionnaire's entrepot
    // (colis that were created/registered at this entrepot and sent from here)
    const colis = await executeQuery(
      `SELECT c.* 
       FROM v_colis_details c
       JOIN colis col ON c.id_colis = col.id_colis
       WHERE col.id_entrepot_localisation = :id_entrepot
         AND col.statut NOT IN ('RECUPEREE')
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

// Get colis reçus (received at gestionnaire's entrepot, waiting to be picked up)
const getColisRecus = async (req, res, next) => {
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
    
    // Get colis reçus: colis that have arrived at this entrepot (destination entrepot)
    // These are colis where the livraison destination is this entrepot
    // and the colis is currently at this entrepot (id_entrepot_localisation = destination)
    // Status should be RECEPTIONNEE (colis received at destination entrepot)
    const colis = await executeQuery(
      `SELECT c.* 
       FROM v_colis_details c
       JOIN colis col ON c.id_colis = col.id_colis
       JOIN livraisons l ON col.id_livraison = l.id_livraison
       WHERE l.id_entrepot_destination = :id_entrepot
         AND col.id_entrepot_localisation = :id_entrepot
         AND col.statut = 'RECEPTIONNEE'
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

// Modify colis status for expédiés (only allow ANNULEE)
const modifyColisStatusExpedies = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;
    const id_user = req.session.userId;
    
    // Only allow ANNULEE status for expédiés
    if (statut !== 'ANNULEE') {
      return res.status(400).json({
        success: false,
        message: 'You can only cancel (ANNULEE) colis expédiés'
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
      message: 'Colis cancelled successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Mark colis as recovered
// Mark colis as recovered (for colis reçus)
const markColisRecupereeRecus = async (req, res, next) => {
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

// Get all clients (only clients created by this gestionnaire)
const getClients = async (req, res, next) => {
  try {
    const id_gestionnaire = req.session.userId;
    
    const clients = await executeQuery(
      'SELECT * FROM clients WHERE id_gestionnaire_ajout = :id_gestionnaire ORDER BY id_client',
      { id_gestionnaire }
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
  getColisExpedies,
  getColisRecus,
  addColis,
  modifyColisStatusExpedies,
  markColisRecupereeRecus,
  getClients,
  createClient,
  getEntrepots,
  getColisHistory,
  getVehicules,
  updateVehiculeStatus
};



