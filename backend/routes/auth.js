const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config');
const { HttpError } = require('../errors');
const { cleanEmail, readEmail, readName } = require('../validation');

const router = express.Router();

const MIN_PASSWORD_LENGTH = 8;
// bcrypt ignore tout ce qui dépasse 72 octets
const MAX_PASSWORD_BYTES = 72;

router.post('/register', async (req, res) => {
  const { name, email, password } = req.body ?? {};
  const cleanName = readName(name);
  const mail = readEmail(email);
  if (
    typeof password !== 'string' ||
    password.length < MIN_PASSWORD_LENGTH ||
    Buffer.byteLength(password) > MAX_PASSWORD_BYTES
  ) {
    throw new HttpError(400, `Mot de passe : ${MIN_PASSWORD_LENGTH} caractères minimum`);
  }

  try {
    const user = await User.create({
      name: cleanName,
      email: mail,
      password: await bcrypt.hash(password, 10),
    });
    res.status(201).json({ id: user._id, name: user.name, email: user.email });
  } catch (err) {
    if (err.code === 11000) throw new HttpError(409, 'Email déjà utilisé');
    throw err;
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  const mail = cleanEmail(email);
  if (!mail || typeof password !== 'string') {
    throw new HttpError(400, 'Email et mot de passe requis');
  }

  const user = await User.findOne({ email: mail });
  if (!user || !(await bcrypt.compare(password, user.password))) {
    throw new HttpError(401, 'Email ou mot de passe incorrect');
  }

  const token = jwt.sign({ id: user._id }, config.jwtSecret, { expiresIn: '7d' });
  res.json({ token, name: user.name, email: user.email, trainingConsent: user.trainingConsent });
});

module.exports = router;
