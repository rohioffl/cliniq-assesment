'use strict';

require('dotenv').config();

const path = require('path');
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { logger, requestLogger } = require('./middleware/logger');
const healthRouter = require('./routes/health');
const patientsRouter = require('./routes/patients');
const { testConnection } = require('./db');

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware (relaxed CSP to allow Tailwind CDN + Google Fonts)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", 'cdn.tailwindcss.com'],
      scriptSrcAttr: ["'unsafe-inline'"],  // allow onclick= handlers in UI
      styleSrc: ["'self'", "'unsafe-inline'", 'fonts.googleapis.com'],
      fontSrc: ["'self'", 'fonts.gstatic.com'],
      connectSrc: ["'self'"],
      imgSrc: ["'self'", 'data:'],
    },
  },
}));
app.use(rateLimit({ windowMs: 60 * 1000, max: 100 }));
app.use(express.json({ limit: '10kb' }));
app.use(requestLogger);

// Serve static UI
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
app.use('/health', healthRouter);
app.use('/api/patients', patientsRouter);

// SPA fallback — serve index.html for non-API routes
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api') || req.path.startsWith('/health')) return next();
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Global error handler
app.use((err, _req, res, _next) => {
  logger.error({ err }, 'Unhandled error');
  res.status(500).json({ error: 'Internal server error' });
});

async function start() {
  // In production, a DB failure should abort startup.
  // In development, warn and continue so the UI is still reachable.
  try {
    await testConnection();
  } catch (err) {
    if (process.env.NODE_ENV === 'production') {
      logger.error({ err }, 'Failed to connect to database — aborting');
      process.exit(1);
    }
    logger.warn({ err }, 'Database unavailable — starting without DB (dev mode)');
  }

  app.listen(PORT, () => {
    logger.info(`Server listening on port ${PORT}`);
  });
}

start();

module.exports = app;
