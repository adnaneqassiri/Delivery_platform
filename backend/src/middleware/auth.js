// Middleware to check if user is authenticated
const requireAuth = (req, res, next) => {
  if (!req.session || !req.session.userId) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required'
    });
  }
  next();
};

// Middleware to check if user has required role(s)
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.session || !req.session.userId) {
      console.log('requireRole - No session or userId:', {
        hasSession: !!req.session,
        userId: req.session?.userId,
        sessionId: req.sessionID
      });
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }
    
    // Normalize roles for comparison (uppercase and trim)
    const sessionRole = req.session.role ? req.session.role.trim().toUpperCase() : null;
    const normalizedRequiredRoles = roles.map(r => r.trim().toUpperCase());
    
    console.log('requireRole - Checking role:', {
      sessionRole: sessionRole,
      originalSessionRole: req.session.role,
      requiredRoles: normalizedRequiredRoles,
      originalRequiredRoles: roles,
      userId: req.session.userId,
      sessionId: req.sessionID
    });
    
    if (!sessionRole || !normalizedRequiredRoles.includes(sessionRole)) {
      console.log('requireRole - Insufficient permissions:', {
        sessionRole: sessionRole,
        requiredRoles: normalizedRequiredRoles,
        match: normalizedRequiredRoles.includes(sessionRole)
      });
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }
    
    next();
  };
};

module.exports = {
  requireAuth,
  requireRole
};



