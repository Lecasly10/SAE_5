require('dotenv').config({ path: require('node:path').resolve(__dirname, '../.env'), quiet: true });
const mongoose = require('mongoose');
const app = require('./app');
const config = require('./config');

if (!config.mongoUri) {
  console.error('MONGODB_URI manquant : voir .env.example');
  process.exit(1);
}

mongoose
  .connect(config.mongoUri)
  .then(() => {
    console.log('MongoDB connecté');
    app.listen(config.port, () => console.log(`Serveur sur le port ${config.port}`));
  })
  .catch((err) => {
    console.error('Connexion MongoDB impossible :', err.message);
    process.exit(1);
  });
