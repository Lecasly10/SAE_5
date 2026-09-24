require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRoutes = require('./routes/auth');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);

mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('MongoDB OK');
    app.listen(process.env.PORT, () => console.log(`Serveur sur le port ${process.env.PORT}`));
  })
  .catch((err) => console.error('Erreur MongoDB :', err));