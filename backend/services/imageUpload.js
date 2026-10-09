const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

function readImage(body) {
  const { image, contentType } = body;
  if (typeof image !== 'string' || !ALLOWED_TYPES.includes(contentType)) {
    return { error: 'Image invalide' };
  }
  const data = Buffer.from(image, 'base64');
  if (data.length === 0 || data.length > MAX_IMAGE_BYTES) {
    return { error: 'Image vide ou trop lourde (6 Mo max)' };
  }
  return { image: { data, contentType } };
}

module.exports = { readImage };
