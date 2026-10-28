const mongoose = require('mongoose');
const imageField = require('./imageField');

const boxSchema = new mongoose.Schema(
  { x: Number, y: Number, width: Number, height: Number },
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
  image: imageField,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Car', carSchema);
