const express = require('express');
const TrainingPhoto = require('../models/TrainingPhoto');
const User = require('../models/User');
const { HttpError } = require('../errors');
const requireAuth = require('../middleware/requireAuth');
const uploadedImage = require('../middleware/uploadedImage');
const { findCar, isCarId } = require('../services/recognition');

const router = express.Router();

router.post('/', requireAuth, uploadedImage, async (req, res) => {
  const { carId } = req.body;
  if (!isCarId(carId) || !(await findCar(carId))) throw new HttpError(400, 'Voiture invalide');

  const user = await User.findById(req.userId).select('trainingConsent');
  if (!user?.trainingConsent) {
    throw new HttpError(403, 'Autorisez l’entraînement de l’IA dans les paramètres');
  }

  await TrainingPhoto.create({ user: req.userId, carId, image: req.image });
  res.status(201).json({ saved: true });
});

module.exports = router;
