const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const config = require('./config/env');
const { testConnection } = require('./config/db');
const { runMigrations } = require('./db/migrate');
const { sanitize } = require('./middleware/sanitize');
const { errorHandler } = require('./middleware/errorHandler');
const { maintenanceMode } = require('./middleware/maintenanceMode');
const routes = require('./routes');

const app = express();

// ── Security headers ──
app.use(helmet());

// ── CORS ──
app.use(cors({
    origin: config.nodeEnv === 'production'
        ? process.env.ALLOWED_ORIGINS?.split(',')
        : '*',
    credentials: true,
}));

// ── Rate limiting ──
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,                  // max 100 requests per window
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        status: 'error',
        message: 'Too many requests, please try again later.',
    },
});
app.use('/api/', limiter);

// ── Body parsing ──
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Input sanitization ──
app.use(sanitize);

// ── Maintenance mode (blocks non-admin, always allows /auth/*) ──
app.use('/api', maintenanceMode);

// ── API routes ──
app.use('/api', routes);

// ── 404 handler ──
app.use((_req, res) => {
    res.status(404).json({
        status: 'error',
        message: 'Route not found',
    });
});

// ── Error handler ──
app.use(errorHandler);

// ── Start server ──
async function start() {
    // Test database connection
    const dbOk = await testConnection();
    if (!dbOk) {
        console.error('❌ Cannot start: database connection failed');
        process.exit(1);
    }
    console.log('✅ Database connected');

    // Run migrations
    try {
        await runMigrations();
    } catch (err) {
        console.error('❌ Migration failed:', err.message);
        process.exit(1);
    }

    // Listen
    app.listen(config.port, () => {
        console.log(`\n🚀 ThinkVault API running on http://localhost:${config.port}`);
        console.log(`   Environment: ${config.nodeEnv}`);
        console.log(`   Health: http://localhost:${config.port}/api/health\n`);
    });
}

start();

module.exports = app;
