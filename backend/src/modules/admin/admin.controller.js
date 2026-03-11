const os = require('os');
const { z } = require('zod');
const { validate } = require('../../middleware/validate');
const adminService = require('./admin.service');

// Schemas
const paginationSchema = z.object({
    page: z.string().regex(/^\d+$/).optional().transform(Number),
    limit: z.string().regex(/^\d+$/).optional().transform(Number),
});

const configUpdateSchema = z.object({
    value: z.string().min(1, 'Value is required'),
});

/**
 * GET /api/admin/health
 * Returns basic system health metrics for admin dashboards.
 */
async function getHealth(req, res, next) {
    try {
        const uptimeSeconds = process.uptime();
        const memUsage = process.memoryUsage();

        res.status(200).json({
            status: 'success',
            data: {
                server: {
                    status: 'ok',
                    uptime_seconds: Math.floor(uptimeSeconds),
                    node_version: process.version,
                    platform: process.platform,
                },
                memory: {
                    heap_used_mb: (memUsage.heapUsed / 1024 / 1024).toFixed(2),
                    heap_total_mb: (memUsage.heapTotal / 1024 / 1024).toFixed(2),
                    rss_mb: (memUsage.rss / 1024 / 1024).toFixed(2),
                },
                system: {
                    load_avg: os.loadavg(),
                    free_memory_mb: (os.freemem() / 1024 / 1024).toFixed(2),
                    total_memory_mb: (os.totalmem() / 1024 / 1024).toFixed(2),
                    cpu_count: os.cpus().length,
                },
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/admin/metrics
 * Overview metrics for dashboard
 */
async function getMetrics(req, res, next) {
    try {
        const metrics = await adminService.getMetrics();
        res.status(200).json({
            status: 'success',
            data: metrics,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/admin/users
 * List all users with pagination
 */
const listUsers = [
    validate(paginationSchema, 'query'),
    async (req, res, next) => {
        try {
            const data = await adminService.listUsers(req.query);
            res.status(200).json({
                status: 'success',
                data,
            });
        } catch (err) {
            next(err);
        }
    }
];

/**
 * GET /api/admin/config
 * List all configurations
 */
async function getConfig(req, res, next) {
    try {
        const configEntries = await adminService.getConfig();
        res.status(200).json({
            status: 'success',
            data: { config: configEntries },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/admin/config/:key
 * Update a specific configuration value
 */
const updateConfig = [
    validate(configUpdateSchema, 'body'),
    async (req, res, next) => {
        try {
            const result = await adminService.updateConfig(
                req.params.key,
                req.body.value,
                req.user.id
            );
            res.status(200).json({
                status: 'success',
                data: result,
            });
        } catch (err) {
            next(err);
        }
    }
];

/**
 * GET /api/admin/config/audit
 * Get config change logs
 */
const getAuditLog = [
    validate(paginationSchema, 'query'),
    async (req, res, next) => {
        try {
            const data = await adminService.getAuditLog(req.query);
            res.status(200).json({
                status: 'success',
                data,
            });
        } catch (err) {
            next(err);
        }
    }
];

module.exports = {
    getHealth,
    getMetrics,
    listUsers,
    getConfig,
    updateConfig,
    getAuditLog,
};
