process.env.JWT_SECRET = 'test-secret';

const assert = require('node:assert/strict');
const { afterEach, describe, it } = require('node:test');
const { recognizeCar, RecognitionError, formatYears } = require('../services/recognition');

const realFetch = global.fetch;

const mockAi = (payload, ok = true) => {
  global.fetch = async () => ({ ok, json: async () => payload });
};

const clio = { brand: 'Renault', model: 'Clio', from_year: 2012, to_year: 2019 };
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
      brand: 'Renault',
      model: 'Clio',
      years: '2012 – 2019',
    });
  });

  it('returns suggestions and the reason when not recognized', async () => {
    const twingo = { brand: 'Renault', model: 'Twingo', from_year: 2014, to_year: null };
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
      { brand: 'Renault', model: 'Clio', years: '2012 – 2019', confidence: 38 },
      { brand: 'Renault', model: 'Twingo', years: '2014 – aujourd’hui', confidence: 31 },
    ]);
  });

  it('fails clearly when the AI service is down', async () => {
    global.fetch = async () => {
      throw new Error('ECONNREFUSED');
    };

    await assert.rejects(recognizeCar(Buffer.from('x')), RecognitionError);
  });

  it('fails clearly when the AI rejects the image', async () => {
    mockAi({ error: 'Image illisible' }, false);

    await assert.rejects(recognizeCar(Buffer.from('x')), RecognitionError);
  });
});

describe('formatYears', () => {
  it('shows an open range for cars still produced', () => {
    assert.equal(formatYears({ from_year: 2019, to_year: null }), '2019 – aujourd’hui');
  });
});
