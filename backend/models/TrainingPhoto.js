const mongoose = require('mongoose');
const imageField = require('./imageField');

// Photo dont l'utilisateur a confirmé la voiture : elle sert à réentraîner l'IA.
const trainingPhotoSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  carId: { type: String, required: true },
  image: imageField,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('TrainingPhoto', trainingPhotoSchema);
