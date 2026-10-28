const assert = require('node:assert/strict');
const { describe, it } = require('node:test');
const mongoose = require('mongoose');
const { DB_NAME, connectDatabase } = require('../database');

describe('connectDatabase', () => {
  it('always writes to the spotit database, even without a name in the URI', async (t) => {
    const connect = t.mock.method(mongoose, 'connect', async () => mongoose);
    const uri = 'mongodb+srv://user:pass@cluster0.example.mongodb.net/?retryWrites=true';

    await connectDatabase(uri);

    assert.equal(DB_NAME, 'spotit');
    assert.deepEqual(connect.mock.calls[0].arguments, [uri, { dbName: 'spotit' }]);
  });
});
