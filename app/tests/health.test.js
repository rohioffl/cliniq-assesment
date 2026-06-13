'use strict';

const request = require('supertest');

// Mock db before requiring app
jest.mock('../src/db', () => ({
  pool: { query: jest.fn().mockResolvedValue({ rows: [] }), end: jest.fn() },
  query: jest.fn(),
  testConnection: jest.fn().mockResolvedValue(true),
}));

const app = require('../src/index');

afterAll(() => {
  const { pool } = require('../src/db');
  pool.end();
});

describe('GET /health', () => {
  it('returns healthy when DB is connected', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body).toHaveProperty('timestamp');
  });

  it('returns 503 when DB is down', async () => {
    const { pool } = require('../src/db');
    pool.query.mockRejectedValueOnce(new Error('DB down'));
    const res = await request(app).get('/health');
    expect(res.status).toBe(503);
    expect(res.body.status).toBe('unhealthy');
  });
});

describe('GET /api/unknown', () => {
  it('returns 404 for unknown API routes', async () => {
    const res = await request(app).get('/api/unknown-endpoint');
    expect(res.status).toBe(404);
  });
});
