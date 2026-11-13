const express = require('express');
const mongoose = require('mongoose');
const Car = require('../models/Car');
const User = require('../models/User');
const { HttpError } = require('../errors');
const requireAuth = require('../middleware/requireAuth');
const uploadedImage = require('../middleware/uploadedImage');
const { scanLimiter } = require('../middleware/rateLimits');
const { recognizeCar, chooseCar, isCarId, carCatalog } = require('../services/recognition');
const { photoLocation } = require('../services/photoLocation');
const { findPlace } = require('../services/places');
const { assessRarity, rarityOf } = require('../services/rarity');
const { collectionStats } = require('../services/stats');
const { readLocation } = require('../validation');

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
  location: car.location ?? null,
  price: car.price ?? null,
  produced: car.produced ?? null,
  rarity: rarityOf(car),
  onRoad: car.onRoad ?? null,
  createdAt: car.createdAt,
});

// Endroit de la photo : celui enregistré dans la photo, sinon la position du
// téléphone. Gardé seulement si l'utilisateur l'a accepté.
async function findLocation(req) {
  const device = readLocation(req.body.location);
  const fromPhoto = req.image.contentType === 'image/jpeg' ? photoLocation(req.image.data) : null;
  if (!fromPhoto && !device) return null;

  const user = await User.findById(req.userId).select('locationConsent');
  if (!user?.locationConsent) return null;
  const location = fromPhoto ? { ...fromPhoto, source: 'photo' } : { ...device, source: 'device' };
  return { ...location, place: await findPlace(location) };
}

router.post('/', scanLimiter, uploadedImage, async (req, res) => {
  const { carId: chosenId } = req.body;
  if (chosenId !== undefined && !isCarId(chosenId)) throw new HttpError(400, 'Voiture invalide');
  const location = await findLocation(req);

  const scan = await recognizeCar(req.image.data);
  const chosen = await chooseCar(scan, chosenId);
  if (!chosen) throw new HttpError(422, 'Voiture non reconnue, elle n’a pas été ajoutée');

  const { carId, brand, model, years, confidence } = chosen;
  const { rarity, onRoad } = assessRarity(chosen);
  const car = await Car.create({
    user: req.userId,
    image: req.image,
    carId,
    brand,
    model,
    years,
    confidence,
    box: scan.box,
    location,
    price: chosen.price ?? null,
    produced: chosen.produced ?? null,
    rarity,
    onRoad,
  });
  res.status(201).json(toJson(car));
});

router.get('/', async (req, res) => {
  const cars = await Car.find({ user: req.userId }).select('-image').sort({ createdAt: -1 });
  res.json(cars.map(toJson));
});

router.get('/stats', async (req, res) => {
  const cars = await Car.find({ user: req.userId }).select('carId brand model years location price rarity createdAt');
  // Sans l'IA, les statistiques restent utiles, sans le pourcentage de collection
  const catalogSize = await carCatalog().then((catalog) => catalog.length, () => null);
  res.json(collectionStats(cars, catalogSize));
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
