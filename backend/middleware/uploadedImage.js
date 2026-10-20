const { HttpError } = require('../errors');

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

module.exports = function uploadedImage(req, res, next) {
  const { image, contentType } = req.body ?? {};
  if (typeof image !== 'string' || !ALLOWED_TYPES.includes(contentType)) {
    throw new HttpError(400, 'Image invalide');
  }

  const data = Buffer.from(image, 'base64');
  if (data.length === 0 || data.length > MAX_IMAGE_BYTES) {
    throw new HttpError(400, 'Image vide ou trop lourde (6 Mo max)');
  }

  req.image = { data, contentType };
  next();
};
