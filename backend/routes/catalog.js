const express = require('express');
const { carCatalog } = require('../services/recognition');

const router = express.Router();

router.get('/', async (req, res) => {
  res.set('Cache-Control', 'public, max-age=3600');
  res.json(await carCatalog());
});

module.exports = router;
