const crypto = require('node:crypto');

if (!process.env.JWT_SECRET) {
  // En ligne, une clé qui change à chaque redémarrage déconnecterait tout le monde
  if (process.env.NODE_ENV === 'production') {
    console.error('JWT_SECRET est obligatoire en production.');
    process.exit(1);
  }
  console.warn('JWT_SECRET absent : clé temporaire utilisée, les connexions seront perdues au redémarrage.');
}

module.exports = {
  port: Number(process.env.PORT) || 3000,
  mongoUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex'),
  aiUrl: process.env.AI_URL || 'http://localhost:5000',
  // Service qui donne le nom du lieu d'une photo ; vide pour ne pas l'utiliser
  geocoderUrl: process.env.GEOCODER_URL ?? 'https://nominatim.openstreetmap.org',
  // Nombre de proxys devant le serveur (nginx sur le serveur en ligne), pour
  // que les limites de requêtes voient l'adresse du visiteur et pas celle du proxy
  trustProxy: Number(process.env.TRUST_PROXY) || false,
  corsOrigins: (process.env.CORS_ORIGIN || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
};
