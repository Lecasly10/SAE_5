const express = require('express');
const Car = require('../models/Car');
const TrainingPhoto = require('../models/TrainingPhoto');
const User = require('../models/User');
const { HttpError } = require('../errors');
const requireAuth = require('../middleware/requireAuth');
const { readEmail, readName } = require('../validation');

const router = express.Router();

router.use(requireAuth);

const FIELDS = 'name email trainingConsent';

const toJson = (user) => ({
  name: user.name,
  email: user.email,
  trainingConsent: user.trainingConsent,
});

router.get('/', async (req, res) => {
  const user = await User.findById(req.userId).select(FIELDS);
  if (!user) throw new HttpError(404, 'Introuvable');
  res.json(toJson(user));
});

// Change le nom, l'e-mail ou l'accord pour entraîner l'IA (un ou plusieurs à la fois)
router.patch('/', async (req, res) => {
  const { name, email, trainingConsent } = req.body ?? {};
  const changes = {};
  if (name !== undefined) changes.name = readName(name);
  if (email !== undefined) changes.email = readEmail(email);
  if (trainingConsent !== undefined) {
    if (typeof trainingConsent !== 'boolean') throw new HttpError(400, 'Choix invalide');
    changes.trainingConsent = trainingConsent;
    changes.trainingConsentAt = trainingConsent ? new Date() : null;
  }
  if (!Object.keys(changes).length) throw new HttpError(400, 'Rien à modifier');

  let user;
  try {
    user = await User.findByIdAndUpdate(req.userId, changes, { new: true }).select(FIELDS);
  } catch (err) {
    if (err.code === 11000) throw new HttpError(409, 'Email déjà utilisé');
    throw err;
  }
  if (!user) throw new HttpError(404, 'Introuvable');

  // Accord retiré : les photos gardées uniquement pour l'entraînement sont effacées
  if (trainingConsent === false) await TrainingPhoto.deleteMany({ user: req.userId });

  res.json(toJson(user));
});

// Supprime le compte et tout ce qui lui appartient
router.delete('/', async (req, res) => {
  await Car.deleteMany({ user: req.userId });
  await TrainingPhoto.deleteMany({ user: req.userId });
  const { deletedCount } = await User.deleteOne({ _id: req.userId });
  if (!deletedCount) throw new HttpError(404, 'Introuvable');
  res.status(204).end();
});

module.exports = router;
