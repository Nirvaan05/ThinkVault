const { z } = require('zod');
const { validate } = require('../../middleware/validate');
const feedbackService = require('./feedback.service');

// ── Schemas ───────────────────────────────────────────────────────────────────

const submitSchema = z.object({
    type: z.enum(['feedback', 'bug']),
    subject: z.string().min(1).max(255),
    body: z.string().min(1).max(10000),
});

const statusSchema = z.object({
    status: z.enum(['open', 'in_progress', 'resolved', 'closed']),
});

const listQuerySchema = z.object({
    type: z.enum(['feedback', 'bug']).optional(),
    status: z.enum(['open', 'in_progress', 'resolved', 'closed']).optional(),
    page: z.string().regex(/^\d+$/).optional().transform(Number),
    limit: z.string().regex(/^\d+$/).optional().transform(Number),
});

// ── Handlers ─────────────────────────────────────────────────────────────────

/**
 * POST /api/feedback
 * Authenticated user submits feedback or bug report.
 */
const submit = [
    validate(submitSchema, 'body'),
    async (req, res, next) => {
        try {
            const entry = await feedbackService.submit({
                userId: req.user.id,
                type: req.body.type,
                subject: req.body.subject,
                body: req.body.body,
            });
            res.status(201).json({ status: 'success', data: entry });
        } catch (err) {
            next(err);
        }
    },
];

/**
 * GET /api/feedback
 * Admin lists all feedback entries with optional filters.
 */
const list = [
    validate(listQuerySchema, 'query'),
    async (req, res, next) => {
        try {
            const data = await feedbackService.list(req.query);
            res.status(200).json({ status: 'success', data });
        } catch (err) {
            next(err);
        }
    },
];

/**
 * GET /api/feedback/:id
 * Admin views a single feedback entry.
 */
async function getById(req, res, next) {
    try {
        const entry = await feedbackService.get(Number(req.params.id));
        res.status(200).json({ status: 'success', data: entry });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/feedback/:id/status
 * Admin updates the status of a feedback entry.
 */
const updateStatus = [
    validate(statusSchema, 'body'),
    async (req, res, next) => {
        try {
            const entry = await feedbackService.updateStatus(
                Number(req.params.id),
                req.body.status
            );
            res.status(200).json({ status: 'success', data: entry });
        } catch (err) {
            next(err);
        }
    },
];

module.exports = { submit, list, getById, updateStatus };
