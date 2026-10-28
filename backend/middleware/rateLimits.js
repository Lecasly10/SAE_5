const { rateLimit } = require('express-rate-limit');

const limiter = (windowMs, limit, error) =>
  rateLimit({ windowMs, limit, standardHeaders: true, legacyHeaders: false, message: { error } });

module.exports = {
  authLimiter: limiter(15 * 60 * 1000, 30, 'Trop de tentatives, réessayez dans quelques minutes'),
  accountLimiter: limiter(15 * 60 * 1000, 60, 'Trop de modifications, réessayez dans quelques minutes'),
  scanLimiter: limiter(60 * 1000, 30, 'Trop d’analyses, patientez une minute'),
};
