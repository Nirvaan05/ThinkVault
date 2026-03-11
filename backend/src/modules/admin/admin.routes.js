const { Router } = require('express');
const adminController = require('./admin.controller');
const { authenticate } = require('../../middleware/auth');
const { authorize } = require('../../middleware/auth');

const router = Router();

// All admin routes require a valid JWT and the 'admin' role
router.use(authenticate);
router.use(authorize('admin'));

// Existing health endpoint
router.get('/health', adminController.getHealth);

// Metrics and Users (06-02)
router.get('/metrics', adminController.getMetrics);
router.get('/users', adminController.listUsers);

// Configuration Management (06-03)
router.get('/config', adminController.getConfig);
router.get('/config/audit', adminController.getAuditLog);
router.put('/config/:key', adminController.updateConfig);

module.exports = router;
