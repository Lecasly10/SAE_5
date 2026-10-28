process.env.JWT_SECRET = 'test-secret';

const assert = require('node:assert/strict');
const http = require('node:http');
const { after, before, describe, it } = require('node:test');
const jwt = require('jsonwebtoken');
const Car = require('../models/Car');
const TrainingPhoto = require('../models/TrainingPhoto');
const User = require('../models/User');

const userId = '64b000000000000000000001';
const headers = { Authorization: `Bearer ${jwt.sign({ id: userId }, 'test-secret')}` };

const aiAnswer = {
  recognized: true,
  reason: null,
  confidence: 88.4,
  car: { id: 'peugeot_208_2019_present', brand: 'Peugeot', model: '208', from_year: 2019, to_year: null },
  suggestions: [],
  box: { x: 0.1, y: 0.1, width: 0.8, height: 0.8 },
};

const f12 = { id: 'ferrari_f12_berlinetta_2012_2015', brand: 'Ferrari', model: 'F12 Berlinetta', from_year: 2012, to_year: 2015 };
const aiCatalog = [f12, aiAnswer.car];

let aiStub;
let server;
let baseUrl;

const listen = (instance) =>
  new Promise((resolve) => instance.listen(0, '127.0.0.1', () => resolve(instance.address().port)));

async function call(method, path, { body, headers } = {}) {
  const response = await fetch(baseUrl + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...headers },
    body: typeof body === 'string' ? body : body && JSON.stringify(body),
  });
  const text = await response.text();
  return { status: response.status, headers: response.headers, json: text ? JSON.parse(text) : null };
}

// Seuls les premiers octets comptent : le faux service IA ne lit pas l'image
const pngBytes = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0]);
const tinyPng = { image: pngBytes.toString('base64'), contentType: 'image/png' };

