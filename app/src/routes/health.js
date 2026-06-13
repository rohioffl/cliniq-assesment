'use strict';

const express = require('express');
const { pool } = require('../db');

const router = express.Router();

router.get('/', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', db: 'connected', timestamp: new Date().toISOString() });
  } catch (_err) {
    res.status(503).json({ status: 'unhealthy', db: 'disconnected', timestamp: new Date().toISOString() });
  }
});

module.exports = router;
