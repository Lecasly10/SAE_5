const jwt = require('jsonwebtoken');
const config = require('../config');
const { HttpError } = require('../errors');

module.exports = function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new HttpError(401, 'Connexion requise');

  try {
    req.userId = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] }).id;
  } catch (err) {
    throw new HttpError(401, 'Session expirée, reconnectez-vous');
  }
  next();
};
