const config = require('../config');

// OpenStreetMap demande un nom d'application dans chaque requête
const USER_AGENT = "SpotIt/1.0 (projet étudiant SAE 5.01)";
const TIMEOUT_MS = 4000;

/** { name, city, country } d'une réponse de Nominatim, ou null. */
function describePlace({ name, address = {} } = {}) {
  const city =
    address.city ?? address.town ?? address.village ?? address.municipality ?? address.county ?? null;
  const country = address.country ?? null;
  if (!city && !country) return null;
  const place = name || address.road || address.suburb || null;
  return { name: place && place !== city ? place : null, city, country };
}

/** Nom du lieu le plus proche d'une position, avec sa ville et son pays.
 * null si le service ne répond pas : la voiture est quand même ajoutée. */
async function findPlace({ latitude, longitude }) {
  if (!config.geocoderUrl) return null;
  const url = new URL('/reverse', config.geocoderUrl);
  url.search = new URLSearchParams({
    format: 'jsonv2',
    lat: latitude,
    lon: longitude,
    zoom: 18,
    'accept-language': 'fr',
  });

  try {
    const response = await fetch(url, {
      headers: { 'User-Agent': USER_AGENT },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    return response.ok ? describePlace(await response.json()) : null;
  } catch {
    return null;
  }
}

module.exports = { findPlace, describePlace };
