const { Router } = require('express');
const feedbackController = require('./feedback.controller');
const { authenticate, authorize } = require('../../middleware/auth');

const router = Router();

// ── User routes (authenticated) ───────────────────────────────────────────────
// POST /api/feedback — submit feedback or bug report
router.post('/', authenticate, feedbackController.submit);

// ── Admin routes (admin only) ─────────────────────────────────────────────────
// GET /api/feedback — list all with filters
router.get('/', authenticate, authorize('admin'), feedbackController.list);

// GET /api/feedback/:id — view single entry
router.get('/:id', authenticate, authorize('admin'), feedbackController.getById);

// PATCH /api/feedback/:id/status — update entry status
router.patch('/:id/status', authenticate, authorize('admin'), feedbackController.updateStatus);

module.exports = router;
