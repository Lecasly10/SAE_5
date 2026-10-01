const express = require('express');
const mongoose = require('mongoose');
const Car = require('../models/Car');
const requireAuth = require('../middleware/requireAuth');
const router = express.Router();

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

router.use(requireAuth);

const toJson = (car) => ({
  id: car._id,
  recognizedName: car.recognizedName,
  caption: car.caption || '',
  createdAt: car.createdAt,
});

router.post('/', async (req, res) => {
  try {
    const { image, contentType } = req.body;
    if (typeof image !== 'string' || !ALLOWED_TYPES.includes(contentType)) {
      return res.status(400).json({ error: 'Image invalide' });
    }
    const data = Buffer.from(image, 'base64');
    if (data.length === 0 || data.length > MAX_IMAGE_BYTES) {
      return res.status(400).json({ error: 'Image vide ou trop lourde (6 Mo max)' });
    }
    const car = await Car.create({
      user: req.userId,
      image: { data, contentType },
    });
    res.status(201).json(toJson(car));
  } catch (err) {
    res.status(500).json({ error: 'Impossible de sauvegarder la photo' });
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
