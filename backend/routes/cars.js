const express = require('express');
const mongoose = require('mongoose');
const Car = require('../models/Car');
const requireAuth = require('../middleware/requireAuth');
const { readImage } = require('../services/imageUpload');
const { recognizeCar, RecognitionError } = require('../services/recognition');
const router = express.Router();

router.use(requireAuth);

const toJson = (car) => ({
  id: car._id,
  brand: car.brand,
  model: car.model,
  years: car.years,
  confidence: car.confidence,
  box: car.box,
  createdAt: car.createdAt,
});

router.post('/', async (req, res) => {
  const { image, error } = readImage(req.body);
  if (error) return res.status(400).json({ error });

  try {
    const recognition = await recognizeCar(image.data);
    const car = await Car.create({ user: req.userId, image, ...recognition });
    res.status(201).json(toJson(car));
  } catch (err) {
    const unavailable = err instanceof RecognitionError;
    res.status(unavailable ? 503 : 500).json({
      error: unavailable ? err.message : 'Impossible de sauvegarder la photo',
    });
  }
});

router.get('/', async (req, res) => {
  try {
    const cars = await Car.find({ user: req.userId })
      .select('-image')
      .sort({ createdAt: -1 });
    res.json(cars.map(toJson));
  } catch (err) {
    res.status(500).json({ error: 'Impossible de charger la bibliothèque' });
  }
});

router.get('/:id/image', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(404).json({ error: 'Introuvable' });
    }
    const car = await Car.findOne({ _id: req.params.id, user: req.userId });
    if (!car) return res.status(404).json({ error: 'Introuvable' });
    res.set('Content-Type', car.image.contentType);
    res.set('Cache-Control', 'private, max-age=86400');
    res.send(car.image.data);
  } catch (err) {
    res.status(500).json({ error: 'Impossible de charger la photo' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(404).json({ error: 'Introuvable' });
    }
    const car = await Car.findOneAndDelete({ _id: req.params.id, user: req.userId });
    if (!car) return res.status(404).json({ error: 'Introuvable' });
    res.status(204).end();
  } catch (err) {
    res.status(500).json({ error: 'Impossible de supprimer la photo' });
  }
});

module.exports = router;
