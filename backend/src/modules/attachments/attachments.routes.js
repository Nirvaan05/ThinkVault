const { Router } = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const attachmentsController = require('./attachments.controller');
const { authenticate } = require('../../middleware/auth');

// ── Multer disk storage ──────────────────────────────────────────────────────
const UPLOADS_DIR = path.join(__dirname, '../../../../uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
    filename: (_req, file, cb) => {
        const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        const ext = path.extname(file.originalname);
        cb(null, `${unique}${ext}`);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB hard limit at transport layer
});

// ── Router ───────────────────────────────────────────────────────────────────
const notesAttachRouter = Router({ mergeParams: true }); // for /notes/:noteId/attachments
const attachRouter = Router();                            // for /attachments/:id/...

notesAttachRouter.use(authenticate);
// POST   /api/notes/:noteId/attachments
notesAttachRouter.post('/:noteId/attachments', upload.single('file'), attachmentsController.uploadAttachment);
// GET    /api/notes/:noteId/attachments
notesAttachRouter.get('/:noteId/attachments', attachmentsController.listAttachments);

attachRouter.use(authenticate);
// GET    /api/attachments/:id/download
attachRouter.get('/:id/download', attachmentsController.downloadAttachment);
// DELETE /api/attachments/:id
attachRouter.delete('/:id', attachmentsController.deleteAttachment);

module.exports = { notesAttachRouter, attachRouter };
