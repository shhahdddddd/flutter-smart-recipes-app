const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwt: jwtConfig } = require('../config/auth.config');

const protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization?.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
      
      const decoded = jwt.verify(token, jwtConfig.secret);
      req.user = await User.findById(decoded.id).select('-password');
      
      if (!req.user) {
        return res.status(401).json({ 
          success: false,
          error: 'Utilisateur non trouvé' 
        });
      }
      
      return next();
    }

    res.status(401).json({ 
      success: false,
      error: 'Non autorisé, token manquant' 
    });
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(401).json({ 
      success: false,
      error: 'Token invalide' 
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    if (req.headers.authorization?.startsWith('Bearer')) {
      const token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, jwtConfig.secret);
      req.user = await User.findById(decoded.id).select('-password');
    }
    next();
  } catch (error) {
    next(); // Continue without user for optional auth
  }
};

module.exports = {
  protect,
  optionalAuth
};