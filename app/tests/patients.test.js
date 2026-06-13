'use strict';

const request = require('supertest');

const mockQuery = jest.fn();

jest.mock('../src/db', () => ({
  pool: { query: jest.fn().mockResolvedValue({ rows: [] }) },
  query: mockQuery,
  testConnection: jest.fn().mockResolvedValue(true),
}));

const app = require('../src/index');

const PATIENT = { id: 1, name: 'John Doe', email: 'john@example.com', created_at: new Date().toISOString() };

describe('Patients API', () => {
  beforeEach(() => jest.clearAllMocks());

  it('GET /api/patients returns list', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [PATIENT] });
    const res = await request(app).get('/api/patients');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
  });

  it('GET /api/patients/:id returns patient', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [PATIENT] });
    const res = await request(app).get('/api/patients/1');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('John Doe');
  });

  it('GET /api/patients/:id returns 404 if not found', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).get('/api/patients/999');
    expect(res.status).toBe(404);
  });

  it('POST /api/patients creates patient', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [PATIENT] });
    const res = await request(app)
      .post('/api/patients')
      .send({ name: 'John Doe', email: 'john@example.com' });
    expect(res.status).toBe(201);
    expect(res.body.email).toBe('john@example.com');
  });

  it('POST /api/patients returns 400 if fields missing', async () => {
    const res = await request(app).post('/api/patients').send({ name: 'John' });
    expect(res.status).toBe(400);
  });

  it('DELETE /api/patients/:id deletes patient', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 1 }] });
    const res = await request(app).delete('/api/patients/1');
    expect(res.status).toBe(204);
  });
});
