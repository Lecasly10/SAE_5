const mongoose = require('mongoose');

const DB_NAME = 'spotit';

// Sans dbName, une adresse sans nom de base (...mongodb.net/?...) écrit dans "test".
function connectDatabase(uri) {
  return mongoose.connect(uri, { dbName: DB_NAME });
}

module.exports = { DB_NAME, connectDatabase };
