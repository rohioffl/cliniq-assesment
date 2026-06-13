'use strict';

const { Pool } = require('pg');
const { logger } = require('./middleware/logger');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

async function testConnection() {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    logger.info('Database connection established');
    await migrate(client);
  } finally {
    client.release();
  }
}

async function migrate(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS patients (
      id         SERIAL PRIMARY KEY,
      name       VARCHAR(255) NOT NULL,
      email      VARCHAR(255) NOT NULL UNIQUE,
      created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
    )
  `);
  await client.query('CREATE INDEX IF NOT EXISTS idx_patients_email ON patients (email)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_patients_created_at ON patients (created_at DESC)');
  logger.info('Database schema ready');
}

async function query(text, params) {
  const start = Date.now();
  const res = await pool.query(text, params);
  logger.debug({ query: text, duration: Date.now() - start, rows: res.rowCount }, 'DB query');
  return res;
}

module.exports = { pool, query, testConnection };
