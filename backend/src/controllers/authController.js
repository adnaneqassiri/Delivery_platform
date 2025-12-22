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
    
    // Store in session
    req.session.userId = result.p_id;
    req.session.role = result.p_role;
    req.session.nom_utilisateur = nom_utilisateur;
    
    res.json({
      success: true,
      data: {
        id: result.p_id,
        role: result.p_role,
        nom_utilisateur: nom_utilisateur
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
    
    res.json({
      success: true,
      data: {
        id: req.session.userId,
        role: req.session.role,
        nom_utilisateur: req.session.nom_utilisateur
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

