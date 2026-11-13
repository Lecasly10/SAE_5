const assert = require('node:assert/strict');
const { describe, it } = require('node:test');
const { photoLocation } = require('../services/photoLocation');
const { assessRarity, rarityOf } = require('../services/rarity');
const { collectionStats } = require('../services/stats');
const { describePlace } = require('../services/places');
const { jpegWithGps } = require('./jpeg');

describe('photo location', () => {
  it('reads where the photo was taken', () => {
    const paris = photoLocation(jpegWithGps({ latitude: 48.85825, longitude: 2.2945 }));
    const santiago = photoLocation(jpegWithGps({ latitude: -33.4489, longitude: -70.6693, little: true }));

    assert.deepEqual(paris, { latitude: 48.85825, longitude: 2.2945 });
    assert.ok(Math.abs(santiago.latitude + 33.4489) < 1e-4);
    assert.ok(Math.abs(santiago.longitude + 70.6693) < 1e-4);
  });

  it('returns null for photos without position or with broken metadata', () => {
    const noFix = jpegWithGps({ latitude: 0, longitude: 0 });
    const broken = jpegWithGps({ latitude: 48.8, longitude: 2.3 }).subarray(0, 40);

    assert.equal(photoLocation(Buffer.from([0xff, 0xd8, 0xff, 0xda, 0, 2])), null);
    assert.equal(photoLocation(noFix), null);
    assert.equal(photoLocation(broken), null);
    assert.equal(photoLocation(Buffer.from('not a photo')), null);
  });
});

describe('rarity', () => {
  it('depends on the brand, the price and the age of the car', () => {
    assert.equal(assessRarity({ brand: 'Renault', years: '1990 – aujourd’hui', price: 9100 }), 'commune');
    assert.equal(assessRarity({ brand: 'Ford', years: '1999 – 2016' }), 'commune');
    assert.equal(assessRarity({ brand: 'Porsche', years: '1964 – aujourd’hui', price: 75200 }), 'epique');
    assert.equal(assessRarity({ brand: 'Ferrari', years: '2012 – 2017', price: 279600 }), 'legendaire');
    assert.equal(assessRarity({ brand: 'Citroën', years: '1948 – 1990' }), 'rare');
  });

  it('depends on how many were built', () => {
    assert.equal(assessRarity({ brand: 'Ferrari', years: '2002 – 2004', produced: 400 }), 'mythique');
    assert.equal(assessRarity({ brand: 'Lamborghini', years: '2005 – 2010', produced: 4100 }), 'legendaire');
    assert.equal(assessRarity({ brand: 'Ford', years: '2005 – 2006', price: 160000, produced: 4000 }), 'epique');
  });

  it('keeps the rarity saved with the car', () => {
    assert.equal(rarityOf({ brand: 'Renault', years: '1990 – aujourd’hui', rarity: 'epique' }), 'epique');
    assert.equal(rarityOf({ brand: 'Peugeot', years: '2019 – aujourd’hui' }), 'commune');
  });
});

describe('place of the photo', () => {
  it('keeps the nearest place, its city and its country', () => {
    assert.deepEqual(
      describePlace({ name: 'Port Hercule', address: { city: 'Monaco', country: 'Monaco' } }),
      { name: 'Port Hercule', city: 'Monaco', country: 'Monaco' }
    );
    assert.deepEqual(
      describePlace({ name: '', address: { road: 'Rue de Rivoli', village: 'Paris', country: 'France' } }),
      { name: 'Rue de Rivoli', city: 'Paris', country: 'France' }
    );
    assert.equal(describePlace({ name: 'Océan', address: {} }), null);
  });
});

describe('collection stats', () => {
  it('counts cars, models, brands and rarities', () => {
    const cars = [
      { carId: 'peugeot_208', brand: 'Peugeot', model: '208', years: '2012 – aujourd’hui', createdAt: '2026-11-02' },
      { carId: 'peugeot_208', brand: 'Peugeot', model: '208', years: '2012 – aujourd’hui', createdAt: '2026-11-03' },
      {
        carId: 'ferrari_f12', brand: 'Ferrari', model: 'F12', years: '2012 – 2017', createdAt: '2026-11-01', price: 279600,
        location: { latitude: 48.8, longitude: 2.3 },
      },
    ];

    const stats = collectionStats(cars, 1170);

    assert.equal(stats.total, 3);
    assert.equal(stats.models, 2);
    assert.equal(stats.brands, 2);
    assert.equal(stats.catalogSize, 1170);
    assert.deepEqual(stats.rarities, { commune: 2, rare: 0, epique: 0, legendaire: 1, mythique: 0 });
    assert.deepEqual(stats.rarest, { brand: 'Ferrari', model: 'F12', rarity: 'legendaire' });
    assert.deepEqual(stats.topBrands, [{ brand: 'Peugeot', count: 2 }, { brand: 'Ferrari', count: 1 }]);
    assert.equal(stats.located, 1);
    assert.equal(stats.firstSpot.toISOString().slice(0, 10), '2026-11-01');
    assert.equal(stats.value, 279600);
    assert.deepEqual(stats.priciest, { brand: 'Ferrari', model: 'F12', price: 279600 });
  });

  it('works with an empty collection', () => {
    const stats = collectionStats([], null);

    assert.equal(stats.total, 0);
    assert.equal(stats.rarest, null);
    assert.equal(stats.firstSpot, null);
  });
});
