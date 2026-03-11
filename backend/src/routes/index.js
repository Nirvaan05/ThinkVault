const { Router } = require('express');
const authRoutes = require('../modules/auth/auth.routes');
const adminRoutes = require('../modules/admin/admin.routes');
const notesRoutes = require('../modules/notes/notes.routes');
const categoriesRoutes = require('../modules/categories/categories.routes');
const tagsRoutes = require('../modules/tags/tags.routes');
const { attachRouter } = require('../modules/attachments/attachments.routes');
const syncRoutes = require('../modules/sync/sync.routes');
const feedbackRoutes = require('../modules/feedback/feedback.routes');

const router = Router();

// Health check
router.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Module routes
router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);
router.use('/notes', notesRoutes);
router.use('/attachments', attachRouter);  // /attachments/:id/download, /attachments/:id
router.use('/categories', categoriesRoutes);
router.use('/tags', tagsRoutes);
router.use('/sync', syncRoutes);
router.use('/feedback', feedbackRoutes);

module.exports = router;
