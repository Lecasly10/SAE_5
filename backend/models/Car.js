const mongoose = require('mongoose');

const boxSchema = new mongoose.Schema(
  { x: Number, y: Number, width: Number, height: Number },
  { _id: false }
);

const carSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  brand: { type: String, required: true },
  model: { type: String, default: '' },
  years: { type: String, default: '' },
  confidence: { type: Number, required: true },
  box: { type: boxSchema, default: null },
  image: {
    data: { type: Buffer, required: true },
    contentType: { type: String, required: true },
  },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Car', carSchema);
