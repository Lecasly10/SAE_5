const { RARITIES, rarityOf } = require('./rarity');

const TOP_BRANDS = 5;

/** Statistiques de la collection d'un utilisateur. catalogSize : nombre de
 * voitures que l'IA connaît, ou null si l'IA ne répond pas. */
function collectionStats(cars, catalogSize) {
  const models = new Set(cars.map((car) => car.carId ?? `${car.brand} ${car.model}`));
  const brands = new Map();
  const rarities = Object.fromEntries(RARITIES.map((rarity) => [rarity, 0]));
  let rarest = null;

  for (const car of cars) {
    brands.set(car.brand, (brands.get(car.brand) ?? 0) + 1);
    const rarity = rarityOf(car);
    rarities[rarity] += 1;
    if (!rarest || RARITIES.indexOf(rarity) > RARITIES.indexOf(rarest.rarity)) {
      rarest = { brand: car.brand, model: car.model, rarity };
    }
  }

  const dates = cars.map((car) => new Date(car.createdAt)).sort((a, b) => a - b);
  const priced = cars.filter((car) => car.price);
  const priciest = priced.reduce((best, car) => (!best || car.price > best.price ? car : best), null);
  return {
    total: cars.length,
    models: models.size,
    brands: brands.size,
    catalogSize,
    rarities,
    rarest,
    topBrands: [...brands]
      .map(([brand, count]) => ({ brand, count }))
      .sort((a, b) => b.count - a.count || a.brand.localeCompare(b.brand))
      .slice(0, TOP_BRANDS),
    located: cars.filter((car) => car.location).length,
    // Prix neuf de toutes les voitures dont on connaît le prix
    value: priced.reduce((sum, car) => sum + car.price, 0),
    priced: priced.length,
    priciest: priciest && { brand: priciest.brand, model: priciest.model, price: priciest.price },
    firstSpot: dates[0] ?? null,
    lastSpot: dates.at(-1) ?? null,
  };
}

module.exports = { collectionStats };
