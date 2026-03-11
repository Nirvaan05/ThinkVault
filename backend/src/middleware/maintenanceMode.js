// Phase 8: Maintenance mode middleware
// Checks app_config 'maintenance_mode' value and blocks non-admin users with 503
// when enabled. Allows admin users and the auth endpoints to pass through.

const { pool } = require('../config/db');

let _cachedValue = null;
let _lastCheck = 0;
const CACHE_TTL_MS = 30_000; // re-check every 30 seconds

async function isMaintenanceModeEnabled() {
    const now = Date.now();
    if (now - _lastCheck < CACHE_TTL_MS && _cachedValue !== null) {
        return _cachedValue;
    }
    try {
        const [rows] = await pool.execute(
            'SELECT config_value FROM app_config WHERE config_key = ? LIMIT 1',
            ['maintenance_mode']
        );
        _cachedValue = rows[0]?.config_value === 'true';
        _lastCheck = now;
    } catch (_) {
        _cachedValue = false; // fail open to avoid locking everyone out on DB error
    }
    return _cachedValue;
}

/**
 * Middleware: returns 503 for non-admin users when maintenance_mode is 'true'.
 * Auth routes (/api/auth/*) are always allowed through so admins can still log in.
 */
async function maintenanceMode(req, res, next) {
    // Always allow auth endpoints so admins can log in
    if (req.path.startsWith('/auth/')) return next();

    const enabled = await isMaintenanceModeEnabled();
    if (!enabled) return next();

    // Allow admin users through
    const role = req.user?.role;
    if (role === 'admin') return next();

    return res.status(503).json({
        status: 'error',
        message: 'The application is currently under maintenance. Please try again later.',
    });
}

module.exports = { maintenanceMode };
