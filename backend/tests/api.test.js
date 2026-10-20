process.env.JWT_SECRET = 'test-secret';

const assert = require('node:assert/strict');
const http = require('node:http');
const { after, before, describe, it } = require('node:test');

const aiAnswer = {
  recognized: true,
  reason: null,
  confidence: 88.4,
  car: { brand: 'Peugeot', model: '208', from_year: 2019, to_year: null },
  suggestions: [],
  box: { x: 0.1, y: 0.1, width: 0.8, height: 0.8 },
};

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

const tinyPng = { image: Buffer.from('not really a png').toString('base64'), contentType: 'image/png' };

describe('API', () => {
  before(async () => {
    aiStub = http.createServer((req, res) => {
      req.resume();
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(aiAnswer));
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

    assert.equal(malformed.status, 400);
    assert.equal(wrongType.json.error, 'Image invalide');
    assert.equal(missing.json.error, 'Image invalide');
  });

  it('forwards a valid image to the recognition service', async () => {
    const { status, json } = await call('POST', '/api/predict', { body: tinyPng });

    assert.equal(status, 200);
    assert.equal(json.recognized, true);
    assert.equal(json.brand, 'Peugeot');
    assert.equal(json.years, '2019 – aujourd’hui');
  });

  it('limits the number of login attempts', async () => {
    let last;
    for (let attempt = 0; attempt < 31; attempt += 1) {
      last = await call('POST', '/api/auth/login', { body: {} });
    }

    assert.equal(last.status, 429);
  });
});
