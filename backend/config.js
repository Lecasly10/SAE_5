const crypto = require('node:crypto');

if (!process.env.JWT_SECRET) {
  console.warn('JWT_SECRET absent : clé temporaire utilisée, les connexions seront perdues au redémarrage.');
}

module.exports = {
  port: Number(process.env.PORT) || 3000,
  mongoUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex'),
  aiUrl: process.env.AI_URL || 'http://localhost:5000',
  corsOrigins: (process.env.CORS_ORIGIN || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
};