describe('API', () => {
  before(async () => {
    aiStub = http.createServer((req, res) => {
      req.resume();
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(req.url === '/cars' ? aiCatalog : aiAnswer));
    });
    process.env.AI_URL = `http://127.0.0.1:${await listen(aiStub)}`;

    server = http.createServer(require('../app'));
    baseUrl = `http://127.0.0.1:${await listen(server)}`;
  });

  after(() => {
    aiStub.close();
    server.close();
  });

  it('answers the health check and sets security headers', async () => {
    const { status, headers, json } = await call('GET', '/api/health');

    assert.equal(status, 200);
    assert.deepEqual(json, { status: 'ok' });
    assert.equal(headers.get('x-content-type-options'), 'nosniff');
    assert.equal(headers.has('x-powered-by'), false);
  });

  it('returns a JSON 404 for unknown routes', async () => {
    const { status, json } = await call('GET', '/api/nope');

    assert.equal(status, 404);
    assert.deepEqual(json, { error: 'Introuvable' });
  });

  it('rejects invalid registrations before touching the database', async () => {
    const valid = { name: 'Alice', email: 'alice@example.com', password: 'longenough' };
    const cases = [
      [{ ...valid, name: '  ' }, 'Nom invalide'],
      [{ ...valid, email: 'pas-un-email' }, 'Email invalide'],
      [{ ...valid, email: { $ne: null } }, 'Email invalide'],
      [{ ...valid, password: 'court' }, 'Mot de passe : 8 caractères minimum'],
      [{ ...valid, password: 'a'.repeat(73) }, 'Mot de passe : 8 caractères minimum'],
    ];

    for (const [body, error] of cases) {
      const response = await call('POST', '/api/auth/register', { body });
      assert.equal(response.status, 400);
      assert.equal(response.json.error, error);
    }
  });

  it('rejects login payloads that are not plain strings', async () => {
    const { status } = await call('POST', '/api/auth/login', {
      body: { email: { $ne: null }, password: { $ne: null } },
    });

    assert.equal(status, 400);
  });

  it('refuses the library without a valid token', async () => {
    const missing = await call('GET', '/api/cars');
    const invalid = await call('GET', '/api/cars', { headers: { Authorization: 'Bearer abc' } });

    assert.equal(missing.status, 401);
    assert.equal(invalid.status, 401);
  });

  it('refuses malformed JSON and invalid images', async () => {
    const malformed = await call('POST', '/api/predict', { body: '{oups' });
    const wrongType = await call('POST', '/api/predict', {
      body: { image: tinyPng.image, contentType: 'text/html' },
    });
    const missing = await call('POST', '/api/predict', { body: {} });
    const disguised = await call('POST', '/api/predict', {
      body: { image: Buffer.from('<script>alert(1)</script>').toString('base64'), contentType: 'image/png' },
    });
    const webpAsJpeg = await call('POST', '/api/predict', {
      body: { image: Buffer.from('RIFF0000WEBPVP8 ').toString('base64'), contentType: 'image/jpeg' },
    });

    assert.equal(malformed.status, 400);
    assert.equal(wrongType.json.error, 'Image invalide');
    assert.equal(missing.json.error, 'Image invalide');
    assert.equal(disguised.json.error, 'Image invalide');
    assert.equal(webpAsJpeg.json.error, 'Image invalide');
  });

  it('forwards a valid image to the recognition service', async () => {
    const { status, json } = await call('POST', '/api/predict', { body: tinyPng });

    assert.equal(status, 200);
    assert.equal(json.recognized, true);
    assert.equal(json.brand, 'Peugeot');
    assert.equal(json.years, '2019 – aujourd’hui');
  });

  it('saves a training photo only when the user agreed to it', async (t) => {
    const create = t.mock.method(TrainingPhoto, 'create', async (doc) => doc);
    let consent = false;
    t.mock.method(User, 'findById', () => ({ select: async () => ({ trainingConsent: consent }) }));
    const photo = { ...tinyPng, carId: 'peugeot_208_2019_present' };

    const anonymous = await call('POST', '/api/training-photos', { body: photo });
    const badCar = await call('POST', '/api/training-photos', { headers, body: { ...tinyPng, carId: '../etc' } });
    const unknownCar = await call('POST', '/api/training-photos', { headers, body: { ...tinyPng, carId: 'renault_clio_2012_2019' } });
    const refused = await call('POST', '/api/training-photos', { headers, body: photo });
    consent = true;
    const saved = await call('POST', '/api/training-photos', { headers, body: photo });

    assert.equal(anonymous.status, 401);
    assert.equal(badCar.json.error, 'Voiture invalide');
    assert.equal(unknownCar.json.error, 'Voiture invalide');
    assert.equal(refused.status, 403);
    assert.equal(saved.status, 201);
    assert.equal(create.mock.callCount(), 1);
    assert.equal(create.mock.calls[0].arguments[0].carId, 'peugeot_208_2019_present');
  });

  it('saves the car the user picked instead of the one the AI guessed', async (t) => {
    const create = t.mock.method(Car, 'create', async (doc) => ({ ...doc, _id: 'abc' }));
    const picked = { id: 'peugeot_308_2021_present', brand: 'Peugeot', model: '308', from_year: 2021, to_year: null };
    aiAnswer.suggestions = [{ ...picked, confidence: 12.2 }];
    t.after(() => {
      aiAnswer.suggestions = [];
    });

    const invalid = await call('POST', '/api/cars', { headers, body: { ...tinyPng, carId: '../etc' } });
    const unknown = await call('POST', '/api/cars', { headers, body: { ...tinyPng, carId: 'renault_clio_2012_2019' } });
    const saved = await call('POST', '/api/cars', { headers, body: { ...tinyPng, carId: picked.id } });
    const fromList = await call('POST', '/api/cars', { headers, body: { ...tinyPng, carId: f12.id } });

    assert.equal(invalid.status, 400);
    assert.equal(unknown.status, 422);
    assert.equal(saved.status, 201);
    assert.equal(saved.json.model, '308');
    assert.equal(create.mock.calls[0].arguments[0].carId, picked.id);
    assert.equal(create.mock.calls[0].arguments[0].confidence, 12);
    assert.equal(fromList.json.brand, 'Ferrari');
    assert.equal(fromList.json.confidence, 0);
  });

  it('lists every car the user can pick', async () => {
    const { status, json } = await call('GET', '/api/catalog');

    assert.equal(status, 200);
    assert.deepEqual(json[0], { carId: f12.id, brand: 'Ferrari', model: 'F12 Berlinetta', years: '2012 – 2015' });
  });

  it('stores the training consent and deletes training photos when it is withdrawn', async (t) => {
    const update = t.mock.method(User, 'findByIdAndUpdate', (id, changes) => ({
      select: async () => ({ name: 'Alice', email: 'alice@example.com', ...changes }),
    }));
    const deleteMany = t.mock.method(TrainingPhoto, 'deleteMany', async () => ({}));

    const invalid = await call('PATCH', '/api/account', { headers, body: { trainingConsent: 'oui' } });
    const given = await call('PATCH', '/api/account', { headers, body: { trainingConsent: true } });
    const withdrawn = await call('PATCH', '/api/account', { headers, body: { trainingConsent: false } });

    assert.equal(invalid.status, 400);
    assert.equal(given.json.trainingConsent, true);
    assert.ok(update.mock.calls[0].arguments[1].trainingConsentAt instanceof Date);
    assert.equal(withdrawn.json.trainingConsent, false);
    assert.equal(deleteMany.mock.callCount(), 1);
    assert.deepEqual(deleteMany.mock.calls[0].arguments[0], { user: userId });
  });

  it('updates the name and e-mail with the same rules as the sign-up', async (t) => {
    const update = t.mock.method(User, 'findByIdAndUpdate', (id, changes) => ({
      select: async () => {
        if (changes.email === 'pris@example.com') throw Object.assign(new Error('duplicate'), { code: 11000 });
        return { name: 'Alice', email: 'alice@example.com', trainingConsent: false, ...changes };
      },
    }));

    const empty = await call('PATCH', '/api/account', { headers, body: {} });
    const badName = await call('PATCH', '/api/account', { headers, body: { name: '  ' } });
    const badEmail = await call('PATCH', '/api/account', { headers, body: { email: { $ne: null } } });
    const taken = await call('PATCH', '/api/account', { headers, body: { email: 'pris@example.com' } });
    const saved = await call('PATCH', '/api/account', { headers, body: { name: ' Bob ', email: 'Bob@Example.com ' } });

    assert.equal(empty.status, 400);
    assert.equal(badName.json.error, 'Nom invalide');
    assert.equal(badEmail.json.error, 'Email invalide');
    assert.equal(taken.status, 409);
    assert.deepEqual(saved.json, { name: 'Bob', email: 'bob@example.com', trainingConsent: false });
    assert.equal(update.mock.callCount(), 2);
  });

  it('deletes the account with all its cars and photos', async (t) => {
    const cars = t.mock.method(Car, 'deleteMany', async () => ({}));
    const photos = t.mock.method(TrainingPhoto, 'deleteMany', async () => ({}));
    let exists = true;
    t.mock.method(User, 'deleteOne', async () => ({ deletedCount: exists ? 1 : 0 }));

    const anonymous = await call('DELETE', '/api/account');
    const deleted = await call('DELETE', '/api/account', { headers });
    exists = false;
    const again = await call('DELETE', '/api/account', { headers });

    assert.equal(anonymous.status, 401);
    assert.equal(deleted.status, 204);
    assert.deepEqual(cars.mock.calls[0].arguments[0], { user: userId });
    assert.deepEqual(photos.mock.calls[0].arguments[0], { user: userId });
    assert.equal(again.status, 404);
  });

  it('limits the number of login attempts', async () => {
    let last;
    for (let attempt = 0; attempt < 31; attempt += 1) {
      last = await call('POST', '/api/auth/login', { body: {} });
    }

    assert.equal(last.status, 429);
  });
});
