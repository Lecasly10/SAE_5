// Rareté d'une voiture pour un passionné, selon 5 critères qui ne dépendent
// que de la voiture :
// - la marque (une Ferrari est toujours spéciale) ;
// - le prix neuf ;
// - le nombre d'exemplaires fabriqués, pour les séries limitées ;
// - la fréquence à laquelle on la croise sur la route (ventes en Europe,
//   annonces aux États-Unis, voir ai/src/market.py) ;
// - son âge (plus fabriquée depuis longtemps).
const RARITIES = ['commune', 'rare', 'epique', 'legendaire', 'mythique'];
// Sur la route, de la plus vue à la moins vue
const ON_ROAD = ['courante', 'peu_courante', 'tres_rare'];
// Moins d'exemplaires que ça : la voiture est mythique
const MYTHIC_PRODUCTION = 1000;

const BRAND_POINTS = new Map([
  ...['Bugatti', 'Pagani', 'Koenigsegg', 'Ferrari', 'Lamborghini', 'McLaren', 'Rolls-Royce', 'Rimac'].map(
    (brand) => [brand, 3]
  ),
  ...['Aston Martin', 'Bentley', 'Maserati', 'Porsche', 'Lotus', 'Alpine', 'Maybach', 'Mercedes-AMG', 'Wiesmann'].map(
    (brand) => [brand, 2]
  ),
  ...['Jaguar', 'Tesla', 'Alfa Romeo', 'Lexus', 'Cadillac', 'Land Rover', 'Abarth', 'Genesis', 'Hummer'].map(
    (brand) => [brand, 1]
  ),
]);

// « 1991 – 2005 » donne 2005, « 2019 – aujourd’hui » donne null
function lastYear(years) {
  const found = String(years ?? '').match(/\d{4}/g);
  return found && !years.includes('aujourd') ? Number(found.at(-1)) : null;
}

function pricePoints(price) {
  if (!price) return 0;
  if (price >= 150000) return 3;
  if (price >= 70000) return 2;
  return price >= 40000 ? 1 : 0;
}

function productionPoints(produced) {
  if (!produced) return 0;
  if (produced <= 500) return 4;
  if (produced <= 1500) return 3;
  if (produced <= 5000) return 2;
  return produced <= 20000 ? 1 : 0;
}

function agePoints(years) {
  const end = lastYear(years);
  if (end === null) return 0;
  if (end < 1995) return 2;
  return end < 2005 ? 1 : 0;
}

/** Indice de ON_ROAD, ou null si on ne sait pas. seen : rang de 0 (jamais
 * vue) à 1 (partout), en Europe et aux États-Unis. Une voiture courante d'un
 * côté de l'océan reste une voiture courante. */
function onRoadLevel(seen) {
  const ranks = [seen?.europe, seen?.america].filter((rank) => rank !== null && rank !== undefined);
  if (!ranks.length) return null;
  const rank = Math.max(...ranks);
  if (rank < 0.1) return 2;
  return rank < 0.33 ? 1 : 0;
}

/** { rarity, onRoad } d'une voiture du catalogue de l'IA (brand, years,
 * price, seen, produced). */
function assessRarity(car) {
  const brand = BRAND_POINTS.get(car.brand) ?? 0;
  const road = onRoadLevel(car.seen);
  // Sans information, la voiture compte comme peu courante
  const points =
    brand + pricePoints(car.price) + productionPoints(car.produced) + (road ?? 1) + agePoints(car.years);

  let level = 0;
  if ((car.produced && car.produced <= MYTHIC_PRODUCTION) || points >= 9) level = 4;
  else if (points >= 6 || brand === 3) level = 3;
  else if (points >= 4) level = 2;
  else if (points >= 2) level = 1;
  return { rarity: RARITIES[level], onRoad: road === null ? null : ON_ROAD[road] };
}

/** Rareté enregistrée avec la voiture, ou calculée pour les voitures
 * ajoutées avant qu'elle existe. */
const rarityOf = (car) => car.rarity ?? assessRarity(car).rarity;

module.exports = { RARITIES, ON_ROAD, assessRarity, rarityOf };
