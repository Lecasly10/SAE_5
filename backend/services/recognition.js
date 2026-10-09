const AI_URL = process.env.AI_URL || 'http://localhost:5000';
const LABEL_PATTERN = /^([^_]+)_(.+)_(\d{4})(\d{4}|Present)$/;

class RecognitionError extends Error {}

function formatBrand(brand) {
  return brand.length <= 3
    ? brand.toUpperCase()
    : brand[0].toUpperCase() + brand.slice(1).toLowerCase();
}

function describeCar(label) {
  const match = label.match(LABEL_PATTERN);
  if (!match) return { brand: label.replaceAll('_', ' '), model: '', years: '' };

  const [, brand, model, from, to] = match;
  return {
    brand: formatBrand(brand),
    model: model.replaceAll('_', ' '),
    years: `${from} – ${to === 'Present' ? 'aujourd’hui' : to}`,
  };
}

async function recognizeCar(imageData) {
  let response;
  try {
    response = await fetch(`${AI_URL}/predict`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/octet-stream' },
      body: imageData,
    });
  } catch (err) {
    throw new RecognitionError('Service de reconnaissance indisponible');
  }
  if (!response.ok) throw new RecognitionError('Analyse impossible pour cette image');

  const { label, confidence, box } = await response.json();
  return { ...describeCar(label), confidence: Math.round(confidence), box };
}

module.exports = { recognizeCar, RecognitionError };
