const { callProcedure, executeQuery } = require('../utils/oracleHelper');

// Get available livraisons (statut = 'CREEE')
// Only from livreur's entrepot and with at least 1 colis
const getAvailableLivraisons = async (req, res, next) => {
  try {
    const id_livreur = req.session.userId;
    
    // Get livreur's entrepot
    const userInfo = await executeQuery(
      'SELECT id_entrepot FROM utilisateurs WHERE id_utilisateur = :id',
      { id: id_livreur }
    );
    
    if (!userInfo || userInfo.length === 0 || !userInfo[0].ID_ENTREPOT) {
      return res.status(400).json({
        success: false,
        message: 'Livreur must be assigned to an entrepot'
      });
    }
    
    const id_entrepot = userInfo[0].ID_ENTREPOT;
    
    // Get livraisons from livreur's entrepot with at least 1 colis
    const livraisons = await executeQuery(
      `SELECT l.id_livraison,
              e1.ville || ' - ' || e1.adresse AS source,
              e2.ville || ' - ' || e2.adresse AS destination,
              u.nom_utilisateur AS livreur,
              v.immatriculation AS vehicule,
              l.statut,
              l.date_creation,
              l.date_livraison,
              COUNT(c.id_colis) AS nb_colis
       FROM livraisons l
       JOIN entrepots e1 ON l.id_entrepot_source = e1.id_entrepot
       JOIN entrepots e2 ON l.id_entrepot_destination = e2.id_entrepot
       LEFT JOIN utilisateurs u ON l.id_livreur = u.id_utilisateur
       LEFT JOIN vehicules v ON l.id_vehicule = v.id_vehicule
       LEFT JOIN colis c ON l.id_livraison = c.id_livraison
       WHERE l.statut = 'CREEE'
         AND l.id_entrepot_source = :id_entrepot
       GROUP BY l.id_livraison, e1.ville, e1.adresse, e2.ville, e2.adresse,
                u.nom_utilisateur, v.immatriculation, l.statut,
                l.date_creation, l.date_livraison
       HAVING COUNT(c.id_colis) >= 1
       ORDER BY l.date_creation DESC`,
      { id_entrepot }
    );
    
    res.json({
      success: true,
      data: livraisons
    });
  } catch (err) {
    next(err);
  }
};

// Take a livraison
const prendreLivraison = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { id_vehicule } = req.body;
    const id_livreur = req.session.userId;
    
    if (!id_vehicule) {
      return res.status(400).json({
        success: false,
        message: 'id_vehicule is required'
      });
    }
    
    await callProcedure(
      'pkg_logitrack.p_prendre_livraison',
      {
        p_id_livraison: parseInt(id),
        p_id_livreur: id_livreur,
        p_id_vehicule: parseInt(id_vehicule)
      },
      {}
    );
    
    res.json({
      success: true,
      message: 'Livraison taken successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get my livraisons (assigned to current livreur)
const getMyLivraisons = async (req, res, next) => {
  try {
    const id_livreur = req.session.userId;
    const livraisons = await executeQuery(
      `SELECT l.id_livraison,
              e1.ville || ' - ' || e1.adresse AS source,
              e2.ville || ' - ' || e2.adresse AS destination,
              u.nom_utilisateur AS livreur,
              v.immatriculation AS vehicule,
              l.statut,
              l.date_creation,
              l.date_livraison,
              COUNT(c.id_colis) AS nb_colis
       FROM livraisons l
       JOIN entrepots e1 ON l.id_entrepot_source = e1.id_entrepot
       JOIN entrepots e2 ON l.id_entrepot_destination = e2.id_entrepot
       LEFT JOIN utilisateurs u ON l.id_livreur = u.id_utilisateur
       LEFT JOIN vehicules v ON l.id_vehicule = v.id_vehicule
       LEFT JOIN colis c ON l.id_livraison = c.id_livraison
       WHERE l.id_livreur = :id_livreur
         AND l.statut IN ('EN_COURS', 'LIVREE')
       GROUP BY l.id_livraison, e1.ville, e1.adresse, e2.ville, e2.adresse,
                u.nom_utilisateur, v.immatriculation, l.statut,
                l.date_creation, l.date_livraison
       ORDER BY l.date_creation DESC`,
      { id_livreur }
    );
    
    res.json({
      success: true,
      data: livraisons
    });
  } catch (err) {
    next(err);
  }
};

// Deliver a livraison
const livrerLivraison = async (req, res, next) => {
  try {
    const { id } = req.params;
    const id_user = req.session.userId;
    
    await callProcedure(
      'pkg_logitrack.p_livrer_livraison',
      {
        p_id_livraison: parseInt(id),
        p_id_user: id_user
      },
      {}
    );
    
    res.json({
      success: true,
      message: 'Livraison delivered successfully'
    });
  } catch (err) {
    next(err);
  }
};

// Get available vehicles
const getVehicules = async (req, res, next) => {
  try {
    const vehicules = await executeQuery(
      `SELECT * FROM v_vehicules_entrepots 
       WHERE statut_vehicule = 'DISPONIBLE'
       ORDER BY immatriculation`
    );
    
    res.json({
      success: true,
      data: vehicules
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAvailableLivraisons,
  prendreLivraison,
  getMyLivraisons,
  livrerLivraison,
  getVehicules
};

