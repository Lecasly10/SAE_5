const config = require('../config');
const { HttpError } = require('../errors');

class RecognitionError extends HttpError {
  constructor(message) {
    super(503, message);
  }
}

const CAR_ID = /^[a-z0-9_]{1,120}$/;
// La liste des voitures ne change qu'après un réentraînement
const CATALOG_LIFETIME_MS = 60 * 60 * 1000;

const isCarId = (value) => typeof value === 'string' && CAR_ID.test(value);

function formatYears({ from_year: from, to_year: to }) {
  return `${from} – ${to ?? 'aujourd’hui'}`;
}

function describeCar(car) {
  return { carId: car.id, brand: car.brand, model: car.model, years: formatYears(car) };
}

async function askAi(path, options, failure) {
  let response;
  try {
    response = await fetch(`${config.aiUrl}${path}`, options);
  } catch (err) {
    throw new RecognitionError('Service de reconnaissance indisponible');
  }
  // L'IA a reçu l'image mais n'a pas pu l'ouvrir : c'est la photo qui pose problème
  if (response.status === 422) throw new HttpError(422, 'Image illisible ou abîmée');
  if (!response.ok) throw new RecognitionError(failure);
  return response.json();
}

async function recognizeCar(imageData) {
  const { recognized, reason, confidence, car, suggestions, box } = await askAi(
    '/predict',
    { method: 'POST', headers: { 'Content-Type': 'application/octet-stream' }, body: imageData },
    'Analyse impossible pour cette image'
  );
  const result = {
    recognized,
    confidence: Math.round(confidence),
    box,
    suggestions: suggestions.map((suggestion) => ({
      ...describeCar(suggestion),
      confidence: Math.round(suggestion.confidence),
    })),
  };

  return recognized ? { ...result, ...describeCar(car) } : { ...result, reason };
}

let catalog = null;
let catalogLoadedAt = 0;

async function carCatalog() {
  if (!catalog || Date.now() - catalogLoadedAt > CATALOG_LIFETIME_MS) {
    catalog = (await askAi('/cars', undefined, 'Liste des voitures indisponible')).map(describeCar);
    catalogLoadedAt = Date.now();
  }
  return catalog;
}

async function findCar(carId) {
  return (await carCatalog()).find((car) => car.carId === carId) ?? null;
}

// Voiture à enregistrer : celle reconnue par l'IA, ou celle que l'utilisateur
// a choisie, dans les suggestions de l'IA ou dans toute la liste.
async function chooseCar(scan, carId) {
  if (carId === undefined) return scan.recognized ? scan : null;

  const suggested = [scan, ...scan.suggestions].find((car) => car.carId === carId);
  if (suggested) return suggested;

  // L'IA ne l'a pas proposée du tout : sa confiance est nulle
  const car = await findCar(carId);
  return car && { ...car, confidence: 0 };
}

module.exports = { recognizeCar, carCatalog, findCar, chooseCar, isCarId, RecognitionError, formatYears };
