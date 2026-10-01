const mongoose = require('mongoose');

const carSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  recognizedName: { type: String, default: 'Modèle reconnu par l’IA' },
  caption: { type: String, default: '' },
  image: {
    data: { type: Buffer, required: true },
    contentType: { type: String, required: true },
  },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Car', carSchema);
