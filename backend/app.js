const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const errorHandler = require('./middleware/errorHandler');
const { accountLimiter, authLimiter, scanLimiter } = require('./middleware/rateLimits');
const accountRoutes = require('./routes/account');
const authRoutes = require('./routes/auth');
const catalogRoutes = require('./routes/catalog');
const carRoutes = require('./routes/cars');
const predictRoutes = require('./routes/predict');
const trainingPhotoRoutes = require('./routes/trainingPhotos');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors(config.corsOrigins.length ? { origin: config.corsOrigins } : undefined));
app.use(express.json({ limit: '10mb' }));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/account', accountLimiter, accountRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/catalog', catalogRoutes);
app.use('/api/predict', scanLimiter, predictRoutes);
app.use('/api/training-photos', scanLimiter, trainingPhotoRoutes);

app.use((req, res) => res.status(404).json({ error: 'Introuvable' }));
app.use(errorHandler);

module.exports = app;
