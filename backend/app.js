const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const errorHandler = require('./middleware/errorHandler');
const { authLimiter, scanLimiter } = require('./middleware/rateLimits');
const authRoutes = require('./routes/auth');
const carRoutes = require('./routes/cars');
const predictRoutes = require('./routes/predict');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors(config.corsOrigins.length ? { origin: config.corsOrigins } : undefined));
app.use(express.json({ limit: '10mb' }));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/predict', scanLimiter, predictRoutes);

app.use((req, res) => res.status(404).json({ error: 'Introuvable' }));
app.use(errorHandler);

module.exports = app;
