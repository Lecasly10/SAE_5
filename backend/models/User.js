const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  // Accord pour que ses photos servent à entraîner l'IA, refusé par défaut
  trainingConsent: { type: Boolean, default: false },
  trainingConsentAt: { type: Date, default: null },
});

module.exports = mongoose.model('User', userSchema);
