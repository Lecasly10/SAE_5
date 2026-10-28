const express = require('express');
const uploadedImage = require('../middleware/uploadedImage');
const { recognizeCar } = require('../services/recognition');

const router = express.Router();

router.post('/', uploadedImage, async (req, res) => {
  res.json(await recognizeCar(req.image.data));
});

module.exports = router;
