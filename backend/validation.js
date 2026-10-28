const { HttpError } = require('./errors');

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_NAME_LENGTH = 60;
const MAX_EMAIL_LENGTH = 254;

const cleanEmail = (value) => (typeof value === 'string' ? value.trim().toLowerCase() : '');

function readName(value) {
  const name = typeof value === 'string' ? value.trim() : '';
  if (!name || name.length > MAX_NAME_LENGTH) throw new HttpError(400, 'Nom invalide');
  return name;
}

function readEmail(value) {
  const email = cleanEmail(value);
  if (email.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(email)) throw new HttpError(400, 'Email invalide');
  return email;
}

module.exports = { cleanEmail, readName, readEmail };
