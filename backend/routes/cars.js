const express = require('express');
const mongoose = require('mongoose');
const Car = require('../models/Car');
const { HttpError } = require('../errors');
const requireAuth = require('../middleware/requireAuth');
const uploadedImage = require('../middleware/uploadedImage');
const { scanLimiter } = require('../middleware/rateLimits');
const { recognizeCar, chooseCar, isCarId } = require('../services/recognition');

const router = express.Router();

router.use(requireAuth);

router.param('id', (req, res, next, id) => {
  next(mongoose.isValidObjectId(id) ? undefined : new HttpError(404, 'Introuvable'));
});

const toJson = (car) => ({
  id: car._id,
  brand: car.brand,
  model: car.model,
  years: car.years,
  confidence: car.confidence,
  box: car.box,
  createdAt: car.createdAt,
});

router.post('/', scanLimiter, uploadedImage, async (req, res) => {
  const { carId: chosenId } = req.body;
  if (chosenId !== undefined && !isCarId(chosenId)) throw new HttpError(400, 'Voiture invalide');

  const scan = await recognizeCar(req.image.data);
  const chosen = await chooseCar(scan, chosenId);
  if (!chosen) throw new HttpError(422, 'Voiture non reconnue, elle n’a pas été ajoutée');

  const { carId, brand, model, years, confidence } = chosen;
  const car = await Car.create({
    user: req.userId,
    image: req.image,
    carId,
    brand,
    model,
    years,
    confidence,
    box: scan.box,
  });
  res.status(201).json(toJson(car));
});

router.get('/', async (req, res) => {
  const cars = await Car.find({ user: req.userId }).select('-image').sort({ createdAt: -1 });
  res.json(cars.map(toJson));
});

router.get('/:id/image', async (req, res) => {
  const car = await Car.findOne({ _id: req.params.id, user: req.userId });
  if (!car) throw new HttpError(404, 'Introuvable');
  const { image } = car;
  res.set('Content-Type', image.contentType);
  res.set('Cache-Control', 'private, max-age=86400');
  res.send(image.data);
});

router.delete('/:id', async (req, res) => {
  const { deletedCount } = await Car.deleteOne({ _id: req.params.id, user: req.userId });
  if (!deletedCount) throw new HttpError(404, 'Introuvable');
  res.status(204).end();
});

module.exports = router;
