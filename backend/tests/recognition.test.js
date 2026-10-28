process.env.JWT_SECRET = 'test-secret';

const assert = require('node:assert/strict');
const { afterEach, describe, it } = require('node:test');
const { recognizeCar, chooseCar, RecognitionError, formatYears } = require('../services/recognition');

const realFetch = global.fetch;

const mockAi = (payload, ok = true, status = ok ? 200 : 500) => {
  global.fetch = async () => ({ ok, status, json: async () => payload });
};

const clio = { id: 'renault_clio_2012_2019', brand: 'Renault', model: 'Clio', from_year: 2012, to_year: 2019 };
const box = { x: 0.1, y: 0.2, width: 0.5, height: 0.4 };

describe('recognizeCar', () => {
  afterEach(() => {
    global.fetch = realFetch;
  });

  it('returns the car with its production years when recognized', async () => {
    mockAi({ recognized: true, reason: null, confidence: 91.4, car: clio, suggestions: [], box });

    assert.deepEqual(await recognizeCar(Buffer.from('x')), {
      recognized: true,
      confidence: 91,
      box,
      suggestions: [],
      carId: 'renault_clio_2012_2019',
      brand: 'Renault',
      model: 'Clio',
      years: '2012 – 2019',
    });
  });

  it('returns suggestions and the reason when not recognized', async () => {
    const twingo = { id: 'renault_twingo_2014_present', brand: 'Renault', model: 'Twingo', from_year: 2014, to_year: null };
    mockAi({
      recognized: false,
      reason: 'unknown',
      confidence: 38.2,
      car: null,
      suggestions: [{ ...clio, confidence: 38.2 }, { ...twingo, confidence: 30.6 }],
      box: null,
    });

    const result = await recognizeCar(Buffer.from('x'));

    assert.equal(result.recognized, false);
    assert.equal(result.reason, 'unknown');
    assert.equal(result.brand, undefined);
    assert.deepEqual(result.suggestions, [
      { carId: 'renault_clio_2012_2019', brand: 'Renault', model: 'Clio', years: '2012 – 2019', confidence: 38 },
      { carId: 'renault_twingo_2014_present', brand: 'Renault', model: 'Twingo', years: '2014 – aujourd’hui', confidence: 31 },
    ]);
  });

  it('fails clearly when the AI service is down', async () => {
    global.fetch = async () => {
      throw new Error('ECONNREFUSED');
    };

    await assert.rejects(recognizeCar(Buffer.from('x')), RecognitionError);
  });

  it('fails clearly when the AI breaks down', async () => {
    mockAi({ error: 'Erreur' }, false);

    await assert.rejects(recognizeCar(Buffer.from('x')), RecognitionError);
  });

  it('blames the photo when the AI cannot open it', async () => {
    mockAi({ error: 'Image illisible' }, false, 422);

    await assert.rejects(recognizeCar(Buffer.from('x')), { status: 422, message: 'Image illisible ou abîmée' });
  });
});

describe('formatYears', () => {
  it('shows an open range for cars still produced', () => {
    assert.equal(formatYears({ from_year: 2019, to_year: null }), '2019 – aujourd’hui');
  });
});

describe('chooseCar', () => {
  const clioScan = { recognized: true, carId: 'renault_clio_2012_2019', suggestions: [{ carId: 'renault_twingo_2014_present' }] };
  const unsureScan = { recognized: false, suggestions: [{ carId: 'renault_twingo_2014_present' }] };

  afterEach(() => {
    global.fetch = realFetch;
  });

  it('keeps the recognized car when the user picked nothing', async () => {
    assert.equal(await chooseCar(clioScan, undefined), clioScan);
    assert.equal(await chooseCar(unsureScan, undefined), null);
  });

  it('prefers the suggestion, then looks in the whole list of cars', async () => {
    mockAi([clio]);

    assert.equal(await chooseCar(unsureScan, 'renault_twingo_2014_present'), unsureScan.suggestions[0]);
    assert.equal(await chooseCar(clioScan, 'renault_clio_2012_2019'), clioScan);
    assert.deepEqual(await chooseCar(unsureScan, 'renault_clio_2012_2019'), {
      carId: 'renault_clio_2012_2019',
      brand: 'Renault',
      model: 'Clio',
      years: '2012 – 2019',
      confidence: 0,
    });
    assert.equal(await chooseCar(unsureScan, 'ferrari_f12_berlinetta_2012_2015'), null);
  });
});
