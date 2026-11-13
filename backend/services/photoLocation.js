// Position GPS que le téléphone enregistre dans les métadonnées EXIF d'une
// photo JPEG, comme l'application Photos qui montre où la photo a été prise.
const EXIF_HEADER = 'Exif\0\0';
const GPS_POINTER = 0x8825;
const GPS_LATITUDE_REF = 1;
const GPS_LATITUDE = 2;
const GPS_LONGITUDE_REF = 3;
const GPS_LONGITUDE = 4;

function readTiff(tiff) {
  const little = tiff.toString('latin1', 0, 2) === 'II';
  const u16 = (offset) => (little ? tiff.readUInt16LE(offset) : tiff.readUInt16BE(offset));
  const u32 = (offset) => (little ? tiff.readUInt32LE(offset) : tiff.readUInt32BE(offset));

  // Chaque entrée fait 12 octets : numéro, type, nombre, valeur ou adresse
  const entries = (ifd) => {
    const found = new Map();
    for (let index = 0; index < u16(ifd); index += 1) {
      const entry = ifd + 2 + index * 12;
      found.set(u16(entry), entry + 8);
    }
    return found;
  };
  const rational = (offset) => u32(offset) / u32(offset + 4);
  const degrees = (offset) => rational(offset) + rational(offset + 8) / 60 + rational(offset + 16) / 3600;

  const gpsPointer = entries(u32(4)).get(GPS_POINTER);
  if (gpsPointer === undefined) return null;
  const gps = entries(u32(gpsPointer));
  if (![GPS_LATITUDE_REF, GPS_LATITUDE, GPS_LONGITUDE_REF, GPS_LONGITUDE].every((tag) => gps.has(tag))) {
    return null;
  }

  const south = tiff.toString('latin1', gps.get(GPS_LATITUDE_REF), gps.get(GPS_LATITUDE_REF) + 1) === 'S';
  const west = tiff.toString('latin1', gps.get(GPS_LONGITUDE_REF), gps.get(GPS_LONGITUDE_REF) + 1) === 'W';
  const latitude = degrees(u32(gps.get(GPS_LATITUDE))) * (south ? -1 : 1);
  const longitude = degrees(u32(gps.get(GPS_LONGITUDE))) * (west ? -1 : 1);
  return checkedLocation(latitude, longitude);
}

/** { latitude, longitude } si la position existe vraiment, sinon null. */
function checkedLocation(latitude, longitude) {
  const valid =
    Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    Math.abs(latitude) <= 90 &&
    Math.abs(longitude) <= 180 &&
    // 0, 0 : le téléphone n'avait pas encore trouvé sa position
    (latitude !== 0 || longitude !== 0);
  if (!valid) return null;
  const round = (value) => Math.round(value * 1e6) / 1e6;
  return { latitude: round(latitude), longitude: round(longitude) };
}

/** Position GPS d'une photo JPEG, ou null si elle n'en a pas. */
function photoLocation(data) {
  if (data[0] !== 0xff || data[1] !== 0xd8) return null;
  try {
    let offset = 2;
    while (offset + 4 <= data.length && data[offset] === 0xff) {
      const marker = data[offset + 1];
      const length = data.readUInt16BE(offset + 2);
      if (marker === 0xe1 && data.toString('latin1', offset + 4, offset + 10) === EXIF_HEADER) {
        return readTiff(data.subarray(offset + 10, offset + 2 + length));
      }
      // Début de l'image elle-même : il n'y a plus de métadonnées après
      if (marker === 0xda) return null;
      offset += 2 + length;
    }
  } catch {
    // Métadonnées abîmées : la photo reste valable, sans position
  }
  return null;
}

module.exports = { photoLocation, checkedLocation };
