'use strict';

const request = require('supertest');

// Mock db before requiring app
jest.mock('../src/db', () => ({
  pool: { query: jest.fn().mockResolvedValue({ rows: [] }) },
  query: jest.fn(),
  testConnection: jest.fn().mockResolvedValue(true),
}));

const app = require('../src/index');

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

describe('GET /unknown', () => {
  it('returns 404 for unknown routes', async () => {
    const res = await request(app).get('/unknown');
    expect(res.status).toBe(404);
  });
});
