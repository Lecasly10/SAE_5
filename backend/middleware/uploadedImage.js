const { HttpError } = require('../errors');

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

// Premiers octets de chaque format : un fichier qui n'est pas une vraie image est refusé
const SIGNATURES = {
  'image/jpeg': (data) => data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff,
  'image/png': (data) => data.subarray(0, 8).equals(PNG_SIGNATURE),
  'image/webp': (data) => data.toString('latin1', 0, 4) === 'RIFF' && data.toString('latin1', 8, 12) === 'WEBP',
};
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

module.exports = function uploadedImage(req, res, next) {
  const { image, contentType } = req.body ?? {};
  if (typeof image !== 'string' || !Object.hasOwn(SIGNATURES, contentType)) {
    throw new HttpError(400, 'Image invalide');
  }

  const data = Buffer.from(image, 'base64');
  if (data.length === 0 || data.length > MAX_IMAGE_BYTES) {
    throw new HttpError(400, 'Image vide ou trop lourde (6 Mo max)');
  }
  if (!SIGNATURES[contentType](data)) throw new HttpError(400, 'Image invalide');

  req.image = { data, contentType };
  next();
};
