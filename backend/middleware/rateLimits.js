const jwt = require('jsonwebtoken');
const { rateLimit } = require('express-rate-limit');
const config = require('../config');

// Vrai si la requête porte un jeton de connexion valide
function isLoggedIn(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return false;
  try {
    jwt.verify(header.slice(7), config.jwtSecret, { algorithms: ['HS256'] });
    return true;
  } catch {
    return false;
  }
}

const limiter = (windowMs, limit, error) =>
  rateLimit({ windowMs, limit, standardHeaders: true, legacyHeaders: false, message: { error } });

module.exports = {
  authLimiter: limiter(15 * 60 * 1000, 30, 'Trop de tentatives, réessayez dans quelques minutes'),
  accountLimiter: limiter(15 * 60 * 1000, 60, 'Trop de modifications, réessayez dans quelques minutes'),
  scanLimiter: limiter(60 * 1000, 30, 'Trop d’analyses, patientez une minute'),
  // Sans compte on peut essayer l'IA, mais moins souvent
  predictLimiter: limiter(60 * 1000, (req) => (isLoggedIn(req) ? 30 : 10), 'Trop d’analyses, patientez une minute'),
  // Bibliothèque : chaque photo affichée est une requête
  libraryLimiter: limiter(60 * 1000, 300, 'Trop de requêtes, patientez une minute'),
};
