const { callProcedure, executeQuery } = require('../utils/oracleHelper');

const login = async (req, res, next) => {
  try {
    const { nom_utilisateur, mot_de_passe } = req.body;
    
    if (!nom_utilisateur || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required'
      });
    }
    
    // Call pkg_logitrack.p_login
    const result = await callProcedure(
      'pkg_logitrack.p_login',
      {
        p_nom: nom_utilisateur,
        p_pwd: mot_de_passe
      },
      {
        p_id: 'NUMBER',
        p_role: 'VARCHAR2'
      }
    );
    
    console.log('Login result:', result);
    
    if (!result || result.p_id === 0 || result.p_id === null || result.p_id === undefined || !result.p_role) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    // Get user's entrepot (if column exists)
    let id_entrepot = null;
    try {
      const userInfo = await executeQuery(
        'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
        { id: result.p_id }
      );
      id_entrepot = userInfo[0]?.ID_ENTREPOT || null;
    } catch (err) {
      // Column might not exist yet, set to null
      console.log('id_entrepot column not found, setting to null');
      id_entrepot = null;
    }
    
    // Store in session (normalize role to uppercase and trim)
    req.session.userId = result.p_id;
    req.session.role = result.p_role ? result.p_role.trim().toUpperCase() : null;
    req.session.nom_utilisateur = nom_utilisateur;
    req.session.id_entrepot = id_entrepot;
    
    console.log('Login - Session stored:', {
      userId: req.session.userId,
      role: req.session.role,
      id_entrepot: id_entrepot,
      originalRole: result.p_role
    });
    
    res.json({
      success: true,
      data: {
        id: result.p_id,
        role: result.p_role,
        nom_utilisateur: nom_utilisateur,
        id_entrepot: id_entrepot
      },
      message: 'Login successful'
    });
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    req.session.destroy((err) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Error logging out'
        });
      }
      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    });
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    if (!req.session || !req.session.userId) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated'
      });
    }
    
<<<<<<< HEAD
    // Get user's entrepot if not in session
    let id_entrepot = req.session.id_entrepot;
    if (!id_entrepot) {
      try {
        const userInfo = await executeQuery(
          'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
          { id: req.session.userId }
        );
        id_entrepot = userInfo[0]?.ID_ENTREPOT || null;
        req.session.id_entrepot = id_entrepot;
      } catch (err) {
        // Column might not exist yet, set to null
        console.log('id_entrepot column not found, setting to null');
        id_entrepot = null;
        req.session.id_entrepot = null;
      }
=======
    // Always get user's entrepot from database to ensure it's up to date
    // (in case it was updated after login)
    let id_entrepot = null;
    try {
      const userInfo = await executeQuery(
        'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
        { id: req.session.userId }
      );
      id_entrepot = userInfo[0]?.ID_ENTREPOT || null;
      // Update session with latest value
      req.session.id_entrepot = id_entrepot;
    } catch (err) {
      // Column might not exist yet, set to null
      console.log('id_entrepot column not found, setting to null');
      id_entrepot = null;
      req.session.id_entrepot = null;
>>>>>>> e2abf37e3262a183a9bb15493d4768a4f62ebff5
    }
    
    res.json({
      success: true,
      data: {
        id: req.session.userId,
        role: req.session.role,
        nom_utilisateur: req.session.nom_utilisateur,
        id_entrepot: id_entrepot
      }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  login,
  logout,
  getMe
};

