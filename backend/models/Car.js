const mongoose = require('mongoose');
const imageField = require('./imageField');

const boxSchema = new mongoose.Schema(
  { x: Number, y: Number, width: Number, height: Number },
  { _id: false }
);

// Lieu le plus proche, par exemple « Port Hercule », « Monaco », « Monaco »
const placeSchema = new mongoose.Schema({ name: String, city: String, country: String }, { _id: false });

// Où la photo a été prise : lue dans la photo, ou position du téléphone
const locationSchema = new mongoose.Schema(
  {
    latitude: Number,
    longitude: Number,
    source: { type: String, enum: ['photo', 'device'] },
    place: { type: placeSchema, default: null },
  },
  { _id: false }
);

const carSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  carId: { type: String, default: null },
  brand: { type: String, required: true },
  model: { type: String, default: '' },
  years: { type: String, default: '' },
  confidence: { type: Number, required: true },
  box: { type: boxSchema, default: null },
  location: { type: locationSchema, default: null },
  // Calculés à l'ajout, d'après la voiture (voir services/rarity.js)
  price: { type: Number, default: null },
  produced: { type: Number, default: null },
  rarity: { type: String, enum: ['commune', 'rare', 'epique', 'legendaire', 'mythique'], default: null },
  image: imageField,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Car', carSchema);
