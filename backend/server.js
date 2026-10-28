require('dotenv').config({ path: require('node:path').resolve(__dirname, '../.env'), quiet: true });
const app = require('./app');
const config = require('./config');
const { connectDatabase } = require('./database');

if (!config.mongoUri) {
  console.error('MONGODB_URI manquant : voir .env.example');
  process.exit(1);
}

connectDatabase(config.mongoUri)
  .then(() => {
    console.log('MongoDB connecté');
    app.listen(config.port, () => console.log(`Serveur sur le port ${config.port}`));
  })
  .catch((err) => {
    console.error('Connexion MongoDB impossible :', err.message);
    process.exit(1);
  });
