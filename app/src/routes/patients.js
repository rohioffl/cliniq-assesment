'use strict';

const express = require('express');
const { query } = require('../db');

const router = express.Router();

// GET all patients
router.get('/', async (_req, res, next) => {
  try {
    const result = await query('SELECT id, name, email, created_at FROM patients ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

// GET single patient
router.get('/:id', async (req, res, next) => {
  try {
    const result = await query(
      'SELECT id, name, email, created_at FROM patients WHERE id = $1',
      [req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Patient not found' });
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// POST create patient
router.post('/', async (req, res, next) => {
  try {
    const { name, email } = req.body;
    if (!name || !email) return res.status(400).json({ error: 'name and email are required' });

    const result = await query(
      'INSERT INTO patients (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// DELETE patient
router.delete('/:id', async (req, res, next) => {
  try {
    const result = await query('DELETE FROM patients WHERE id = $1 RETURNING id', [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ error: 'Patient not found' });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
