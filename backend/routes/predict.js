const express = require('express');
const { readImage } = require('../services/imageUpload');
const { recognizeCar } = require('../services/recognition');
const router = express.Router();

router.post('/', async (req, res) => {
  const { image, error } = readImage(req.body);
  if (error) return res.status(400).json({ error });

  try {
    res.json(await recognizeCar(image.data));
  } catch (err) {
    res.status(503).json({ error: err.message });
  }
});

module.exports = router;
