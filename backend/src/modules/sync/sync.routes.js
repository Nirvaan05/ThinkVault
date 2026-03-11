const { Router } = require('express');
const syncController = require('./sync.controller');
const { authenticate } = require('../../middleware/auth');

const router = Router();

router.use(authenticate);

// GET /api/sync/delta?since=<ISO8601>
router.get('/delta', syncController.delta);

module.exports = router;
