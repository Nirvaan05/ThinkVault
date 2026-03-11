const { Router } = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const notesController = require('./notes.controller');
const attachmentsController = require('../attachments/attachments.controller');
const { validate } = require('../../middleware/validate');
const { createNoteSchema, updateNoteSchema, listNotesSchema, searchNotesSchema } = require('./notes.schemas');
const { authenticate } = require('../../middleware/auth');

// ── Multer disk storage (for attachment uploads) ─────────────────────────────
const UPLOADS_DIR = path.join(__dirname, '../../../../uploads');
if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
    filename: (_req, file, cb) => {
        const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        cb(null, `${unique}${path.extname(file.originalname)}`);
    },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

const router = Router();

// All notes routes require authentication
router.use(authenticate);

// ── Search (must come before /:id to avoid route collision) ─────────────────
router.get('/search', validate(searchNotesSchema, 'query'), notesController.searchNotes);

// ── Attachments (declared BEFORE /:id to avoid catch-all collision) ────────────
router.post('/:noteId/attachments', upload.single('file'), attachmentsController.uploadAttachment);
router.get('/:noteId/attachments', attachmentsController.listAttachments);

// ── Notes CRUD ──────────────────────────────────────────────────────────────
router.post('/', validate(createNoteSchema), notesController.createNote);
router.get('/', validate(listNotesSchema, 'query'), notesController.listNotes);
router.get('/:id', notesController.getNote);
router.patch('/:id', validate(updateNoteSchema), notesController.updateNote);
router.delete('/:id', notesController.deleteNote);

module.exports = router;
