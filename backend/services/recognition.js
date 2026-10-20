const config = require('../config');
const { HttpError } = require('../errors');

class RecognitionError extends HttpError {
  constructor(message) {
    super(503, message);
  }
}

function formatYears({ from_year: from, to_year: to }) {
  return `${from} – ${to ?? 'aujourd’hui'}`;
}

function describeCar(car) {
  return { brand: car.brand, model: car.model, years: formatYears(car) };
}

async function recognizeCar(imageData) {
  let response;
  try {
    response = await fetch(`${config.aiUrl}/predict`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/octet-stream' },
      body: imageData,
    });
  } catch (err) {
    throw new RecognitionError('Service de reconnaissance indisponible');
  }
  if (!response.ok) throw new RecognitionError('Analyse impossible pour cette image');

  const { recognized, reason, confidence, car, suggestions, box } = await response.json();
  const result = { recognized, confidence: Math.round(confidence), box };

  if (recognized) return { ...result, ...describeCar(car) };

  return {
    ...result,
    reason,
    suggestions: suggestions.map((suggestion) => ({
      ...describeCar(suggestion),
      confidence: Math.round(suggestion.confidence),
    })),
  };
}

module.exports = { recognizeCar, RecognitionError, formatYears };
