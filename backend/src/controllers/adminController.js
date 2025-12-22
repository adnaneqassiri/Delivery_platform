const { callProcedure, executeQuery } = require('../utils/oracleHelper');
const { requireAuth, requireRole } = require('../middleware/auth');

// Get KPIs from v_kpi_dashboard view
const getKPIs = async (req, res, next) => {
  try {
    const kpis = await executeQuery('SELECT * FROM v_kpi_dashboard');
    
    if (kpis.length === 0) {
      return res.json({
        success: true,
        data: {
          colis_count: 0,
          livraisons_count: 0,
          chiffre_affaire: 0,
          livreurs_count: 0,
          entrepots_count: 0,
          clients_count: 0
        }
      });
    }
    
    // Get additional counts for admins and gestionnaires
    const adminCount = await executeQuery(
      "SELECT COUNT(*) as count FROM utilisateurs WHERE role = 'ADMIN' AND actif = 1"
    );
    const gestionnaireCount = await executeQuery(
      "SELECT COUNT(*) as count FROM utilisateurs WHERE role = 'GESTIONNAIRE' AND actif = 1"
    );
    
    res.json({
      success: true,
      data: {
        ...kpis[0],
        admins_count: adminCount[0]?.COUNT || 0,
        gestionnaires_count: gestionnaireCount[0]?.COUNT || 0
      }
    });
  } catch (err) {
    next(err);
  }
};

// Get all users
const getUsers = async (req, res, next) => {
  try {
    const users = await executeQuery(
      'SELECT id_utilisateur, nom_utilisateur, role, cin, actif, date_creation FROM utilisateurs ORDER BY id_utilisateur'
    );
    
    res.json({
      success: true,
      data: users
    });
  } catch (err) {
    next(err);
  }
};

// Create user
const createUser = async (req, res, next) => {
  try {
    const { nom_utilisateur, mot_de_passe, role, cin } = req.body;
    
    if (!nom_utilisateur || !mot_de_passe || !role) {
      return res.status(400).json({
        success: false,
        message: 'nom_utilisateur, mot_de_passe, and role are required'
      });
    }
    
    const result = await callProcedure(
      'pkg_logitrack.p_creer_utilisateur',
      {
        p_nom: nom_utilisateur,
        p_pwd: mot_de_passe,
        p_role: role,
        p_cin: cin || null
      },
      {
        p_id: 'NUMBER'
      }
    );
    
    res.json({
      success: true,
      data: { id: result.p_id },
      message: 'User created successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Update user (activate/deactivate)
const updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { actif, role, cin } = req.body;
    
    const updates = [];
    const binds = { id: parseInt(id) };
    
    if (actif !== undefined) {
      updates.push('actif = :actif');
      binds.actif = actif ? 1 : 0;
    }
    
    if (role) {
      updates.push('role = :role');
      binds.role = role;
    }
    
    if (cin !== undefined) {
      updates.push('cin = :cin');
      binds.cin = cin || null;
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }
    
    const query = `UPDATE utilisateurs SET ${updates.join(', ')} WHERE id_utilisateur = :id`;
    await executeQuery(query, binds);
    
    res.json({
      success: true,
      message: 'User updated successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get all entrepots
const getEntrepots = async (req, res, next) => {
  try {
    const entrepots = await executeQuery(`
      SELECT e.id_entrepot, e.adresse, e.ville, e.telephone, e.date_creation,
             u.nom_utilisateur as gestionnaire_nom, e.id_user
      FROM entrepots e
      LEFT JOIN utilisateurs u ON e.id_user = u.id_utilisateur
      ORDER BY e.id_entrepot
    `);
    
    res.json({
      success: true,
      data: entrepots
    });
  } catch (err) {
    next(err);
  }
};

// Create entrepot
const createEntrepot = async (req, res, next) => {
  try {
    const { adresse, ville, telephone, id_user } = req.body;
    
    if (!adresse || !ville) {
      return res.status(400).json({
        success: false,
        message: 'adresse and ville are required'
      });
    }
    
    const result = await callProcedure(
      'pkg_logitrack.p_creer_entrepot',
      {
        p_adresse: adresse,
        p_ville: ville,
        p_tel: telephone || null,
        p_id_user: id_user || null
      },
      {
        p_id: 'NUMBER'
      }
    );
    
    res.json({
      success: true,
      data: { id: result.p_id },
      message: 'Entrepot created successfully'
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

// Get gestionnaires for dropdown
const getGestionnaires = async (req, res, next) => {
  try {
    const gestionnaires = await executeQuery(
      "SELECT id_utilisateur, nom_utilisateur FROM utilisateurs WHERE role IN ('GESTIONNAIRE', 'ADMIN') AND actif = 1 ORDER BY nom_utilisateur"
    );
    
    res.json({
      success: true,
      data: gestionnaires
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getKPIs,
  getUsers,
  createUser,
  updateUser,
  getEntrepots,
  createEntrepot,
  getClients,
  createClient,
  getGestionnaires
};



