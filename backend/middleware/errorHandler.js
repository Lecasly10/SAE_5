const { HttpError } = require('../errors');

module.exports = function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message });
  }
  if (err.status >= 400 && err.status < 500) {
    return res.status(err.status).json({ error: 'Requête invalide' });
  }
  console.error(err);
  res.status(500).json({ error: 'Erreur du serveur' });
};
